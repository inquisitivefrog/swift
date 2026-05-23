//
//  EggsGameShared.swift
//  DinoGames
//
//  Shared CT-scanner eggs game used by Dino Eggs and Ptero Eggs.
//

import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Morphology & settings

struct EggsMorphology {
    let assetPrefix: String
    /// When set (e.g. `ptero-nests`), nest images use `{nestAssetPrefix}-{clade}` instead of `{assetPrefix}-nesting-{style}`.
    let nestAssetPrefix: String?
    /// When set, CT scanner tool images use `{scannerToolPrefix}-tools-scanner-*` (Ptero Eggs reuses dino scanner art).
    let scannerToolPrefix: String?
    let eggType: (Dinosaur) -> String?
    let nestingStyle: (String) -> String
    let nestingFallbackText: (String) -> String
    let scanAssetName: (String) -> String
    let randomColorsAsset: (String) -> String?

    func nestingImageName(style: String) -> String {
        if let nest = nestAssetPrefix { return "\(nest)-\(style)" }
        return "\(assetPrefix)-nesting-\(style)"
    }

    func eggImageName(eggType: String) -> String { "\(assetPrefix)-\(eggType)" }
    func scansEmptyName() -> String { "\(assetPrefix)-scans-empty" }

    private var scannerPrefix: String { scannerToolPrefix ?? assetPrefix }

    func scannerOpenName() -> String { "\(scannerPrefix)-tools-scanner-open" }
    func scannerClosedName() -> String { "\(scannerPrefix)-tools-scanner-closed" }
    func eggAudioKey(eggType: String) -> String { "\(assetPrefix)-\(eggType)" }

    func nestingAudioKey(style: String) -> String {
        if let nest = nestAssetPrefix { return "\(nest)-\(style)" }
        return "\(assetPrefix)-nesting-\(style)"
    }
}

struct EggsGameSettings {
    let morphology: EggsMorphology
    let gameKeyPrefix: String
    let gameplayDirectionsAudioKey: String
    let gameplayDirectionsFallback: String
    let beepKey: String
    let scanFailedKey: String
    let tapCreatureKey: String
    let successImageName: String
    let creatureEmoji: String
    /// When set (Dino Eggs), each round intro is directions → nest clip → tap scanner.
    let roundIntroNestAudioKey: ((String) -> String)?
    let roundIntroTapScannerAudioKey: String?
    let onVictoryComplete: (String) -> Void

    var usesCompactRoundIntro: Bool { roundIntroNestAudioKey != nil }
}

// MARK: - Data Models

struct EggsGameRound: Identifiable {
    let id: Int
    /// The dinosaur whose egg matches (clade is secret).
    let correctCreature: Dinosaur
    /// Morphological egg clade (e.g. hadrosaur); drives colored egg, nest, and scan art.
    let eggType: String
    /// Nest lookup key (same as `eggType` for Dino Eggs; clade for Ptero Eggs).
    let nestingStyle: String
    /// Two dinosaurs from other clades as distractors.
    let distractors: [Dinosaur]
}

struct EggsGameConfig {
    let settings: EggsGameSettings
    let totalRounds: Int
    let id: String
    let title: String
    let introAudio: String
    let gameplayDirectionsAudio: String
    let rounds: [EggsGameRound]
}

/// Main explore carousel: nest and colored egg before scan; nest, egg, and scan result after.
private enum MainExploreImagePhase: Equatable {
    case nest
    case egg
    case scan
}

// MARK: - Main View

