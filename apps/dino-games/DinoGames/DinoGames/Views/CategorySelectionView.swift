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
    case sea
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .land: return "Dinosaurs"
        case .sea: return "Marine Reptiles"
        case .air: return "Pterosaurs"
        }
    }
    
    /// Expected asset name (add these images to `Assets.xcassets` when ready).
    var imageAssetName: String {
        switch self {
        case .land: return "category-land"
        case .sea: return "category-sea"
        case .air: return "category-air"
        }
    }
    
    var fallbackSystemImageName: String {
        switch self {
        case .land: return "leaf.fill"
        case .sea: return "drop.fill"
        case .air: return "wind"
        }
    }
}

struct CategorySelectionView: View {
    @State private var selectedCategory: GameCategory?
    @State private var navigateToGames = false
    @State private var speechManager = SpeechManager()
    @State private var isSpeaking = false
    @State private var hasPlayedWelcome = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Choose A Game Type")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 24)
                
                VStack(spacing: 18) {
                    ForEach(GameCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category,
                            isDisabled: isSpeaking,
                            onTap: { handleTap(category) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Track when TTS/audio finishes so we can re-enable taps quickly.
                speechManager.onAudioFinished = {
                    isSpeaking = false
                }
                
                // Play welcome audio when view first appears (after splash screen)
                if !hasPlayedWelcome {
                    hasPlayedWelcome = true
                    isSpeaking = true
                    speechManager.speak("welcome-to-dino-games")
                }
            }
            .onDisappear {
                // Fade out category name audio when navigating to game list to avoid a click
                speechManager.stopCurrentAudio()
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GameSelectionView(category: selectedCategory ?? .land)
            }
            .allowsHitTesting(!isSpeaking) // Disable interaction while welcome audio plays
            .opacity(isSpeaking ? 0.7 : 1.0) // Visual indicator that interaction is disabled
        }
    }
    
    private func handleTap(_ category: GameCategory) {
        selectedCategory = category
        
        // Speak the category name. We don't have recorded audio yet, so this will fall back to TTS.
        isSpeaking = true
        speechManager.speak(category.title)
        
        // Navigate after a short moment so the category name audio can finish (or nearly finish) before the next screen.
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
                        .frame(height: 120)
                        .padding(.top, 6)
                } else {
                    Image(systemName: category.fallbackSystemImageName)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(height: 120)
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
            .padding(.vertical, 10)
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

