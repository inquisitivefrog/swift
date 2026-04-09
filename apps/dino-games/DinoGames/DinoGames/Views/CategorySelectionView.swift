//
//  CategorySelectionView.swift
//  DinoGames
//
//  Created by Cursor on 1/28/26.
//

import SwiftUI
import UIKit

enum GameCategory: String, CaseIterable, Identifiable {
    case land
    case air
    case mosasaurs
    case plesiosaurs
    case ichthyosaurs
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .land: return "Dinosaurs"
        case .air: return "Pterosaurs"
        case .mosasaurs: return "Mosasaurs"
        case .plesiosaurs: return "Plesiosaurs"
        case .ichthyosaurs: return "Ichthyosaurs"
        }
    }
    
    /// Expected asset name (add these images to `Assets.xcassets` when ready).
    var imageAssetName: String {
        switch self {
        case .land: return "category-land"
        case .air: return "category-air"
        case .mosasaurs: return "category-mosasaurs"
        case .plesiosaurs: return "category-plesiosaurs"
        case .ichthyosaurs: return "category-ichthyosaurs"
        }
    }
    
    var fallbackSystemImageName: String {
        switch self {
        case .land: return "leaf.fill"
        case .air: return "wind"
        case .mosasaurs: return "lizard.fill"
        case .plesiosaurs: return "tortoise.fill"
        case .ichthyosaurs: return "fish.fill"
        }
    }
}

struct CategorySelectionView: View {
    @State private var selectedCategory: GameCategory?
    @State private var navigateToGames = false
    @State private var showCredits = false
    @State private var speechManager = SpeechManager()
    /// Each category image is disabled until its cover message has played.
    @State private var enabledLand = false
    @State private var enabledAir = false
    @State private var enabledMosasaurs = false
    @State private var enabledPlesiosaurs = false
    @State private var enabledIchthyosaurs = false
    /// True only after the fourth clip (marine reptiles) has finished; prevents tapping during that clip and overlapping audio.
    @State private var coverSequenceComplete = false
    @State private var hasStartedCoverSequence = false
    
    private func isEnabled(_ category: GameCategory) -> Bool {
        switch category {
        case .land: return enabledLand
        case .air: return enabledAir
        case .mosasaurs: return enabledMosasaurs
        case .plesiosaurs: return enabledPlesiosaurs
        case .ichthyosaurs: return enabledIchthyosaurs
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title fixed at top so it isn't pushed off by larger cards
                Text("Choose A Game Type")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(GameCategory.allCases) { category in
                            CategoryCard(
                                category: category,
                                isSelected: selectedCategory == category,
                                isDisabled: !isEnabled(category),
                                onTap: { handleTap(category) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Credits") { showCredits = true }
                }
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
            .onAppear {
                if !hasStartedCoverSequence {
                    hasStartedCoverSequence = true
                    startCoverSequence()
                }
            }
            .onDisappear {
                speechManager.stopCurrentAudio()
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GameSelectionView(category: selectedCategory ?? .land, navigateToCategories: $navigateToGames)
            }
            // Ignore taps until all four cover clips have finished (avoids overlapping audio when user taps right after sea is enabled)
            .allowsHitTesting(coverSequenceComplete)
        }
    }
    
    /// Four-step cover: welcome → enable land + dinosaurs → enable air + pterosaurs → enable sea + marine. Chain with short delay to avoid clicks.
    private func startCoverSequence() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverWelcomeDone()
        }
        speechManager.speak("cover-choose-a-game-type")
    }
    
    private func coverWelcomeDone() {
        enabledLand = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverLandDone()
        }
        speechManager.speak("cover-dinosaurs-on-land", chainDelay: true)
    }
    
    private func coverLandDone() {
        enabledAir = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverAirDone()
        }
        speechManager.speak("cover-pterosaurs-in-the-sky", chainDelay: true)
    }
    
    private func coverAirDone() {
        enabledMosasaurs = true
        enabledPlesiosaurs = true
        enabledIchthyosaurs = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverSequenceComplete = true
        }
        speechManager.speak("cover-and-marine-reptiles-in-the-sea", chainDelay: true)
    }
    
    private func handleTap(_ category: GameCategory) {
        selectedCategory = category
        speechManager.speak(category.title)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            navigateToGames = true
        }
    }
}

private struct CategoryCard: View {
    let category: GameCategory
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if UIImage(named: category.imageAssetName) != nil {
                    Image(category.imageAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minHeight: 160, maxHeight: 200)
                        .padding(.top, 6)
                } else {
                    Image(systemName: category.fallbackSystemImageName)
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(height: 160)
                        .padding(.top, 6)
                }
                
                // Subtitle appears when tapped/selected (for accessibility + parents).
                if isSelected {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color.blue.opacity(0.18) : Color.gray.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .animation(.spring(response: 0.28), value: isSelected)
            .opacity(isDisabled ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    CategorySelectionView()
}

