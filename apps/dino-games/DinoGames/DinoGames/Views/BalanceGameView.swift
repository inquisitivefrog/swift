//
//  BalanceGameView.swift
//  DinoGames
//
//  Balance the Dinosaurs: pick a heavy dinosaur, then add dinos to the other side until the seesaw balances (each dino once).
//

import SwiftUI
import UIKit

// MARK: - Data Models

struct BalanceItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String?
    let emoji: String
    let estimatedWeightKg: Double
}

struct BalanceGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [BalanceItem] // 9 dinosaurs for this round
}

// MARK: - Main View

enum BalancePhase {
    case selectHeavy       // Tap one dinosaur to put on the left
    case adding            // Tap to add dinos to the right (each once)
    case victory           // Balanced – show row + Congratulations!
    case ranOut            // Used all 8 and still too light
}

struct BalanceGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: BalanceGameConfig

    @State private var speechManager = SpeechManager()
    @State private var phase: BalancePhase = .selectHeavy
    @State private var leftItem: BalanceItem?
    @State private var rightItems: [BalanceItem] = []
    @State private var availableToAdd: [BalanceItem] = []

    @State private var seesawAngle: Double = 0
    @State private var leftItemOffset: CGFloat = 0
    @State private var rightItemOffset: CGFloat = 0
    @State private var leftItemOpacity: Double = 1.0
    @State private var rightItemOpacity: Double = 1.0
    @State private var showSpeedLines = false
    @State private var lighterFlewFromLeft: Bool? = nil
    @State private var canSelectNext = false

    /// End sequence: -1 none, 0 ranOut playing you-did-it, 1 highlighting each dino, 2 playing crowd-cheering
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    @State private var hasStartedRanOutEndAudio = false
    /// Prevents "game-balance-see-I-told-you" from playing twice when balanced with 1–2 items
    @State private var hasPlayedSeeIToldYou = false

    private var leftMass: Double { leftItem?.estimatedWeightKg ?? 0 }
    private var rightMass: Double { rightItems.reduce(0) { $0 + $1.estimatedWeightKg } }
    private var massDiff: Double { leftMass - rightMass }
    private var isWithin10Percent: Bool { leftMass > 0 && rightMass >= leftMass * 0.9 && rightMass < leftMass }
    private var isBalanced: Bool { leftMass > 0 && rightMass >= leftMass }
    private var isRightWayHeavier: Bool { leftMass > 0 && rightMass >= leftMass * 1.2 }
    private var allDinosaursUsed: [BalanceItem] {
        guard let left = leftItem else { return rightItems }
        return [left] + rightItems
    }

    /// Heavy = in top half of game's 9 items by weight; light = bottom half.
    private func isHeavy(_ item: BalanceItem) -> Bool {
        let sorted = gameConfig.items.sorted { $0.estimatedWeightKg < $1.estimatedWeightKg }
        guard let threshold = sorted.dropFirst(4).first?.estimatedWeightKg else { return true }
        return item.estimatedWeightKg >= threshold
    }

    /// Extra vertical space between "available to add" and scale when 3rd, 5th, or 7th dinosaur on right.
    private var addingPhaseExtraSpacing: CGFloat {
        guard phase == .adding else { return 0 }
        if rightItems.count >= 7 { return 66 }
        if rightItems.count >= 5 { return 44 }
        if rightItems.count >= 3 { return 22 }
        return 0
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height: geometry.size.height * 0.04)

                if phase == .victory || phase == .ranOut {
                    victoryOrRanOutView
                } else if phase == .selectHeavy {
                    selectHeavyView(geometry: geometry)
                } else {
                    addingView(geometry: geometry)
                }

                Spacer().frame(height: geometry.size.height * 0.12 + addingPhaseExtraSpacing)
                seesawView(geometry: geometry)
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // No Done button; end sequence plays you-did-it → highlight each → crowd-cheering → auto-dismiss
            if phase != .victory && phase != .ranOut {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .onAppear {
            // Intro already played on transition screen (game-can-you-balance-the-dinosaurs); don't repeat
            if phase == .selectHeavy {
                speechManager.speak("game-balance-choose-a-heavy-dinosaur")
                speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil }
            }
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        }
        .onDisappear {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }

    // MARK: - Select heavy (phase 1)

    private func selectHeavyView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Text("Choose a heavy dinosaur")
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(Array(gameConfig.items.dropFirst(row * 3).prefix(3))) { item in
                            BalanceItemCard(item: item) {
                                handleSelectHeavy(item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(width: geometry.size.width)
    }

    private func handleSelectHeavy(_ item: BalanceItem) {
        guard phase == .selectHeavy else { return }
        canSelectNext = false
        leftItem = item
        availableToAdd = gameConfig.items.filter { $0.id != item.id }
        phase = .adding
        speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
        if isHeavy(item) {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak("game-balance-good-job-keep-going")
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.canSelectNext = true
                }
            }
        } else {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak("game-balance-this-game-will-end-quick")
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.speak("game-balance-good-job-keep-going")
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        self.canSelectNext = true
                    }
                }
            }
        }
    }

    // MARK: - Adding (phase 2): available dinosaurs at top in 2 rows of 4; remove as selected.

    private func addingView(geometry: GeometryProxy) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: 10) {
            Text("Add dinosaurs to balance")
                .font(.headline)
                .foregroundColor(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(availableToAdd) { item in
                    BalanceItemCard(item: item) {
                        handleAddToRight(item)
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(width: geometry.size.width)
    }

    private func handleAddToRight(_ item: BalanceItem) {
        guard phase == .adding, canSelectNext, availableToAdd.contains(where: { $0.id == item.id }) else { return }
        canSelectNext = false
        rightItems.append(item)
        availableToAdd.removeAll { $0.id == item.id }

        let newRightMass = rightMass
        updateSeesawTilt()

        speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            playHandrailAfterAdd(newRightMass: newRightMass, addedItem: item)
        }
    }

    private func playHandrailAfterAdd(newRightMass: Double, addedItem: BalanceItem) {
        if isBalanced {
            if rightItems.count > 2 {
                withAnimation(.easeInOut(duration: 0.6)) {
                    seesawAngle = 0
                    leftItemOffset = 0
                    rightItemOffset = 0
                    leftItemOpacity = 1.0
                    rightItemOpacity = 1.0
                    showSpeedLines = false
                    lighterFlewFromLeft = nil
                }
            }
            if rightItems.count <= 2 {
                if !hasPlayedSeeIToldYou {
                    hasPlayedSeeIToldYou = true
                    speechManager.speak("game-balance-see-I-told-you")
                }
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.phase = .victory
                    self.startEndSequence()
                }
            } else {
                speechManager.speak("you-did-it")
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.phase = .victory
                    self.startEndSequence()
                }
            }
            return
        }
        if availableToAdd.isEmpty && newRightMass < leftMass {
            phase = .ranOut
            endSequenceStep = 0
            return
        }
        if newRightMass >= leftMass * 0.9 && newRightMass < leftMass {
            speechManager.speak("game-balance-almost-there")
        } else if isHeavy(addedItem) && newRightMass < leftMass * 0.9 {
            speechManager.speak("game-balance-good-job-keep-going")
        } else if newRightMass < leftMass * 0.5 {
            speechManager.speak("pick-someone-heavier")
        } else {
            speechManager.speak("game-balance-good-job-keep-going")
        }
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            canSelectNext = true
        }
    }

    private func updateSeesawTilt() {
        let diff = massDiff
        let rightHeavy = rightMass > leftMass
        let massive = leftMass > 0 && (rightHeavy ? rightMass >= leftMass * 1.2 : -diff >= leftMass * 0.5)
        /// Level only when sides are roughly equal; when right wins (right > left), show tilt and left dino flying
        let roughlyEqual = leftMass > 0 && abs(diff) < leftMass * 0.05

        withAnimation(.easeInOut(duration: 0.6)) {
            if roughlyEqual {
                seesawAngle = 0
                leftItemOffset = 0
                rightItemOffset = 0
                leftItemOpacity = 1.0
                rightItemOpacity = 1.0
                showSpeedLines = false
                lighterFlewFromLeft = nil
            } else if diff > 0 {
                // Left heavier
                seesawAngle = -15
                leftItemOffset = 20
                rightItemOffset = -20
                leftItemOpacity = 1.0
                rightItemOpacity = 1.0
                showSpeedLines = true
                lighterFlewFromLeft = false
            } else {
                // Right heavier
                seesawAngle = 15
                rightItemOffset = 20
                leftItemOffset = massive ? -220 : -150
                leftItemOpacity = 0
                rightItemOpacity = 1.0
                showSpeedLines = true
                lighterFlewFromLeft = true
            }
        }
    }

    // MARK: - Seesaw

    private func seesawView(geometry: GeometryProxy) -> some View {
        ZStack {
            SeesawSupportView().offset(y: 45)
            Circle()
                .fill(Color.gray)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.brown, lineWidth: 2))
                .offset(y: 28)
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                .frame(width: geometry.size.width * 0.38, height: 22)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                .rotationEffect(.degrees(seesawAngle), anchor: .center)
                .offset(y: 28)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brown.opacity(0.9))
                .frame(width: 56, height: 12)
                .rotationEffect(.degrees(seesawAngle), anchor: .center)
                .offset(x: -(geometry.size.width * 0.28), y: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brown.opacity(0.9))
                .frame(width: 56, height: 12)
                .rotationEffect(.degrees(seesawAngle), anchor: .center)
                .offset(x: geometry.size.width * 0.28, y: 14)

            if let left = leftItem, phase == .adding || phase == .victory || phase == .ranOut {
                itemView(item: left)
                    .offset(x: -(geometry.size.width * 0.28), y: leftItemOffset - 70)
                    .opacity(leftItemOpacity)
            }
            if phase == .adding || phase == .victory || phase == .ranOut {
                rightSideStackView(geometry: geometry)
            }
            if showSpeedLines, lighterFlewFromLeft == false {
                SpeedLinesView().offset(x: geometry.size.width * 0.28, y: rightItemOffset - 70)
            }
            if showSpeedLines, lighterFlewFromLeft == true {
                SpeedLinesView().offset(x: -(geometry.size.width * 0.28), y: leftItemOffset - 70)
            }
        }
        .frame(height: 250)
        .frame(width: geometry.size.width)
    }

    /// Right side of scale: one heavy = full size (100); multiple = 2-column grid with smaller cells (52).
    private func rightSideStackView(geometry: GeometryProxy) -> some View {
        Group {
            if rightItems.isEmpty {
                EmptyView()
            } else if rightItems.count == 1 {
                rightItemView(rightItems[0], size: 100)
                    .offset(x: geometry.size.width * 0.28, y: rightItemOffset - 70)
                    .opacity(rightItemOpacity)
            } else {
                let cellSize: CGFloat = 52
                let rowSpacing: CGFloat = 6
                let colSpacing: CGFloat = 8
                VStack(alignment: .center, spacing: rowSpacing) {
                    if rightItems.count >= 7 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[6], size: cellSize)
                            if rightItems.count > 7 { rightItemView(rightItems[7], size: cellSize) }
                        }
                    }
                    if rightItems.count >= 5 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[4], size: cellSize)
                            if rightItems.count > 5 { rightItemView(rightItems[5], size: cellSize) }
                        }
                    }
                    if rightItems.count >= 3 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[2], size: cellSize)
                            if rightItems.count > 3 { rightItemView(rightItems[3], size: cellSize) }
                        }
                    }
                    HStack(spacing: colSpacing) {
                        if rightItems.count > 0 { rightItemView(rightItems[0], size: cellSize) }
                        if rightItems.count > 1 { rightItemView(rightItems[1], size: cellSize) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(width: cellSize * 2 + colSpacing, height: rightItems.count >= 7 ? 252 : 180)
                .offset(x: geometry.size.width * 0.28, y: rightItemOffset - 70)
                .opacity(rightItemOpacity)
            }
        }
    }

    private func rightItemView(_ item: BalanceItem, size: CGFloat) -> some View {
        Group {
            if let name = item.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(item.emoji).font(.system(size: size * 0.8))
            }
        }
        .frame(width: size, height: size)
    }

    private func itemView(item: BalanceItem) -> some View {
        Group {
            if let name = item.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            } else {
                Text(item.emoji).font(.system(size: 80))
            }
        }
    }

    // MARK: - End sequence (you-did-it → darkened row → highlight each with name+audio → crowd-cheering → dismiss)

    private func startEndSequence() {
        endSequenceStep = 1
        endHighlightIndex = 0
        let participants = allDinosaursUsed
        if participants.isEmpty {
            playWeHaveWinnerAndDismiss()
        } else {
            let p = participants[0]
            speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let participants = allDinosaursUsed
        if endHighlightIndex < participants.count {
            let p = participants[endHighlightIndex]
            speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            playWeHaveWinnerAndDismiss()
        }
    }

    private func playWeHaveWinnerAndDismiss() {
        endSequenceStep = 2
        speechManager.speak("crowd-cheering")
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.isPresented = false
        }
    }

    private var victoryOrRanOutView: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: 20) {
            Spacer()
            // Grid: max 3 per row so images and names stay readable (multiple rows when needed)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(allDinosaursUsed.enumerated()), id: \.element.id) { index, item in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    VStack(spacing: 8) {
                        endSequenceParticipantImage(item: item, isHighlighted: isHighlighted)
                        if isHighlighted {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if phase == .ranOut && endSequenceStep == 0 && !hasStartedRanOutEndAudio {
                hasStartedRanOutEndAudio = true
                speechManager.speak("you-did-it")
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    endSequenceStep = 1
                    endHighlightIndex = 0
                    let participants = allDinosaursUsed
                    if participants.isEmpty {
                        playWeHaveWinnerAndDismiss()
                    } else {
                        let p = participants[0]
                        speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
                        speechManager.onAudioFinished = { advanceEndHighlight() }
                    }
                }
            }
        }
    }

    private func endSequenceParticipantImage(item: BalanceItem, isHighlighted: Bool) -> some View {
        Group {
            if let name = item.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(isHighlighted ? 1.0 : 0.35)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 4)
                    )
            } else {
                Text(item.emoji)
                    .font(.system(size: 44))
                    .frame(width: 88, height: 88)
                    .opacity(isHighlighted ? 1.0 : 0.35)
            }
        }
    }
}

