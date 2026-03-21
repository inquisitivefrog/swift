//
//  SmilingDinosGameView.swift
//  DinoGames
//
//  Smiling Dinos: Match 2 dinosaur smiles to 3 teeth (2 matches + 1 distractor). Mimics Match the Dinosaur framework.
//  Left column: Smiles (dino-smile-{slug}). Right column: Tooth Shapes (dino-smile-tooth-{toothType}).
//  Each smile matches one tooth. 3 rounds, 6 introduced per game. Victory: re-introduce teeth.
//

import SwiftUI
@preconcurrency import AVFoundation

/// Display name for tooth type: strips -v1, -v2, -ankylosaurid, -ceratopsian, -stegosaurid before formatting.
private func dinoSmileToothDisplayName(_ toothType: String) -> String {
    var s = toothType
    if let range = s.range(of: #"-v\d+"#, options: .regularExpression) {
        s.removeSubrange(range)
    }
    for suffix in ["-ankylosaurid", "-ceratopsian", "-stegosaurid"] {
        s = s.replacingOccurrences(of: suffix, with: "")
    }
    return s.replacingOccurrences(of: "-", with: " ").capitalized
}

/// Play tooth audio for Dino Smile. Tries dino-smile-{toothType}, -v1, -v2 so Audio/Smile/dino-smile-{toothType}-v1.m4a (e.g. diamond-battery, flute-leaf) is found when base doesn't exist.
private func playToothAudio(speechManager: SpeechManager, toothType: String, fallbackText: String, onFinished: (() -> Void)?) {
    let baseKey = "dino-smile-\(toothType)"
    let url = speechManager.urlForAudio(key: baseKey)
        ?? speechManager.urlForAudio(key: "\(baseKey)-v1")
        ?? speechManager.urlForAudio(key: "\(baseKey)-v2")
    if let url {
        speechManager.onAudioFinished = onFinished
        speechManager.playAudioFile(url: url, fallbackSpeakText: fallbackText)
    } else {
        speechManager.onAudioFinished = onFinished
        speechManager.speak(fallbackText)
    }
}

// MARK: - Data Models

struct SmilingDinosRound: Identifiable {
    let id: Int
    /// 2 pairs: (dinosaur, toothType). Each smile matches one tooth.
    let pairs: [(dinosaur: Dinosaur, toothType: String)]
    /// 1 distractor tooth that does not match any dinosaur in this round.
    let distractorToothType: String
}

struct SmilingDinosGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let gameplayDirectionsAudio: String
    let rounds: [SmilingDinosRound]
}

// MARK: - Main View

