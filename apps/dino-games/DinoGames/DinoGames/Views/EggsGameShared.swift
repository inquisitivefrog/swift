//
//  EggsGameShared.swift
//  DinoGames
//
//  Shared CT-scanner eggs game used by Dino Eggs and Ptero Eggs.
//

import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Morphology & settings

/// How egg-game art is named under the asset catalog.
enum EggsMorphologyAssetStyle: Equatable {
    /// `dino-eggs-{clade}` / `ptero-eggs-{clade}`; nests via `nestAssetPrefix` or `*-nesting-*`.
    case cladeBased
    /// `marine-eggs-egg-{slug}`, `marine-eggs-nest-{slug}`, `marine-eggs-live-{slug}`, `marine-eggs-spawn-{slug}`.
    case marineSegments(prefix: String = "marine-eggs")
}

struct EggsMorphology {
    let assetPrefix: String
    /// When set (e.g. `ptero-nests`), nest images use `{nestAssetPrefix}-{clade}` instead of `{assetPrefix}-nesting-{style}`.
    let nestAssetPrefix: String?
    /// When set, CT scanner tool images use `{scannerToolPrefix}-tools-scanner-*` (Ptero/Marine Eggs reuse dino scanner art).
    let scannerToolPrefix: String?
    let assetStyle: EggsMorphologyAssetStyle
    let eggType: (Dinosaur) -> String?
    let nestingStyle: (String) -> String
    let nestingFallbackText: (String) -> String
    let scanAssetName: (String) -> String
    let randomColorsAsset: (String) -> String?
    /// When set (Marine Eggs), resolves catalog slug → bundled egg imageset name.
    let eggImageNameResolver: ((String) -> String)?
    /// Maps gameplay clade/slug → bundled imageset suffix when they differ (e.g. `transitional` → `transition`).
    let imageLookupKey: ((String) -> String)?
    /// When set (Marine Eggs), spoken egg keys use `marine-eggs-{slug}` instead of `marine-eggs-egg-{slug}`.
    let eggAudioKeyResolver: ((String) -> String)?

    init(
        assetPrefix: String,
        nestAssetPrefix: String?,
        scannerToolPrefix: String?,
        assetStyle: EggsMorphologyAssetStyle = .cladeBased,
        eggType: @escaping (Dinosaur) -> String?,
        nestingStyle: @escaping (String) -> String,
        nestingFallbackText: @escaping (String) -> String,
        scanAssetName: @escaping (String) -> String,
        randomColorsAsset: @escaping (String) -> String?,
        eggImageNameResolver: ((String) -> String)? = nil,
        imageLookupKey: ((String) -> String)? = nil,
        eggAudioKeyResolver: ((String) -> String)? = nil
    ) {
        self.assetPrefix = assetPrefix
        self.nestAssetPrefix = nestAssetPrefix
        self.scannerToolPrefix = scannerToolPrefix
        self.assetStyle = assetStyle
        self.eggType = eggType
        self.nestingStyle = nestingStyle
        self.nestingFallbackText = nestingFallbackText
        self.scanAssetName = scanAssetName
        self.randomColorsAsset = randomColorsAsset
        self.eggImageNameResolver = eggImageNameResolver
        self.imageLookupKey = imageLookupKey
        self.eggAudioKeyResolver = eggAudioKeyResolver
    }

    func bundledImageKey(forClade clade: String) -> String {
        imageLookupKey?(clade) ?? clade
    }

    func nestingImageName(style: String) -> String {
        let key = bundledImageKey(forClade: style)
        switch assetStyle {
        case .cladeBased:
            if let nest = nestAssetPrefix { return "\(nest)-\(key)" }
            return "\(assetPrefix)-nesting-\(key)"
        case .marineSegments(let prefix):
            return "\(prefix)-nest-\(key)"
        }
    }

