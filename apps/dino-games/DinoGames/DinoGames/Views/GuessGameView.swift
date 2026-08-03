//
//  GuessGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/26/26.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RoundQuestion: Identifiable {
    let id: Int // Round number (1, 2, 3)
    let questionImageName: String // Silhouette image name
    let questionImageFallback: String? // Fallback full image name
    let correctAnswerId: Int // ID of the correct dinosaur
    let options: [Dinosaur] // 3 dinosaurs: 1 correct + 2 decoys (all unique)
    /// Whose Bones?: victory walk speaks `body-{key}` → Audio/Body/{key}.m4a (e.g. skull, ribcage).
    let bodySegmentSpeechKey: String?

    init(
        id: Int,
        questionImageName: String,
        questionImageFallback: String?,
        correctAnswerId: Int,
        options: [Dinosaur],
        bodySegmentSpeechKey: String? = nil
    ) {
        self.id = id
        self.questionImageName = questionImageName
        self.questionImageFallback = questionImageFallback
        self.correctAnswerId = correctAnswerId
        self.options = options
        self.bodySegmentSpeechKey = bodySegmentSpeechKey
    }
}

// MARK: - Name That Dinosaur used-creature persistence (avoid repeat in future games, acknowledge in victory block)

private enum NameThatDinosaurStorage {
    static let usedCreatureIdsKey = "nameThatDinosaurUsedCreatureIds"
    static let usedCladeRawValuesKey = "nameThatDinosaurUsedCladeRawValues"
    static let cladeCount = DinoClade.allCases.count

    static func loadUsedCreatureIds() -> Set<Int> {
        guard let array = UserDefaults.standard.array(forKey: usedCreatureIdsKey) as? [Int] else { return [] }
        return Set(array)
    }

    static func appendUsedCreatureIds(_ ids: [Int]) {
        var current = loadUsedCreatureIds()
        current.formUnion(ids)
        UserDefaults.standard.set(Array(current), forKey: usedCreatureIdsKey)
    }

    static func clearIfNeeded(availableCount: Int) {
        if availableCount < 3 {
            UserDefaults.standard.removeObject(forKey: usedCreatureIdsKey)
        }
    }

    /// Clades already used in recent games; not used again until all 9 have been used (then cleared).
    static func loadUsedCladeRawValues() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedCladeRawValuesKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedCladeRawValues(_ rawValues: [String]) {
        var current = loadUsedCladeRawValues()
        current.formUnion(rawValues)
        UserDefaults.standard.set(Array(current), forKey: usedCladeRawValuesKey)
        if current.count >= cladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }

    static func clearUsedCladesIfAllUsed() {
        if loadUsedCladeRawValues().count >= cladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }
}

// MARK: - Name That Marine Reptile used-creature / clade persistence

private enum NameThatMarineReptileStorage {
    static let usedCreatureIdsKey = "nameThatMarineReptileUsedCreatureIds"
    static let usedCladeRawValuesKey = "nameThatMarineReptileUsedCladeRawValues"

    static func loadUsedCreatureIds() -> Set<Int> {
        guard let array = UserDefaults.standard.array(forKey: usedCreatureIdsKey) as? [Int] else { return [] }
        return Set(array)
    }

    static func appendUsedCreatureIds(_ ids: [Int]) {
        var current = loadUsedCreatureIds()
        current.formUnion(ids)
        UserDefaults.standard.set(Array(current), forKey: usedCreatureIdsKey)
    }

    static func clearUsedCreaturesIfNeeded(availableCount: Int, roundCount: Int) {
        if availableCount < roundCount {
            UserDefaults.standard.removeObject(forKey: usedCreatureIdsKey)
        }
    }

    static func loadUsedCladeRawValues() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedCladeRawValuesKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedCladeRawValues(_ rawValues: [String], maxCladeCount: Int) {
        var current = loadUsedCladeRawValues()
        current.formUnion(rawValues)
        UserDefaults.standard.set(Array(current), forKey: usedCladeRawValuesKey)
        if current.count >= maxCladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }

    static func clearUsedCladesIfAllUsed(maxCladeCount: Int) {
        if maxCladeCount > 0, loadUsedCladeRawValues().count >= maxCladeCount {
            UserDefaults.standard.removeObject(forKey: usedCladeRawValuesKey)
        }
    }
}

// MARK: - Marine Smile used-creature persistence (one fresh smiling reptile per tooth type when possible)

private enum MarineSmileStorage {
    static let usedCreatureIdsKey = "marineSmileUsedCreatureIds"

    static func loadUsedCreatureIds() -> Set<Int> {
        guard let array = UserDefaults.standard.array(forKey: usedCreatureIdsKey) as? [Int] else { return [] }
        return Set(array)
    }

    static func appendUsedCreatureIds(_ ids: [Int]) {
        var current = loadUsedCreatureIds()
        current.formUnion(ids)
        UserDefaults.standard.set(Array(current), forKey: usedCreatureIdsKey)
    }

    static func clearIfNeeded(playableCount: Int, roundCount: Int) {
        if playableCount < roundCount {
            UserDefaults.standard.removeObject(forKey: usedCreatureIdsKey)
        }
    }
}

// MARK: - Dino Footprints slot rotation (clade × size footprint images)

private enum DinoFootprintsStorage {
    static let usedSlotKeysKey = "dinoFootprintsUsedSlotKeys"

    static func loadUsedSlotKeys() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedSlotKeysKey) as? [String] else { return [] }
        return Set(array)
    }

    /// Marks slots used after a completed game; clears storage once every occupiable (clade|size) slot has been seen.
    static func appendUsedSlotKeys(_ keys: [String], allPossibleSlotKeys: Set<String>) {
        guard !allPossibleSlotKeys.isEmpty else { return }
        var current = loadUsedSlotKeys()
        current.formUnion(keys)
        if allPossibleSlotKeys.isSubset(of: current) {
            UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
        } else {
            UserDefaults.standard.set(Array(current), forKey: usedSlotKeysKey)
        }
    }

    static func clearUsedSlots() {
        UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
    }
}

// MARK: - Ptero Footprints slot rotation (morphotype × size, matches `ptero-footprint-{stem}-*` assets)

private enum PteroFootprintsStorage {
    static let usedSlotKeysKey = "pteroFootprintsUsedSlotKeys"

    static func loadUsedSlotKeys() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedSlotKeysKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedSlotKeys(_ keys: [String], allPossibleSlotKeys: Set<String>) {
        guard !allPossibleSlotKeys.isEmpty else { return }
        var current = loadUsedSlotKeys()
        current.formUnion(keys)
        if allPossibleSlotKeys.isSubset(of: current) {
            UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
        } else {
            UserDefaults.standard.set(Array(current), forKey: usedSlotKeysKey)
        }
    }

    static func clearUsedSlots() {
        UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
    }
}

// MARK: - Marine Footprints slot rotation (locomotion × clade track images)

private enum MarineFootprintsStorage {
    static let usedSlotKeysKey = "marineFootprintsUsedSlotKeys"

    static func loadUsedSlotKeys() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: usedSlotKeysKey) as? [String] else { return [] }
        return Set(array)
    }

    static func appendUsedSlotKeys(_ keys: [String], allPossibleSlotKeys: Set<String>) {
        guard !allPossibleSlotKeys.isEmpty else { return }
        var current = loadUsedSlotKeys()
        current.formUnion(keys)
        if allPossibleSlotKeys.isSubset(of: current) {
            UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
        } else {
            UserDefaults.standard.set(Array(current), forKey: usedSlotKeysKey)
        }
    }

    static func clearUsedSlots() {
        UserDefaults.standard.removeObject(forKey: usedSlotKeysKey)
    }
}

// MARK: - Game Configuration

struct GuessGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let rounds: [RoundQuestion]
    let availableDinosaurs: [Dinosaur]
    /// Runs when the player finishes all rounds, as the final “good job + crowd” begins (e.g. UserDefaults for Name That Dinosaur).
    let victorySideEffect: (() -> Void)?

    init(
        id: String,
        title: String,
        introAudio: String,
        rounds: [RoundQuestion],
        availableDinosaurs: [Dinosaur],
        victorySideEffect: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.introAudio = introAudio
        self.rounds = rounds
        self.availableDinosaurs = availableDinosaurs
        self.victorySideEffect = victorySideEffect
    }
}

// MARK: - Main View

