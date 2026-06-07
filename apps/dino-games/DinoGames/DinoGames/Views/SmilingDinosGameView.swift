//
//  SmilingDinosGameView.swift
//  DinoGames
//
//  Smiling Dinos: Match 2 dinosaur smiles to 3 teeth (2 matches + 1 distractor). Mimics Match the Dinosaur framework.
//  Left column: Smiles (dino-smile-{slug}). Right column: Tooth Shapes (dino-smile-tooth-{toothType}).
//  Each smile matches one tooth. 3 rounds, 6 introduced per game. Victory: shared pipeline; recap re-introduces tooth shapes.
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

enum SmileGameLine {
    case land
    case air
}

/// Play tooth/beak shape audio. Land tries dino-smile-{toothType} variants; air tries ptero-smile-tooth-{toothType}.
private func playToothAudio(
    speechManager: SpeechManager,
    toothType: String,
    line: SmileGameLine,
    fallbackText: String,
    chainDelay: Bool = false,
    onFinished: (() -> Void)?
) {
    let candidateKeys: [String]
    switch line {
    case .land:
        let baseKey = "dino-smile-\(toothType)"
        candidateKeys = [baseKey, "\(baseKey)-v1", "\(baseKey)-v2", "dino-smile-tooth-\(toothType)"]
    case .air:
        candidateKeys = [
            PteroSmileMorphology.toothAudioKey(for: toothType),
            "ptero-smile-tooth-\(toothType)",
            "ptero-smile-\(toothType)",
        ]
    }
    let url = candidateKeys.lazy.compactMap { speechManager.urlForAudio(key: $0) }.first
    if let url {
        speechManager.onAudioFinished = onFinished
        speechManager.playAudioFile(url: url, fallbackSpeakText: fallbackText)
    } else {
        speechManager.onAudioFinished = onFinished
        speechManager.speak(fallbackText, chainDelay: chainDelay)
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

    var line: SmileGameLine { id == "ptero-smile" ? .air : .land }

    var successImageCandidates: [String] {
        switch line {
        case .land:
            return ["game-dino-smile-success", "game-smiling-dinos-success", "game-smiling-dinos"]
        case .air:
            return ["game-ptero-smile-success", "game-ptero-smile"]
        }
    }

    func toothImageName(for toothType: String) -> String {
        switch line {
        case .land:
            return "dino-smile-tooth-\(toothType)"
        case .air:
            return PteroSmileMorphology.toothImageAssetName(for: toothType)
        }
    }

    var pickCreatureFirstPrompt: String {
        line == .air ? "pick-a-pterosaur-first" : "pick-a-dinosaur-first"
    }
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
    @State private var showMatchFeedback = false
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
                        .padding()
                }
            }
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
        showMatchFeedback = false
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
                // Fixed-height label area: selection name or intro name
                Text(selectedItemLabel ?? " ")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(height: 52)
                    .opacity(selectedItemLabel != nil ? 1 : 0)
            }

            HStack(spacing: 20) {
                VStack(spacing: 15) {
                    Text("Smiles")
                        .font(.headline)
                    ForEach((displayedDinosaurs.isEmpty ? dinosaurs : displayedDinosaurs), id: \.id) { dino in
                        SmileCard(
                            line: gameConfig.line,
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
                            imageName: gameConfig.toothImageName(for: toothType),
                            toothType: toothType,
                            isSelected: selectedToothType == toothType,
                            isMatched: matchedPairs.contains(where: { id in
                                pairs.contains { $0.dinosaur.id == id && $0.toothType == toothType }
                            }),
                            hasFailedAttempt: matchedPairs.isEmpty && selectedToothType == toothType && showMatchFeedback && !isCorrect,
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
        speechManager.speak(gameConfig.gameplayDirectionsAudio)
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
            playToothAudio(speechManager: speechManager, toothType: toothType, line: gameConfig.line, fallbackText: fallback, onFinished: advanceIntroWalk)
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
            speechManager.speak(gameConfig.pickCreatureFirstPrompt)
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

        showMatchFeedback = true
        self.isCorrect = isCorrectMatch
        isAudioPlaying = true

        let playMatchFeedback: () -> Void = {
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.showMatchFeedback = false
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
        playToothAudio(speechManager: speechManager, toothType: toothType, line: gameConfig.line, fallbackText: fallback) {
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
            endSequenceStep = -1
            endHighlightIndex = 0
            showVictory = true
        } else {
            currentRound += 1
            resetGameState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startIntroWalk()
            }
        }
    }

    // MARK: - Victory (shared: recap tooth shapes → success stinger → good-job + crowd)

    /// Deduplicated tooth types for victory display (preserves order of first appearance).
    private var victoryToothTypesUnique: [String] {
        var seen = Set<String>()
        return victoryToothTypes.filter { seen.insert($0).inserted }
    }

    private var smileVictoryRecapItems: [VictoryRecapDisplayItem] {
        victoryToothTypesUnique.map { toothType in
            let imageName = gameConfig.toothImageName(for: toothType)
            return VictoryRecapDisplayItem(
                id: toothType,
                title: dinoSmileToothDisplayName(toothType),
                imageAssetName: ImageAssetCache.imageExists(named: imageName) ? imageName : nil,
                fallbackEmoji: "🦷"
            )
        }
    }

    private var victoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: smileVictoryRecapItems.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            hideGameTitleDuringSuccessPhase: false,
            scrollRows: {
                ForEach(Array(smileVictoryRecapItems.enumerated()), id: \.element.id) { index, item in
                    StandardVictoryRecapRowView(
                        item: item,
                        isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: gameConfig.successImageCandidates,
                    catalogGameIdForStinger: gameConfig.id,
                    imageSide: GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
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
            if smileVictoryRecapItems.isEmpty {
                endSequenceStep = 2
            } else {
                speakSmileVictoryRecap(at: 0)
                speechManager.onAudioFinished = { advanceSmileVictoryHighlight() }
            }
        }
    }

    private func speakSmileVictoryRecap(at index: Int) {
        guard index < victoryToothTypesUnique.count else { return }
        let toothType = victoryToothTypesUnique[index]
        let fallback = dinoSmileToothDisplayName(toothType)
        playToothAudio(
            speechManager: speechManager,
            toothType: toothType,
            line: gameConfig.line,
            fallbackText: fallback,
            chainDelay: true,
            onFinished: nil
        )
    }

    private func advanceSmileVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryToothTypesUnique.count {
            speakSmileVictoryRecap(at: endHighlightIndex)
            speechManager.onAudioFinished = { advanceSmileVictoryHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager,
            beforeDismiss: { isAudioPlaying = false }
        )
    }
}

// MARK: - Cards

private let dinoSmileCardSize: CGFloat = 165

private struct SmileCard: View {
    let line: SmileGameLine
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void

    private var imageName: String? {
        switch line {
        case .air:
            return PteroSmileMorphology.smilePortraitAssetName(for: dinosaur)
        case .land:
            let slug = dinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dinosaur.id)"
            let smileName = "dino-smile-\(slug)"
            if ImageAssetCache.imageExists(named: smileName) { return smileName }
            if let dinoName = dinosaur.imageName, ImageAssetCache.imageExists(named: dinoName) { return dinoName }
            return nil
        }
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
    let imageName: String
    let toothType: String
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void

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

// MARK: - Game Config

struct SmilingDinosGameConfigs {
    static var smilingDinos: SmilingDinosGameConfig {
        var usedIds: Set<Int> = []
        var usedToothTypes: Set<String> = []
        var rounds: [SmilingDinosRound] = []
        let pool = dinosaursWithSmileAndTooth

        let allToothTypes = Set(pool.compactMap { DentalMorphology.smileToothType(for: $0) }.filter { ImageAssetCache.imageExists(named: "dino-smile-tooth-\($0)") })
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
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

    static var isPteroSmilePlayable: Bool { makePteroSmile() != nil }

    static var pteroSmile: SmilingDinosGameConfig {
        guard let config = makePteroSmile() else {
            fatalError("Ptero Smile requires 6 pterosaurs with bundled smile and tooth art")
        }
        return config
    }

    static func config(for category: GameCategory) -> SmilingDinosGameConfig {
        switch category {
        case .air:
            return pteroSmile
        default:
            return smilingDinos
        }
    }

    static func makePteroSmile() -> SmilingDinosGameConfig? {
        let pool = pterosaursWithSmileAndTooth
        guard let rounds = buildPteroSmileRounds(from: pool) else { return nil }
        return SmilingDinosGameConfig(
            id: "ptero-smile",
            title: "Ptero Smile!",
            introAudio: "game-ptero-smile",
            gameplayDirectionsAudio: "game-ptero-smile-gameplay-directions",
            rounds: rounds
        )
    }

    private static var pterosaursWithSmileAndTooth: [Dinosaur] {
        AirPterosaurData.allPterosaurs.filter { ptero in
            guard PteroSmileMorphology.smilePortraitAssetName(for: ptero) != nil,
                  let toothType = PteroSmileMorphology.smileToothType(for: ptero) else { return false }
            return ImageAssetCache.imageExists(named: PteroSmileMorphology.toothImageAssetName(for: toothType))
        }
    }

    private static func buildPteroSmileRounds(from pool: [Dinosaur]) -> [SmilingDinosRound]? {
        var usedIds: Set<Int> = []
        var usedToothTypes: Set<String> = []
        var rounds: [SmilingDinosRound] = []

        let allToothTypes = Set(pool.compactMap { PteroSmileMorphology.smileToothType(for: $0) })
        let morphGroupByTooth = Dictionary(uniqueKeysWithValues: allToothTypes.map {
            ($0, PteroSmileMorphology.morphologyGroup(for: $0))
        })

        for roundId in 1...3 {
            let available = pool.filter { !usedIds.contains($0.id) }
            let availableWithNewTeeth = available.filter { ptero in
                guard let toothType = PteroSmileMorphology.smileToothType(for: ptero) else { return false }
                return !usedToothTypes.contains(toothType)
            }
            let selectionPool = availableWithNewTeeth.count >= 2 ? availableWithNewTeeth : available
            let byMorph = Dictionary(grouping: selectionPool) { ptero in
                PteroSmileMorphology.smileToothType(for: ptero)
                    .map { PteroSmileMorphology.morphologyGroup(for: $0) } ?? "unknown"
            }
            let morphsWithPteros = byMorph.keys.filter { !(byMorph[$0] ?? []).isEmpty }.shuffled()
            let selected: [Dinosaur]
            if morphsWithPteros.count >= 2 {
                selected = (0..<2).compactMap { index in
                    let group = morphsWithPteros[index]
                    return (byMorph[group] ?? []).shuffled().first
                }
            } else {
                let shuffled = selectionPool.count >= 2 ? selectionPool.shuffled() : pool.shuffled()
                selected = Array(shuffled.prefix(2))
            }
            guard selected.count == 2, Set(selected.map(\.id)).count == 2 else { break }

            var pairs: [(Dinosaur, String)] = []
            var roundToothTypes: Set<String> = []
            for ptero in selected {
                guard let toothType = PteroSmileMorphology.smileToothType(for: ptero) else { continue }
                pairs.append((ptero, toothType))
                roundToothTypes.insert(toothType)
            }
            guard pairs.count == 2 else { break }

            let baseCandidates = allToothTypes.subtracting(roundToothTypes)
            let roundMorphGroups = Set(roundToothTypes.compactMap { morphGroupByTooth[$0] })
            let distractorCandidates = baseCandidates.filter { candidate in
                guard let group = morphGroupByTooth[candidate] else { return true }
                return !roundMorphGroups.contains(group)
            }
            let distractor = (distractorCandidates.isEmpty ? Array(baseCandidates) : Array(distractorCandidates)).randomElement()
            guard let distractor else { break }

            usedIds.formUnion(selected.map(\.id))
            usedToothTypes.formUnion(roundToothTypes)
            rounds.append(SmilingDinosRound(id: roundId, pairs: pairs, distractorToothType: distractor))
        }

        guard rounds.count >= 3 else { return nil }
        return Array(rounds.prefix(3))
    }
}