struct SmilingDinosGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: SmilingDinosGameConfig

    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var selectedDinosaur: Dinosaur?
    @State private var selectedToothType: String?
    @State private var matchedPairs: Set<Int> = []
    @State private var failedAttempts: Set<Int> = []
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isCorrect = false
    @State private var isAudioPlaying = false
    @State private var showVictory = false
    @State private var introWalkComplete = false
    @State private var introWalkStep = 0
    @State private var usedDinosaurIds: Set<Int> = []
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var victoryToothTypes: [String] = []
    /// Shuffled display order for each round so smiles and teeth are not aligned.
    @State private var displayedDinosaurs: [Dinosaur] = []
    @State private var displayedToothTypes: [String] = []

    private let totalRounds = 3

    private var currentRoundConfig: SmilingDinosRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    private var pairs: [(dinosaur: Dinosaur, toothType: String)] {
        currentRoundConfig?.pairs ?? []
    }

    private var dinosaurs: [Dinosaur] {
        pairs.map { $0.dinosaur }
    }

    private var toothTypes: [String] {
        (pairs.map { $0.toothType }) + [currentRoundConfig?.distractorToothType ?? ""].filter { !$0.isEmpty }
    }

    /// Display order for intro (matches on-screen layout, top to bottom).
    private var introSmilesOrder: [Dinosaur] { displayedDinosaurs.isEmpty ? dinosaurs : displayedDinosaurs }
    private var introTeethOrder: [String] { displayedToothTypes.isEmpty ? toothTypes : displayedToothTypes }

    /// Label shown below round status when a Smile or Tooth is selected, or during intro walk.
    private var selectedItemLabel: String? {
        // During intro walk: show the dinosaur or tooth being introduced (in display order, top to bottom)
        if !introWalkComplete, introWalkStep >= 1, introWalkStep <= 5 {
            if introWalkStep <= 2, introWalkStep - 1 < introSmilesOrder.count {
                return introSmilesOrder[introWalkStep - 1].name
            }
            if introWalkStep >= 3, introWalkStep - 3 < introTeethOrder.count {
                return dinoSmileToothDisplayName(introTeethOrder[introWalkStep - 3])
            }
        }
        // During gameplay: show user selection
        guard selectedDinosaur != nil || selectedToothType != nil else { return nil }
        var parts: [String] = []
        if let dino = selectedDinosaur {
            parts.append(dino.name)
        }
        if let tooth = selectedToothType {
            let formatted = dinoSmileToothDisplayName(tooth)
            parts.append(parts.isEmpty ? formatted : "→ \(formatted)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    var body: some View {
        NavigationView {
            Group {
                if showVictory {
                    victoryView
                } else {
                    mainGameView
                }
            }
            .padding()
            .onAppear {
                guard currentRound == 1 else { return }
                resetGameState()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startIntroWalk()
                }
            }
            .allowsHitTesting(!isAudioPlaying)
            .opacity(isAudioPlaying ? 0.7 : 1.0)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func resetGameState() {
        selectedDinosaur = nil
        selectedToothType = nil
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        showFeedback = false
        introWalkComplete = false
        introWalkStep = 0
    }

    // MARK: - Main Game

    private var mainGameView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(gameConfig.title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                // Fixed-height label area: selection name, intro name, or feedback (That's right! / Try again!)
                Text(showFeedback ? feedbackMessage : (selectedItemLabel ?? " "))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(showFeedback ? (isCorrect ? .green : .orange) : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(height: 52)
                    .opacity(showFeedback || selectedItemLabel != nil ? 1 : 0)
            }

            HStack(spacing: 20) {
                VStack(spacing: 15) {
                    Text("Smiles")
                        .font(.headline)
                    ForEach((displayedDinosaurs.isEmpty ? dinosaurs : displayedDinosaurs), id: \.id) { dino in
                        SmileCard(
                            dinosaur: dino,
                            isSelected: selectedDinosaur?.id == dino.id,
                            isMatched: matchedPairs.contains(dino.id),
                            hasFailedAttempt: failedAttempts.contains(dino.id),
                            isIntroHighlighted: !introWalkComplete && introWalkStep >= 1 && introWalkStep <= 2 && introWalkStep - 1 < introSmilesOrder.count && introSmilesOrder[introWalkStep - 1].id == dino.id,
                            onTap: { handleSmileTap(dino) }
                        )
                    }
                }

                VStack(spacing: 15) {
                    Text("Tooth Shapes")
                        .font(.headline)
                    ForEach(displayedToothTypes.isEmpty ? toothTypes : displayedToothTypes, id: \.self) { toothType in
                        ToothCard(
                            toothType: toothType,
                            isSelected: selectedToothType == toothType,
                            isMatched: matchedPairs.contains(where: { id in
                                pairs.contains { $0.dinosaur.id == id && $0.toothType == toothType }
                            }),
                            hasFailedAttempt: matchedPairs.isEmpty && selectedToothType == toothType && showFeedback && !isCorrect,
                            isIntroHighlighted: !introWalkComplete && introWalkStep >= 3 && introWalkStep <= 5 && introWalkStep - 3 < introTeethOrder.count && introTeethOrder[introWalkStep - 3] == toothType,
                            onTap: { handleToothTap(toothType) }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
        .task(id: currentRound) {
            displayedDinosaurs = dinosaurs.shuffled()
            displayedToothTypes = toothTypes.shuffled()
        }
        .id(currentRound)
    }

    // MARK: - Intro Walk

    private func startIntroWalk() {
        guard dinosaurs.count >= 2, toothTypes.count >= 3 else {
            introWalkComplete = true
            isAudioPlaying = false
            return
        }
        introWalkStep = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.advanceIntroWalk()
        }
        speechManager.speak("game-dino-smile-gameplay-directions")
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep >= 6 {
            introWalkComplete = true
            isAudioPlaying = false
            return
        }
        speechManager.onAudioFinished = { advanceIntroWalk() }
        if introWalkStep <= 2, introWalkStep - 1 < introSmilesOrder.count {
            let d = introSmilesOrder[introWalkStep - 1]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        } else if introWalkStep >= 3, introWalkStep - 3 < introTeethOrder.count {
            let toothType = introTeethOrder[introWalkStep - 3]
            let fallback = dinoSmileToothDisplayName(toothType)
            playToothAudio(speechManager: speechManager, toothType: toothType, fallbackText: fallback, onFinished: advanceIntroWalk)
        }
    }

    // MARK: - Tap Handlers

    private func handleSmileTap(_ dino: Dinosaur) {
        guard !isAudioPlaying else { return }
        if matchedPairs.contains(dino.id) {
            speechManager.speak("pick-another-one")
            return
        }
        if selectedDinosaur?.id == dino.id {
            selectedDinosaur = nil
            return
        }
        isAudioPlaying = true
        speechManager.onAudioFinished = { DispatchQueue.main.async { self.isAudioPlaying = false } }
        speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
        selectedDinosaur = dino
        selectedToothType = nil
    }

    private func handleToothTap(_ toothType: String) {
        guard !isAudioPlaying else { return }
        let alreadyMatched = pairs.contains { $0.toothType == toothType && matchedPairs.contains($0.dinosaur.id) }
        if alreadyMatched {
            speechManager.speak("pick-another-one")
            return
        }
        if selectedDinosaur == nil {
            isAudioPlaying = true
            speechManager.onAudioFinished = { DispatchQueue.main.async { self.isAudioPlaying = false } }
            speechManager.speak("pick-a-dinosaur-first")
            return
        }
        if selectedToothType == toothType {
            selectedToothType = nil
            return
        }
        selectedToothType = toothType

        guard let dino = selectedDinosaur else { return }
        let correctTooth = pairs.first { $0.dinosaur.id == dino.id }?.toothType
        let isCorrectMatch = correctTooth == toothType

        showFeedback = true
        self.isCorrect = isCorrectMatch
        feedbackMessage = isCorrectMatch ? "That's right!" : "Try again!"
        isAudioPlaying = true

        let playMatchFeedback: () -> Void = {
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.showFeedback = false
                if isCorrectMatch {
                    self.matchedPairs.insert(dino.id)
                    if self.matchedPairs.count >= 2 {
                        self.finishRound()
                    } else {
                        self.selectedDinosaur = nil
                        self.selectedToothType = nil
                        self.isAudioPlaying = false
                    }
                } else {
                    self.failedAttempts.insert(dino.id)
                    self.selectedDinosaur = nil
                    self.selectedToothType = nil
                    self.isAudioPlaying = false
                }
            }
            if let url = self.speechManager.urlForAudio(key: isCorrectMatch ? "thats-right-you-guessed-it" : "try-again") {
                self.speechManager.playAudioFile(url: url)
            } else {
                self.speechManager.speak(isCorrectMatch ? "thats-right-you-guessed-it" : "try-again")
            }
        }

        // Play tooth audio first, then match feedback
        let fallback = dinoSmileToothDisplayName(toothType)
        playToothAudio(speechManager: speechManager, toothType: toothType, fallbackText: fallback) {
            self.speechManager.onAudioFinished = nil
            playMatchFeedback()
        }
    }

    private func finishRound() {
        for (_, toothType) in pairs {
            victoryToothTypes.append(toothType)
        }
        usedDinosaurIds.formUnion(dinosaurs.map(\.id))
        selectedDinosaur = nil
        selectedToothType = nil

        if currentRound >= totalRounds {
            isAudioPlaying = false
            showVictory = true
            // endSequenceStep and endHighlightIndex are set in victoryView.onAppear (guard requires -1)
        } else {
            currentRound += 1
            resetGameState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startIntroWalk()
            }
        }
    }

    // MARK: - Victory

    private let victoryRowHeight: CGFloat = 72
    /// Visible height for sliding list (~3 rows like Toothache); list scrolls as we walk through items.
    private var victoryListVisibleHeight: CGFloat { 16 + 3 * 92 + 2 * 12 + 16 }

    /// Deduplicated tooth types for victory display (preserves order of first appearance).
    private var victoryToothTypesUnique: [String] {
        var seen = Set<String>()
        return victoryToothTypes.filter { seen.insert($0).inserted }
    }

    private var victoryView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(victoryToothTypesUnique.enumerated()), id: \.offset) { index, toothType in
                                ToothVictoryRowView(toothType: toothType, isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .frame(height: min(CGFloat(victoryToothTypesUnique.count) * (92 + 12) + 32, victoryListVisibleHeight))
                    .onChange(of: endHighlightIndex) { _, newValue in
                        if newValue >= 0, newValue < victoryToothTypesUnique.count {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        successImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playGoodJobAndCrowdThenDismiss()
                                }
                            }
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryToothTypesUnique.isEmpty {
                endSequenceStep = 2
            } else {
                let toothType = victoryToothTypesUnique[0]
                let fallback = dinoSmileToothDisplayName(toothType)
                playToothAudio(speechManager: speechManager, toothType: toothType, fallbackText: fallback, onFinished: advanceVictoryHighlight)
                // Timeout: if audio never completes, advance after 6s to prevent permanent hang
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if endHighlightIndex == 0, endSequenceStep == 1 {
                        advanceVictoryHighlight()
                    }
                }
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryToothTypesUnique.count {
            let toothType = victoryToothTypesUnique[endHighlightIndex]
            let fallback = dinoSmileToothDisplayName(toothType)
            playToothAudio(speechManager: speechManager, toothType: toothType, fallbackText: fallback, onFinished: advanceVictoryHighlight)
            let currentIndex = endHighlightIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if endHighlightIndex == currentIndex, endSequenceStep == 1 {
                    advanceVictoryHighlight()
                }
            }
        } else {
            endSequenceStep = 2
        }
    }

    private var successImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-smile-success") {
                Image("game-dino-smile-success")
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

    private func playGoodJobAndCrowdThenDismiss() {
        let goodJobURL = speechManager.urlForAudio(key: "good-job-you-got-them-all")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")
        if let u1 = goodJobURL, let u2 = crowdURL {
            speechManager.playTogether(url1: u1, url2: u2) {
                self.speechManager.onAudioFinished = nil
                self.isAudioPlaying = false
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isAudioPlaying = false
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            isAudioPlaying = false
            isPresented = false
        }
    }
}

// MARK: - Cards

private let dinoSmileCardSize: CGFloat = 165

private struct SmileCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void

    private var imageName: String? {
        let slug = dinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dinosaur.id)"
        let smileName = "dino-smile-\(slug)"
        if ImageAssetCache.imageExists(named: smileName) { return smileName }
        if let dinoName = dinosaur.imageName, ImageAssetCache.imageExists(named: dinoName) { return dinoName }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            Group {
                if let name = imageName {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: dinoSmileCardSize, height: dinoSmileCardSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: dinoSmileCardSize, height: dinoSmileCardSize)
                        .overlay(Text(dinosaur.icon).font(.system(size: 48)))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || isIntroHighlighted ? 4 : 2)
            )
            .opacity(isMatched ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isMatched { return .green }
        if hasFailedAttempt { return .red }
        if isSelected || isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

private struct ToothCard: View {
    let toothType: String
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void

    private var imageName: String {
        "dino-smile-tooth-\(toothType)"
    }

    private var isDiamondBattery: Bool { toothType.contains("diamond-battery") }

    var body: some View {
        Button(action: onTap) {
            Group {
                if ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: dinoSmileCardSize, height: dinoSmileCardSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(diamondBatteryShineOverlay)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: dinoSmileCardSize, height: dinoSmileCardSize)
                        .overlay(Text("🦷").font(.system(size: 48)))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || isIntroHighlighted ? 4 : 2)
            )
            .opacity(isMatched ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isMatched { return .green }
        if hasFailedAttempt { return .red }
        if isSelected || isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }

    @ViewBuilder private var diamondBatteryShineOverlay: some View {
        if isDiamondBattery {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
        }
    }
}

private struct ToothVictoryImage: View {
    let toothType: String
    let isHighlighted: Bool

    private var imageName: String { "dino-smile-tooth-\(toothType)" }
    private var isDiamondBattery: Bool { toothType.contains("diamond-battery") }

    var body: some View {
        Group {
            if ImageAssetCache.imageExists(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(diamondBatteryShineOverlay)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            } else {
                Text("🦷")
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }

    @ViewBuilder private var diamondBatteryShineOverlay: some View {
        if isDiamondBattery {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
        }
    }
}

/// Victory row: tooth shape image + name.
private struct ToothVictoryRowView: View {
    let toothType: String
    let isHighlighted: Bool
    private let rowHeight: CGFloat = 92

    private var imageName: String { "dino-smile-tooth-\(toothType)" }
    private var isDiamondBattery: Bool { toothType.contains("diamond-battery") }

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(diamondBatteryShineOverlay)
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                } else {
                    Text("🦷")
                        .font(.system(size: 40))
                        .frame(width: 72, height: 72)
                        .opacity(isHighlighted ? 1.0 : 0.4)
                }
            }
            Text(dinoSmileToothDisplayName(toothType))
                .font(.title2)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isHighlighted ? 1.0 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: rowHeight)
        .background(RoundedRectangle(cornerRadius: 12).fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2))
    }

    @ViewBuilder private var diamondBatteryShineOverlay: some View {
        if isDiamondBattery {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
        }
    }
}

