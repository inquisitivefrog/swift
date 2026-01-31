//
//  WeighGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/24/26.
//

import SwiftUI
import UIKit

// MARK: - Data Models

struct WeighableItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String? // Optional image name in Assets.xcassets
    let emoji: String // Emoji fallback
    let weight: Int // Weight value for comparison (1-8 scale, allows multiple items per side)
    let category: String // "dinosaur", "person", "vehicle", "building"
}

// MARK: - Game Configuration

struct WeighGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [WeighableItem]
    
    // Threshold for "nearly the same" weight (within this difference)
    let similarWeightThreshold: Int = 1
}

// MARK: - Main View

struct WeighGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: WeighGameConfig
    
    @State private var speechManager = SpeechManager()
    @State private var selectedLeftItem: WeighableItem?
    @State private var selectedRightItem: WeighableItem?
    @State private var isWeighing = false
    @State private var seesawAngle: Double = 0 // -15 to +15 degrees
    @State private var leftItemOffset: CGFloat = 0
    @State private var rightItemOffset: CGFloat = 0
    @State private var leftItemOpacity: Double = 1.0
    @State private var showSpeedLines = false
    @State private var roundsCompleted = 0
    private let maxRounds = 3
    /// When true, the user can tap a second dinosaur; stays false until the first dinosaur's name audio has finished.
    @State private var canSelectSecondDinosaur = false
    
    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top padding to prevent truncation
                Spacer()
                    .frame(height: geometry.size.height * 0.05) // 5% padding at top
                
                // Top - Item grid (2 rows x 4 columns) or game-over message
                if isGameOver {
                    VStack(spacing: 16) {
                        Text("Great job!")
                            .font(.title)
                            .foregroundColor(.primary)
                        Text("You weighed six dinosaurs.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: geometry.size.width)
                    .padding(.top, 20)
                } else {
                    VStack(spacing: 10) {
                        Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        // 3×3 grid (9 items)
                        VStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { row in
                                HStack(spacing: 10) {
                                    ForEach(Array(gameConfig.items.dropFirst(row * 3).prefix(3))) { item in
                                        ItemCard(
                                            item: item,
                                            isSelected: selectedLeftItem?.id == item.id || selectedRightItem?.id == item.id,
                                            isDisabled: isWeighing || isGameOver || (selectedLeftItem != nil && selectedRightItem != nil) || (selectedLeftItem != nil && selectedRightItem == nil && !canSelectSecondDinosaur)
                                        ) {
                                            handleItemTap(item)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                    .frame(width: geometry.size.width)
                }
                
                // Increased space between images and seesaw
                Spacer()
                    .frame(height: geometry.size.height * 0.15) // 15% space between images and seesaw
                
                // Bottom - Seesaw area (centered in remaining space)
                VStack {
                    Spacer()
                        .frame(minHeight: 10) // Small spacer
                    
                    ZStack {
                        // A-frame support (playground seesaw style)
                        SeesawSupportView()
                            .offset(y: 45)
                        
                        // Pivot (fulcrum)
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.brown, lineWidth: 2))
                            .offset(y: 28)
                        
                        // Main beam (shorter than seat span so seats extend past the bar – seesaw look)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .frame(width: geometry.size.width * 0.38, height: 22)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(y: 28)
                        
                        // Left platform (sits past the end of the beam)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brown.opacity(0.9))
                            .frame(width: 56, height: 12)
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(x: -(geometry.size.width * 0.28), y: 14)
                        
                        // Right platform (sits past the end of the beam)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.brown.opacity(0.9))
                            .frame(width: 56, height: 12)
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(x: geometry.size.width * 0.28, y: 14)
                    
                        // Left side item (on left seat)
                        if let leftItem = selectedLeftItem {
                            Group {
                                if let imageName = leftItem.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else {
                                    Text(leftItem.emoji)
                                        .font(.system(size: 80))
                                }
                            }
                            .offset(x: -(geometry.size.width * 0.28), y: leftItemOffset - 70)
                            .opacity(leftItemOpacity)
                            
                            if showSpeedLines && selectedRightItem != nil {
                                SpeedLinesView()
                                    .offset(x: geometry.size.width * 0.28, y: rightItemOffset - 70)
                            }
                        }
                        
                        // Right side item (on right seat)
                        if let rightItem = selectedRightItem {
                            Group {
                                if let imageName = rightItem.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else {
                                    Text(rightItem.emoji)
                                        .font(.system(size: 80))
                                }
                            }
                            .offset(x: geometry.size.width * 0.28, y: rightItemOffset - 70)
                        }
                    }
                    .frame(height: 250) // Seesaw area height
                    
                    // Use remaining space at bottom (shifted down from top)
                    Spacer()
                }
                .frame(width: geometry.size.width)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        .onAppear {
            // Force landscape orientation immediately
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
                // Fallback method - force rotation
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        }
        .onDisappear {
            // Allow rotation back to portrait when leaving
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    private func handleItemTap(_ item: WeighableItem) {
        guard !isWeighing else { return }
        
        if selectedLeftItem == nil {
            // First selection: show name, play audio, allow second selection only after name finishes
            selectedLeftItem = item
            canSelectSecondDinosaur = false
            speechManager.onAudioFinished = {
                self.canSelectSecondDinosaur = true
                self.speechManager.onAudioFinished = nil
            }
            speechManager.speak(item.name)
        } else if selectedRightItem == nil && selectedLeftItem?.id != item.id && canSelectSecondDinosaur {
            // Second selection: show name, play audio, then start weighing when name finishes
            selectedRightItem = item
            canSelectSecondDinosaur = false
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.startWeighing()
            }
            speechManager.speak(item.name)
        }
    }
    
    private func startWeighing() {
        guard let left = selectedLeftItem,
              let right = selectedRightItem else { return }
        
        isWeighing = true
        let weightDiff = left.weight - right.weight
        
        // Pause 0.2 seconds before adjusting seesaw
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 1.5)) {
                if abs(weightDiff) <= gameConfig.similarWeightThreshold {
                    // Similar weight - slight tilt, one higher
                    if weightDiff > 0 {
                        seesawAngle = -3 // Slight tilt left (reversed)
                        rightItemOffset = -20 // Right item higher
                    } else {
                        seesawAngle = 3 // Slight tilt right (reversed)
                        leftItemOffset = -20 // Left item higher
                    }
                } else if weightDiff > 0 {
                    // Left is heavier - left side goes down (reversed direction)
                    seesawAngle = -15 // Tilt left (reversed)
                    leftItemOffset = 20 // Left item goes down
                    rightItemOffset = -20 // Right item goes up
                    showSpeedLines = true
                } else {
                    // Right is heavier - right side goes down, left launches up
                    seesawAngle = 15 // Tilt right (reversed)
                    rightItemOffset = 20 // Right item goes down
                    leftItemOffset = -150 // Launch up (from -70 base)
                    leftItemOpacity = 0 // Fade out
                }
            }
            
            // After tilt: announce result — either "they both weigh about the same" or "[name] is heavier".
            // Only after that audio finishes do we count the round and show game over or reset.
            let isNearlySame = abs(weightDiff) <= self.gameConfig.similarWeightThreshold
            if isNearlySame {
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.finishWeighingRound()
                }
                self.speechManager.speak("they-both-weigh-about-the-same")
            } else {
                let heavier = weightDiff >= 0 ? left : right
                self.speechManager.onAudioFinished = {
                    self.speechManager.speak("is-heavier", chainDelay: true)
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        // Pregnant pause so the player can enjoy the moment (e.g. T-Rex launched into space)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.finishWeighingRound()
                        }
                    }
                }
                self.speechManager.speak(heavier.name)
            }
        }
    }
    
    /// Called when the result audio for this round has finished (so the winner is declared before we advance).
    private func finishWeighingRound() {
        roundsCompleted += 1
        if roundsCompleted >= maxRounds {
            isWeighing = false
            selectedLeftItem = nil
            selectedRightItem = nil
            speechManager.speak("great-job-you-weighed-six-dinosaurs")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.isPresented = false
            }
        } else {
            resetWeighing()
        }
    }
    
    private func resetWeighing() {
        withAnimation {
            seesawAngle = 0
            leftItemOffset = 0
            rightItemOffset = 0
            leftItemOpacity = 1.0
            showSpeedLines = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedLeftItem = nil
            selectedRightItem = nil
            isWeighing = false
            canSelectSecondDinosaur = false
        }
    }
}