    func eggImageName(eggType: String) -> String {
        if let eggImageNameResolver { return eggImageNameResolver(eggType) }
        switch assetStyle {
        case .cladeBased:
            return "\(assetPrefix)-\(eggType)"
        case .marineSegments(let prefix):
            return "\(prefix)-egg-\(eggType)"
        }
    }

    func scansEmptyName() -> String {
        switch assetStyle {
        case .cladeBased:
            if assetPrefix == "ptero-eggs" { return "ptero-eggs-scan-empty" }
            return "\(assetPrefix)-scans-empty"
        case .marineSegments:
            return "dino-eggs-scans-empty"
        }
    }

    private var scannerPrefix: String { scannerToolPrefix ?? assetPrefix }

    func scannerOpenName() -> String { "\(scannerPrefix)-tools-scanner-open" }
    func scannerClosedName() -> String { "\(scannerPrefix)-tools-scanner-closed" }

    func eggAudioKey(eggType: String) -> String {
        if let eggAudioKeyResolver { return eggAudioKeyResolver(eggType) }
        switch assetStyle {
        case .cladeBased:
            return "\(assetPrefix)-\(eggType)"
        case .marineSegments(let prefix):
            return "\(prefix)-egg-\(eggType)"
        }
    }

    func nestingAudioKey(style: String) -> String {
        switch assetStyle {
        case .cladeBased:
            if let nest = nestAssetPrefix { return "\(nest)-\(style)" }
            return "\(assetPrefix)-nesting-\(style)"
        case .marineSegments(let prefix):
            return "\(prefix)-nest-\(style)"
        }
    }
}

struct EggsSourceHint: Identifiable, Equatable {
    let id: String
    let imageName: String
    let displayName: String
    let audioKey: String
}

struct EggsGameSettings {
    let morphology: EggsMorphology
    let gameKeyPrefix: String
    let gameplayDirectionsAudioKey: String
    let gameplayDirectionsFallback: String
    let beepKey: String
    let scanFailedKey: String
    /// Optional prompt after scan audio (e.g. “tap the dinosaur”). nil for pre-reader eggs play — egg/nest audio is enough.
    let tapCreatureAfterScanKey: String?
    let successImageName: String
    let creatureEmoji: String
    /// When set (Dino Eggs), each round intro may include a nest clip before tap-scanner (only if `playsEggNestNameIntro`).
    let roundIntroNestAudioKey: ((String) -> String)?
    let roundIntroTapScannerAudioKey: String?
    /// Pre-reader play: skip spoken/written egg-type and nest labels during round intro.
    let playsEggNestNameIntro: Bool
    /// Pre-reader play: skip “tap the CT scanner” prompts (intro + early creature taps).
    let playsTapScannerPrompt: Bool
    /// Pre-reader play: hide creature names under portrait cards.
    let showsCreatureNameOnCards: Bool
    /// Victory recap rows show the matched creature name and use its `imageName` audio when bundled.
    let victoryRecapUsesCreatureName: Bool
    /// When false, keep the game title visible during the success card (marine success art has no title).
    let hideGameTitleDuringSuccessPhase: Bool
    /// When false, keep the recap list visible above the success card (Name That / Ptero Eggs style).
    let collapseRecapListDuringSuccessPhase: Bool
    /// Source hints overlay (Dino Eggs: shape + color). nil = no hints button.
    let sourceHints: [EggsSourceHint]?
    let sourceHintsTitle: String
    let sourceHintsGridIntroAudioKey: String?
    let onVictoryComplete: (String) -> Void

    var usesCompactRoundIntro: Bool { roundIntroNestAudioKey != nil }
    var hasSourceHints: Bool { !(sourceHints ?? []).isEmpty }
}

