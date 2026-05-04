//
//  CategorySelectionView.swift
//  DinoGames
//
//  Created by Cursor on 1/28/26.
//

import SwiftUI
import UIKit

/// Leaf category used by `GameCatalog` and game views (land / air / marine reptiles).
enum GameCategory: String, CaseIterable, Identifiable, Hashable {
    case land
    case air
    case marineReptiles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .land: return "Dinosaurs"
        case .air: return "Pterosaurs"
        case .marineReptiles: return "Marine Reptiles"
        }
    }

    /// Expected asset name (add these images to `Assets.xcassets` when ready).
    var imageAssetName: String {
        switch self {
        case .land: return "category-land"
        case .air: return "category-air"
        case .marineReptiles: return "category-sea"
        }
    }

    var fallbackSystemImageName: String {
        switch self {
        case .land: return "leaf.fill"
        case .air: return "wind"
        case .marineReptiles: return "water.waves"
        }
    }
}

/// Top-level choice on the splash screen (three cards: Dinosaurs, Pterosaurs, Sea).
private enum RootGameType: String, CaseIterable, Identifiable {
    case dinosaurs
    case pterosaurs
    case sea

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dinosaurs: return "Dinosaurs"
        case .pterosaurs: return "Pterosaurs"
        case .sea: return "Sea"
        }
    }

    var imageAssetName: String {
        switch self {
        case .dinosaurs: return "category-land"
        case .pterosaurs: return "category-air"
        case .sea: return "category-sea"
        }
    }

    var fallbackSystemImageName: String {
        switch self {
        case .dinosaurs: return "leaf.fill"
        case .pterosaurs: return "wind"
        case .sea: return "water.waves"
        }
    }
}

private enum CategoryNavRoute: Hashable {
    case gameLevels(GameCategory)
}

struct CategorySelectionView: View {
    @State private var navigationPath: [CategoryNavRoute] = []
    @State private var selectedRoot: RootGameType?
    @State private var speechManager = SpeechManager()
    @State private var enabledDinosaurs = false
    @State private var enabledPterosaurs = false
    @State private var enabledSea = false
    @State private var coverSequenceComplete = false
    @State private var hasStartedCoverSequence = false

    private func isEnabled(_ root: RootGameType) -> Bool {
        switch root {
        case .dinosaurs: return enabledDinosaurs
        case .pterosaurs: return enabledPterosaurs
        case .sea: return enabledSea
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Text("Choose A Game Type")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(RootGameType.allCases) { root in
                            RootCategoryCard(
                                root: root,
                                isSelected: selectedRoot == root,
                                isDisabled: !isEnabled(root),
                                onTap: { handleRootTap(root) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !hasStartedCoverSequence {
                    hasStartedCoverSequence = true
                    startCoverSequence()
                }
            }
            .onDisappear {
                speechManager.stopCurrentAudio()
            }
            .allowsHitTesting(coverSequenceComplete)
            .navigationDestination(for: CategoryNavRoute.self) { route in
                switch route {
                case .gameLevels(let category):
                    GameSelectionView(category: category)
                }
            }
        }
    }

    /// Welcome → Dinosaurs → Pterosaurs → Sea (marine), then allow taps.
    private func startCoverSequence() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverWelcomeDone()
        }
        speechManager.speak("cover-choose-a-game-type")
    }

    private func coverWelcomeDone() {
        enabledDinosaurs = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverLandDone()
        }
        speechManager.speak("cover-dinosaurs-on-land", chainDelay: true)
    }

    private func coverLandDone() {
        enabledPterosaurs = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverAirDone()
        }
        speechManager.speak("cover-pterosaurs-in-the-sky", chainDelay: true)
    }

    private func coverAirDone() {
        enabledSea = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.coverSequenceComplete = true
        }
        speechManager.speak("cover-and-marine-reptiles-in-the-sea", chainDelay: true)
    }

    private func handleRootTap(_ root: RootGameType) {
        selectedRoot = root
        speechManager.speak(root.title)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch root {
            case .dinosaurs:
                navigationPath.append(.gameLevels(.land))
            case .pterosaurs:
                navigationPath.append(.gameLevels(.air))
            case .sea:
                navigationPath.append(.gameLevels(.marineReptiles))
            }
        }
    }
}

// MARK: - Root splash cards (Dinosaurs / Pterosaurs / Sea)

private struct RootCategoryCard: View {
    let root: RootGameType
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if UIImage(named: root.imageAssetName) != nil {
                    Image(root.imageAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minHeight: 160, maxHeight: 200)
                        .padding(.top, 6)
                } else {
                    Image(systemName: root.fallbackSystemImageName)
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(height: 160)
                        .padding(.top, 6)
                }

                if isSelected {
                    Text(root.title)
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
