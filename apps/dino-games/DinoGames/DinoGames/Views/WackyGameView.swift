//
//  WackyGameView.swift
//  DinoGames
//
//  Shows three wacky dinosaur images at random. Each image is shown with a short
//  delay before the name plays so the player can admire the image first.
//  Add ImageSets to Assets with prefix "wacky-" (e.g. wacky-trex, wacky-triceratops).
//

/// Delay (seconds) after each image appears before playing its name—lets the player admire the image first.
private let admireDelay: TimeInterval = 1.2

import SwiftUI

struct WackyGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

/// Image set name → display name (for label and audio; display name matches SpeechManager).
private let wackyImageToName: [(imageName: String, displayName: String)] = [
    ("wacky-trex", "T-Rex"),
    ("wacky-triceratops", "Triceratops"),
    ("wacky-stegosaurus", "Stegosaurus"),
    ("wacky-velociraptor", "Velociraptor"),
    ("wacky-therizinosaurus", "Therizinosaurus"),
    ("wacky-spinosaurus", "Spinosaurus"),
    ("wacky-apatosaurus", "Apatosaurus"),
    ("wacky-ankylosaurus", "Ankylosaurus"),
    ("wacky-corythosaurus", "Corythosaurus"),
    ("wacky-parasaurolophus", "Parasaurolophus"),
    ("wacky-iguanodon", "Iguanodon"),
    ("wacky-troodon", "Troodon"),
    ("wacky-diplodocus", "Diplodocus"),
    ("wacky-pachycephalosaurus", "Pachycephalosaurus"),
]

struct WackyGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: WackyGameConfig
    
    @State private var speechManager = SpeechManager()
    /// Three (imageName, displayName) chosen at random for this session.
    @State private var selectedItems: [(imageName: String, displayName: String)] = []
    /// Which of the three is currently shown (0, 1, or 2).
    @State private var currentIndex = 0
    /// Victory sequence: after showing all 3, walk list then success image + good-job + crowd.
    @State private var showVictory = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    
    var body: some View {
        NavigationView {
            Group {
                if showVictory {
                    victoryView
                } else {
                    VStack(spacing: 12) {
                        if selectedItems.isEmpty {
                            Text("Loading…")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if currentIndex < selectedItems.count {
                    let item = selectedItems[currentIndex]
                    if UIImage(named: item.imageName) != nil {
                        Image(item.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 420)
                            .padding(.horizontal)
                    } else {
                        Text("Wacky!")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    Text(item.displayName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startSequence()
            }
        }
    }
    
    // MARK: - Victory (standard: scroll list → success image → good-job + crowd → dismiss)
    
    private var victoryView: some View {
        VictorySplitColumnView(
                listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: selectedItems.count),
                showSuccessPhase: endSequenceStep == 2,
                endHighlightIndex: endHighlightIndex,
                gameTitle: gameConfig.title,
                scrollRows: {
                    ForEach(Array(selectedItems.enumerated()), id: \.offset) { index, item in
                        let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                        HStack(spacing: 16) {
                            wackyVictoryImage(item: item, isHighlighted: isHighlighted)
                            Text(item.displayName)
                                .font(.title2)
                                .fontWeight(isHighlighted ? .semibold : .regular)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(isHighlighted ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(height: StandardVictoryLayout.rowHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .id(index)
                    }
                },
                successPhase: {
                    LandGameVictorySuccessStingerThenContinue(
                        candidateSuccessImageNames: ["game-wacky-dinosaurs-success", "game-wacky-dinosaurs", "wacky-trex"],
                        catalogGameIdForStinger: gameConfig.id,
                        speechManager: speechManager,
                        onContinue: playGoodJobAndCrowdThenDismiss
                    )
                }
            )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if selectedItems.isEmpty {
                endSequenceStep = 2
            } else {
                let item = selectedItems[0]
                let audioKey = "dino-\(item.imageName.replacingOccurrences(of: "wacky-", with: ""))"
                speechManager.speak(audioKey: audioKey, fallbackText: item.displayName)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
            }
        }
    }
    
    private func wackyVictoryImage(item: (imageName: String, displayName: String), isHighlighted: Bool) -> some View {
        Group {
            if UIImage(named: item.imageName) != nil {
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(isHighlighted ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 72, height: 72)
                    .overlay(Text("🦖").font(.system(size: 40)))
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }
    
    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < selectedItems.count {
            let item = selectedItems[endHighlightIndex]
            let audioKey = "dino-\(item.imageName.replacingOccurrences(of: "wacky-", with: ""))"
            speechManager.speak(audioKey: audioKey, fallbackText: item.displayName)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
        } else {
            endSequenceStep = 2
        }
    }
    
    private func playGoodJobAndCrowdThenDismiss() {
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                LandDinosaurProgress.notifyCompletionIfLandGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: gameConfig.id)
            isPresented = false
        }
    }
    
    private func startSequence() {
        guard wackyImageToName.count >= 3 else {
            selectedItems = Array(wackyImageToName)
            if !selectedItems.isEmpty {
                speechManager.speak(selectedItems[0].displayName)
            }
            return
        }
        selectedItems = Array(wackyImageToName.shuffled().prefix(3))
        currentIndex = 0
        
        // Delay before first name so player can admire the image
        DispatchQueue.main.asyncAfter(deadline: .now() + admireDelay) {
            speechManager.speak(selectedItems[0].displayName)
        }
        
        // Show first ~3s, second ~3s, third ~3s, then exit; play name after admireDelay when each appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            currentIndex = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + admireDelay) {
                if selectedItems.count > 1 {
                    speechManager.speak(selectedItems[1].displayName)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            currentIndex = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + admireDelay) {
                if selectedItems.count > 2 {
                    speechManager.speak(selectedItems[2].displayName)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
            showVictory = true
        }
    }
}

// MARK: - Configs

enum WackyGameConfigs {
    static let wackyDinosaurs = WackyGameConfig(
        id: "wacky-dinosaurs",
        title: "Wacky Dinosaurs!",
        introAudio: nil
    )
}

#Preview {
    WackyGameView(isPresented: .constant(true), gameConfig: WackyGameConfigs.wackyDinosaurs)
}