struct EggsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: EggsGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var matchedPairs: Set<Int> = []
    @State private var failedAttempts: Set<Int> = []
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isCorrect = false
    @State private var showVictory = false
    @State private var introWalkComplete = false
    @State private var introWalkStep = 0
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var victoryRounds: [(creature: Dinosaur, eggType: String, scanResultEmpty: Bool)] = []
    @State private var displayedCreatures: [Dinosaur] = []
    @State private var mainImagePhase: MainExploreImagePhase = .nest
    /// Scanner: open until user taps to scan (when egg visible).
    @State private var scannerIsOpen = true
    /// Flash opacity (1 = normal, 0.5 = dim); animates 4 times over 2s then beep on the active tool.
    @State private var scanFlashOpacity: Double = 1.0
    /// When true, scanner area shows scan result (empty or clade) until round completes.
    @State private var hintShown = false
    /// When true, scan showed empty (20%); when false, showed clade image (80%).
    @State private var scanResultEmpty = false
    /// True while flash+beep sequence runs; prevents main-image toggle from reopening scanner.
    @State private var scanInProgress = false
    /// Colored egg asset for this round (e.g. dino-egg-colors-{clade}). Picked at round start.
    @State private var roundColorsAsset: String? = nil
    /// When true (scanner finished), main egg area shows scan result (empty or baby skeleton).
    @State private var scannerActive = false

    private var totalRounds: Int { gameConfig.totalRounds }
    private let mainImageDisplaySeconds: Double = 3.0

    private var currentRoundConfig: EggsGameRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    /// All 3 dinosaurs: correct + 2 distractors (shuffled for display).
    private var creatures: [Dinosaur] {
        guard let r = currentRoundConfig else { return [] }
        return ([r.correctCreature] + r.distractors).shuffled()
    }

    private var morphology: EggsMorphology { gameConfig.settings.morphology }

    private func nestingImageExists(style: String) -> Bool {
        ImageAssetCache.imageExists(named: morphology.nestingImageName(style: style))
    }

    private var eggType: String? { currentRoundConfig?.eggType }
    private var nestingStyle: String? { currentRoundConfig?.nestingStyle }

    private var introCreaturesOrder: [Dinosaur] { displayedCreatures.isEmpty ? creatures : displayedCreatures }

    /// Label during intro walk.
    private var introLabel: String? {
        guard !introWalkComplete else { return nil }
        if gameConfig.settings.usesCompactRoundIntro {
            switch introWalkStep {
            case 1:
                return gameConfig.settings.morphology.nestingFallbackText(nestingStyle ?? eggType ?? "")
            case 2: return "Tap the CT scanner"
            default: return nil
            }
        }
        switch introWalkStep {
        case 1: return eggType?.replacingOccurrences(of: "-", with: " ").capitalized
        case 2: return nestingStyle?.replacingOccurrences(of: "-", with: " ").capitalized
        case 3, 4, 5:
            let idx = introWalkStep - 3
            return idx < introCreaturesOrder.count ? introCreaturesOrder[idx].name : nil
        default: return nil
        }
    }

    private var introWalkFinalStep: Int {
        gameConfig.settings.usesCompactRoundIntro ? 2 : 5
    }

    /// Subtitle under the round counter (intro lines, answer prompt, or try-again / success).
    private var statusLabel: String? {
        if showFeedback { return feedbackMessage }
        if let intro = introLabel { return intro }
        if scannerActive { return "Tap the dinosaur that laid this egg" }
        return nil
    }

    var body: some View {
        let content = Group {
            if showVictory { victoryView } else { mainGameView }
        }
        .padding()
        .onAppear {
            guard currentRound == 1 else { return }
            resetGameState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startIntroWalk() }
        }
        .allowsHitTesting(!speechManager.isPlaying)
        .opacity(speechManager.isPlaying ? 0.7 : 1.0)
        .navigationBarTitleDisplayMode(.inline)
        return NavigationView { content }
    }

    private func resetGameState() {
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        showFeedback = false
        introWalkComplete = false
        introWalkStep = 0
        hintShown = false
        scanResultEmpty = false
        scanInProgress = false
        scannerActive = false
    }

    // MARK: - Main Game

    private var mainGameView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(gameConfig.title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(statusLabel ?? " ")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(showFeedback ? (isCorrect ? .green : .orange) : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(height: 52)
                    .opacity(statusLabel != nil ? 1 : 0)
            }

            // Alternating main image: nest ↔ egg, then nest ↔ egg ↔ scan after CT scan.
            mainAlternatingImage

            // CT scanner only (magnify + SEM removed for simpler flow)
            scannerToolRowView

            // Three dinosaurs below (dino-{slug}), tappable—only one matches the displayed egg
            threeCreatureLayout
        }
        .task(id: currentRound) {
            displayedCreatures = creatures.shuffled()
            if let clade = currentRoundConfig?.eggType {
                roundColorsAsset = gameConfig.settings.morphology.randomColorsAsset(clade)
            }
        }
        .id(currentRound)
    }

    private func mainImageAssetName(style: String, phase: MainExploreImagePhase) -> String? {
        switch phase {
        case .nest:
            guard nestingImageExists(style: style) else { return nil }
            return morphology.nestingImageName(style: style)
        case .egg:
            guard let egg = eggType else { return nil }
            if let colors = roundColorsAsset, ImageAssetCache.imageExists(named: colors) {
                return colors
            }
            let fallback = morphology.eggImageName(eggType: egg)
            return ImageAssetCache.imageExists(named: fallback) ? fallback : roundColorsAsset
        case .scan:
            guard let egg = eggType else { return nil }
            if scanResultEmpty, ImageAssetCache.imageExists(named: morphology.scansEmptyName()) {
                return morphology.scansEmptyName()
            }
            let scan = morphology.scanAssetName(egg)
            return ImageAssetCache.imageExists(named: scan) ? scan : morphology.scansEmptyName()
        }
    }

    private func nextMainImagePhase(after phase: MainExploreImagePhase, nestingAvailable: Bool) -> MainExploreImagePhase {
        if scannerActive {
            if nestingAvailable {
                switch phase {
                case .nest: return .egg
                case .egg: return .scan
                case .scan: return .nest
                }
            }
            return phase == .egg ? .scan : .egg
        }
        if nestingAvailable {
            return phase == .nest ? .egg : .nest
        }
        return .egg
    }

    private var mainAlternatingImage: some View {
        let style = nestingStyle ?? eggType ?? "ground-nest"
        let nestingAvailable = nestingImageExists(style: style)
        let displayPhase: MainExploreImagePhase = {
            if mainImagePhase == .nest, !nestingAvailable { return .egg }
            return mainImagePhase
        }()

        return Group {
            if let imgName = mainImageAssetName(style: style, phase: displayPhase),
               ImageAssetCache.imageExists(named: imgName) {
                Image(imgName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.2))
                    .frame(width: 260, height: 130)
            }
        }
        .padding(.horizontal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.4), value: mainImagePhase)
        .onAppear { mainImagePhase = .nest }
        .onChange(of: currentRound) { _, _ in
            mainImagePhase = .nest
            scannerIsOpen = true
            scanFlashOpacity = 1
            hintShown = false
            scanResultEmpty = false
            scanInProgress = false
            scannerActive = false
            if let clade = currentRoundConfig?.eggType {
                roundColorsAsset = gameConfig.settings.morphology.randomColorsAsset(clade)
            }
        }
        .onChange(of: mainImagePhase) { _, new in
            if new == .nest, !scanInProgress, !scannerActive {
                scannerIsOpen = true
                scanFlashOpacity = 1
            }
        }
        .task(id: currentRound) {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(mainImageDisplaySeconds * 1_000_000_000))
                if Task.isCancelled { break }
                // Hold the scan result steady while the player chooses — no timing puzzle.
                if scannerActive { continue }
                let style = nestingStyle ?? eggType ?? "ground-nest"
                let nestingAvailable = nestingImageExists(style: style)
                let next = nextMainImagePhase(after: mainImagePhase, nestingAvailable: nestingAvailable)
                if next == mainImagePhase { continue }
                mainImagePhase = next
            }
        }
    }

    private let scannerToolImageSize: CGFloat = 100

    private var scannerToolRowView: some View {
        let egg = currentRoundConfig?.eggType ?? ""
        let emptyExists = ImageAssetCache.imageExists(named: morphology.scansEmptyName())
        let cladeImageName = egg.isEmpty ? "" : gameConfig.settings.morphology.scanAssetName(egg)
        let cladeExists = !cladeImageName.isEmpty && ImageAssetCache.imageExists(named: cladeImageName)

        return HStack {
            Spacer(minLength: 0)
            scannerToolImage(emptyExists: emptyExists, cladeExists: cladeExists)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: scannerIsOpen)
        .animation(.easeInOut(duration: 0.15), value: scanFlashOpacity)
        .animation(.easeInOut(duration: 0.3), value: scannerActive)
        .animation(.easeInOut(duration: 0.3), value: scanInProgress)
    }

    @ViewBuilder
    private func scannerToolImage(emptyExists: Bool, cladeExists: Bool) -> some View {
        let openName = morphology.scannerOpenName()
        let closedName = morphology.scannerClosedName()
        let displayName: String? = {
            if scanInProgress || !scannerIsOpen {
                return ImageAssetCache.imageExists(named: closedName) ? closedName : (ImageAssetCache.imageExists(named: openName) ? openName : nil)
            }
            return ImageAssetCache.imageExists(named: openName) ? openName : (ImageAssetCache.imageExists(named: closedName) ? closedName : nil)
        }()

        Group {
            if let name = displayName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: scannerToolImageSize, height: scannerToolImageSize)
                    .opacity(scanInProgress ? scanFlashOpacity : 1)
            } else {
                scannerToolPlaceholder
            }
        }
        .contentShape(Rectangle())
        .opacity((scanInProgress || scannerActive) ? 0.5 : 1)
        .onTapGesture {
            guard scannerIsOpen, !scanInProgress, !scannerActive else { return }
            mainImagePhase = .egg
            scannerIsOpen = false
            scanFlashOpacity = 1
            scanInProgress = true
            runScanFlashThenBeep {
                self.scanInProgress = false
                let rolledEmpty = Double.random(in: 0..<1) < 0.2
                self.scanResultEmpty = rolledEmpty && emptyExists
                self.hintShown = self.scanResultEmpty || cladeExists
                self.scannerActive = true
                self.mainImagePhase = .scan
                if self.scanResultEmpty {
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        self.speechManager.speak(gameConfig.settings.tapCreatureKey)
                    }
                    self.speechManager.speak(gameConfig.settings.scanFailedKey)
                } else {
                    self.speechManager.speak(gameConfig.settings.tapCreatureKey)
                }
            }
        }
    }

    @ViewBuilder
    private var scannerToolPlaceholder: some View {
        VStack(spacing: 4) {
            Text("📡")
                .font(.system(size: 32))
            Text("CT scanner")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: scannerToolImageSize, height: scannerToolImageSize)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15)))
    }

    private func runScanFlashThenBeep(then: @escaping () -> Void) {
        Task { @MainActor in
            for _ in 0..<4 {
                scanFlashOpacity = 0.5
                try? await Task.sleep(nanoseconds: 500_000_000)
                scanFlashOpacity = 1
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if let url = speechManager.urlForAudio(key: gameConfig.settings.beepKey) {
                let prev = speechManager.onAudioFinished
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = prev
                    DispatchQueue.main.async { then() }
                }
                speechManager.playAudioFile(url: url)
            } else {
                then()
            }
        }
    }

    private var threeCreatureLayout: some View {
        let dinos = displayedCreatures.isEmpty ? creatures : displayedCreatures
        return VStack(spacing: 12) {
            // Top: middle dinosaur (index 1)
            if dinos.count > 1 {
                creatureCard(for: dinos[1], index: 1)
            }
            // Bottom: left (0) and right (2)
            HStack(spacing: 24) {
                if !dinos.isEmpty { creatureCard(for: dinos[0], index: 0) }
                if dinos.count > 2 { creatureCard(for: dinos[2], index: 2) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func creatureCard(for creature: Dinosaur, index: Int) -> some View {
        let isHighlighted = !introWalkComplete && introWalkStep >= 3 && introWalkStep <= 5
            && introWalkStep - 3 < introCreaturesOrder.count && introCreaturesOrder[introWalkStep - 3].id == creature.id
        return EggsGameCreatureCard(
            creatureEmoji: gameConfig.settings.creatureEmoji,
            creature: creature,
            isSelected: false,
            isMatched: matchedPairs.contains(creature.id),
            hasFailedAttempt: failedAttempts.contains(creature.id),
            isIntroHighlighted: isHighlighted,
            compact: true,
            onTap: { handleCreatureTap(creature) }
        )
    }

    // MARK: - Intro (Dino Eggs: directions → nest → tap scanner; Ptero: directions → egg → nest → 3 creatures)

    private func startIntroWalk() {
        let compact = gameConfig.settings.usesCompactRoundIntro
        guard creatures.count >= 3, eggType != nil, compact || nestingStyle != nil else {
            introWalkComplete = true
            return
        }
        introWalkStep = 0
        speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil; self.advanceIntroWalk() }
        speechManager.speak(
            audioKey: gameConfig.settings.gameplayDirectionsAudioKey,
            fallbackText: gameConfig.settings.gameplayDirectionsFallback
        )
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep > introWalkFinalStep {
            introWalkComplete = true
            return
        }
        speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil; self.advanceIntroWalk() }
        if gameConfig.settings.usesCompactRoundIntro {
            switch introWalkStep {
            case 1:
                guard let clade = eggType,
                      let nestKey = gameConfig.settings.roundIntroNestAudioKey?(clade) else {
                    advanceIntroWalk()
                    return
                }
                let fallback = morphology.nestingFallbackText(nestingStyle ?? clade)
                speechManager.speak(audioKey: nestKey, fallbackText: fallback)
            case 2:
                let scannerKey = gameConfig.settings.roundIntroTapScannerAudioKey ?? "game-dino-eggs-tap-the-scanner"
                speechManager.speak(audioKey: scannerKey, fallbackText: "Tap the CT scanner")
            default:
                advanceIntroWalk()
            }
            return
        }
        switch introWalkStep {
        case 1:
            let fallback = (eggType ?? "").replacingOccurrences(of: "-", with: " ").capitalized
            speechManager.speak(audioKey: morphology.eggAudioKey(eggType: eggType ?? ""), fallbackText: fallback)
        case 2:
            let fallback = gameConfig.settings.morphology.nestingFallbackText(nestingStyle ?? "")
            speechManager.speak(audioKey: morphology.nestingAudioKey(style: nestingStyle ?? ""), fallbackText: fallback)
        case 3, 4, 5:
            let idx = introWalkStep - 3
            guard idx < introCreaturesOrder.count else { advanceIntroWalk(); return }
            let d = introCreaturesOrder[idx]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        default:
            advanceIntroWalk()
        }
    }


    // MARK: - Tap Handlers

    /// Non-nil after CT scan completes — player may answer on any carousel phase (nest, egg, or scan).
    private var currentDisplayedEggType: String? {
        guard scannerActive else { return nil }
        return eggType
    }

    private func handleCreatureTap(_ creature: Dinosaur) {
        guard !speechManager.isPlaying else { return }
        if matchedPairs.contains(creature.id) {
            speechManager.speak("pick-another-one")
            return
        }

        if currentDisplayedEggType != nil {
            // Egg is showing: tap = answer. Correct dinosaur matches the egg.
            let correctDino = currentRoundConfig?.correctCreature
            let isCorrectMatch = creature.id == correctDino?.id

            showFeedback = true
            isCorrect = isCorrectMatch
            feedbackMessage = isCorrectMatch ? "That's right!" : "Try again!"

            if isCorrectMatch {
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        self.showFeedback = false
                        self.matchedPairs.insert(creature.id)
                        self.finishRound()
                    }
                    self.playAnswerFeedbackAudio(key: "thats-right-you-guessed-it")
                }
                speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
            } else {
                failedAttempts.insert(creature.id)
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.showFeedback = false
                }
                playAnswerFeedbackAudio(key: "try-again")
            }
        } else {
            // Before scan: remind player to use the CT scanner (not a graded guess).
            speechManager.onAudioFinished = nil
            let scannerKey = gameConfig.settings.roundIntroTapScannerAudioKey ?? "game-dino-eggs-tap-the-scanner"
            if let url = speechManager.urlForAudio(key: scannerKey) {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("Tap the CT scanner first")
            }
        }
    }

    private func playAnswerFeedbackAudio(key: String) {
        if let url = speechManager.urlForAudio(key: key) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(key)
        }
    }

    private func finishRound() {
        if let r = currentRoundConfig, let egg = eggType {
            victoryRounds.append((creature: r.correctCreature, eggType: egg, scanResultEmpty: scanResultEmpty))
        }

        if currentRound >= totalRounds {
            endSequenceStep = -1
            endHighlightIndex = 0
            showVictory = true
        } else {
            currentRound += 1
            resetGameState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startIntroWalk() }
        }
    }

    // MARK: - Victory (shared: recap walk → success stinger → good-job + crowd)

    private var victoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: victoryRounds.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            extendScrollListToMaxWidth: true,
            scrollRows: {
                ForEach(Array(victoryRounds.enumerated()), id: \.offset) { index, round in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: "\(round.creature.id)-\(index)",
                            title: round.creature.name,
                            imageAssetName: eggsVictoryRecapImageName(eggType: round.eggType, scanResultEmpty: round.scanResultEmpty),
                            fallbackEmoji: gameConfig.settings.creatureEmoji
                        ),
                        isHighlighted: isHighlighted
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: [gameConfig.settings.successImageName, "game-\(gameConfig.id)"],
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
            if victoryRounds.isEmpty {
                endSequenceStep = 2
            } else {
                let creature = victoryRounds[0].creature
                speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if endHighlightIndex == 0, endSequenceStep == 1 { advanceVictoryHighlight() }
                }
            }
        }
    }

    /// Recap thumbnail: colored egg from play, then scan result if needed.
    private func eggsVictoryRecapImageName(eggType: String, scanResultEmpty: Bool) -> String? {
        if let colored = morphology.randomColorsAsset(eggType),
           ImageAssetCache.imageExists(named: colored) {
            return colored
        }
        let eggName = morphology.eggImageName(eggType: eggType)
        if ImageAssetCache.imageExists(named: eggName) { return eggName }
        if scanResultEmpty, ImageAssetCache.imageExists(named: morphology.scansEmptyName()) {
            return morphology.scansEmptyName()
        }
        let scanName = morphology.scanAssetName(eggType)
        return ImageAssetCache.imageExists(named: scanName) ? scanName : nil
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryRounds.count {
            let creature = victoryRounds[endHighlightIndex].creature
            speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
            let currentIndex = endHighlightIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if endHighlightIndex == currentIndex, endSequenceStep == 1 { advanceVictoryHighlight() }
            }
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
                gameConfig.settings.onVictoryComplete(self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                gameConfig.settings.onVictoryComplete(self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            gameConfig.settings.onVictoryComplete(gameConfig.id)
            isPresented = false
        }
    }
}