// MARK: - Components

struct ItemCard: View {
    let item: WeighableItem
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let imageName = item.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                } else {
                    Text(item.emoji)
                        .font(.system(size: 60))
                }
                if isSelected {
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        .disabled(isDisabled && !isSelected)
    }
}

struct SpeedLinesView: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 2, height: 40)
            }
        }
    }
}

// A-frame support under the seesaw (wider base, playground style)
struct SeesawSupportView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Left leg
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12, height: 58)
                .rotationEffect(.degrees(-22))
                .offset(x: -48)
            // Right leg
            Rectangle()
                .fill(Color.brown.opacity(0.9))
                .frame(width: 12, height: 58)
                .rotationEffect(.degrees(22))
                .offset(x: 48)
            // Base bar (wider for stability)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brown)
                .frame(width: 140, height: 12)
        }
    }
}

// MARK: - Dinosaur Weight Pool (for random selection)
//
// Weight chart — estimated adult body mass per species (for consistent seesaw ordering):
// ┌─────────────────────┬──────────────────┬─────────────────────────────────────────┐
// │ Species              │ Est. weight (kg) │ Notes (for future reference)             │
// ├─────────────────────┼──────────────────┼─────────────────────────────────────────┤
// │ Velociraptor         │ ~20              │ Small theropod; ~2 m long                │
// │ Troodon              │ ~50              │ Small theropod; ~2.4 m long             │
// │ Parasaurolophus      │ ~2,700           │ Hadrosaur; ~9–10 m long                  │
// │ Corythosaurus        │ ~3,500           │ Hadrosaur; ~9–10 m long                    │
// │ Iguanodon            │ ~4,500           │ Ornithopod; ~9–10 m (tie with Stegosaurus) │
// │ Therizinosaurus      │ ~5,000           │ Therizinosaur; large; heavier than hadrosaurs │
// │ Stegosaurus          │ ~4,500           │ Stegosaur; ~7–9 m (tie with Iguanodon)   │
// │ Ankylosaurus         │ ~6,000           │ Ankylosaur; heavily armored               │
// │ Spinosaurus          │ ~7,000           │ Spinosaurid; semi-aquatic; ~14–18 m      │
// │ T-Rex                │ ~8,000           │ Large theropod; ~12 m long               │
// │ Triceratops          │ ~9,000           │ Ceratopsian; ~8–9 m long                  │
// │ Apatosaurus          │ ~25,000          │ Sauropod; ~21–23 m long                   │
// └─────────────────────┴──────────────────┴─────────────────────────────────────────┘