/// Ordered steps for the per-round intro audio walk.
private enum EggsIntroWalkStep {
    case gameplayDirections
    case eggTypeAudio
    case nestAudio
    case tapScanner
    case creatureName(index: Int)
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
    /// When false (Marine Eggs live/spawn-only species), the main image stays on `fixedMainImageAssetName` — no nest↔egg carousel.
    var alternatesNestAndEgg: Bool = true
    /// Bundled `marine-eggs-live-*` or `marine-eggs-spawn-*` for specimen-only rounds.
    var fixedMainImageAssetName: String? = nil
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
    /// Marine Eggs: fixed live or spawn art (no nest/egg pair for that species).
    case specimen
}

/// Restarts the main-image carousel timer when post-scan rotation begins so the scan frame gets a full dwell.
private struct EggsMainImageCarouselTaskID: Equatable {
    let round: Int
    let scanInProgress: Bool
    let postScanCarouselActive: Bool
}

// MARK: - Main View

struct EggsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: EggsGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var matchedPairs: Set<Int> = []
    @State private var failedAttempts: Set<Int> = []
    @State private var showVictory = false
    @State private var introWalkComplete = false
    @State private var introWalkStep = 0
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var victoryRounds: [(eggType: String, eggImageAssetName: String?, displayTitle: String, victoryAudioKey: String)] = []
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
    /// When true (scanner finished), player may answer; scan joins nest/egg carousel once `postScanCarouselActive`.
    @State private var scannerActive = false
    /// After CT scan resolves: nest ↔ egg ↔ scan rotation (avoids a brief scan flash before the carousel is ready).
    @State private var postScanCarouselActive = false
    /// Prevents duplicate scan-outcome audio if the scanner callback runs more than once.
    @State private var scanOutcomeAudioStarted = false
    /// True from a correct answer until the next round intro begins — freezes carousel and shows green match.
    @State private var roundAnswered = false
    @State private var showSourceEggsHints = false

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
    private var alternatesNestAndEgg: Bool { currentRoundConfig?.alternatesNestAndEgg ?? true }
    private var usesSpecimenOnlyRound: Bool { !alternatesNestAndEgg }

    private var introCreaturesOrder: [Dinosaur] { displayedCreatures.isEmpty ? creatures : displayedCreatures }

    private var introWalkSteps: [EggsIntroWalkStep] {
        let settings = gameConfig.settings
        var steps: [EggsIntroWalkStep] = []
        if usesSpecimenOnlyRound {
            if settings.playsEggNestNameIntro {
                steps.append(.creatureName(index: 0))
            }
            if settings.playsTapScannerPrompt {
                steps.append(.tapScanner)
            }
            return steps
        }
        if settings.usesCompactRoundIntro {
            if settings.playsEggNestNameIntro, settings.roundIntroNestAudioKey != nil {
                steps.append(.nestAudio)
            }
            if settings.playsTapScannerPrompt {
                steps.append(.tapScanner)
            }
            return steps
        }
        if settings.playsEggNestNameIntro {
            steps.append(.eggTypeAudio)
            steps.append(.nestAudio)
        }
        if settings.playsTapScannerPrompt {
            steps.append(.tapScanner)
        }
        steps.append(.creatureName(index: 0))
        steps.append(.creatureName(index: 1))
        steps.append(.creatureName(index: 2))
        return steps
    }

    private var introWalkFinalStep: Int { introWalkSteps.count }

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
        .opacity(speechManager.isPlaying ? 0.7 : 1.0)
        .navigationBarTitleDisplayMode(.inline)
        return NavigationView { content }
            .overlay(alignment: .topTrailing) {
                if gameConfig.settings.hasSourceHints, !showVictory {
                    Button {
                        showSourceEggsHints = true
                    } label: {
                        Text("Hints")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Circle().fill(Color.blue))
                            .frame(width: 72, height: 72)
                    }
                    .disabled(speechManager.isPlaying)
                    .opacity(speechManager.isPlaying ? 0.45 : 1.0)
                    .padding(.top, 8)
                    .padding(.trailing, 16)
                }
            }
            .fullScreenCover(isPresented: $showSourceEggsHints) {
                if let hints = gameConfig.settings.sourceHints {
                    SourceEggsHintsView(
                        hints: hints,
                        title: gameConfig.settings.sourceHintsTitle,
                        hintGridIntroAudioKey: gameConfig.settings.sourceHintsGridIntroAudioKey,
                        onDismiss: { showSourceEggsHints = false }
                    )
                }
            }
    }

    private func resetGameState() {
        matchedPairs.removeAll()
        failedAttempts.removeAll()
        introWalkComplete = false
        introWalkStep = 0
        hintShown = false
        scanResultEmpty = false
        scanInProgress = false
        scannerActive = false
        postScanCarouselActive = false
        scanOutcomeAudioStarted = false
        roundAnswered = false
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
            }

            // Alternating main image: nest ↔ egg, then nest ↔ egg ↔ scan after CT scan.
            mainAlternatingImage

            // CT scanner only (magnify + SEM removed for simpler flow)
            scannerToolRowView
                .allowsHitTesting(true)

            // Three dinosaurs below (dino-{slug}), tappable—only one matches the displayed egg
            threeCreatureLayout
                .allowsHitTesting(!speechManager.isPlaying)
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
        case .specimen:
            guard let name = currentRoundConfig?.fixedMainImageAssetName,
                  ImageAssetCache.imageExists(named: name) else { return nil }
            return name
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
        if usesSpecimenOnlyRound {
            if scannerActive {
                return phase == .specimen ? .scan : .specimen
            }
            return .specimen
        }
        if scannerActive {
            if nestingAvailable {
                switch phase {
                case .nest: return .egg
                case .egg: return .scan
                case .scan: return .nest
                case .specimen: return .scan
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
        let nestingAvailable = !usesSpecimenOnlyRound && nestingImageExists(style: style)
        let displayPhase: MainExploreImagePhase = {
            if usesSpecimenOnlyRound { return mainImagePhase == .scan ? .scan : .specimen }
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
        .onAppear { mainImagePhase = usesSpecimenOnlyRound ? .specimen : .nest }
        .onChange(of: currentRound) { _, _ in
            mainImagePhase = usesSpecimenOnlyRound ? .specimen : .nest
            scannerIsOpen = true
            scanFlashOpacity = 1
            hintShown = false
            scanResultEmpty = false
            scanInProgress = false
            scannerActive = false
            postScanCarouselActive = false
            scanOutcomeAudioStarted = false
            roundAnswered = false
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
        .task(id: EggsMainImageCarouselTaskID(
            round: currentRound,
            scanInProgress: scanInProgress,
            postScanCarouselActive: postScanCarouselActive
        )) {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(mainImageDisplaySeconds * 1_000_000_000))
                if Task.isCancelled { break }
                if roundAnswered { continue }
                if scanInProgress { continue }
                if scannerActive, !postScanCarouselActive { continue }
                if scannerActive, !roundAnswered {
                    if mainImagePhase != .scan {
                        mainImagePhase = .scan
                    }
                    continue
                }
                let style = nestingStyle ?? eggType ?? "ground-nest"
                let nestingAvailable = !usesSpecimenOnlyRound && nestingImageExists(style: style)
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
            scannerToolImage(eggClade: egg, emptyExists: emptyExists, cladeExists: cladeExists)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: scannerIsOpen)
        .animation(.easeInOut(duration: 0.15), value: scanFlashOpacity)
        .animation(.easeInOut(duration: 0.3), value: scannerActive)
        .animation(.easeInOut(duration: 0.3), value: scanInProgress)
    }

    @ViewBuilder
    private func scannerToolImage(eggClade: String, emptyExists: Bool, cladeExists: Bool) -> some View {
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
        .opacity(scanInProgress ? scanFlashOpacity : 1)
        .onTapGesture {
            guard scannerIsOpen, !scanInProgress, !scannerActive else { return }
            scanInProgress = true
            scanOutcomeAudioStarted = false
            mainImagePhase = usesSpecimenOnlyRound ? .specimen : .egg
            scannerIsOpen = false
            scanFlashOpacity = 1
            runScanFlashThenBeep {
                guard !self.scanOutcomeAudioStarted else { return }
                self.scanInProgress = false
                let rolledEmpty = Double.random(in: 0..<1) < 0.2
                self.scanResultEmpty = rolledEmpty && emptyExists
                self.hintShown = self.scanResultEmpty || cladeExists
                self.scannerActive = true
                self.mainImagePhase = .scan
                self.postScanCarouselActive = true
                self.playScanOutcomeThenTapCreature(eggClade: eggClade, scanEmpty: self.scanResultEmpty)
            }
        }
    }

    /// After CT scan: empty → `scanFailedKey`; otherwise clade/creature audio. Uses `chainDelay` so clips are not dropped right after the beep.
    private func playScanOutcomeThenTapCreature(eggClade: String, scanEmpty: Bool) {
        guard !scanOutcomeAudioStarted else { return }
        scanOutcomeAudioStarted = true
        let morphology = gameConfig.settings.morphology
        if let tapKey = gameConfig.settings.tapCreatureAfterScanKey {
            speechManager.onAudioFinished = {
                speechManager.onAudioFinished = nil
                speechManager.speak(tapKey, chainDelay: true)
            }
        } else {
            speechManager.onAudioFinished = nil
        }
        if scanEmpty {
            speechManager.speak(gameConfig.settings.scanFailedKey, chainDelay: true)
        } else if usesSpecimenOnlyRound, let creature = currentRoundConfig?.correctCreature {
            speechManager.speak(
                audioKey: creature.imageName ?? creature.name,
                fallbackText: creature.name,
                chainDelay: true
            )
        } else if gameConfig.settings.victoryRecapUsesCreatureName, let creature = currentRoundConfig?.correctCreature {
            speechManager.speak(
                audioKey: creature.imageName ?? creature.name,
                fallbackText: creature.name,
                chainDelay: true
            )
        } else {
            let key = morphology.eggAudioKey(eggType: eggClade)
            speechManager.speak(audioKey: key, fallbackText: "", chainDelay: true)
        }
    }

    @ViewBuilder
    private var scannerToolPlaceholder: some View {
        Text("📡")
            .font(.system(size: 32))
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
        let isHighlighted = introHighlightsCreature(creature)
        return EggsGameCreatureCard(
            creatureEmoji: gameConfig.settings.creatureEmoji,
            creature: creature,
            showsName: gameConfig.settings.showsCreatureNameOnCards,
            isSelected: false,
            isMatched: matchedPairs.contains(creature.id),
            hasFailedAttempt: failedAttempts.contains(creature.id),
            isIntroHighlighted: isHighlighted,
            compact: true,
            onTap: { handleCreatureTap(creature) }
        )
    }

    private func introHighlightsCreature(_ creature: Dinosaur) -> Bool {
        guard !introWalkComplete, introWalkStep >= 1, introWalkStep <= introWalkSteps.count else { return false }
        let step = introWalkSteps[introWalkStep - 1]
        guard case .creatureName(let index) = step,
              index < introCreaturesOrder.count,
              introCreaturesOrder[index].id == creature.id else { return false }
        return true
    }

    // MARK: - Intro (Dino Eggs: directions → tap scanner; Ptero: directions → tap scanner → 3 creatures)

    private func startIntroWalk() {
        let compact = gameConfig.settings.usesCompactRoundIntro
        guard creatures.count >= 3, eggType != nil, usesSpecimenOnlyRound || compact || nestingStyle != nil else {
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
        playIntroWalkStep(introWalkSteps[introWalkStep - 1])
    }

    private func playIntroWalkStep(_ step: EggsIntroWalkStep) {
        switch step {
        case .gameplayDirections:
            advanceIntroWalk()
        case .eggTypeAudio:
            guard let eggType else { advanceIntroWalk(); return }
            speechManager.speak(audioKey: morphology.eggAudioKey(eggType: eggType), fallbackText: "")
        case .nestAudio:
            if gameConfig.settings.usesCompactRoundIntro,
               let clade = eggType,
               let nestKey = gameConfig.settings.roundIntroNestAudioKey?(clade) {
                speechManager.speak(audioKey: nestKey, fallbackText: "")
            } else if let nestingStyle {
                speechManager.speak(audioKey: morphology.nestingAudioKey(style: nestingStyle), fallbackText: "")
            } else {
                advanceIntroWalk()
            }
        case .tapScanner:
            playTapScannerPrompt()
        case .creatureName(let index):
            guard index < introCreaturesOrder.count else { advanceIntroWalk(); return }
            if usesSpecimenOnlyRound, index == 0, let correct = currentRoundConfig?.correctCreature {
                speechManager.speak(audioKey: correct.imageName ?? correct.name, fallbackText: "")
            } else {
                let creature = introCreaturesOrder[index]
                speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: "")
            }
        }
    }

    private func playTapScannerPrompt() {
        let scannerKey = gameConfig.settings.roundIntroTapScannerAudioKey ?? "game-dino-eggs-tap-the-scanner"
        if let url = speechManager.urlForAudio(key: scannerKey) {
            speechManager.playAudioFile(url: url)
        } else {
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
        guard !speechManager.isPlaying, !roundAnswered else { return }
        if matchedPairs.contains(creature.id) {
            speechManager.speak("pick-another-one")
            return
        }

        if currentDisplayedEggType != nil {
            // Egg is showing: tap = answer. Correct dinosaur matches the egg.
            let correctDino = currentRoundConfig?.correctCreature
            let isCorrectMatch = creature.id == correctDino?.id

            if isCorrectMatch {
                matchedPairs.insert(creature.id)
                failedAttempts.removeAll()
                roundAnswered = true
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.finishRound()
                        }
                    }
                    self.playAnswerFeedbackAudio(key: "thats-right-you-guessed-it")
                }
                speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
            } else {
                failedAttempts.insert(creature.id)
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.playAnswerFeedbackAudio(key: "try-again")
                }
                speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
            }
        } else if gameConfig.settings.playsTapScannerPrompt {
            speechManager.onAudioFinished = nil
            let scannerKey = gameConfig.settings.roundIntroTapScannerAudioKey ?? "game-dino-eggs-tap-the-scanner"
            if let url = speechManager.urlForAudio(key: scannerKey) {
                speechManager.playAudioFile(url: url)
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
        // Settle on nest before clearing scan state so an empty scan cannot flash to skeleton.
        mainImagePhase = .nest
        scanInProgress = false
        scannerActive = false
        postScanCarouselActive = false
        scanOutcomeAudioStarted = false

        if let egg = eggType {
            let creature = currentRoundConfig?.correctCreature
            let displayTitle: String
            let audioKey: String
            if gameConfig.settings.victoryRecapUsesCreatureName, let creature {
                displayTitle = creature.name
                audioKey = creature.imageName ?? creature.name
            } else {
                displayTitle = ""
                audioKey = morphology.eggAudioKey(eggType: egg)
            }
            victoryRounds.append((
                eggType: egg,
                eggImageAssetName: coloredEggAssetName(for: egg),
                displayTitle: displayTitle,
                victoryAudioKey: audioKey
            ))
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

    // MARK: - Victory (shared: egg recap walk → crowd + success card → dismiss)

    private var victoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: victoryRounds.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            hideGameTitleDuringSuccessPhase: gameConfig.settings.hideGameTitleDuringSuccessPhase,
            collapseRecapListDuringSuccessPhase: gameConfig.settings.collapseRecapListDuringSuccessPhase,
            extendScrollListToMaxWidth: true,
            scrollRows: {
                ForEach(Array(victoryRounds.enumerated()), id: \.offset) { index, round in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: "\(round.eggType)-\(index)",
                            title: round.displayTitle,
                            imageAssetName: round.eggImageAssetName,
                            fallbackEmoji: "🥚"
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
                    imageSide: gameConfig.settings.collapseRecapListDuringSuccessPhase
                        ? GameCatalogImageMetrics.nameThatVictorySuccessImageSide
                        : 180,
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
                speakVictoryEgg(at: 0)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if endHighlightIndex == 0, endSequenceStep == 1 { advanceVictoryHighlight() }
                }
            }
        }
    }

    /// Colored egg asset for gameplay carousel (colors art only — never clade `dino-eggs-*` egg silhouettes).
    private func coloredEggAssetName(for eggType: String) -> String? {
        if let colors = roundColorsAsset, ImageAssetCache.imageExists(named: colors) {
            return colors
        }
        if let colors = morphology.randomColorsAsset(eggType),
           ImageAssetCache.imageExists(named: colors) {
            return colors
        }
        return nil
    }

    private func speakVictoryEgg(at index: Int) {
        guard index < victoryRounds.count else { return }
        let round = victoryRounds[index]
        speechManager.speak(audioKey: round.victoryAudioKey, fallbackText: round.displayTitle)
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryRounds.count {
            speakVictoryEgg(at: endHighlightIndex)
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
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager,
            beforeDismiss: { gameConfig.settings.onVictoryComplete(gameConfig.id) }
        )
    }
}

// MARK: - Cards

private let eggsGameCardSize: CGFloat = 100
private let eggsGameCardSizeCompact: CGFloat = 88

private struct EggsGameCreatureCard: View {
    let creatureEmoji: String
    let creature: Dinosaur
    var showsName: Bool = false
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
        if hasFailedAttempt { return .red }
        if isSelected || isIntroHighlighted { return .accentColor }
        return .clear
    }

    private var strokeWidth: CGFloat {
        if isMatched || hasFailedAttempt { return 4 }
        if isSelected || isIntroHighlighted { return 3 }
        return 0
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
                    if showsName {
                        Text(creature.name)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .scaleEffect(isMatched ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isMatched)
            .animation(.easeOut(duration: 0.35), value: hasFailedAttempt)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
    }
}

// MARK: - Source Eggs Hints (Dino Eggs)

struct SourceEggsHintsView: View {
    let hints: [EggsSourceHint]
    let title: String
    var hintGridIntroAudioKey: String?
    let onDismiss: () -> Void
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedHint: EggsSourceHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedHint == nil {
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
            .disabled(speechManager.isPlaying)
            .opacity(speechManager.isPlaying ? 0.45 : 1.0)
            .padding(.leading, 8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .allowsHitTesting(!speechManager.isPlaying)
        .opacity(speechManager.isPlaying ? 0.85 : 1.0)
        .onAppear { playIntroOnce() }
    }

    private var gridView: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2.weight(.semibold))
                .padding(.top, 44)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(hints) { hint in
                    Button {
                        showHintDetail(hint)
                    } label: {
                        if ImageAssetCache.imageExists(named: hint.imageName) {
                            Image(hint.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 140)
                                .overlay(Text(hint.displayName).font(.title3).foregroundColor(.secondary))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let hint = selectedHint {
            VStack(spacing: 20) {
                Spacer()
                if ImageAssetCache.imageExists(named: hint.imageName) {
                    Image(hint.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 340, maxHeight: 220)
                }
                Text(hint.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        guard let key = hintGridIntroAudioKey, let url = speechManager.urlForAudio(key: key) else { return }
        speechManager.onAudioFinished = nil
        speechManager.playAudioFile(url: url)
    }

    private func showHintDetail(_ hint: EggsSourceHint) {
        guard !speechManager.isPlaying else { return }
        selectedHint = hint
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedHint = nil
            }
        }
        if let url = speechManager.urlForAudio(key: hint.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(hint.displayName)
        }
    }
}