// MARK: - Game Config

struct SmilingDinosGameConfigs {
    static var smilingDinos: SmilingDinosGameConfig {
        var usedIds: Set<Int> = []
        var usedToothTypes: Set<String> = []
        var rounds: [SmilingDinosRound] = []
        let pool = dinosaursWithSmileAndTooth

        let allToothTypes = Set(pool.compactMap { DentalMorphology.smileToothType(for: $0) }.filter { ImageAssetCache.imageExists(named: "dino-smile-tooth-\($0)") })
        let cladeById = MatchingGameConfigs.dinosaurCladeById
        let toothTypeToClades: [String: Set<DinoClade>] = {
            var map: [String: Set<DinoClade>] = [:]
            for dino in pool {
                guard let tt = DentalMorphology.smileToothType(for: dino),
                      ImageAssetCache.imageExists(named: "dino-smile-tooth-\(tt)") else { continue }
                let clade = cladeById[dino.id] ?? .theropod
                map[tt, default: []].insert(clade)
            }
            return map
        }()
        for roundId in 1...3 {
            let available = pool.filter { !usedIds.contains($0.id) }
            let availableWithNewTeeth = available.filter { d in
                guard let tt = DentalMorphology.smileToothType(for: d) else { return false }
                return !usedToothTypes.contains(tt)
            }
            let selectionPool = availableWithNewTeeth.count >= 2 ? availableWithNewTeeth : available
            let byClade = Dictionary(grouping: selectionPool) { cladeById[$0.id] ?? .theropod }
            let cladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }.shuffled()
            let selected: [Dinosaur]
            if cladesWithDinos.count >= 2 {
                selected = (0..<2).compactMap { i in
                    let clade = cladesWithDinos[i]
                    return (byClade[clade] ?? []).shuffled().first
                }
            } else {
                let shuffled = selectionPool.count >= 2 ? selectionPool.shuffled() : pool.shuffled()
                selected = Array(shuffled.prefix(2))
            }
            guard selected.count == 2, Set(selected.map(\.id)).count == 2 else { break }

            var pairs: [(Dinosaur, String)] = []
            var roundToothTypes: Set<String> = []
            for dino in selected {
                guard let toothType = DentalMorphology.smileToothType(for: dino) else { continue }
                pairs.append((dino, toothType))
                roundToothTypes.insert(toothType)
            }
            guard pairs.count == 2 else { break }

            // Exclude distractor teeth from the same clade(s) as the correct teeth, so children
            // don't face "Pencil Peg vs Heavy Peg" (both sauropod) when matching Apatosaurus.
            let baseCandidates = allToothTypes.subtracting(roundToothTypes).subtracting(usedToothTypes)
            let roundClades = Set(roundToothTypes.compactMap { toothTypeToClades[$0] }.joined())
            let distractorCandidates = baseCandidates.isEmpty ? [] : baseCandidates.filter { candidate in
                guard let candidateClades = toothTypeToClades[candidate] else { return true }
                return candidateClades.isDisjoint(with: roundClades)
            }
            let distractor = (distractorCandidates.isEmpty ? Array(baseCandidates) : distractorCandidates).randomElement()
            guard let distractor else { break }

            usedIds.formUnion(selected.map(\.id))
            usedToothTypes.formUnion(roundToothTypes)
            usedToothTypes.insert(distractor)
            rounds.append(SmilingDinosRound(id: roundId, pairs: pairs, distractorToothType: distractor))
        }

