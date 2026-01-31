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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else {
                        Text("Wacky!")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Text(item.displayName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startSequence()
            }
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
            isPresented = false
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