// MARK: - Card

struct BalanceItemCard: View {
    let item: BalanceItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let name = item.imageName, UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                } else {
                    Text(item.emoji).font(.system(size: 50))
                }
                Text(item.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 2))
    }
}

// MARK: - Pool and Config

private struct BalancePoolEntry {
    let name: String
    let imageName: String
    let emoji: String
    let estimatedWeightKg: Double
}

private let balanceDinosaurPool: [BalancePoolEntry] = [
    BalancePoolEntry(name: "Velociraptor", imageName: "dino-velociraptor", emoji: "🦖", estimatedWeightKg: 20),
    BalancePoolEntry(name: "Troodon", imageName: "dino-troodon", emoji: "🦉", estimatedWeightKg: 50),
    BalancePoolEntry(name: "Parasaurolophus", imageName: "dino-parasaurolophus", emoji: "🦆", estimatedWeightKg: 2_700),
    BalancePoolEntry(name: "Corythosaurus", imageName: "dino-corythosaurus", emoji: "🦆", estimatedWeightKg: 3_500),
    BalancePoolEntry(name: "Edmontosaurus", imageName: "dino-edmontosaurus", emoji: "🦆", estimatedWeightKg: 4_000),
    BalancePoolEntry(name: "Iguanodon", imageName: "dino-iguanodon", emoji: "🦎", estimatedWeightKg: 4_500),
    BalancePoolEntry(name: "Therizinosaurus", imageName: "dino-therizinosaurus", emoji: "🦕", estimatedWeightKg: 5_000),
    BalancePoolEntry(name: "Stegosaurus", imageName: "dino-stegosaurus", emoji: "🦎", estimatedWeightKg: 4_500),
    BalancePoolEntry(name: "Ankylosaurus", imageName: "dino-ankylosaurus", emoji: "🛡️", estimatedWeightKg: 6_000),
    BalancePoolEntry(name: "Spinosaurus", imageName: "dino-spinosaurus", emoji: "🦖", estimatedWeightKg: 7_000),
    BalancePoolEntry(name: "T-Rex", imageName: "dino-trex", emoji: "🦖", estimatedWeightKg: 8_000),
    BalancePoolEntry(name: "Triceratops", imageName: "dino-triceratops", emoji: "🦏", estimatedWeightKg: 9_000),
    BalancePoolEntry(name: "Apatosaurus", imageName: "dino-apatosaurus", emoji: "🦕", estimatedWeightKg: 25_000),
]

struct BalanceGameConfigs {
    static let balanceDinosaur = BalanceGameConfig(
        id: "balance-the-dinosaur",
        title: "Balance the Dinosaurs!",
        introAudio: "game-can-you-balance-the-dinosaurs",
        items: []
    )

    static func balanceDinosaurRandomized() -> BalanceGameConfig {
        let chosen = balanceDinosaurPool.shuffled().prefix(9)
        let items = chosen.enumerated().map { index, entry in
            BalanceItem(
                id: index + 1,
                name: entry.name,
                imageName: entry.imageName,
                emoji: entry.emoji,
                estimatedWeightKg: entry.estimatedWeightKg
            )
        }
        return BalanceGameConfig(
            id: "balance-the-dinosaur",
            title: "Balance the Dinosaurs!",
            introAudio: "game-can-you-balance-the-dinosaurs",
            items: items
        )
    }
}

#Preview {
    BalanceGameView(isPresented: .constant(true), gameConfig: BalanceGameConfigs.balanceDinosaurRandomized())
}