        guard rounds.count >= 3 else {
            fatalError("Need at least 3 rounds for Smiling Dinos (pool has \(pool.count) dinosaurs with smile+tooth)")
        }

        return SmilingDinosGameConfig(
            id: "smiling-dinos",
            title: "Dino Smile!",
            introAudio: "game-dino-smile",
            gameplayDirectionsAudio: "game-dino-smile-gameplay-directions",
            rounds: Array(rounds.prefix(3))
        )
    }

    private static var dinosaursWithSmileAndTooth: [Dinosaur] {
        var pool = MatchingGameConfigs.allDinosaurs.filter { dino in
            let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
            let smileName = "dino-smile-\(slug)"
            guard ImageAssetCache.imageExists(named: smileName),
                  let toothType = DentalMorphology.smileToothType(for: dino) else { return false }
            let toothName = "dino-smile-tooth-\(toothType)"
            return ImageAssetCache.imageExists(named: toothName)
        }
        if pool.count < 6 {
            pool = MatchingGameConfigs.allDinosaurs.filter { dino in
            guard let toothType = DentalMorphology.smileToothType(for: dino) else { return false }
            let toothName = "dino-smile-tooth-\(toothType)"
            return ImageAssetCache.imageExists(named: toothName) && (dino.imageName?.hasPrefix("dino-") == true)
            }
        }
        return pool
    }
}