// MARK: - Cards

private let eggsGameCardSize: CGFloat = 100
private let eggsGameCardSizeCompact: CGFloat = 88

private struct EggsGameCreatureCard: View {
    let creatureEmoji: String
    let creature: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    var compact: Bool = false
    let onTap: () -> Void

    private var size: CGFloat { compact ? eggsGameCardSizeCompact : eggsGameCardSize }

    private var imageName: String? {
        let name = creature.imageName ?? "dino-\(creature.id)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isSelected || isIntroHighlighted { return .accentColor }
        if hasFailedAttempt { return .red.opacity(0.75) }
        return .clear
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 4) {
                    if let name = imageName {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(isMatched ? 0.5 : 1.0)
                    } else {
                        Text(creatureEmoji)
                            .font(.system(size: 40))
                            .frame(width: size, height: size)
                            .opacity(isMatched ? 0.5 : 1.0)
                    }
                    Text(creature.name)
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if hasFailedAttempt && !isMatched {
                    Text("✗")
                        .font(.system(size: compact ? 28 : 32))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMatched ? Color.green.opacity(0.15) : (isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: hasFailedAttempt || isMatched ? 3 : 2))
            .animation(.easeOut(duration: 0.35), value: hasFailedAttempt)
        }
        .buttonStyle(.plain)
    }
}