private struct WeighableDinosaurPoolEntry {
    let name: String
    let imageName: String
    let emoji: String
    /// Estimated adult body mass in kg (for ordering only; used to assign game weight 1–9).
    let estimatedWeightKg: Double
}

private let allWeighableDinosaurs: [WeighableDinosaurPoolEntry] = [
    WeighableDinosaurPoolEntry(name: "Velociraptor", imageName: "dino-velociraptor", emoji: "🦖", estimatedWeightKg: 20),
    WeighableDinosaurPoolEntry(name: "Troodon", imageName: "dino-troodon", emoji: "🦉", estimatedWeightKg: 50),
    WeighableDinosaurPoolEntry(name: "Parasaurolophus", imageName: "dino-parasaurolophus", emoji: "🦆", estimatedWeightKg: 2_700),
    WeighableDinosaurPoolEntry(name: "Corythosaurus", imageName: "dino-corythosaurus", emoji: "🦆", estimatedWeightKg: 3_500),
    WeighableDinosaurPoolEntry(name: "Iguanodon", imageName: "dino-iguanodon", emoji: "🦎", estimatedWeightKg: 4_500),
    WeighableDinosaurPoolEntry(name: "Therizinosaurus", imageName: "dino-therizinosaurus", emoji: "🦕", estimatedWeightKg: 5_000),
    WeighableDinosaurPoolEntry(name: "Stegosaurus", imageName: "dino-stegosaurus", emoji: "🦎", estimatedWeightKg: 4_500),
    WeighableDinosaurPoolEntry(name: "Ankylosaurus", imageName: "dino-ankylosaurus", emoji: "🛡️", estimatedWeightKg: 6_000),
    WeighableDinosaurPoolEntry(name: "Spinosaurus", imageName: "dino-spinosaurus", emoji: "🦖", estimatedWeightKg: 7_000),
    WeighableDinosaurPoolEntry(name: "T-Rex", imageName: "dino-trex", emoji: "🦖", estimatedWeightKg: 8_000),
    WeighableDinosaurPoolEntry(name: "Triceratops", imageName: "dino-triceratops", emoji: "🦏", estimatedWeightKg: 9_000),
    WeighableDinosaurPoolEntry(name: "Apatosaurus", imageName: "dino-apatosaurus", emoji: "🦕", estimatedWeightKg: 25_000),
]

// MARK: - Game Configurations

struct WeighGameConfigs {
    /// Fixed config used as template (same id/title/intro); items are ignored when opening — use `weighDinosaurRandomized()` for play.
    static let weighDinosaur = WeighGameConfig(
        id: "weigh-dinosaur",
        title: "Weigh the Dinosaur!",
        introAudio: "game-intro-weigh",
        items: [] // Not used; caller uses weighDinosaurRandomized() for a random set of 9.
    )

    /// Returns a config with 9 dinosaurs chosen at random from the pool, ordered by estimated weight.
    /// Dinosaurs with the same estimated weight get the same game weight so "they both weigh about the same" can play.
    static func weighDinosaurRandomized() -> WeighGameConfig {
        let chosen = allWeighableDinosaurs.shuffled().prefix(9).sorted { $0.estimatedWeightKg < $1.estimatedWeightKg }
        var rank = 0
        var prevKg: Double = -1
        let items = chosen.enumerated().map { index, entry in
            if entry.estimatedWeightKg > prevKg {
                rank += 1
                prevKg = entry.estimatedWeightKg
            }
            return WeighableItem(
                id: index + 1,
                name: entry.name,
                imageName: entry.imageName,
                emoji: entry.emoji,
                weight: rank,
                category: "dinosaur"
            )
        }
        return WeighGameConfig(
            id: "weigh-dinosaur",
            title: "Weigh the Dinosaur!",
            introAudio: "game-intro-weigh",
            items: items
        )
    }
}

#Preview {
    WeighGameView(isPresented: .constant(true), gameConfig: WeighGameConfigs.weighDinosaurRandomized())
}
