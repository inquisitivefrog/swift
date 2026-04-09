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

    /// Balance the Dinosaurs: 5 rounds; Balance the Pterosaurs: 1 round.
    private var maxRounds: Int { gameConfig.id == "balance-the-dinosaur" ? 3 : 1 }
    @State private var roundsCompleted = 0
    @State private var currentRound = 1
    /// Items for the current round (9 dinos or 6 pterosaurs). Round 1 uses config; rounds 2+ use new random set for dinosaur game.
    @State private var roundItems: [BalanceItem] = []
    /// All dinosaurs used across rounds (for victory walk). Deduplicated by first appearance.
    @State private var allRoundParticipants: [BalanceItem] = []

    @State private var seesawAngle: Double = 0
    @State private var leftItemOffset: CGFloat = 0
    @State private var rightItemOffset: CGFloat = 0
    @State private var leftItemOpacity: Double = 1.0
    @State private var rightItemOpacity: Double = 1.0
    @State private var showSpeedLines = false
    @State private var lighterFlewFromLeft: Bool? = nil
    @State private var canSelectNext = false
    /// Fallback: if audio callback never fires, re-enable selection after delay so game doesn't get stuck
    @State private var canSelectFallbackWorkItem: DispatchWorkItem?

    /// End sequence: -1 none, 0 ranOut playing you-did-it, 1 highlighting each dino, 2 playing crowd-cheering
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    @State private var hasStartedRanOutEndAudio = false
    /// Prevents "game-balance-see-I-told-you" from playing twice when balanced with 1–2 items
    @State private var hasPlayedSeeIToldYou = false

    /// Intro walk: -1 none, 0..<count = current index (highlight + name). When done, play "choose a heavy dinosaur".
    @State private var introWalkStep: Int = -1
    /// Items for the current round (roundItems when set, else gameConfig.items for initial load).
    private var currentRoundItems: [BalanceItem] {
        roundItems.isEmpty ? gameConfig.items : roundItems
    }
    private var introWalkComplete: Bool {
        currentRoundItems.isEmpty || introWalkStep >= currentRoundItems.count
    }

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

    /// Heavy = in top half of game's items by weight; light = bottom half. Works for 9 (dinosaur) or 6 (pterosaur) items.
    private func isHeavy(_ item: BalanceItem) -> Bool {
        let sorted = currentRoundItems.sorted { $0.estimatedWeightKg < $1.estimatedWeightKg }
        let half = sorted.count / 2
        guard let threshold = sorted.dropFirst(half).first?.estimatedWeightKg else { return true }
        return item.estimatedWeightKg >= threshold
    }

    /// Weigh-dino-* for Balance the Dinosaurs on the seesaw only; grid uses dino-* for larger, clearer images.
    private func weighImageName(for item: BalanceItem) -> String? {
        guard gameConfig.id == "balance-the-dinosaur" else { return item.imageName }
        let base = item.imageName ?? item.name
        let weighName = "weigh-\(base)"
        return ImageAssetCache.imageExists(named: weighName) ? weighName : item.imageName
    }

    /// Grid uses dino-* (square poses, better at small size); seesaw uses weigh-dino-* via weighImageName.
    private func gridImageName(for item: BalanceItem) -> String? {
        gameConfig.id == "balance-the-dinosaur" ? item.imageName : (weighImageName(for: item) ?? item.imageName)
    }

    /// Scale factor for seesaw image (like Weigh the Dinosaur). Heavier gets full size (1.2); lighter scales by weight ratio; min 0.55 keeps small dinos visible.
    private func seesawImageScale(for item: BalanceItem, relativeTo other: BalanceItem?) -> CGFloat {
        guard gameConfig.id == "balance-the-dinosaur" else { return 1.0 }
        let kg = item.estimatedWeightKg
        if let other = other {
            let otherKg = other.estimatedWeightKg
            if kg >= otherKg {
                return 1.2
            } else {
                let ratio = kg / otherKg
                let t = sqrt(max(ratio, 0.001))
                return CGFloat(max(0.55, 0.35 + 0.85 * t))
            }
        }
        let logMin = log10(0.5)
        let logMax = log10(70_000.0)
        let logKg = log10(max(kg, 0.5))
        let t = (logKg - logMin) / (logMax - logMin)
        return CGFloat(max(0.55, 0.35 + 0.85 * min(max(t, 0), 1)))
    }

    /// Victory list row height and visible area (show ~4 rows).
    private let victoryRowHeight: CGFloat = 92
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

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
            let safeHeight = max(geometry.size.height, 0)
            VStack(spacing: 0) {
                Spacer().frame(height: max(0, safeHeight * 0.04))

                if phase == .victory || phase == .ranOut {
                    victoryOrRanOutView
                } else if phase == .selectHeavy {
                    selectHeavyView(geometry: geometry)
                } else {
                    addingView(geometry: geometry)
                }

                Spacer().frame(height: max(0, safeHeight * 0.12 + addingPhaseExtraSpacing))
                seesawView(geometry: geometry)
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase != .victory && phase != .ranOut {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .onAppear {
            // Init round items on first load
            if roundItems.isEmpty && !gameConfig.items.isEmpty {
                roundItems = gameConfig.items
            }
            // Intro walk: introduce all dinosaurs in grid, then play "choose a heavy dinosaur"
            if phase == .selectHeavy, !currentRoundItems.isEmpty {
                introWalkStep = 0
                startBalanceIntroWalk()
            }
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
            }
        }
        .onDisappear {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }

    // MARK: - Select heavy (phase 1)

    private func selectHeavyView(geometry: GeometryProxy) -> some View {
        let rows = (currentRoundItems.count + 2) / 3
        return VStack(spacing: 12) {
            if maxRounds > 1 {
                Text("Round \(currentRound) of \(maxRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Text(gameConfig.id == "balance-the-pterosaur" ? "Choose a heavy pterosaur" : "Choose a heavy dinosaur")
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 10) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            if index < currentRoundItems.count {
                                let item = currentRoundItems[index]
                                BalanceItemCard(item: item, displayImageName: gridImageName(for: item), isIntroHighlighted: introWalkStep == index, isDisabled: !introWalkComplete) {
                                    handleSelectHeavy(item)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(width: max(1, geometry.size.width))
    }

    /// Walk the 9 (or 6) dinosaurs: speak name at introWalkStep, then advance; when done, play "choose a heavy dinosaur".
    private func startBalanceIntroWalk() {
        guard introWalkStep >= 0, introWalkStep < currentRoundItems.count else { return }
        let item = currentRoundItems[introWalkStep]
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.advanceBalanceIntroWalk()
        }
        speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
    }

    private func advanceBalanceIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep >= currentRoundItems.count {
            let chooseHeavyKey = gameConfig.id == "balance-the-pterosaur" ? "game-balance-choose-a-heavy-pterosaur" : "game-balance-choose-a-heavy-dinosaur"
            speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil }
            speechManager.speak(chooseHeavyKey)
            return
        }
        startBalanceIntroWalk()
    }

    private func handleSelectHeavy(_ item: BalanceItem) {
        guard phase == .selectHeavy, introWalkComplete else { return }
        canSelectNext = false
        leftItem = item
        availableToAdd = currentRoundItems.filter { $0.id != item.id }
        phase = .adding
        speechManager.speak(audioKey: item.imageName ?? item.name, fallbackText: item.name)
        let nowChooseKey = gameConfig.id == "balance-the-pterosaur" ? "game-balance-now-choose-pterosaurs" : "game-balance-now-choose-dinosaurs"

        canSelectFallbackWorkItem?.cancel()
        let fallback = DispatchWorkItem {
            canSelectFallbackWorkItem = nil
            canSelectNext = true
        }
        canSelectFallbackWorkItem = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: fallback)

        if isHeavy(item) {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak(nowChooseKey)
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.canSelectFallbackWorkItem?.cancel()
                    self.canSelectFallbackWorkItem = nil
                    self.canSelectNext = true
                }
            }
        } else {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak("game-balance-this-game-will-end-quick")
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.speak(nowChooseKey)
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        self.canSelectFallbackWorkItem?.cancel()
                        self.canSelectFallbackWorkItem = nil
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
            if maxRounds > 1 {
                Text("Round \(currentRound) of \(maxRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Text("Add dinosaurs to balance")
                .font(.headline)
                .foregroundColor(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(availableToAdd) { item in
                    BalanceItemCard(item: item, displayImageName: gridImageName(for: item), isDisabled: !canSelectNext) {
                        handleAddToRight(item)
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(width: max(1, geometry.size.width))
    }

    private func handleAddToRight(_ item: BalanceItem) {
        guard phase == .adding, availableToAdd.contains(where: { $0.id == item.id }) else {
            if phase == .adding && !availableToAdd.contains(where: { $0.id == item.id }) {
                speechManager.speak("pick-another-one")
            }
            return
        }
        guard canSelectNext else {
            speechManager.speak("you-cannot-choose-that-one-now")
            return
        }
        canSelectNext = false
        rightItems.append(item)
        availableToAdd.removeAll { $0.id == item.id }

        let newRightMass = rightMass
        updateSeesawTilt()

        canSelectFallbackWorkItem?.cancel()
        let fallback = DispatchWorkItem {
            canSelectFallbackWorkItem = nil
            canSelectNext = true
        }
        canSelectFallbackWorkItem = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: fallback)

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
                    self.finishRoundAndEitherAdvanceOrShowVictory(isVictory: true)
                }
            } else {
                speechManager.speak("you-did-it")
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.finishRoundAndEitherAdvanceOrShowVictory(isVictory: true)
                }
            }
            canSelectFallbackWorkItem?.cancel()
            canSelectFallbackWorkItem = nil
            return
        }
        if availableToAdd.isEmpty && newRightMass < leftMass {
            canSelectFallbackWorkItem?.cancel()
            canSelectFallbackWorkItem = nil
            finishRoundAndEitherAdvanceOrShowVictory(isVictory: false)
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
            canSelectFallbackWorkItem?.cancel()
            canSelectFallbackWorkItem = nil
            canSelectNext = true
        }
    }

    /// Called when round ends (balanced or ran out). Accumulates participants; advances to next round or shows final victory.
    private func finishRoundAndEitherAdvanceOrShowVictory(isVictory: Bool) {
        var seen: Set<Int> = []
        for item in allDinosaursUsed {
            if seen.insert(item.id).inserted {
                allRoundParticipants.append(item)
            }
        }
        roundsCompleted += 1
        if roundsCompleted >= maxRounds {
            phase = isVictory ? .victory : .ranOut
            if isVictory {
                startEndSequence()
            } else {
                endSequenceStep = 0
            }
        } else {
            advanceToNextRound()
        }
    }

    /// Reset state and load new items for the next round.
    private func advanceToNextRound() {
        currentRound += 1
        leftItem = nil
        rightItems = []
        availableToAdd = []
        seesawAngle = 0
        leftItemOffset = 0
        rightItemOffset = 0
        leftItemOpacity = 1.0
        rightItemOpacity = 1.0
        showSpeedLines = false
        lighterFlewFromLeft = nil
        hasPlayedSeeIToldYou = false
        if gameConfig.id == "balance-the-dinosaur" {
            roundItems = BalanceGameConfigs.makeRandomBalanceDinosaurItems()
        }
        phase = .selectHeavy
        introWalkStep = maxRounds > 1 ? currentRoundItems.count : 0  // Skip intro walk for rounds 2+
        canSelectNext = false
        canSelectFallbackWorkItem?.cancel()
        let fallback = DispatchWorkItem {
            self.canSelectFallbackWorkItem = nil
            self.canSelectNext = true
        }
        canSelectFallbackWorkItem = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: fallback)
        if maxRounds > 1 {
            let chooseHeavyKey = gameConfig.id == "balance-the-pterosaur" ? "game-balance-choose-a-heavy-pterosaur" : "game-balance-choose-a-heavy-dinosaur"
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.canSelectFallbackWorkItem?.cancel()
                self.canSelectFallbackWorkItem = nil
                self.canSelectNext = true
            }
            speechManager.speak(chooseHeavyKey)
        } else {
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
                // Left heavier – no speed lines; user adds dinos until balanced
                seesawAngle = -15
                leftItemOffset = 20
                rightItemOffset = -20
                leftItemOpacity = 1.0
                rightItemOpacity = 1.0
                showSpeedLines = false
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

    // MARK: - Seesaw (same structure as Weigh the Dinosaur)

    private func seesawView(geometry: GeometryProxy) -> some View {
        let safeWidth = max(geometry.size.width, 1)
        let beamW = max(safeWidth * 0.28, 100)
        let sideMargin: CGFloat = 12
        // Seat top (where dinosaur feet rest): seat is at y:-15, height 12, so top at -21
        let seatTopY: CGFloat = -21
        let frameWidth = max(1, safeWidth - 2 * sideMargin)
        let maxDinoWidth = max(100, frameWidth - 2 * beamW)

        return ZStack {
            // A-frame support (shared with Weigh)
            SeesawSupportView()
                .offset(y: 45)

            // Beam + seats + dinosaurs rotate as one unit around fulcrum; fulcrum stays fixed
            ZStack {
                ZStack {
                    // Beam (arm) – two halves
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .frame(width: beamW, height: 18)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                            .offset(x: -beamW / 2)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                            .frame(width: beamW, height: 18)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.6), lineWidth: 1))
                            .offset(x: beamW / 2)
                    }
                    // Seats (above beam center)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown.opacity(0.9))
                        .frame(width: 56, height: 12)
                        .offset(x: -beamW, y: -15)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown.opacity(0.9))
                        .frame(width: 56, height: 12)
                        .offset(x: beamW, y: -15)

                    // Left dinosaur (on left seat) – rotates with beam so stays on seat
                    if let left = leftItem, phase == .adding || phase == .victory || phase == .ranOut {
                let heaviestRight = rightItems.max(by: { $0.estimatedWeightKg < $1.estimatedWeightKg })
                let scale = seesawImageScale(for: left, relativeTo: heaviestRight)
                let idealHeight = 130 * scale
                let idealWidth = idealHeight * 2
                let rightMaxW: CGFloat = {
                    if rightItems.count == 1, let r = rightItems.first {
                        return 130 * seesawImageScale(for: r, relativeTo: left) * 2
                    }
                    return idealWidth
                }()
                let scaleFactor = max(idealWidth, rightMaxW) > maxDinoWidth ? maxDinoWidth / max(idealWidth, rightMaxW) : 1.0
                let (width, height) = (idealWidth * scaleFactor, idealHeight * scaleFactor)
                let baseY = seatTopY - height / 2
                Group {
                    if let imageName = weighImageName(for: left) {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width, height: height, alignment: .bottom)
                    } else {
                        Text(left.emoji).font(.system(size: 80))
                            .frame(width: width, height: height)
                    }
                }
                .frame(width: width, height: height, alignment: .bottom)
                .clipped()
                .offset(x: -beamW, y: leftItemOffset + baseY)
                .opacity(leftItemOpacity)
                .zIndex(10)
                    }

                    // Right side (single or grid) – rotates with beam so stays on seat
                    if phase == .adding || phase == .victory || phase == .ranOut {
                        rightSideStackView(beamW: beamW, seatTopY: seatTopY, maxDinoWidth: maxDinoWidth)
                    }

                    // Speed lines (only when left flew; rotate with beam)
                    if showSpeedLines, lighterFlewFromLeft == false {
                let rightBaseY: CGFloat = {
                    switch rightItems.count {
                    case 1:
                        if let r = rightItems.first, let left = leftItem {
                            let scale = seesawImageScale(for: r, relativeTo: left)
                            let idealH = 130 * scale
                            let idealW = idealH * 2
                            let leftW = 130 * seesawImageScale(for: left, relativeTo: r) * 2
                            let sf = max(idealW, leftW) > maxDinoWidth ? maxDinoWidth / max(idealW, leftW) : 1.0
                            return seatTopY - (idealH * sf) / 2
                        }
                        return seatTopY - 65
                    case 2:
                        let gridH: CGFloat = 52  // 1 row
                        return seatTopY - gridH / 2
                    case 3...6:
                        let rows: CGFloat = rightItems.count <= 4 ? 2 : 3
                        let gridH = rows * 52 + max(0, rows - 1) * 2
                        return seatTopY - gridH / 2
                    default:
                        let rows: CGFloat = 4
                        let gridH = rows * 52 + 3 * 2
                        return seatTopY - gridH / 2
                    }
                }()
                SpeedLinesView()
                    .offset(x: beamW, y: rightItemOffset + rightBaseY)
                    }
                    if showSpeedLines, lighterFlewFromLeft == true, let left = leftItem {
                let heaviestRight = rightItems.max(by: { $0.estimatedWeightKg < $1.estimatedWeightKg })
                let scale = seesawImageScale(for: left, relativeTo: heaviestRight)
                let idealH = 130 * scale
                let idealW = idealH * 2
                let rightMaxW: CGFloat = {
                    if rightItems.count == 1, let r = rightItems.first {
                        return 130 * seesawImageScale(for: r, relativeTo: left) * 2
                    }
                    return idealW
                }()
                let sf = max(idealW, rightMaxW) > maxDinoWidth ? maxDinoWidth / max(idealW, rightMaxW) : 1.0
                let baseY = seatTopY - (idealH * sf) / 2
                SpeedLinesView()
                    .offset(x: -beamW, y: leftItemOffset + baseY)
                    }
                }
                .rotationEffect(.degrees(seesawAngle), anchor: UnitPoint(x: 0.5, y: 1))
            }
        }
        .frame(width: frameWidth, height: 260)
        .clipped()
        .frame(width: safeWidth)
    }

    /// Right side: one dino = full size on seat; multiple = 2-column grid (same layout as before).
    private func rightSideStackView(beamW: CGFloat, seatTopY: CGFloat, maxDinoWidth: CGFloat) -> some View {
        Group {
            if rightItems.isEmpty {
                EmptyView()
            } else if rightItems.count == 1 {
                let right = rightItems[0]
                let scale = seesawImageScale(for: right, relativeTo: leftItem)
                let idealHeight = 130 * scale
                let idealWidth = idealHeight * 2
                let leftIdealW = leftItem.map { 130 * seesawImageScale(for: $0, relativeTo: right) * 2 } ?? idealWidth
                let scaleFactor = max(idealWidth, leftIdealW) > maxDinoWidth ? maxDinoWidth / max(idealWidth, leftIdealW) : 1.0
                let (width, height) = (idealWidth * scaleFactor, idealHeight * scaleFactor)
                let baseY = seatTopY - height / 2
                Group {
                    if let imageName = weighImageName(for: right) {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width, height: height, alignment: .bottom)
                    } else {
                        Text(right.emoji).font(.system(size: 80))
                            .frame(width: width, height: height)
                    }
                }
                .frame(width: width, height: height, alignment: .bottom)
                .clipped()
                .offset(x: beamW, y: rightItemOffset + baseY)
                .opacity(rightItemOpacity)
                .zIndex(10)
            } else {
                let cellSize: CGFloat = 52
                let rowSpacing: CGFloat = 2   // Tight stack so dinosaurs appear on seat without gaps
                let colSpacing: CGFloat = 4
                let rows: CGFloat = {
                    switch rightItems.count {
                    case 2: return 1
                    case 3...4: return 2
                    case 5...6: return 3
                    default: return 4
                    }
                }()
                let gridHeight = rows * cellSize + max(0, rows - 1) * rowSpacing
                // Align bottom of grid with seat top so first row (items 0,1) sits ON the seat; rows above stack upward
                let baseY = seatTopY - gridHeight
                let heaviest = ([leftItem].compactMap { $0 } + rightItems)
                    .max(by: { $0.estimatedWeightKg < $1.estimatedWeightKg })
                VStack(alignment: .center, spacing: rowSpacing) {
                    if rightItems.count >= 7 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[6], size: cellSize, heaviest: heaviest)
                            if rightItems.count > 7 { rightItemView(rightItems[7], size: cellSize, heaviest: heaviest) }
                        }
                    }
                    if rightItems.count >= 5 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[4], size: cellSize, heaviest: heaviest)
                            if rightItems.count > 5 { rightItemView(rightItems[5], size: cellSize, heaviest: heaviest) }
                        }
                    }
                    if rightItems.count >= 3 {
                        HStack(spacing: colSpacing) {
                            rightItemView(rightItems[2], size: cellSize, heaviest: heaviest)
                            if rightItems.count > 3 { rightItemView(rightItems[3], size: cellSize, heaviest: heaviest) }
                        }
                    }
                    HStack(spacing: colSpacing) {
                        if rightItems.count > 0 { rightItemView(rightItems[0], size: cellSize, heaviest: heaviest) }
                        if rightItems.count > 1 { rightItemView(rightItems[1], size: cellSize, heaviest: heaviest) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(width: cellSize * 2 + colSpacing, height: gridHeight)
                .offset(x: beamW, y: rightItemOffset + baseY)
                .opacity(rightItemOpacity)
                .zIndex(10)
            }
        }
    }

    private func rightItemView(_ item: BalanceItem, size: CGFloat, heaviest: BalanceItem? = nil) -> some View {
        let scale = heaviest.map { min(1.0, seesawImageScale(for: item, relativeTo: $0)) } ?? 1.0
        let effectiveSize = size * scale
        return Group {
            if let name = weighImageName(for: item) ?? item.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: effectiveSize, height: effectiveSize)
            } else {
                Text(item.emoji).font(.system(size: effectiveSize * 0.8))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - End sequence (scroll list → highlight each + name audio → success image → good-job/you-did-it + crowd → dismiss)

    private func startEndSequence() {
        endSequenceStep = 1
        endHighlightIndex = 0
        let participants = allRoundParticipants.isEmpty ? allDinosaursUsed : allRoundParticipants
        if participants.isEmpty {
            endSequenceStep = 2
        } else {
            let p = participants[0]
            speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let participants = allRoundParticipants.isEmpty ? allDinosaursUsed : allRoundParticipants
        if endHighlightIndex < participants.count {
            let p = participants[endHighlightIndex]
            speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    /// Standard victory flow: scroll list → success image → good-job/you-did-it + crowd → dismiss.
    private func playCelebrationAndDismiss(useGoodJob: Bool) {
        let key = useGoodJob ? "good-job-you-got-them-all" : "you-did-it"
        let goodJobURL = speechManager.urlForAudio(key: key)
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

    /// Success image for end sequence: game-balance-the-dinosaur-success or game-balance-the-pterosaur-success.
    private var balanceSuccessImageView: some View {
        Group {
            let successName = "game-\(gameConfig.id)-success"
            let fallbackName = "game-\(gameConfig.id)"
            if ImageAssetCache.imageExists(named: successName) {
                Image(successName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: fallbackName) {
                Image(fallbackName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🎉")
                    .font(.system(size: 100))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var victoryOrRanOutView: some View {
        let participants = allRoundParticipants.isEmpty ? allDinosaursUsed : allRoundParticipants
        return VStack(spacing: 0) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(participants.enumerated()), id: \.element.id) { index, item in
                                let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                                HStack(spacing: 16) {
                                    balanceVictoryImage(item: item, isHighlighted: isHighlighted)
                                    Text(item.name)
                                        .font(.title2)
                                        .fontWeight(isHighlighted ? .semibold : .regular)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(isHighlighted ? 1.0 : 0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(height: victoryRowHeight)
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
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: endHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Group {
                    if endSequenceStep == 2 {
                        balanceSuccessImageView
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playCelebrationAndDismiss(useGoodJob: phase == .victory)
                                }
                            }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if phase == .ranOut && endSequenceStep == 0 && !hasStartedRanOutEndAudio {
                hasStartedRanOutEndAudio = true
                endSequenceStep = 1
                endHighlightIndex = 0
                if participants.isEmpty {
                    endSequenceStep = 2
                } else {
                    let p = participants[0]
                    speechManager.speak(audioKey: p.imageName ?? p.name, fallbackText: p.name)
                    speechManager.onAudioFinished = { advanceEndHighlight() }
                }
            }
        }
    }

    private func balanceVictoryImage(item: BalanceItem, isHighlighted: Bool) -> some View {
        Group {
            if let name = gridImageName(for: item) ?? item.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
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
                Text(item.emoji)
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }
}

// MARK: - Card

struct BalanceItemCard: View {
    let item: BalanceItem
    /// When provided (e.g. weigh-dino-* for Balance the Dinosaurs), use this for the image instead of item.imageName.
    var displayImageName: String? = nil
    var isIntroHighlighted: Bool = false
    var isDisabled: Bool = false
    let onTap: () -> Void

    private var imageNameToUse: String? { displayImageName ?? item.imageName }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let name = imageNameToUse, ImageAssetCache.imageExists(named: name) {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                } else {
                    Text(item.emoji).font(.system(size: 50))
                }
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
            }
        }
        .disabled(isDisabled)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isIntroHighlighted ? Color.accentColor : Color.blue.opacity(0.3), lineWidth: isIntroHighlighted ? 4 : 2))
        .opacity(isDisabled && !isIntroHighlighted ? 0.5 : 1.0)
    }
}

// MARK: - Pool and Config

private struct BalancePoolEntry {
    let id: Int
    let name: String
    let imageName: String
    let emoji: String
    let estimatedWeightKg: Double
}

private let balancePterosaurPool: [BalancePoolEntry] = [
    BalancePoolEntry(id: 1, name: "Anurognathus", imageName: "ptero-anurognathus", emoji: "🦅", estimatedWeightKg: 0.2),
    BalancePoolEntry(id: 2, name: "Rhamphorhynchus", imageName: "ptero-rhamphorhynchus", emoji: "🦅", estimatedWeightKg: 1.5),
    BalancePoolEntry(id: 3, name: "Dimorphodon", imageName: "ptero-dimorphodon", emoji: "🦅", estimatedWeightKg: 2),
    BalancePoolEntry(id: 4, name: "Pterodactylus", imageName: "ptero-pteradactylus", emoji: "🦅", estimatedWeightKg: 2),
    BalancePoolEntry(id: 5, name: "Nyctosaurus", imageName: "ptero-nyctosaurus", emoji: "🦅", estimatedWeightKg: 2),
    BalancePoolEntry(id: 6, name: "Tapejara", imageName: "ptero-tapejara", emoji: "🦅", estimatedWeightKg: 15),
    BalancePoolEntry(id: 7, name: "Tupandactylus", imageName: "ptero-tupandactylus", emoji: "🦅", estimatedWeightKg: 15),
    BalancePoolEntry(id: 8, name: "Dsungaripterus", imageName: "ptero-dsungaripterus", emoji: "🦅", estimatedWeightKg: 20),
    BalancePoolEntry(id: 9, name: "Pteranodon", imageName: "ptero-pteranodon", emoji: "🦅", estimatedWeightKg: 25),
    BalancePoolEntry(id: 10, name: "Quetzalcoatlus", imageName: "ptero-quetzacoatlus", emoji: "🦅", estimatedWeightKg: 200),
]

struct BalanceGameConfigs {
    static let balanceDinosaur = BalanceGameConfig(
        id: "balance-the-dinosaur",
        title: "Balance the Dinosaurs!",
        introAudio: "game-can-you-balance-the-dinosaurs",
        items: []
    )

    /// Returns 9 dinosaurs: one per clade (9 clades), shuffled for random grid order. Same logic as Weigh the Dinosaur.
    static func makeRandomBalanceDinosaurItems() -> [BalanceItem] {
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            guard let img = d.imageName, img.hasPrefix("dino-"),
                  MatchingGameConfigs.dinosaurEstimatedWeightKgById[d.id] != nil
            else { return false }
            return true
        }
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        var chosen: [Dinosaur] = []
        for clade in DinoClade.allCases {
            guard let candidates = byClade[clade], !candidates.isEmpty else { continue }
            chosen.append(candidates.randomElement()!)
        }
        while chosen.count < 9 {
            let extras = pool.filter { d in !chosen.contains(where: { $0.id == d.id }) }
            guard let one = extras.randomElement() else { break }
            chosen.append(one)
        }
        return chosen.shuffled().map { d in
            BalanceItem(
                id: d.id,
                name: d.name,
                imageName: d.imageName,
                emoji: d.icon,
                estimatedWeightKg: MatchingGameConfigs.dinosaurEstimatedWeightKgById[d.id] ?? 1000
            )
        }
    }

    static func balanceDinosaurRandomized() -> BalanceGameConfig {
        return BalanceGameConfig(
            id: "balance-the-dinosaur",
            title: "Balance the Dinosaurs!",
            introAudio: "game-can-you-balance-the-dinosaurs",
            items: makeRandomBalanceDinosaurItems()
        )
    }

    static let balancePterosaur = BalanceGameConfig(
        id: "balance-the-pterosaur",
        title: "Balance the Pterosaurs!",
        introAudio: "game-can-you-balance-the-pterosaurs",
        items: []
    )

    static func balancePterosaurRandomized() -> BalanceGameConfig {
        let chosen = balancePterosaurPool.shuffled().prefix(6)
        let items = chosen.map { entry in
            BalanceItem(
                id: entry.id,
                name: entry.name,
                imageName: entry.imageName,
                emoji: entry.emoji,
                estimatedWeightKg: entry.estimatedWeightKg
            )
        }
        return BalanceGameConfig(
            id: "balance-the-pterosaur",
            title: "Balance the Pterosaurs!",
            introAudio: "game-can-you-balance-the-pterosaurs",
            items: items
        )
    }
}

#Preview {
    BalanceGameView(isPresented: .constant(true), gameConfig: BalanceGameConfigs.balanceDinosaurRandomized())
}