struct GuessGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: GuessGameConfig
    
    @State private var speechManager = SpeechManager()
    @State private var currentRound = 1 // 1, 2, or 3
    @State private var selectedDinosaur: Dinosaur?
    @State private var isAudioPlaying = false
    @State private var errorCount = 0 // Track errors across all rounds
    @State private var successCount = 0 // Track successful rounds
    @State private var wrongGuessesThisRound = 0
    @State private var isGameComplete = false
    @State private var isProcessingAnswer = false
    
    /// End sequence: -1 none, 1 = walking row (highlight + name audio), 2 = good-job + crowd then dismiss
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0
    
    /// Options walk: highlight each of the 3 choices and play name before allowing selection (each round).
    @State private var optionsWalkIndex: Int? = nil

    /// When true, show the Source Footprints / pterosaur track hints overlay (footprint guess games).
    @State private var showSourceFootprintsHints = false

    private var isFootprintsGuessGame: Bool {
        gameConfig.id == "dino-footprints" || gameConfig.id == "ptero-footprints" || gameConfig.id == "marine-footprints"
    }

    /// Tracks first appearance so we only reset on initial load, not when advancing rounds (avoids resetting currentRound when SwiftUI re-invokes onAppear).
    @State private var hasInitiallyAppeared = false

    /// The correct dinosaurs per round in round order, filtered for duplicates (first appearance) for end-sequence row.
    private var endSequenceDinosaurs: [Dinosaur] {
        var seen: Set<Int> = []
        return gameConfig.rounds
            .map { r in r.options.first(where: { $0.id == r.correctAnswerId })! }
            .filter { seen.insert($0.id).inserted }
    }

    /// Victory recap: thumbnail = main clue art from that round; title = owner name (e.g. footprint + dinosaur).
    private var guessVictoryRecapItems: [VictoryRecapDisplayItem] {
        if isFootprintsGuessGame {
            return gameConfig.rounds.compactMap { round in
                guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { return nil }
                return VictoryRecapDisplayItem(
                    id: "round-\(round.id)",
                    title: dinosaur.name,
                    imageAssetName: guessFootprintVictoryImageName(round: round, dinosaur: dinosaur),
                    fallbackEmoji: dinosaur.icon
                )
            }
        }
        var seen: Set<Int> = []
        var items: [VictoryRecapDisplayItem] = []
        for round in gameConfig.rounds {
            guard let dinosaur = round.options.first(where: { $0.id == round.correctAnswerId }) else { continue }
            guard seen.insert(dinosaur.id).inserted else { continue }
            items.append(
                VictoryRecapDisplayItem(
                    id: "\(dinosaur.id)",
                    title: dinosaur.name,
                    imageAssetName: guessVictoryRecapImageName(round: round, dinosaur: dinosaur),
                    fallbackEmoji: dinosaur.icon
                )
            )
        }
        return items
    }

    /// Same footprint asset shown large at the top of the round (`footprint-*` / `ptero-footprint-*`), not the dinosaur portrait.
    private func guessFootprintVictoryImageName(round: RoundQuestion, dinosaur: Dinosaur) -> String? {
        if ImageAssetCache.imageExists(named: round.questionImageName) {
            return round.questionImageName
        }
        if let name = dinosaur.imageName, ImageAssetCache.imageExists(named: name) {
            return name
        }
        return nil
    }

    private func guessVictoryRecapImageName(round: RoundQuestion, dinosaur: Dinosaur) -> String? {
        if usesQuestionArtInVictoryRecap, ImageAssetCache.imageExists(named: round.questionImageName) {
            return round.questionImageName
        }
        if let name = dinosaur.imageName, ImageAssetCache.imageExists(named: name) {
            return name
        }
        return nil
    }

    /// Creature to speak during victory walk at `index` (aligned with `guessVictoryRecapItems`).
    private func guessVictoryRecapDinosaur(at index: Int) -> Dinosaur? {
        if isFootprintsGuessGame {
            guard index < gameConfig.rounds.count else { return nil }
            let round = gameConfig.rounds[index]
            return round.options.first(where: { $0.id == round.correctAnswerId })
        }
        guard index < endSequenceDinosaurs.count else { return nil }
        return endSequenceDinosaurs[index]
    }

    /// Guess games whose rounds teach non-portrait clues (footprints, silhouettes, skeletons, …).
    private var usesQuestionArtInVictoryRecap: Bool {
        switch gameConfig.id {
        case "dino-footprints", "ptero-footprints", "marine-footprints",
             "dino-bones", "whose-bones",
             "name-that-dinosaur", "name-that-pterosaur", "name-that-marine-reptile":
            return true
        default:
            return false
        }
    }

    /// Whose Bones?: body segment keys aligned with `endSequenceDinosaurs` for victory audio.
    private var endSequenceBodySegmentSpeechKeys: [String] {
        guard gameConfig.id == "whose-bones" else { return [] }
        var keys: [String] = []
        var seen: Set<Int> = []
        for r in gameConfig.rounds {
            guard let seg = r.bodySegmentSpeechKey else { continue }
            guard let dino = r.options.first(where: { $0.id == r.correctAnswerId }) else { continue }
            guard seen.insert(dino.id).inserted else { continue }
            keys.append(seg)
        }
        return keys
    }

    // Get current round question
    private var currentQuestion: RoundQuestion? {
        gameConfig.rounds.first { $0.id == currentRound }
    }
    
    // Reset game state
    private func resetGameState() {
        currentRound = 1
        selectedDinosaur = nil
        errorCount = 0
        successCount = 0
        wrongGuessesThisRound = 0
        isGameComplete = false
        isProcessingAnswer = false
        endSequenceStep = -1
        endHighlightIndex = 0
        optionsWalkIndex = nil
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isGameComplete {
                    guessGameEndSequenceView
                } else {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let safeHeight = max(geometry.size.height, 1)
                let topInset = geometry.safeAreaInsets.top
                // Phone-tuned baselines; grow on iPad (Footprints / Name That / Bones share this layout).
                let playMaxScale: CGFloat = 1.85
                let clueSide = min(
                    GameCatalogImageMetrics.scaled(340, safeWidth: safeWidth, maxScale: playMaxScale),
                    safeWidth * 0.72,
                    max(1, safeHeight - topInset) * 0.52
                )
                let optionSpacing = GameCatalogImageMetrics.scaled(14, safeWidth: safeWidth, maxScale: playMaxScale)
                let optionRowHPad: CGFloat = 12
                // DinosaurOptionCard chrome is imageSide+12 (idle) or imageSide+36 (highlight) — budget for highlight.
                let optionCardChrome: CGFloat = 36
                let optionRowAvail = max(1, safeWidth - optionRowHPad * 2 - optionSpacing * 2)
                let maxOptionCardWidth = optionRowAvail / 3
                let optionImageSide = min(
                    GameCatalogImageMetrics.scaled(150, safeWidth: safeWidth, maxScale: playMaxScale),
                    max(56, maxOptionCardWidth - optionCardChrome)
                )
                let titleFontSize = GameCatalogImageMetrics.scaled(34, safeWidth: safeWidth, maxScale: playMaxScale)
                let roundFontSize = GameCatalogImageMetrics.scaled(20, safeWidth: safeWidth, maxScale: playMaxScale)
                let optionLabelFontSize = GameCatalogImageMetrics.scaled(17, safeWidth: safeWidth, maxScale: playMaxScale)
                VStack(spacing: GameCatalogImageMetrics.scaled(20, safeWidth: safeWidth, maxScale: playMaxScale)) {
                Text(gameConfig.title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 8 + topInset)

                if let question = currentQuestion {
                    // Main game area - one question at a time
                    VStack(spacing: GameCatalogImageMetrics.scaled(24, safeWidth: safeWidth, maxScale: playMaxScale)) {
                        // Top: Question image (silhouette), then round label below
                        VStack(spacing: 10) {
                            // Question image: primary silhouette, then dinosaur alternate `dino-silhouette-*`, then tinted body (pterosaurs skip dino path when fallback is `ptero-*`).
                            if ImageAssetCache.imageExists(named: question.questionImageName) {
                                Image(question.questionImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: clueSide, height: clueSide)
                            } else {
                                let fallbackKey = question.questionImageFallback?.lowercased() ?? ""
                                let isPterosaurBody = fallbackKey.hasPrefix("ptero-")
                                let isMarineBody = fallbackKey.hasPrefix("marine-")
                                let dinoAlt: String? = {
                                    guard !isPterosaurBody, !isMarineBody else { return nil }
                                    let baseName = question.questionImageFallback?.replacingOccurrences(of: "dino-", with: "") ?? ""
                                    guard !baseName.isEmpty else { return nil }
                                    return "dino-silhouette-\(baseName)"
                                }()
                                if let dinoAlt, ImageAssetCache.imageExists(named: dinoAlt) {
                                    Image(dinoAlt)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: clueSide, height: clueSide)
                                } else if let fallback = question.questionImageFallback, !fallback.isEmpty {
                                    Image(fallback)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: clueSide, height: clueSide)
                                        .colorMultiply(.black)
                                        .opacity(0.8)
                                } else {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: clueSide, height: clueSide)
                                }
                            }
                            Text("Round \(currentRound) of \(gameConfig.rounds.count)")
                                .font(.system(size: roundFontSize, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Bottom: 3 dinosaur options in a row (options walk highlights each, then tap enabled)
                        HStack(spacing: optionSpacing) {
                            ForEach(Array(question.options.enumerated()), id: \.element.id) { index, dinosaur in
                                DinosaurOptionCard(
                                    dinosaur: dinosaur,
                                    isSelected: selectedDinosaur?.id == dinosaur.id,
                                    isDisabled: isProcessingAnswer || isAudioPlaying || optionsWalkIndex != nil,
                                    isHighlighted: optionsWalkIndex == index,
                                    imageSide: optionImageSide,
                                    labelFontSize: optionLabelFontSize,
                                    onTap: {
                                        handleDinosaurTap(dinosaur, question: question)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, optionRowHPad)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            } // GeometryReader
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .onAppear {
                guard !isGameComplete else { return }
                if !hasInitiallyAppeared {
                    hasInitiallyAppeared = true
                    resetGameState()
                }
                speechManager.isPlaying = false
                speechManager.onAudioFinished = nil
                speechManager.onAudioFinished = {
                    isAudioPlaying = false
                }
                // Intro already played on the transition screen; for Dino Footprints and Dino Bones play round intro at start of each round
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    startRoundIfNeeded()
                }
            }
            .onChange(of: currentRound) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startRoundIfNeeded()
                }
            }
            .onDisappear {
                speechManager.onAudioFinished = nil
                speechManager.stopCurrentAudio()
                isAudioPlaying = false
            }
            .allowsHitTesting(!isAudioPlaying && !isProcessingAnswer && optionsWalkIndex == nil)
            .gameSheetDismissDisabledWhileAudioPlaying(isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil)
            // No dimming when audio plays — keep full brightness so dinosaurs are easy to see during intro walk
            .overlay(alignment: .topTrailing) {
                if isFootprintsGuessGame, currentQuestion != nil, !isGameComplete {
                    GeometryReader { geo in
                        let safeWidth = max(geo.size.width, 1)
                        let playMaxScale: CGFloat = 1.85
                        let hintSide = GameCatalogImageMetrics.scaled(72, safeWidth: safeWidth, maxScale: playMaxScale)
                        let hintFont = GameCatalogImageMetrics.scaled(12, safeWidth: safeWidth, maxScale: playMaxScale)
                        Button {
                            showSourceFootprintsHints = true
                        } label: {
                            Text("Hints")
                                .font(.system(size: hintFont, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: hintSide, height: hintSide)
                                .background(Circle().fill(Color.blue))
                        }
                        .disabled(isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil)
                        .opacity((isAudioPlaying || isProcessingAnswer || optionsWalkIndex != nil) ? 0.45 : 1.0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                }
            }
            .fullScreenCover(isPresented: $showSourceFootprintsHints) {
                if gameConfig.id == "marine-footprints" {
                    SourceMarineFootprintsHintsView(onDismiss: { showSourceFootprintsHints = false })
                } else if gameConfig.id == "ptero-footprints" {
                    SourcePteroFootprintsHintsView(onDismiss: { showSourceFootprintsHints = false })
                } else {
                    SourceFootprintsHintsView(onDismiss: { showSourceFootprintsHints = false })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// Starts the round: for Dino Footprints plays "identify the footprint" then options walk; for Dino Bones plays "identify the skeleton" then options walk; for other guess games goes straight to options walk.
    private func startRoundIfNeeded() {
        guard !isGameComplete else { return }
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else { return }
        if gameConfig.id == "dino-footprints" || gameConfig.id == "ptero-footprints" || gameConfig.id == "marine-footprints" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                guard !self.isGameComplete else { return }
                self.playFootprintsHintThenStartOptionsWalk()
            }
            speechManager.speak("game-footprints-identify-the-footprint")
        } else if gameConfig.id == "dino-bones" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                guard !self.isGameComplete else { return }
                self.playDinoBonesHintThenStartOptionsWalk()
            }
            speechManager.speak("game-dino-bones-identify-the-skeleton")
        } else if gameConfig.id == "whose-bones" {
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                guard !self.isGameComplete else { return }
                self.startOptionsWalkIfNeeded()
            }
            speechManager.speak("game-whose-bones-gameplay")
        } else {
            startOptionsWalkIfNeeded()
        }
    }

    /// Plays game-hint then starts the options walk. Keeps isAudioPlaying true so taps are blocked (no click sounds).
    private func playFootprintsHintThenStartOptionsWalk() {
        guard !isGameComplete else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            guard !self.isGameComplete else { return }
            self.startOptionsWalkIfNeeded()
        }
        if let url = speechManager.urlForAudio(key: "game-hint") {
            speechManager.playAudioFile(url: url)
        } else {
            startOptionsWalkIfNeeded()
        }
    }

    private func playDinoBonesHintThenStartOptionsWalk() {
        startOptionsWalkIfNeeded()
    }

    private func startOptionsWalkIfNeeded() {
        guard !isGameComplete else { return }
        guard let question = currentQuestion, !question.options.isEmpty, optionsWalkIndex == nil else { return }
        optionsWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(audioKey: question.options[0].imageName ?? question.options[0].name, fallbackText: question.options[0].name)
    }

    private func advanceOptionsWalk() {
        speechManager.onAudioFinished = nil
        guard !isGameComplete else {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        guard let question = currentQuestion else {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        let next = (optionsWalkIndex ?? 0) + 1
        if next >= question.options.count {
            optionsWalkIndex = nil
            isAudioPlaying = false
            return
        }
        optionsWalkIndex = next
        speechManager.onAudioFinished = { advanceOptionsWalk() }
        speechManager.speak(audioKey: question.options[next].imageName ?? question.options[next].name, fallbackText: question.options[next].name)
    }

    private func handleDinosaurTap(_ dinosaur: Dinosaur, question: RoundQuestion) {
        guard !isProcessingAnswer && !isAudioPlaying && optionsWalkIndex == nil else { return }
        
        selectedDinosaur = dinosaur
        isAudioPlaying = true
        
        // Wait for dinosaur name to finish before playing thats-right / try-again (avoids truncation)
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.checkAnswer(dinosaur: dinosaur, question: question)
        }
        speechManager.speak(audioKey: dinosaur.imageName ?? dinosaur.name, fallbackText: dinosaur.name)
    }
    
    private func checkAnswer(dinosaur: Dinosaur, question: RoundQuestion) {
        isProcessingAnswer = true
        let isCorrectAnswer = dinosaur.id == question.correctAnswerId
        
        if isCorrectAnswer {
            // Correct! Play success audio; round/game advances after it finishes (no feedback text)
            successCount += 1
            wrongGuessesThisRound = 0
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.selectedDinosaur = nil
                    if self.currentRound < self.gameConfig.rounds.count {
                        self.currentRound += 1
                        self.wrongGuessesThisRound = 0
                        self.isProcessingAnswer = false
                        self.isAudioPlaying = false
                        // startOptionsWalkIfNeeded() will run from .onChange(of: currentRound)
                    } else {
                        self.selectedDinosaur = nil
                        self.isProcessingAnswer = false
                        self.isAudioPlaying = false
                        self.optionsWalkIndex = nil
                        self.isGameComplete = true
                        // End sequence (darkened row → highlight + name → good-job + crowd → dismiss) runs in guessGameEndSequenceView
                    }
                }
            }
            speechManager.speak(correctGuessAudioKey)
        } else {
            wrongGuessesThisRound += 1
            errorCount += 1
            isAudioPlaying = true
            // No auto-skip: allow unlimited attempts so kids can map sound ↔ image.
            speechManager.speak(tryAgainAudioKey)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.async {
                    self.isAudioPlaying = false
                    self.selectedDinosaur = nil
                    self.isProcessingAnswer = false
                }
            }
        }
    }
    
    /// Recap list height: up to `StandardVictoryLayout.maxVisibleRecapRows` rows visible; longer lists scroll.
    private var victoryListVisibleHeight: CGFloat {
        StandardVictoryLayout.recapListScrollHeight(itemCount: guessVictoryRecapItems.count)
    }

    // MARK: - End sequence: recap walk (highlight + name audio) + success card on one screen, then good-job + crowd and dismiss

    private var guessGameEndSequenceView: some View {
        VictorySplitColumnView(
            listScrollHeight: victoryListVisibleHeight,
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            scrollRows: {
                ForEach(Array(guessVictoryRecapItems.enumerated()), id: \.element.id) { index, item in
                    StandardVictoryRecapRowView(
                        item: item,
                        isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    gameConfigId: gameConfig.id,
                    imageSide: guessGameSuccessImageSide,
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
            if guessVictoryRecapItems.isEmpty {
                endSequenceStep = 2
            } else if gameConfig.id == "whose-bones" {
                let keys = endSequenceBodySegmentSpeechKeys
                if !keys.isEmpty {
                    speechManager.speak("body-\(keys[0])")
                } else if let d = guessVictoryRecapDinosaur(at: 0) {
                    speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                }
                speechManager.onAudioFinished = { advanceEndHighlight() }
            } else if let d = guessVictoryRecapDinosaur(at: 0) {
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    /// End-sequence success art: full victory card (larger than the level-2 picker art, which shares a row with two other games).
    private var guessGameSuccessImageSide: CGFloat {
        switch gameConfig.id {
        case "name-that-dinosaur", "name-that-pterosaur", "name-that-marine-reptile", "marine-smile",
             "dino-footprints", "ptero-footprints", "marine-footprints", "dino-bones", "whose-bones":
            return GameCatalogImageMetrics.nameThatVictorySuccessImageSide
        default:
            return 180
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < guessVictoryRecapItems.count {
            if gameConfig.id == "whose-bones" {
                let keys = endSequenceBodySegmentSpeechKeys
                if endHighlightIndex < keys.count {
                    speechManager.speak("body-\(keys[endHighlightIndex])")
                } else if let d = guessVictoryRecapDinosaur(at: endHighlightIndex) {
                    speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                }
            } else if let d = guessVictoryRecapDinosaur(at: endHighlightIndex) {
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
            }
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }
    
    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager,
            beforeDismiss: { gameConfig.victorySideEffect?() }
        )
    }

    private var correctGuessAudioKey: String {
        switch gameConfig.id {
        case "marine-smile":
            return "game-name-that-marine-reptile-thats-right"
        case "name-that-marine-reptile":
            return "game-name-that-marine-reptile-thats-right"
        default:
            return "thats-right-you-guessed-it"
        }
    }

    private var tryAgainAudioKey: String {
        switch gameConfig.id {
        case "marine-smile":
            return "game-name-that-marine-reptile-try-again"
        case "name-that-marine-reptile":
            return "game-name-that-marine-reptile-try-again"
        default:
            return "try-again"
        }
    }
}

// MARK: - Dinosaur Option Card View

struct DinosaurOptionCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isDisabled: Bool
    /// When true (e.g. Find Mama options walk), show same highlight and name as selected.
    var isHighlighted: Bool = false
    var imageSide: CGFloat = 90
    var labelFontSize: CGFloat = 15
    let onTap: () -> Void

    private var showHighlight: Bool { isSelected || isHighlighted }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Dinosaur image or emoji (show icon when image asset is missing, e.g. some dinosaurs in catalog)
                if let imageName = dinosaur.imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSide, height: imageSide)
                } else {
                    Text(dinosaur.icon)
                        .font(.system(size: min(60, imageSide * 0.67)))
                }

                // Dinosaur name (shown when selected or highlighted during options walk)
                if showHighlight {
                    Text(dinosaur.name)
                        .font(.system(size: labelFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .allowsTightening(true)
                        .multilineTextAlignment(TextAlignment.center)
                        .frame(width: imageSide + 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(
                width: showHighlight ? imageSide + 36 : imageSide + 12,
                height: showHighlight ? imageSide + labelFontSize + 48 : imageSide + 32
            )
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(showHighlight ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(showHighlight ? Color.blue : Color.clear, lineWidth: 3)
            )
            // Full brightness during intro walk (no dim) so dinosaurs are easy to see when introduced
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Source Footprints Hints (Dino Footprints)

/// One clade entry for the Source Footprints hints grid. Uses `source-dino-footprints-{clade}` and audio `Footprints/dino-{clade}.m4a` (land); ptero/marine use separate source hint imagesets.
private struct SourceFootprintCladeHint: Identifiable {
    let id: String
    let imageName: String  // e.g. source-dino-footprints-theropod (imageset name in Assets)
    let displayName: String
    let audioKey: String  // e.g. footprint-therapod → Footprints/dino-theropod.m4a (audio file uses correct “theropod” spelling)
}

private var sourceFootprintsHintClades: [SourceFootprintCladeHint] {
    LandGameDisplayMomentCatalog.footprintSourceHints.map {
        SourceFootprintCladeHint(id: $0.id, imageName: $0.imageAssetName, displayName: $0.displayText, audioKey: $0.audioKey)
    }
}

struct SourceFootprintsHintsView: View {
    let onDismiss: () -> Void
    @State private var speechManager = SpeechManager()
    @State private var selectedClade: SourceFootprintCladeHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Show either grid or full-screen detail (no overlay — avoids jarring partial visibility)
            if selectedClade == nil {
                gridView
            } else {
                detailView
            }

            // Back to game: < in upper left
            Button {
                onDismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            playIntroOnce()
        }
    }

    private var gridView: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let cardHeight = SourceHintsLayout.gridCardHeight(safeWidth: safeWidth)
            let spacing = SourceHintsLayout.gridSpacing(safeWidth: safeWidth)
            let hPad = SourceHintsLayout.horizontalPadding(safeWidth: safeWidth)
            let titleFont = SourceHintsLayout.titleFont(safeWidth: safeWidth)
            let fallbackFont = SourceHintsLayout.fallbackLabelFont(safeWidth: safeWidth)
            AlwaysVisibleScrollbarScrollView {
                VStack(spacing: spacing) {
                    SourceHintsScreenTitle(title: "Source Footprints", fontSize: titleFont)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                        ForEach(sourceFootprintsHintClades) { clade in
                            Button {
                                showCladeDetail(clade)
                            } label: {
                                if UIImage(named: clade.imageName) != nil {
                                    Image(clade.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: cardHeight)
                                        .clipped()
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: cardHeight)
                                        .overlay(Text(clade.displayName).font(.system(size: fallbackFont)).foregroundColor(.secondary))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, spacing)
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let clade = selectedClade {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let detailSide = SourceHintsLayout.detailImageSide(safeWidth: safeWidth)
                let labelFont = SourceHintsLayout.detailLabelFont(safeWidth: safeWidth)
                VStack(spacing: 20) {
                    Spacer()
                    if UIImage(named: clade.imageName) != nil {
                        Image(clade.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: detailSide, maxHeight: detailSide)
                    }
                    Text(clade.displayName)
                        .font(.system(size: labelFont, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        if let url = speechManager.urlForAudio(key: "game-footprints-tap-the-footprint-to-hear-description") {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showCladeDetail(_ clade: SourceFootprintCladeHint) {
        selectedClade = clade
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            // Auto-return to grid after clade audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedClade = nil
            }
        }
        if let url = speechManager.urlForAudio(key: clade.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(clade.displayName)
            // TTS completion triggers onAudioFinished via AVSpeechSynthesizerDelegate
        }
    }
}

// MARK: - Source Pterosaur Footprints Hints (Ptero Footprints)

private struct SourcePteroFootprintMorphHint: Identifiable {
    let id: String
    let imageName: String
    let displayName: String
    /// `SpeechManager` key → `Ptero-Footprints/ptero-footprints-{clade}.m4a`
    let audioKey: String
}

private let sourcePteroFootprintsHintMorphs: [SourcePteroFootprintMorphHint] = PterosaurGuessGroup.allCases.map { group in
    let stem = group == .transitional ? "transition" : group.rawValue
    return SourcePteroFootprintMorphHint(
        id: stem,
        imageName: "source-ptero-footprints-\(stem)",
        displayName: group.displayName,
        audioKey: "ptero-footprints-\(stem)"
    )
}

struct SourcePteroFootprintsHintsView: View {
    let onDismiss: () -> Void
    @State private var speechManager = SpeechManager()
    @State private var selectedMorph: SourcePteroFootprintMorphHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedMorph == nil {
                gridView
            } else {
                detailView
            }

            Button {
                onDismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            playIntroOnce()
        }
    }

    private var gridView: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let cardHeight = SourceHintsLayout.gridCardHeight(safeWidth: safeWidth)
            let spacing = SourceHintsLayout.gridSpacing(safeWidth: safeWidth)
            let hPad = SourceHintsLayout.horizontalPadding(safeWidth: safeWidth)
            let titleFont = SourceHintsLayout.titleFont(safeWidth: safeWidth)
            let fallbackFont = SourceHintsLayout.fallbackLabelFont(safeWidth: safeWidth)
            VStack(spacing: spacing) {
                SourceHintsScreenTitle(title: "Pterosaur track types", fontSize: titleFont)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                    ForEach(sourcePteroFootprintsHintMorphs) { morph in
                        Button {
                            showMorphDetail(morph)
                        } label: {
                            if UIImage(named: morph.imageName) != nil {
                                Image(morph.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cardHeight)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: cardHeight)
                                    .overlay(Text(morph.displayName).font(.system(size: fallbackFont)).foregroundColor(.secondary))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, hPad)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let morph = selectedMorph {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let detailSide = SourceHintsLayout.detailImageSide(safeWidth: safeWidth)
                let labelFont = SourceHintsLayout.detailLabelFont(safeWidth: safeWidth)
                VStack(spacing: 20) {
                    Spacer()
                    if UIImage(named: morph.imageName) != nil {
                        Image(morph.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: detailSide, maxHeight: detailSide)
                    }
                    Text(morph.displayName)
                        .font(.system(size: labelFont, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        if let url = speechManager.urlForAudio(key: "game-footprints-tap-the-footprint-to-hear-description") {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showMorphDetail(_ morph: SourcePteroFootprintMorphHint) {
        selectedMorph = morph
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedMorph = nil
            }
        }
        if let url = speechManager.urlForAudio(key: morph.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(morph.displayName)
        }
    }
}

// MARK: - Source Marine Footprints Hints (Marine Footprints)

private struct SourceMarineFootprintSlotHint: Identifiable {
    let id: String
    let imageName: String
    let displayName: String
    /// `SpeechManager` key → `Marine-Footprints/{locomotion}.m4a`
    let audioKey: String
}

private var sourceMarineFootprintsHintSlots: [SourceMarineFootprintSlotHint] {
    MarineFootprintsMechanics.shippedHintSlots.map { slot in
        SourceMarineFootprintSlotHint(
            id: slot.locomotion,
            imageName: slot.hintImageName,
            displayName: slot.hintDisplayName,
            audioKey: slot.hintAudioKey
        )
    }
}

struct SourceMarineFootprintsHintsView: View {
    let onDismiss: () -> Void
    @State private var speechManager = SpeechManager()
    @State private var selectedSlot: SourceMarineFootprintSlotHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedSlot == nil {
                gridView
            } else {
                detailView
            }

            Button {
                onDismiss()
            } label: {
                Text("<")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
            .padding(.leading, 8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            playIntroOnce()
        }
    }

    private var gridView: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let cardHeight = SourceHintsLayout.gridCardHeight(safeWidth: safeWidth)
            let spacing = SourceHintsLayout.gridSpacing(safeWidth: safeWidth)
            let hPad = SourceHintsLayout.horizontalPadding(safeWidth: safeWidth)
            let titleFont = SourceHintsLayout.titleFont(safeWidth: safeWidth)
            let fallbackFont = SourceHintsLayout.fallbackLabelFont(safeWidth: safeWidth)
            VStack(spacing: spacing) {
                SourceHintsScreenTitle(title: "Marine track types", fontSize: titleFont)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                    ForEach(sourceMarineFootprintsHintSlots) { slot in
                        Button {
                            showSlotDetail(slot)
                        } label: {
                            if ImageAssetCache.imageExists(named: slot.imageName) {
                                Image(slot.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cardHeight)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: cardHeight)
                                    .overlay(Text(slot.displayName).font(.system(size: fallbackFont)).foregroundColor(.secondary))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, hPad)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let slot = selectedSlot {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let detailSide = SourceHintsLayout.detailImageSide(safeWidth: safeWidth)
                let labelFont = SourceHintsLayout.detailLabelFont(safeWidth: safeWidth)
                VStack(spacing: 20) {
                    Spacer()
                    if ImageAssetCache.imageExists(named: slot.imageName) {
                        Image(slot.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: detailSide, maxHeight: detailSide)
                    }
                    Text(slot.displayName)
                        .font(.system(size: labelFont, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        if let url = speechManager.urlForAudio(key: "game-footprints-tap-the-footprint-to-hear-description") {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showSlotDetail(_ slot: SourceMarineFootprintSlotHint) {
        selectedSlot = slot
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedSlot = nil
            }
        }
        if let url = speechManager.urlForAudio(key: slot.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(slot.displayName)
        }
    }
}

// MARK: - Marine Footprints (locomotion + clade)

/// Catalog + test surface for `marine-footprints-{walk|punt|swim|drag}-{clade}` gameplay art.
enum MarineFootprintsMechanics {
    struct SlotDefinition: Equatable {
        let locomotion: String
        /// Imageset suffix, e.g. `thalattosuchian` in `marine-footprints-walk-thalattosuchian`.
        let cladeAssetSlug: String
        /// `marine-{group}-*` segment, e.g. `thala`.
        let marineGroupRaw: String

        var slotKey: String { "\(locomotion)|\(marineGroupRaw)" }
        /// Base stem before optional `-v1`…`-v4` variant suffix.
        var imageBaseName: String { "marine-footprints-\(locomotion)-\(cladeAssetSlug)" }
        /// Source reference art for the hints grid (`source-marine-footprints-{locomotion}`).
        var hintImageName: String { "source-marine-footprints-\(locomotion)" }
        var hintDisplayName: String { locomotion.prefix(1).uppercased() + locomotion.dropFirst() }
        var displayName: String { SeaMarineReptileData.displayTitleForMarineGroup(marineGroupRaw) }
        /// Hint tile narration: `marine-footprints-{locomotion}` → `Audio/Marine-Footprints/{locomotion}.m4a`.
        var hintAudioKey: String { "marine-footprints-\(locomotion)" }
    }

    /// All `(locomotion, clade)` pairs the game knows about; grows as new imagesets ship.
    static let registry: [SlotDefinition] = [
        SlotDefinition(locomotion: "walk", cladeAssetSlug: "thalattosuchian", marineGroupRaw: "thala"),
        SlotDefinition(locomotion: "punt", cladeAssetSlug: "nothosaur", marineGroupRaw: "notho"),
        SlotDefinition(locomotion: "swim", cladeAssetSlug: "mosasaur", marineGroupRaw: "mosa"),
        SlotDefinition(locomotion: "drag", cladeAssetSlug: "testudine", marineGroupRaw: "testu"),
    ]

    static func bundledImageNames(for slot: SlotDefinition) -> [String] {
        let base = slot.imageBaseName
        var names: [String] = []
        if ImageAssetCache.imageExists(named: base) { names.append(base) }
        names += (1...4).compactMap { variant in
            let name = "\(base)-v\(variant)"
            return ImageAssetCache.imageExists(named: name) ? name : nil
        }
        return names
    }

    static func pickGameplayImageName(for slot: SlotDefinition) -> String? {
        bundledImageNames(for: slot).randomElement()
    }

    static var shippedSlots: [SlotDefinition] {
        registry.filter { !bundledImageNames(for: $0).isEmpty }
    }

    /// Locomotion slots with bundled source hint art (`source-marine-footprints-*`).
    static var shippedHintSlots: [SlotDefinition] {
        registry.filter { ImageAssetCache.imageExists(named: $0.hintImageName) }
    }

    static var isPlayable: Bool {
        GuessGameConfigs.makeMarineFootprints() != nil
    }
}

private func pickThreeMarineFootprintSlots(
    availableSlotKeys: [String],
    slotByKey: [String: MarineFootprintsMechanics.SlotDefinition]
) -> [String] {
    guard !availableSlotKeys.isEmpty else { return [] }
    let keys = availableSlotKeys.shuffled()
    var byGroup: [String: [String]] = [:]
    for key in keys {
        guard let slot = slotByKey[key] else { continue }
        byGroup[slot.marineGroupRaw, default: []].append(key)
    }
    var picked: [String] = []
    for group in byGroup.keys.shuffled() {
        guard picked.count < 3 else { break }
        if let slotKey = byGroup[group]?.randomElement(), !picked.contains(slotKey) {
            picked.append(slotKey)
        }
    }
    var remaining = keys.filter { !picked.contains($0) }
    remaining.shuffle()
    while picked.count < 3, let next = remaining.popLast() {
        if !picked.contains(next) {
            picked.append(next)
        }
    }
    return Array(picked.prefix(3))
}

// MARK: - Dino Footprints (clade + size)

/// Footprint image sets: `footprint-{clade}-{size}` (small|medium|large) or `footprint-{clade}-{variant}-medium` for variety; gameplay picks the tier that matches the correct dinosaur’s map entry.
/// Use imageNameForAsset for lookup; asset imagesets are `footprint-{assetStem}-{size}`.
/// Separate from `DinoClade` / `LandDinosaurCladeCatalog` (9 buckets for land games); morphological buckets for Dino Footprints assets.
private enum FootprintClade: String, CaseIterable {
    case ankylosaur
    case ceratopsian
    case hadrosaur
    case ornithischian
    case ornithomimid
    case sauropod
    case spinosaurid
    case stegosaur
    case theropod

    /// Name used in footprint image set names (footprint-{this}-{size}).
    var imageNameForAsset: String {
        rawValue
    }
}

private enum DinoSize: String, CaseIterable {
    case small
    case medium
    case large

    /// Stable ordering for sorting dinosaurs within a clade (small → large).
    fileprivate var sortOrder: Int {
        switch self {
        case .small: return 0
        case .medium: return 1
        case .large: return 2
        }
    }
}

/// Map of dinosaur slug (dino-* suffix) → (clade, presumed footprint size). Only dinosaurs listed here are playable in Dino Footprints. Add new species here when you add them to the app.
private let footprintDinosaurMap: [String: (clade: FootprintClade, size: DinoSize)] = [
    // Theropods (non-spinosaurid, non-ornithomimid)
    "trex": (.theropod, .large),
    "velociraptor": (.theropod, .small),
    "troodon": (.theropod, .small),
    "therizinosaurus": (.theropod, .medium),
    "masiakasaurus": (.theropod, .small),
    "torvosaurus": (.theropod, .large),
    "majungasaurus": (.theropod, .large),
    "allosaurus": (.theropod, .large),
    "oviraptor": (.theropod, .small),
    "compsognathus": (.theropod, .small),
    "microraptor": (.theropod, .small),
    "giganotosaurus": (.theropod, .large),
    "deinonychus": (.theropod, .medium),
    "dromaeosaurus": (.theropod, .medium),
    "albertosaurus": (.theropod, .large),
    "anchiornis": (.theropod, .small),
    "archaeopteryx": (.theropod, .small),
    "ceratosaurus": (.theropod, .medium),
    "eosinopteryx": (.theropod, .small),
    "pedopenna": (.theropod, .small),
    "utahraptor": (.theropod, .medium),
    "xiaotingia": (.theropod, .small),
    "acrocanthosaurus": (.theropod, .large),
    "carcharodontosaurus": (.theropod, .large),
    "carnotaurus": (.theropod, .medium),
    "fukuiraptor": (.theropod, .small),
    "gigantoraptor": (.theropod, .medium),
    // Spinosaurids
    "spinosaurus": (.spinosaurid, .large),
    "baryonyx": (.spinosaurid, .medium),
    "suchomimus": (.spinosaurid, .large),
    "riparovenator": (.spinosaurid, .medium),
    // Ornithomimids / ornithomimosaurs
    "gallimimus": (.ornithomimid, .medium),
    "ornithomimus": (.ornithomimid, .medium),
    "struthiomimus": (.ornithomimid, .medium),
    "deinocheirus": (.ornithomimid, .large),
    // Sauropods
    "apatosaurus": (.sauropod, .large),
    "diplodocus": (.sauropod, .large),
    "camarasaurus": (.sauropod, .large),
    "rapetosaurus": (.sauropod, .large),
    "argentinosaurus": (.sauropod, .large),
    "brachiosaurus": (.sauropod, .large),
    "brontosaurus": (.sauropod, .large),
    "amargasaurus": (.sauropod, .medium),
    "mamenchisaurus": (.sauropod, .large),
    // Ceratopsians
    "triceratops": (.ceratopsian, .large),
    "chasmosaurus": (.ceratopsian, .medium),
    "torosaurus": (.ceratopsian, .large),
    "kosmoceratops": (.ceratopsian, .medium),
    "styracosaurus": (.ceratopsian, .medium),
    // Hadrosaurs and other iguanodont-grade ornithopods (broad three-toed herbivore tracks)
    "corythosaurus": (.hadrosaur, .medium),
    "parasaurolophus": (.hadrosaur, .medium),
    "iguanodon": (.hadrosaur, .medium),
    "edmontosaurus": (.hadrosaur, .large),
    "lambeosaurus": (.hadrosaur, .medium),
    "maiasaura": (.hadrosaur, .medium),
    "ouranosaurus": (.hadrosaur, .medium),
    // Basal / small ornithopods — generic ornithischian track morphotype (`footprint-ornithischian-*`)
    "dryosaurus": (.ornithischian, .small),
    "gasparinisaura": (.ornithischian, .small),
    "pachycephalosaurus": (.hadrosaur, .small),
    "stegoceras": (.hadrosaur, .small),
    "stygimoloch": (.hadrosaur, .small),
    // Stegosaurs
    "stegosaurus": (.stegosaur, .medium),
    "kentrosaurus": (.stegosaur, .medium),
    "huayangosaurus": (.stegosaur, .medium),
    // Ankylosaurs
    "ankylosaurus": (.ankylosaur, .large),
    "euoplocephalus": (.ankylosaur, .medium),
    "edmontonia": (.ankylosaur, .medium),
    "nodosaurus": (.ankylosaur, .medium),
    "polacanthus": (.ankylosaur, .medium),
]

private func size(forDinosaurSlug slug: String) -> DinoSize? {
    footprintDinosaurMap[slug]?.size
}

private func slugForFootprint(_ dinosaur: Dinosaur) -> String? {
    guard let imageName = dinosaur.imageName, imageName.hasPrefix("dino-") else { return nil }
    return imageName.replacingOccurrences(of: "dino-", with: "").lowercased()
}

/// Dinosaurs in one morphotype clade, ordered small → medium → large, then name.
private func sortDinosaursWithinCladeByFootprintSize(_ dinosaurs: [Dinosaur]) -> [Dinosaur] {
    dinosaurs.sorted { a, b in
        let oa = slugForFootprint(a).flatMap { size(forDinosaurSlug: $0)?.sortOrder } ?? 99
        let ob = slugForFootprint(b).flatMap { size(forDinosaurSlug: $0)?.sortOrder } ?? 99
        if oa != ob { return oa < ob }
        return a.name < b.name
    }
}

private func parseFootprintSlotKey(_ key: String) -> (clade: FootprintClade, size: DinoSize)? {
    let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let clade = FootprintClade(rawValue: parts[0]),
          let size = DinoSize(rawValue: parts[1]) else { return nil }
    return (clade, size)
}

/// Groups playable dinosaurs by `(clade|size)` slot; each bucket sorted by name (same tier).
private func footprintSlotBuckets(for dinosaurs: [Dinosaur]) -> [String: [Dinosaur]] {
    var buckets: [String: [Dinosaur]] = [:]
    for d in dinosaurs {
        guard let slug = slugForFootprint(d), let pair = footprintDinosaurMap[slug] else { continue }
        let key = "\(pair.clade.rawValue)|\(pair.size.rawValue)"
        buckets[key, default: []].append(d)
    }
    for key in buckets.keys {
        buckets[key]?.sort { $0.name < $1.name }
    }
    return buckets
}

/// Footprint art for this morphotype + size tier (`footprint-{clade}-{size}`). Medium tier still prefers numbered variants when bundled.
private func footprintImageName(clade: FootprintClade, size: DinoSize) -> String {
    let base = clade.imageNameForAsset
    if size == .medium {
        let variants = (1...3).map { "footprint-\(base)-\($0)-medium" }
        let available = variants.filter { ImageAssetCache.imageExists(named: $0) }
        if let pick = available.randomElement() { return pick }
    }
    let direct = "footprint-\(base)-\(size.rawValue)"
    if ImageAssetCache.imageExists(named: direct) { return direct }
    let medium = "footprint-\(base)-medium"
    if ImageAssetCache.imageExists(named: medium) { return medium }
    return direct
}

/// Picks three `(clade|size)` slots for one game: prefers three different clades when available slots allow.
private func pickThreeFootprintSlots(
    availableSlotKeys: [String],
    buckets: [String: [Dinosaur]]
) -> [String] {
    guard !availableSlotKeys.isEmpty else { return [] }
    let keys = availableSlotKeys.shuffled()
    var byClade: [FootprintClade: [String]] = [:]
    for key in keys {
        guard let parsed = parseFootprintSlotKey(key) else { continue }
        byClade[parsed.clade, default: []].append(key)
    }
    var picked: [String] = []
    let cladeOrder = FootprintClade.allCases.filter { (byClade[$0]?.isEmpty == false) }.shuffled()
    for clade in cladeOrder {
        guard picked.count < 3 else { break }
        guard let slotKey = byClade[clade]?.randomElement(),
              buckets[slotKey]?.isEmpty == false else { continue }
        if !picked.contains(slotKey) {
            picked.append(slotKey)
        }
    }
    var remaining = keys.filter { !picked.contains($0) && (buckets[$0]?.isEmpty == false) }
    remaining.shuffle()
    while picked.count < 3, let next = remaining.popLast() {
        if !picked.contains(next) {
            picked.append(next)
        }
    }
    return Array(picked.prefix(3))
}

// MARK: - Ptero Footprints (pterosaur morphotype track family + size tier)

/// Asset stem `ptero-footprint-{rawValue}-*`; `transition` matches `PterosaurGuessGroup.transitional`.
private enum PteroFootprintMorphotype: String, CaseIterable {
    case azhdarchid, basal, ornithocheiroid, specialist, tapejarid, thalassodromid, transition

    static func from(guessGroup: PterosaurGuessGroup) -> PteroFootprintMorphotype {
        switch guessGroup {
        case .transitional: return .transition
        default:
            return PteroFootprintMorphotype(rawValue: guessGroup.rawValue)!
        }
    }

    var guessGroup: PterosaurGuessGroup {
        switch self {
        case .transition: return .transitional
        default:
            return PterosaurGuessGroup(rawValue: rawValue)!
        }
    }
}

/// Per-creature size tier within its guess group (small → large by weight rank), so each `(morphotype|size)` slot can fill.
private let pteroFootprintSizeByCreatureId: [Int: DinoSize] = {
    var result: [Int: DinoSize] = [:]
    for group in PterosaurGuessGroup.allCases {
        let members = AirPterosaurData.allPterosaurs.filter { PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") == group }
        let sorted = members.sorted {
            (AirPterosaurData.pterosaurEstimatedWeightKgById[$0.id] ?? 0) < (AirPterosaurData.pterosaurEstimatedWeightKgById[$1.id] ?? 0)
        }
        let n = sorted.count
        guard n > 0 else { continue }
        if n == 1 {
            result[sorted[0].id] = .medium
            continue
        }
        for (idx, d) in sorted.enumerated() {
            let f = Double(idx) / Double(n - 1)
            let tier: DinoSize
            if f <= 1.0 / 3.0 {
                tier = .small
            } else if f <= 2.0 / 3.0 {
                tier = .medium
            } else {
                tier = .large
            }
            result[d.id] = tier
        }
    }
    return result
}()

private func pteroFootprintPair(for dinosaur: Dinosaur) -> (morph: PteroFootprintMorphotype, size: DinoSize)? {
    guard let group = PterosaurGuessGroup.guessGroup(forImageName: dinosaur.imageName ?? ""),
          let size = pteroFootprintSizeByCreatureId[dinosaur.id] else { return nil }
    return (PteroFootprintMorphotype.from(guessGroup: group), size)
}

private func sortPterosaursWithinMorphByFootprintSize(_ pterosaurs: [Dinosaur]) -> [Dinosaur] {
    pterosaurs.sorted { a, b in
        let oa = pteroFootprintPair(for: a).map { $0.size.sortOrder } ?? 99
        let ob = pteroFootprintPair(for: b).map { $0.size.sortOrder } ?? 99
        if oa != ob { return oa < ob }
        return a.name < b.name
    }
}

private func parsePteroFootprintSlotKey(_ key: String) -> (morph: PteroFootprintMorphotype, size: DinoSize)? {
    let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let morph = PteroFootprintMorphotype(rawValue: parts[0]),
          let size = DinoSize(rawValue: parts[1]) else { return nil }
    return (morph, size)
}

private func pteroFootprintSlotBuckets(for pterosaurs: [Dinosaur]) -> [String: [Dinosaur]] {
    var buckets: [String: [Dinosaur]] = [:]
    for d in pterosaurs {
        guard let pair = pteroFootprintPair(for: d) else { continue }
        let key = "\(pair.morph.rawValue)|\(pair.size.rawValue)"
        buckets[key, default: []].append(d)
    }
    for key in buckets.keys {
        buckets[key]?.sort { $0.name < $1.name }
    }
    return buckets
}

private func pteroFootprintImageName(morph: PteroFootprintMorphotype, size: DinoSize) -> String {
    let stem = morph.rawValue
    let direct = "ptero-footprint-\(stem)-\(size.rawValue)"
    if UIImage(named: direct) != nil { return direct }
    return "ptero-footprint-\(stem)-medium"
}

private func pickThreePteroFootprintSlots(
    availableSlotKeys: [String],
    buckets: [String: [Dinosaur]]
) -> [String] {
    guard !availableSlotKeys.isEmpty else { return [] }
    let keys = availableSlotKeys.shuffled()
    var byMorph: [PteroFootprintMorphotype: [String]] = [:]
    for key in keys {
        guard let parsed = parsePteroFootprintSlotKey(key) else { continue }
        byMorph[parsed.morph, default: []].append(key)
    }
    var picked: [String] = []
    let morphOrder = PteroFootprintMorphotype.allCases.filter { (byMorph[$0]?.isEmpty == false) }.shuffled()
    for morph in morphOrder {
        guard picked.count < 3 else { break }
        guard let slotKey = byMorph[morph]?.randomElement(),
              buckets[slotKey]?.isEmpty == false else { continue }
        if !picked.contains(slotKey) {
            picked.append(slotKey)
        }
    }
    var remaining = keys.filter { !picked.contains($0) && (buckets[$0]?.isEmpty == false) }
    remaining.shuffle()
    while picked.count < 3, let next = remaining.popLast() {
        if !picked.contains(next) {
            picked.append(next)
        }
    }
    return Array(picked.prefix(3))
}

// MARK: - Game Configurations

struct GuessGameConfigs {
    // Create a random game configuration with 3 rounds (identify by silhouette = Name that Dinosaur).
    // Rules: (1) choose 3 dinosaur clades at random; (2) choose 1 dinosaur from each clade; (3) exclude dinosaurs already used in previous games (persisted); victory block acknowledges the 3.
    static var nameThatDinosaur: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for guess game, but only have \(allDinosaurs.count)")
        }

        // Pool: dinosaurs with dino- image (for silhouette asset name). Exclude previously used so they are not repeated in future games.
        var usedIds = NameThatDinosaurStorage.loadUsedCreatureIds()
        var pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return !usedIds.contains(d.id)
        }
        if pool.count < 3 {
            NameThatDinosaurStorage.clearIfNeeded(availableCount: pool.count)
            usedIds = []
            pool = allDinosaurs.filter { d in
                guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
                return true
            }
        }
        let questionPool = pool.count >= 3 ? pool : allDinosaurs

        // Pick 3 clades at random; prefer clades not yet used in recent games (maximize variety across 9 clades).
        let byClade = Dictionary(grouping: questionPool) { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        var usedClades = NameThatDinosaurStorage.loadUsedCladeRawValues()
        if usedClades.count >= NameThatDinosaurStorage.cladeCount {
            NameThatDinosaurStorage.clearUsedCladesIfAllUsed()
            usedClades = []
        }
        let availableClades = allCladesWithDinos.filter { !usedClades.contains($0.rawValue) }
        let cladesToUse = (availableClades.count >= 3 ? availableClades : allCladesWithDinos).shuffled()
        let questionDinosaurs: [Dinosaur]
        if cladesToUse.count >= 3 {
            questionDinosaurs = (0..<3).compactMap { i in
                let clade = cladesToUse[i]
                return (byClade[clade] ?? []).shuffled().first
            }
        } else {
            questionDinosaurs = Array(questionPool.shuffled().prefix(3))
        }
        guard questionDinosaurs.count == 3,
              Set(questionDinosaurs.map { $0.id }).count == 3 else {
            fatalError("Need at least 3 unique dinosaurs for guess game")
        }
        
        var rounds: [RoundQuestion] = []
        
        for (roundNumber, questionDinosaur) in questionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            
            // Decoys: never the question’s clade; prefer two different non-question clades when the pool allows.
            let questionClade = LandDinosaurCladeCatalog.clade(forCreatureId: questionDinosaur.id)
            let decoys = LandDinosaurCladeCatalog.pickTwoDecoysDifferentClades(
                question: questionDinosaur,
                questionClade: questionClade,
                pool: questionPool
            )
            
            // Verify decoys are unique
            let decoyIds = Set(decoys.map { $0.id })
            assert(decoyIds.count == 2, "Both decoys must be unique")
            assert(!decoyIds.contains(questionDinosaur.id), "Decoys must not match question")
            
            // Combine: 1 correct + 2 decoys, then shuffle
            var options = [questionDinosaur] + decoys
            options.shuffle()
            
            // Verify all 3 options are unique
            let optionIds = Set(options.map { $0.id })
            assert(optionIds.count == 3, "All 3 options must be unique")
            
            // Create silhouette image name (dino-silhouette- prefix for Name That Dinosaur; allows ptero-silhouette- etc. later)
            let baseName = questionDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            let silhouetteImageName = "dino-silhouette-\(baseName)"
            
            let round = RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionDinosaur.imageName,
                correctAnswerId: questionDinosaur.id,
                options: options
            )
            
            rounds.append(round)
        }
        
        // Verify all rounds have unique question dinosaurs (no duplicate silhouettes)
        let questionIds = Set(rounds.map { $0.correctAnswerId })
        assert(questionIds.count == 3, "All 3 rounds must have unique question dinosaurs")
        
        return GuessGameConfig(
            id: "name-that-dinosaur",
            title: "Name That Dinosaur!",
            introAudio: "can-you-name-the-dinosaur",
            rounds: rounds,
            availableDinosaurs: allDinosaurs,
            victorySideEffect: {
                let usedIds = rounds.map { $0.correctAnswerId }
                NameThatDinosaurStorage.appendUsedCreatureIds(usedIds)
                let usedCladeRawValues = usedIds.map { LandDinosaurCladeCatalog.clade(forCreatureId: $0).rawValue }
                NameThatDinosaurStorage.appendUsedCladeRawValues(usedCladeRawValues)
            }
        )
    }
    
    // Name That Pterosaur!: full `AirPterosaurData` pool; `questionImageName` follows `AirPterosaurData.silhouetteAssetName` (bundled silhouette when present, else view uses tinted body).
    static var nameThatPterosaur: GuessGameConfig {
        let pool = MatchingGameConfigs.allPterosaurs
        let roundCount = 3
        guard pool.count >= roundCount else {
            fatalError("Need at least \(roundCount) pterosaurs for guess game, but only have \(pool.count)")
        }
        return makeSilhouetteGuessGame(
            id: "name-that-pterosaur",
            title: "Name That Pterosaur!",
            introAudio: "can-you-name-the-pterosaur",
            pool: pool,
            roundCount: roundCount,
            bodyImagePrefixFor: { AirPterosaurData.bodyImagePrefix(for: $0.imageName ?? "") }
        )
    }

    // MARK: - Marine reptiles (sea category)

    static var nameThatMarineReptile: GuessGameConfig {
        let allMarineReptiles = SeaMarineReptileData.allMarineReptiles
        let roundCount = 3
        guard allMarineReptiles.count >= roundCount else {
            fatalError("Need at least \(roundCount) marine reptiles for guess game, but only have \(allMarineReptiles.count)")
        }

        var usedIds = NameThatMarineReptileStorage.loadUsedCreatureIds()
        var pool = allMarineReptiles.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("marine-") else { return false }
            return !usedIds.contains(d.id)
        }
        if pool.count < roundCount {
            NameThatMarineReptileStorage.clearUsedCreaturesIfNeeded(availableCount: pool.count, roundCount: roundCount)
            usedIds = []
            pool = allMarineReptiles.filter { $0.imageName?.hasPrefix("marine-") == true }
        }
        let questionPool = pool.count >= roundCount ? pool : allMarineReptiles
        let byClade = Dictionary(grouping: questionPool) { SeaMarineReptileData.marineCladeRawValue(for: $0) }
        let allCladesWithCreatures = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        let allMarineClades = Set(allMarineReptiles.map { SeaMarineReptileData.marineCladeRawValue(for: $0) })
        var usedClades = NameThatMarineReptileStorage.loadUsedCladeRawValues()
        let maxCladeCount = allMarineClades.count
        if usedClades.count >= maxCladeCount {
            NameThatMarineReptileStorage.clearUsedCladesIfAllUsed(maxCladeCount: maxCladeCount)
            usedClades = []
        }
        let availableClades = allCladesWithCreatures.filter { !usedClades.contains($0) }
        let cladesToUse = (availableClades.count >= roundCount ? availableClades : allCladesWithCreatures).shuffled()

        let questionCreatures: [Dinosaur]
        if cladesToUse.count >= roundCount {
            questionCreatures = (0..<roundCount).compactMap { i in
                let clade = cladesToUse[i]
                return (byClade[clade] ?? []).shuffled().first
            }
        } else {
            questionCreatures = Array(questionPool.shuffled().prefix(roundCount))
        }
        guard questionCreatures.count == roundCount,
              Set(questionCreatures.map(\.id)).count == roundCount else {
            fatalError("Need \(roundCount) unique marine reptiles for guess game")
        }

        var rounds: [RoundQuestion] = []
        for (roundNumber, questionCreature) in questionCreatures.enumerated() {
            let roundId = roundNumber + 1
            let decoys = SeaMarineReptileData.pickTwoDecoysDistinctMarineClades(question: questionCreature, pool: questionPool)

            var options = [questionCreature] + decoys
            options.shuffle()
            let bodyImagePrefix = SeaMarineReptileData.marineBodyImagePrefix(for: questionCreature)
            let baseName = questionCreature.imageName?.replacingOccurrences(of: bodyImagePrefix, with: "") ?? ""
            let silhouetteImageName = "\(bodyImagePrefix.dropLast())-silhouette-\(baseName)"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: silhouetteImageName,
                questionImageFallback: questionCreature.imageName,
                correctAnswerId: questionCreature.id,
                options: options
            ))
        }

        return GuessGameConfig(
            id: "name-that-marine-reptile",
            title: "Name That Marine Reptile!",
            introAudio: "can-you-name-that-marine-reptile",
            rounds: rounds,
            availableDinosaurs: allMarineReptiles,
            victorySideEffect: {
                let usedIds = rounds.map(\.correctAnswerId)
                NameThatMarineReptileStorage.appendUsedCreatureIds(usedIds)
                let usedCladeRawValues = usedIds.compactMap { id in
                    allMarineReptiles.first(where: { $0.id == id }).map { SeaMarineReptileData.marineCladeRawValue(for: $0) }
                }
                NameThatMarineReptileStorage.appendUsedCladeRawValues(usedCladeRawValues, maxCladeCount: maxCladeCount)
            }
        )
    }

    // Marine Smile!: tooth reference image on top, three smiling marine reptiles below — one per tooth type per game (crusher, needle-spike, slicer). Same guess flow as Name That Marine Reptile.
    static func makeMarineSmile() -> GuessGameConfig? {
        let roundCount = 3
        let all = MarineSmileMorphology.playableCreatures
        guard all.count >= roundCount else { return nil }

        let poolByType = MarineSmileMorphology.creaturesByToothType(in: all)
        guard MarineSmileToothType.allCases.allSatisfy({ (poolByType[$0]?.isEmpty == false) }) else {
            return nil
        }
        for type in MarineSmileToothType.allCases {
            guard MarineSmileMorphology.referenceToothImageName(for: type) != nil else { return nil }
        }

        var usedIds = MarineSmileStorage.loadUsedCreatureIds()
        func candidates(for type: MarineSmileToothType, excluding gameIds: Set<Int>) -> [Dinosaur] {
            (poolByType[type] ?? []).filter { !usedIds.contains($0.id) && !gameIds.contains($0.id) }
        }

        var gameUsedIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for (index, toothType) in MarineSmileToothType.allCases.shuffled().enumerated() {
            var correctPool = candidates(for: toothType, excluding: gameUsedIds)
            if correctPool.isEmpty {
                MarineSmileStorage.clearIfNeeded(playableCount: all.count, roundCount: roundCount)
                usedIds = []
                correctPool = candidates(for: toothType, excluding: gameUsedIds)
            }
            guard let correct = correctPool.shuffled().first else { return nil }
            gameUsedIds.insert(correct.id)

            let decoys = MarineSmileMorphology.pickTwoDecoysOtherToothTypes(
                correct: correct,
                poolByType: poolByType,
                excludedIds: gameUsedIds
            )
            guard decoys.count == 2 else { return nil }
            gameUsedIds.formUnion(decoys.map(\.id))

            guard let questionImageName = MarineSmileMorphology.referenceToothImageName(for: toothType) else {
                return nil
            }
            var options = [correct] + decoys
            options.shuffle()
            rounds.append(
                RoundQuestion(
                    id: index + 1,
                    questionImageName: questionImageName,
                    questionImageFallback: questionImageName,
                    correctAnswerId: correct.id,
                    options: options
                )
            )
        }

        guard rounds.count == roundCount else { return nil }

        return GuessGameConfig(
            id: "marine-smile",
            title: "Marine Smile!",
            introAudio: "game-marine-smile",
            rounds: rounds,
            availableDinosaurs: all,
            victorySideEffect: {
                MarineSmileStorage.appendUsedCreatureIds(rounds.map(\.correctAnswerId))
            }
        )
    }

    // Dino Footprints!: Each round shows `footprint-{clade}-{size}` for one footprint tier. Pool is sorted by size within each morphotype clade. Rotation cycles every occupiable (clade×size) slot so all bundled footprint tiers surface over time; each game prefers three distinct clades for decoys (two other morphotypes).
    static var dinoFootprints: GuessGameConfig {
        let landDinosaurs = MatchingGameConfigs.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        let all = landDinosaurs.filter { d in
            let slug = d.imageName?.replacingOccurrences(of: "dino-", with: "").lowercased() ?? ""
            return footprintDinosaurMap[slug] != nil
        }
        guard all.count >= 5 else {
            fatalError("Need at least 5 dinosaurs in footprintDinosaurMap for Dino Footprints, but only have \(all.count)")
        }

        let slotBuckets = footprintSlotBuckets(for: all)
        let allPossibleSlotKeys = Set(slotBuckets.keys.filter { (slotBuckets[$0]?.isEmpty == false) })
        guard allPossibleSlotKeys.count >= 3 else {
            fatalError("Need at least 3 distinct (clade|size) slots with dinosaurs for Dino Footprints (have \(allPossibleSlotKeys.count))")
        }

        let byCladeGrouped = Dictionary(grouping: all) { d -> FootprintClade in
            let slug = d.imageName?.replacingOccurrences(of: "dino-", with: "").lowercased() ?? ""
            return footprintDinosaurMap[slug]!.clade
        }
        var byClade: [FootprintClade: [Dinosaur]] = [:]
        for clade in FootprintClade.allCases {
            guard let group = byCladeGrouped[clade] else { continue }
            byClade[clade] = sortDinosaursWithinCladeByFootprintSize(group)
        }

        let cladesWithOneOrMore = FootprintClade.allCases.filter { (byClade[$0] ?? []).count >= 1 }
        guard cladesWithOneOrMore.count >= 3 else {
            fatalError("Need at least 3 clades with 1+ dinosaur for Dino Footprints (have \(cladesWithOneOrMore.count))")
        }

        var availableKeys: [String] = allPossibleSlotKeys.filter { !DinoFootprintsStorage.loadUsedSlotKeys().contains($0) }
        if availableKeys.count < 3 {
            DinoFootprintsStorage.clearUsedSlots()
            availableKeys = Array(allPossibleSlotKeys)
        }

        let pickedSlotKeys = pickThreeFootprintSlots(availableSlotKeys: availableKeys, buckets: slotBuckets)
        guard pickedSlotKeys.count == 3 else {
            fatalError("Dino Footprints: expected 3 rounds (picked \(pickedSlotKeys.count) slots)")
        }

        var usedQuestionIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for roundId in 1...3 {
            let slotKey = pickedSlotKeys[roundId - 1]
            guard let parsed = parseFootprintSlotKey(slotKey),
                  var candidates = slotBuckets[slotKey], !candidates.isEmpty else {
                fatalError("Dino Footprints: empty slot \(slotKey)")
            }
            candidates.shuffle()
            let correct = candidates.first { !usedQuestionIds.contains($0.id) } ?? candidates[0]
            usedQuestionIds.insert(correct.id)

            let questionClade = parsed.clade
            let otherClades = FootprintClade.allCases.filter { $0 != questionClade && (byClade[$0]?.isEmpty == false) }.shuffled()
            guard otherClades.count >= 2 else {
                fatalError("Dino Footprints: need 2 decoy clades for \(questionClade)")
            }

            var excluded: Set<Int> = [correct.id]
            var decoy1: Dinosaur?
            var decoy2: Dinosaur?
            outerDecoys: for i in 0..<otherClades.count {
                for j in (i + 1)..<otherClades.count {
                    let c1 = otherClades[i], c2 = otherClades[j]
                    let pool1 = byClade[c1] ?? []
                    let pool2 = byClade[c2] ?? []
                    guard let d1 = pool1.filter({ !excluded.contains($0.id) }).randomElement() else { continue }
                    excluded.insert(d1.id)
                    guard let d2 = pool2.filter({ !excluded.contains($0.id) }).randomElement() else {
                        excluded.remove(d1.id)
                        continue
                    }
                    decoy1 = d1
                    decoy2 = d2
                    break outerDecoys
                }
            }
            guard let d1 = decoy1, let d2 = decoy2 else {
                fatalError("Dino Footprints: could not pick decoys for round \(roundId)")
            }

            var options = [correct, d1, d2]
            options.shuffle()
            let imageName = footprintImageName(clade: parsed.clade, size: parsed.size)
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: imageName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options
            ))
        }

        return GuessGameConfig(
            id: "dino-footprints",
            title: "Dino Footprints!",
            introAudio: "game-dino-footprints",
            rounds: rounds,
            availableDinosaurs: all,
            victorySideEffect: {
                let keys = rounds.compactMap { round -> String? in
                    guard let d = all.first(where: { $0.id == round.correctAnswerId }),
                          let slug = slugForFootprint(d),
                          let pair = footprintDinosaurMap[slug] else { return nil }
                    return "\(pair.clade.rawValue)|\(pair.size.rawValue)"
                }
                DinoFootprintsStorage.appendUsedSlotKeys(keys, allPossibleSlotKeys: allPossibleSlotKeys)
            }
        )
    }

    // Ptero Footprints!: Same rotation pattern as Dino Footprints — `ptero-footprint-{morphotype}-{size}`; pool is all pterosaurs with guess-group + weight-tier slots; decoys from two other morphotypes when possible.
    static var pteroFootprints: GuessGameConfig {
        let all = MatchingGameConfigs.allPterosaurs.filter { pteroFootprintPair(for: $0) != nil }
        guard all.count >= 5 else {
            fatalError("Need at least 5 pterosaurs for Ptero Footprints, but only have \(all.count)")
        }

        let slotBuckets = pteroFootprintSlotBuckets(for: all)
        let allPossibleSlotKeys = Set(slotBuckets.keys.filter { (slotBuckets[$0]?.isEmpty == false) })
        guard allPossibleSlotKeys.count >= 3 else {
            fatalError("Need at least 3 distinct (morphotype|size) slots with pterosaurs for Ptero Footprints (have \(allPossibleSlotKeys.count))")
        }

        let byMorphGrouped = Dictionary(grouping: all) { d -> PteroFootprintMorphotype in
            pteroFootprintPair(for: d)!.morph
        }
        var byMorph: [PteroFootprintMorphotype: [Dinosaur]] = [:]
        for morph in PteroFootprintMorphotype.allCases {
            guard let group = byMorphGrouped[morph] else { continue }
            byMorph[morph] = sortPterosaursWithinMorphByFootprintSize(group)
        }

        let morphsWithOneOrMore = PteroFootprintMorphotype.allCases.filter { (byMorph[$0] ?? []).count >= 1 }
        guard morphsWithOneOrMore.count >= 3 else {
            fatalError("Need at least 3 morphotypes with 1+ pterosaur for Ptero Footprints (have \(morphsWithOneOrMore.count))")
        }

        var availableKeys: [String] = allPossibleSlotKeys.filter { !PteroFootprintsStorage.loadUsedSlotKeys().contains($0) }
        if availableKeys.count < 3 {
            PteroFootprintsStorage.clearUsedSlots()
            availableKeys = Array(allPossibleSlotKeys)
        }

        let pickedSlotKeys = pickThreePteroFootprintSlots(availableSlotKeys: availableKeys, buckets: slotBuckets)
        guard pickedSlotKeys.count == 3 else {
            fatalError("Ptero Footprints: expected 3 rounds (picked \(pickedSlotKeys.count) slots)")
        }

        var usedQuestionIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for roundId in 1...3 {
            let slotKey = pickedSlotKeys[roundId - 1]
            guard let parsed = parsePteroFootprintSlotKey(slotKey),
                  var candidates = slotBuckets[slotKey], !candidates.isEmpty else {
                fatalError("Ptero Footprints: empty slot \(slotKey)")
            }
            candidates.shuffle()
            let correct = candidates.first { !usedQuestionIds.contains($0.id) } ?? candidates[0]
            usedQuestionIds.insert(correct.id)

            let questionMorph = parsed.morph
            let otherMorphs = PteroFootprintMorphotype.allCases.filter { $0 != questionMorph && (byMorph[$0]?.isEmpty == false) }.shuffled()
            guard otherMorphs.count >= 2 else {
                fatalError("Ptero Footprints: need 2 decoy morphotypes for \(questionMorph)")
            }

            var excluded: Set<Int> = [correct.id]
            var decoy1: Dinosaur?
            var decoy2: Dinosaur?
            outerDecoys: for i in 0..<otherMorphs.count {
                for j in (i + 1)..<otherMorphs.count {
                    let m1 = otherMorphs[i], m2 = otherMorphs[j]
                    let pool1 = byMorph[m1] ?? []
                    let pool2 = byMorph[m2] ?? []
                    guard let d1 = pool1.filter({ !excluded.contains($0.id) }).randomElement() else { continue }
                    excluded.insert(d1.id)
                    guard let d2 = pool2.filter({ !excluded.contains($0.id) }).randomElement() else {
                        excluded.remove(d1.id)
                        continue
                    }
                    decoy1 = d1
                    decoy2 = d2
                    break outerDecoys
                }
            }
            guard let d1 = decoy1, let d2 = decoy2 else {
                fatalError("Ptero Footprints: could not pick decoys for round \(roundId)")
            }

            var options = [correct, d1, d2]
            options.shuffle()
            let imageName = pteroFootprintImageName(morph: parsed.morph, size: parsed.size)
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: imageName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options
            ))
        }

        return GuessGameConfig(
            id: "ptero-footprints",
            title: "Ptero Footprints!",
            introAudio: "game-ptero-footprints",
            rounds: rounds,
            availableDinosaurs: all,
            victorySideEffect: {
                let keys = rounds.compactMap { round -> String? in
                    guard let d = all.first(where: { $0.id == round.correctAnswerId }),
                          let pair = pteroFootprintPair(for: d) else { return nil }
                    return "\(pair.morph.rawValue)|\(pair.size.rawValue)"
                }
                PteroFootprintsStorage.appendUsedSlotKeys(keys, allPossibleSlotKeys: allPossibleSlotKeys)
            }
        )
    }

    // Marine Footprints!: Each round shows `marine-footprints-{locomotion}-{clade}`; player picks the marine reptile from the matching clade. Two decoys from other clades. Rotation cycles bundled `(locomotion|clade)` slots.
    static func makeMarineFootprints() -> GuessGameConfig? {
        let all = SeaMarineReptileData.allMarineReptiles
        guard all.count >= 5 else { return nil }

        let shipped = MarineFootprintsMechanics.shippedSlots
        guard shipped.count >= 3 else { return nil }

        let byClade = Dictionary(grouping: all) { SeaMarineReptileData.marineCladeRawValue(for: $0) }
        let playableSlots = shipped.filter { (byClade[$0.marineGroupRaw]?.isEmpty == false) }
        guard playableSlots.count >= 3 else { return nil }

        let allPossibleSlotKeys = Set(playableSlots.map(\.slotKey))
        let slotByKey = Dictionary(uniqueKeysWithValues: playableSlots.map { ($0.slotKey, $0) })

        var availableKeys = playableSlots.map(\.slotKey).filter { !MarineFootprintsStorage.loadUsedSlotKeys().contains($0) }
        if availableKeys.count < 3 {
            MarineFootprintsStorage.clearUsedSlots()
            availableKeys = playableSlots.map(\.slotKey)
        }

        let pickedSlotKeys = pickThreeMarineFootprintSlots(availableSlotKeys: availableKeys, slotByKey: slotByKey)
        guard pickedSlotKeys.count == 3 else { return nil }

        var usedQuestionIds: Set<Int> = []
        var rounds: [RoundQuestion] = []
        for roundId in 1...3 {
            let slotKey = pickedSlotKeys[roundId - 1]
            guard let slot = slotByKey[slotKey],
                  var candidates = byClade[slot.marineGroupRaw], !candidates.isEmpty else { return nil }
            candidates.shuffle()
            let correct = candidates.first { !usedQuestionIds.contains($0.id) } ?? candidates[0]
            usedQuestionIds.insert(correct.id)

            let decoys = SeaMarineReptileData.pickTwoDecoysDistinctMarineClades(question: correct, pool: all)
            guard decoys.count == 2 else { return nil }

            var options = [correct] + decoys
            options.shuffle()
            guard let questionImageName = MarineFootprintsMechanics.pickGameplayImageName(for: slot) else { return nil }
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: questionImageName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options
            ))
        }

        return GuessGameConfig(
            id: "marine-footprints",
            title: "Marine Footprints!",
            introAudio: "game-marine-footprints",
            rounds: rounds,
            availableDinosaurs: all,
            victorySideEffect: {
                MarineFootprintsStorage.appendUsedSlotKeys(pickedSlotKeys, allPossibleSlotKeys: allPossibleSlotKeys)
            }
        )
    }

    // Dino Bones!: identify dinosaur from museum preparator scene—skeleton on tarp, paleontologist with gift fossil, one bone missing.
    // Clue: nearly articulated skeleton, gift fossil (partially in matrix), skull, or obvious missing bone (skull/foreleg/femur).
    // 3 rounds, 3 options per round. Images: dino-bones-{slug}; fallback: dino-silhouette-{slug}. Pool filtered to dinosaurs with dino-bones images.
    // game-dino-bones-identify-the-skeleton.m4a plays at start of each round before options walk.
    static var dinoBones: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        guard allDinosaurs.count >= 3 else {
            fatalError("Need at least 3 dinosaurs for Dino Bones, but only have \(allDinosaurs.count)")
        }
        let pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            let slug = imageName.replacingOccurrences(of: "dino-", with: "")
            return UIImage(named: "dino-bones-\(slug)") != nil
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with dino-bones-{slug} images for Dino Bones, but only have \(pool.count)")
        }
        let byClade = Dictionary(grouping: pool) { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) }
        let allCladesWithDinos = byClade.keys.filter { !(byClade[$0] ?? []).isEmpty }
        let roundCount = 3
        let finalQuestionDinosaurs: [Dinosaur]
        if allCladesWithDinos.count >= roundCount {
            let cladesToUse = Array(allCladesWithDinos.shuffled().prefix(roundCount))
            finalQuestionDinosaurs = cladesToUse.compactMap { (byClade[$0] ?? []).shuffled().first }
        } else {
            finalQuestionDinosaurs = Array(pool.shuffled().prefix(roundCount))
        }
        guard finalQuestionDinosaurs.count == roundCount, Set(finalQuestionDinosaurs.map { $0.id }).count == roundCount else {
            fatalError("Need \(roundCount) unique dinosaurs for Dino Bones")
        }
        var rounds: [RoundQuestion] = []
        for (roundNumber, questionDinosaur) in finalQuestionDinosaurs.enumerated() {
            let roundId = roundNumber + 1
            let questionClade = LandDinosaurCladeCatalog.clade(forCreatureId: questionDinosaur.id)
            let decoyCandidates = pool.filter { d in
                d.id != questionDinosaur.id && LandDinosaurCladeCatalog.clade(forCreatureId: d.id) != questionClade
            }
            let decoys: [Dinosaur]
            if decoyCandidates.count >= 2 {
                decoys = Array(decoyCandidates.shuffled().prefix(2))
            } else {
                let fallback = pool.filter { $0.id != questionDinosaur.id }
                decoys = Array(fallback.shuffled().prefix(2))
            }
            guard decoys.count == 2 else {
                fatalError("Not enough decoys for Dino Bones round \(roundId)")
            }
            var options = [questionDinosaur] + decoys
            options.shuffle()
            let baseName = questionDinosaur.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            let bonesImageName = "dino-bones-\(baseName)"
            rounds.append(RoundQuestion(
                id: roundId,
                questionImageName: bonesImageName,
                questionImageFallback: questionDinosaur.imageName,
                correctAnswerId: questionDinosaur.id,
                options: options
            ))
        }
        return GuessGameConfig(
            id: "dino-bones",
            title: "Dino Bones!",
            introAudio: "game-dino-bones",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }

    /// Temporarily 2 rounds while `dino-body-*` coverage is limited (e.g. ankylosaur + sauropod). Increase when more clades ship.
    private static let whoseBonesRoundCount = 2

    /// Whose Bones?: main image is `dino-body-{segment}-{clade}`; pick the dinosaur whose clade matches the clue. Options use full-body `dino-{slug}` art (same as Match / Weigh).
    static var whoseBones: GuessGameConfig {
        let allDinosaurs = MatchingGameConfigs.allDinosaurs
        let pool = allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-") else { return false }
            return UIImage(named: imageName) != nil
        }
        guard pool.count >= 3 else {
            fatalError("Need at least 3 dinosaurs with bundled dino- full-body images for Whose Bones, but only have \(pool.count)")
        }
        var clueQueue = shuffledWhoseBonesClues()
        guard clueQueue.count >= whoseBonesRoundCount else {
            fatalError("Need at least \(whoseBonesRoundCount) dino-body-* imagesets for Whose Bones, but only have \(clueQueue.count)")
        }
        var rounds: [RoundQuestion] = []
        var usedCorrectIds: Set<Int> = []
        while rounds.count < whoseBonesRoundCount && !clueQueue.isEmpty {
            let clue = clueQueue.removeFirst()
            let matching = dinoCladesMatchingBodyAssetClade(clue.assetClade)
            guard !matching.isEmpty else { continue }
            let correctPool = pool.filter { matching.contains(LandDinosaurCladeCatalog.clade(forCreatureId: $0.id)) && !usedCorrectIds.contains($0.id) }
            guard let correct = correctPool.shuffled().first else { continue }
            let decoyPool = pool.filter { !matching.contains(LandDinosaurCladeCatalog.clade(forCreatureId: $0.id)) && $0.id != correct.id }
            guard decoyPool.count >= 2 else { continue }
            let decoys = Array(decoyPool.shuffled().prefix(2))
            var options = [correct] + decoys
            options.shuffle()
            rounds.append(RoundQuestion(
                id: rounds.count + 1,
                questionImageName: clue.imageAssetName,
                questionImageFallback: correct.imageName,
                correctAnswerId: correct.id,
                options: options,
                bodySegmentSpeechKey: clue.segment
            ))
            usedCorrectIds.insert(correct.id)
        }
        guard rounds.count == whoseBonesRoundCount else {
            fatalError("Could not build \(whoseBonesRoundCount) Whose Bones rounds (clade/body asset mismatch — add clues or adjust pool)")
        }
        return GuessGameConfig(
            id: "whose-bones",
            title: "Whose Bones?",
            introAudio: "game-whose-bones",
            rounds: rounds,
            availableDinosaurs: allDinosaurs
        )
    }

    private struct WhoseBonesClue {
        let imageAssetName: String
        let segment: String
        let assetClade: String
    }

    private static let whoseBonesSegments = ["skull", "neck", "foreleg", "hindleg", "pelvis", "ribcage", "shoulder", "tail"]

    private static func shuffledWhoseBonesClues() -> [WhoseBonesClue] {
        var clues: [WhoseBonesClue] = []
        for name in ImageAssetNames.knownAssets where name.hasPrefix("dino-body-") {
            guard let parsed = parseDinoBodyAssetName(name) else { continue }
            clues.append(WhoseBonesClue(imageAssetName: name, segment: parsed.segment, assetClade: parsed.clade))
        }
        return clues.shuffled()
    }

    private static func parseDinoBodyAssetName(_ name: String) -> (segment: String, clade: String)? {
        let prefix = "dino-body-"
        guard name.hasPrefix(prefix) else { return nil }
        let rest = String(name.dropFirst(prefix.count))
        for seg in whoseBonesSegments {
            let mid = "\(seg)-"
            guard rest.hasPrefix(mid) else { continue }
            let clade = String(rest.dropFirst(mid.count))
            if clade.isEmpty { continue }
            return (seg, clade)
        }
        return nil
    }

    private static func dinoCladesMatchingBodyAssetClade(_ assetClade: String) -> Set<DinoClade> {
        switch assetClade {
        case "sauropod": return [.sauropod]
        case "ankylosaur": return [.ankylosaurid]
        case "ceratopsian": return [.ceratopsian]
        case "hadrosaur": return [.hadrosaur]
        case "stegosaur": return [.stegosaur]
        case "small-theropod", "large-theropod", "ornithomimid":
            return [.theropod, .spinosaurid]
        case "ornithischian":
            return [.ornithopod, .pachycephalosaur, .stegosaur, .ankylosaurid, .ceratopsian, .hadrosaur]
        default:
            return []
        }
    }
}
