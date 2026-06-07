//
//  DinoToolsGameView.swift
//  DinoGames
//
//  Dino Tools: Help the paleontologist use tools (magnifying glass, SEM microscope, CT scanner) to identify
//  the egg species and return the egg to its mother. Flow: magnify → SEM → scanner → select dinosaur.
//
//  Tool row artwork: prefers `dino-tools-*` (Dinosaur-Tools: paleontologist | preparator | restorer) when present, else `dino-eggs-tools-*` (Dinosaur-Eggs).
//

import SwiftUI
@preconcurrency import AVFoundation

// MARK: - Egg Morphology (dinosaur → egg type)

private enum EggMorphology {
    /// Maps dinosaur slug to egg type for dino-eggs-{eggType} images.
    private static let eggTypeBySlug: [String: String] = [
        "trex": "large-theropod", "triceratops": "ceratopsian", "stegosaurus": "stegosaur", "velociraptor": "small-theropod",
        "therizinosaurus": "ornithischian", "spinosaurus": "large-theropod", "apatosaurus": "sauropod", "ankylosaurus": "ankylosaur",
        "corythosaurus": "hadrosaur", "parasaurolophus": "hadrosaur", "iguanodon": "ornithischian", "troodon": "small-theropod",
        "edmontosaurus": "hadrosaur", "camarasaurus": "sauropod", "dryosaurus": "ornithischian", "gallimimus": "ornithomimid",
        "pachycephalosaurus": "ornithischian", "albertosaurus": "large-theropod", "anchiornis": "small-theropod",
        "archaeopteryx": "small-theropod", "argentinosaurus": "sauropod", "baryonyx": "large-theropod", "brachiosaurus": "sauropod",
        "ceratosaurus": "large-theropod", "chasmosaurus": "ceratopsian", "compsognathus": "small-theropod", "deinonychus": "small-theropod",
        "diplodocus": "sauropod", "dromaeosaurus": "small-theropod", "eosinopteryx": "small-theropod", "giganotosaurus": "large-theropod",
        "kosmoceratops": "ceratopsian", "microraptor": "small-theropod", "pedopenna": "small-theropod", "torosaurus": "ceratopsian",
        "utahraptor": "small-theropod", "xiaotingia": "small-theropod", "masiakasaurus": "small-theropod", "torvosaurus": "large-theropod",
        "rapetosaurus": "sauropod", "majungasaurus": "large-theropod", "allosaurus": "large-theropod", "oviraptor": "ornithomimid",
        "brontosaurus": "sauropod", "kentrosaurus": "stegosaur", "edmontonia": "ankylosaur", "lambeosaurus": "hadrosaur",
        "maiasaura": "hadrosaur", "stegoceras": "ornithischian", "stygimoloch": "ornithischian", "nodosaurus": "ankylosaur",
        "euoplocephalus": "ankylosaur", "polacanthus": "ankylosaur", "styracosaurus": "ceratopsian", "huayangosaurus": "stegosaur",
        "ouranosaurus": "ornithischian", "suchomimus": "large-theropod", "acrocanthosaurus": "large-theropod",
        "amargasaurus": "sauropod", "australovenator": "large-theropod", "carcharodontosaurus": "large-theropod",
        "deinocheirus": "ornithomimid", "fukuiraptor": "small-theropod", "gasparinisaura": "ornithischian",
        "mamenchisaurus": "sauropod", "gigantoraptor": "ornithomimid", "gigantosaurus": "large-theropod",
        "ornithomimus": "ornithomimid", "struthiomimus": "ornithomimid",
    ]

    static func eggType(for dino: Dinosaur) -> String? {
        let slug = dino.imageName?.replacingOccurrences(of: "dino-", with: "") ?? "\(dino.id)"
        return eggTypeBySlug[slug]
    }

    /// Nesting style that pairs with each egg type (scientifically associated).
    private static let nestingStyleByEggType: [String: String] = [
        "hadrosaur": "mound-nest",
        "ornithomimid": "rings",
        "ceratopsian": "open-scrape",
        "sauropod": "buried-pit-nest",
        "ankylosaur": "ground-nest",
        "stegosaur": "ground-nest",
        "ornithischian": "ground-nest",
        "large-theropod": "open-scrape",
        "small-theropod": "burrow",
    ]

    static func nestingStyle(forEggType eggType: String) -> String {
        nestingStyleByEggType[eggType] ?? "ground-nest"
    }

    /// TTS-friendly fallback for nesting style (avoids "nest" → "net" mispronunciation).
    private static let nestingFallbackByStyle: [String: String] = [
        "buried-pit-nest": "A buried pit nest",
        "mound-nest": "A mound nest",
        "ground-nest": "A ground nest",
        "open-scrape": "Open scrape",
        "rings": "Rings",
        "burrow": "Burrow",
    ]

    static func nestingFallbackText(for nestingStyle: String) -> String {
        nestingFallbackByStyle[nestingStyle]
            ?? nestingStyle.replacingOccurrences(of: "-", with: " ").capitalized
    }

    /// Maps egg type to dino-eggs-scans-{name} asset (some use -id suffix).
    static func scanAssetName(forEggType eggType: String) -> String {
        switch eggType {
        case "ankylosaur": return "dino-eggs-scans-ankylosaurid"
        case "stegosaur": return "dino-eggs-scans-stegosaurid"
        default: return "dino-eggs-scans-\(eggType)"
        }
    }

    /// Random dino-eggs-colors-{clade}-* asset for main egg display. Falls back to dino-eggs-{clade} if none.
    static func randomColorsAsset(forClade clade: String) -> String? {
        let prefix = "dino-eggs-colors-\(clade)-"
        let matches = ImageAssetCache.assets(matchingPrefix: prefix)
        if let chosen = matches.randomElement() { return chosen }
        let fallback = "dino-eggs-\(clade)"
        return ImageAssetCache.imageExists(named: fallback) ? fallback : nil
    }

    /// Magnified egg image: dino-eggs-magnify-{clade}-magnified.
    static func magnifiedAsset(forClade clade: String) -> String {
        "dino-eggs-magnify-\(clade)-magnified"
    }

    /// SEM magnified egg image: dino-eggs-sem-{clade}-magnified-sem.
    static func semMagnifiedAsset(forClade clade: String) -> String {
        "dino-eggs-sem-\(clade)-magnified-sem"
    }
}

// MARK: - Data Models

private enum DinoToolsScanningTool {
    case scanner
    case sem
}

/// First matching imageset name (prefers earlier entries).
private func dinoToolsFirstAssetName(_ candidates: [String]) -> String? {
    candidates.first { ImageAssetCache.imageExists(named: $0) }
}

struct DinoToolsRound: Identifiable {
    let id: Int
    /// The dinosaur whose egg matches (clade is secret).
    let correctDinosaur: Dinosaur
    /// Egg type for dino-eggs-{eggType} image.
    let eggType: String
    /// Nesting style for dino-eggs-nesting-{style} image.
    let nestingStyle: String
    /// Two dinosaurs from other clades as distractors.
    let distractors: [Dinosaur]
}

struct DinoToolsGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let gameplayDirectionsAudio: String
    let rounds: [DinoToolsRound]
}

// MARK: - Main View

struct DinoToolsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoToolsGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var currentRound = 1
    @State private var matchedPairs: Set<Int> = []
    @State private var failedAttempts: Set<Int> = []
    @State private var showVictory = false
    @State private var introWalkComplete = false
    @State private var introWalkStep = 0
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var victoryRounds: [(dinosaur: Dinosaur, eggType: String, scanResultEmpty: Bool)] = []
    @State private var displayedDinosaurs: [Dinosaur] = []
    /// When true, show nest image; when false, show egg.
    @State private var showNestImage = true
    /// Scanner: open until user taps to scan (when egg visible). SEM also triggers scan.
    @State private var scannerIsOpen = true
    /// Which tool is currently scanning; nil when idle. Flash opacity applies to this tool.
    @State private var scanningTool: DinoToolsScanningTool? = nil
    /// Flash opacity (1 = normal, 0.5 = dim); animates 4 times over 2s then beep on the active tool.
    @State private var scanFlashOpacity: Double = 1.0
    /// When true, scanner area shows scan result (empty or clade) until round completes.
    @State private var hintShown = false
    /// When true, scan showed empty (20%); when false, showed clade image (80%).
    @State private var scanResultEmpty = false
    /// True while flash+beep sequence runs; prevents main-image toggle from reopening scanner.
    @State private var scanInProgress = false
    /// Random colors asset for this round (dino-eggs-colors-{clade}-*). Picked at round start.
    @State private var roundColorsAsset: String? = nil
    /// When true (magnify tapped), main egg area shows dino-eggs-magnify-{clade}-magnified.
    @State private var magnifyActive = false
    /// When true (SEM tapped), main egg area shows dino-eggs-sem-{clade}-magnified-sem.
    @State private var semActive = false
    /// When true (Scanner tapped), main egg area shows scan result (empty or baby skeleton).
    @State private var scannerActive = false

    /// PoC: 1 round for testing; revert to 3 when enhancement is decided.
    private let totalRounds = 1
    private let mainImageDisplaySeconds: Double = 3.0

    private var currentRoundConfig: DinoToolsRound? {
        gameConfig.rounds.first { $0.id == currentRound }
    }

    /// All 3 dinosaurs: correct + 2 distractors (shuffled for display).
    private var dinosaurs: [Dinosaur] {
        guard let r = currentRoundConfig else { return [] }
        return ([r.correctDinosaur] + r.distractors).shuffled()
    }

    private var eggType: String? { currentRoundConfig?.eggType }
    private var nestingStyle: String? { currentRoundConfig?.nestingStyle }

    private var introDinosaursOrder: [Dinosaur] { displayedDinosaurs.isEmpty ? dinosaurs : displayedDinosaurs }

    /// Label during intro: egg type, nesting style, or current dinosaur name.
    private var introLabel: String? {
        guard !introWalkComplete else { return nil }
        switch introWalkStep {
        case 1: return eggType?.replacingOccurrences(of: "-", with: " ").capitalized
        case 2: return nestingStyle?.replacingOccurrences(of: "-", with: " ").capitalized
        case 3, 4, 5:
            let idx = introWalkStep - 3
            return idx < introDinosaursOrder.count ? introDinosaursOrder[idx].name : nil
        default: return nil
        }
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
        introWalkComplete = false
        introWalkStep = 0
        hintShown = false
        scanResultEmpty = false
        scanInProgress = false
        scanningTool = nil
        magnifyActive = false
        semActive = false
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
                Text(introLabel ?? " ")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(height: 52)
                    .opacity(introLabel != nil ? 1 : 0)
            }

            // Alternating main image: nest ↔ egg (egg is draggable to scanner)
            mainAlternatingImage

            // Three tools in a row: Scanner (replaces Micro CT), Magnify, SEM
            threeToolsRowView

            // Three dinosaurs below (dino-{slug}), tappable—only one matches the displayed egg
            threeDinoLayout
        }
        .task(id: currentRound) {
            displayedDinosaurs = dinosaurs.shuffled()
            if let clade = currentRoundConfig?.eggType {
                roundColorsAsset = EggMorphology.randomColorsAsset(forClade: clade)
            }
        }
        .id(currentRound)
    }

    private var mainAlternatingImage: some View {
        let style = nestingStyle ?? "ground-nest"

        return Group {
            if showNestImage, ImageAssetCache.imageExists(named: "dino-eggs-nesting-\(style)") {
                Image("dino-eggs-nesting-\(style)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else if let egg = eggType {
                let imgName: String = {
                    if scannerActive {
                        if scanResultEmpty, ImageAssetCache.imageExists(named: "dino-eggs-scans-empty") {
                            return "dino-eggs-scans-empty"
                        }
                        let scan = EggMorphology.scanAssetName(forEggType: egg)
                        return ImageAssetCache.imageExists(named: scan) ? scan : "dino-eggs-scans-empty"
                    }
                    if semActive {
                        let sem = EggMorphology.semMagnifiedAsset(forClade: egg)
                        return ImageAssetCache.imageExists(named: sem) ? sem : EggMorphology.magnifiedAsset(forClade: egg)
                    }
                    if magnifyActive {
                        let mag = EggMorphology.magnifiedAsset(forClade: egg)
                        return ImageAssetCache.imageExists(named: mag) ? mag : (roundColorsAsset ?? "dino-eggs-\(egg)")
                    }
                    if let colors = roundColorsAsset, ImageAssetCache.imageExists(named: colors) {
                        return colors
                    }
                    let fallback = "dino-eggs-\(egg)"
                    return ImageAssetCache.imageExists(named: fallback) ? fallback : (roundColorsAsset ?? fallback)
                }()
                if ImageAssetCache.imageExists(named: imgName) {
                    Image(imgName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 340, maxHeight: 220)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brown.opacity(0.2))
                        .frame(width: 260, height: 130)
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.2))
                    .frame(width: 260, height: 130)
            }
        }
        .padding(.horizontal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.4), value: showNestImage)
        .onAppear { showNestImage = true }
        .onChange(of: currentRound) { _, _ in
            showNestImage = true
            scannerIsOpen = true
            scanFlashOpacity = 1
            hintShown = false
            scanResultEmpty = false
            scanInProgress = false
            scanningTool = nil
            magnifyActive = false
            semActive = false
            scannerActive = false
            if let clade = currentRoundConfig?.eggType {
                roundColorsAsset = EggMorphology.randomColorsAsset(forClade: clade)
            }
        }
        .onChange(of: showNestImage) { _, new in
            if !new { failedAttempts.removeAll() }
            else if !scanInProgress { scannerIsOpen = true; scanFlashOpacity = 1; scanningTool = nil }
        }
        .task(id: currentRound) {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(mainImageDisplaySeconds * 1_000_000_000))
                if Task.isCancelled { break }
                if scannerActive { break }
                if magnifyActive || semActive { break }
                showNestImage.toggle()
            }
        }
    }

    /// Fixed size per tool so three fit in a row. Was 280×120 single; now ~90×90 each.
    private let toolImageSize: CGFloat = 90
    private let toolSpacing: CGFloat = 12

    private var threeToolsRowView: some View {
        let egg = currentRoundConfig?.eggType ?? ""
        let emptyExists = ImageAssetCache.imageExists(named: "dino-eggs-scans-empty")
        let cladeImageName = egg.isEmpty ? "" : EggMorphology.scanAssetName(forEggType: egg)
        let cladeExists = !cladeImageName.isEmpty && ImageAssetCache.imageExists(named: cladeImageName)

        return HStack(spacing: toolSpacing) {
            magnifyToolImage
            semToolImage
            scannerToolImage(emptyExists: emptyExists, cladeExists: cladeExists)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: scannerIsOpen)
        .animation(.easeInOut(duration: 0.15), value: scanFlashOpacity)
        .animation(.easeInOut(duration: 0.3), value: scannerActive)
        .animation(.easeInOut(duration: 0.3), value: scanningTool)
    }

    @ViewBuilder
    private var magnifyToolImage: some View {
        let magnifierName = dinoToolsFirstAssetName([
            "dino-tools-dental-pick",
            "dino-tools-tape-measure",
            "dino-tools-hand-held-sifting-screen",
            "dino-eggs-tools-magnifier",
        ])
        Group {
            if let n = magnifierName {
                Image(n)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: toolImageSize, height: toolImageSize)
            } else {
                toolImage(name: nil, label: "Magnify", emoji: "🔍")
            }
        }
        .contentShape(Rectangle())
        .opacity((magnifyActive || semActive || scannerActive) ? 0.5 : 1)
        .onTapGesture {
            guard !showNestImage, !magnifyActive, !semActive, !scannerActive else { return }
            magnifyActive = true
            speechManager.speak(
                audioKey: "game-dino-tools-tap-the-sem",
                fallbackText: "Eggs can also be sorted by eggshell texture. Help the paleontologist by tapping the SEM microscope to look closer when you see the egg."
            )
        }
    }

    @ViewBuilder
    private var semToolImage: some View {
        let inactiveName = dinoToolsFirstAssetName([
            "dino-tools-dust-snorkel",
            "dino-tools-exhaust-fume-hood",
            "dino-tools-abrasive-cabinet",
            "dino-eggs-tools-sem-inactive",
        ])
        let scanningName = dinoToolsFirstAssetName([
            "dino-tools-downdraft-bench",
            "dino-tools-dust-snorkel",
            "dino-eggs-tools-sem-scanning",
        ])
        let isSemScanning = scanningTool == .sem && scanInProgress
        let displayName: String? = {
            if isSemScanning, let s = scanningName { return s }
            if let i = inactiveName { return i }
            return scanningName
        }()

        Group {
            if let name = displayName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: toolImageSize, height: toolImageSize)
                    .opacity(scanningTool == .sem ? scanFlashOpacity : 1)
            } else {
                toolImage(name: nil, label: "SEM", emoji: "🔬")
            }
        }
        .contentShape(Rectangle())
        .opacity(!magnifyActive || semActive || scannerActive ? 0.5 : 1)
        .onTapGesture {
            guard !showNestImage else { return }
            if scanningTool != nil || semActive || scannerActive { return }
            if !magnifyActive {
                speechManager.speak(audioKey: "game-dino-tools-tap-magnifying-glass-first", fallbackText: "Tap the magnifying glass first to examine the egg.")
                return
            }
            scanningTool = .sem
            scanFlashOpacity = 1
            scanInProgress = true
            runScanFlashThenBeep {
                self.scanInProgress = false
                self.scanningTool = nil
                self.semActive = true
                self.speechManager.speak(
                    audioKey: "game-dino-tools-tap-the-scanner",
                    fallbackText: "Eggs can also be scanned to identify species. Help the paleontologist by tapping the CT scanner oven when you see the egg."
                )
            }
        }
    }

    @ViewBuilder
    private func scannerToolImage(emptyExists: Bool, cladeExists: Bool) -> some View {
        let openName = dinoToolsFirstAssetName([
            "dino-tools-3d-printer",
            "dino-tools-wet-sieve-stack",
            "dino-eggs-tools-scanner-open",
        ])
        let closedName = dinoToolsFirstAssetName([
            "dino-tools-digital-restoration",
            "dino-tools-specimen-crate",
            "dino-tools-3d-printer",
            "dino-eggs-tools-scanner-closed",
        ])
        let displayName: String? = {
            if scanningTool == .scanner || !scannerIsOpen {
                if let c = closedName { return c }
                return openName
            }
            if let o = openName { return o }
            return closedName
        }()

        Group {
            if let name = displayName {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: toolImageSize, height: toolImageSize)
                    .opacity(scanningTool == .scanner ? scanFlashOpacity : 1)
            } else {
                toolImage(name: nil, label: "Scanner", emoji: "📡")
            }
        }
        .contentShape(Rectangle())
        .opacity(!semActive || scannerActive ? 0.5 : 1)
        .onTapGesture {
            guard scannerIsOpen, scanningTool == nil, !showNestImage else { return }
            if scannerActive { return }
            if !semActive {
                speechManager.speak(audioKey: "game-dino-tools-tap-sem-microscope-first", fallbackText: "Tap the SEM microscope first to look at the eggshell.")
                return
            }
            scannerIsOpen = false
            scanningTool = .scanner
            scanFlashOpacity = 1
            scanInProgress = true
            runScanFlashThenBeep {
                self.scanInProgress = false
                self.scanningTool = nil
                let rolledEmpty = Double.random(in: 0..<1) < 0.2
                self.scanResultEmpty = rolledEmpty && emptyExists
                self.hintShown = self.scanResultEmpty || cladeExists
                self.scannerActive = true
                self.showNestImage = false
                if self.scanResultEmpty {
                    self.speechManager.onAudioFinished = {
                        self.speechManager.onAudioFinished = nil
                        self.speechManager.speak("game-dino-tools-tap-the-dinosaur")
                    }
                    self.speechManager.speak("game-dino-tools-scan-failed")
                } else {
                    self.speechManager.speak("game-dino-tools-tap-the-dinosaur")
                }
            }
        }
    }

    @ViewBuilder
    private func toolImage(name: String?, label: String, emoji: String) -> some View {
        let assetName = name.flatMap { ImageAssetCache.imageExists(named: $0) ? $0 : nil }
        if let n = assetName {
            Image(n)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: toolImageSize, height: toolImageSize)
        } else {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: toolImageSize, height: toolImageSize)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15)))
        }
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
            if let url = speechManager.urlForAudio(key: "game-dino-tools-beep") {
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

    private var threeDinoLayout: some View {
        let dinos = displayedDinosaurs.isEmpty ? dinosaurs : displayedDinosaurs
        return VStack(spacing: 12) {
            // Top: middle dinosaur (index 1)
            if dinos.count > 1 {
                dinoCard(for: dinos[1], index: 1)
            }
            // Bottom: left (0) and right (2)
            HStack(spacing: 24) {
                if !dinos.isEmpty { dinoCard(for: dinos[0], index: 0) }
                if dinos.count > 2 { dinoCard(for: dinos[2], index: 2) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func dinoCard(for dino: Dinosaur, index: Int) -> some View {
        let isHighlighted = !introWalkComplete && introWalkStep >= 3 && introWalkStep <= 5
            && introWalkStep - 3 < introDinosaursOrder.count && introDinosaursOrder[introWalkStep - 3].id == dino.id
        return DinoToolsDinoCard(
            dinosaur: dino,
            isSelected: false,
            isMatched: matchedPairs.contains(dino.id),
            hasFailedAttempt: failedAttempts.contains(dino.id),
            isIntroHighlighted: isHighlighted,
            compact: true,
            onTap: { handleDinoTap(dino) }
        )
    }

    // MARK: - Intro (each round: 1) directions, 2) egg type, 3) nesting style, 4) three dinosaurs, 5) wait for tap)

    private func startIntroWalk() {
        guard dinosaurs.count >= 3, eggType != nil, nestingStyle != nil else {
            introWalkComplete = true
            return
        }
        introWalkStep = 0
        speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil; self.advanceIntroWalk() }
        speechManager.speak(
            audioKey: "game-dino-tools-gameplay-directions",
            fallbackText: "Egg identification depends on shape, size, and color. Tap the magnifying glass to examine the egg more closely."
        )
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        introWalkStep += 1
        if introWalkStep > 5 {
            introWalkComplete = true
            return
        }
        speechManager.onAudioFinished = { self.speechManager.onAudioFinished = nil; self.advanceIntroWalk() }
        switch introWalkStep {
        case 1:
            let fallback = (eggType ?? "").replacingOccurrences(of: "-", with: " ").capitalized
            speechManager.speak(audioKey: "dino-eggs-\(eggType ?? "")", fallbackText: fallback)
        case 2:
            let fallback = EggMorphology.nestingFallbackText(for: nestingStyle ?? "")
            speechManager.speak(audioKey: "dino-eggs-nesting-\(nestingStyle ?? "")", fallbackText: fallback)
        case 3, 4, 5:
            let idx = introWalkStep - 3
            guard idx < introDinosaursOrder.count else { advanceIntroWalk(); return }
            let d = introDinosaursOrder[idx]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
        default:
            advanceIntroWalk()
        }
    }


    // MARK: - Tap Handlers

    /// Non-nil when user can answer (scan complete, egg showing). Flow: magnify → SEM → scanner → select dinosaur.
    private var currentDisplayedEggType: String? {
        guard !showNestImage, scannerActive else { return nil }
        return eggType
    }

    private func handleDinoTap(_ dino: Dinosaur) {
        guard !speechManager.isPlaying else { return }
        if matchedPairs.contains(dino.id) {
            speechManager.speak("pick-another-one")
            return
        }

        if currentDisplayedEggType != nil {
            // Egg is showing: tap = answer. Correct dinosaur matches the egg.
            let correctDino = currentRoundConfig?.correctDinosaur
            let isCorrectMatch = dino.id == correctDino?.id

            // Restate dinosaur name first for educational reinforcement, then play feedback
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    if isCorrectMatch {
                        self.matchedPairs.insert(dino.id)
                        self.finishRound()
                    } else {
                        self.failedAttempts.insert(dino.id)
                    }
                }
                let key = isCorrectMatch ? "thats-right-you-guessed-it" : "try-again"
                if let url = self.speechManager.urlForAudio(key: key) {
                    self.speechManager.playAudioFile(url: url)
                } else {
                    self.speechManager.speak(key)
                }
            }
            speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
        } else {
            // Nest is showing: just speak the dinosaur name
            speechManager.onAudioFinished = nil
            speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
        }
    }

    private func finishRound() {
        if let r = currentRoundConfig, let egg = eggType {
            victoryRounds.append((dinosaur: r.correctDinosaur, eggType: egg, scanResultEmpty: scanResultEmpty))
        }

        if currentRound >= totalRounds {
            showVictory = true
        } else {
            currentRound += 1
            resetGameState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startIntroWalk() }
        }
    }

    // MARK: - Victory

    private var victoryListVisibleHeight: CGFloat {
        let n = max(1, victoryRounds.count)
        return 16 + CGFloat(n) * 100 + CGFloat(max(0, n - 1)) * 12 + 16
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
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(victoryRounds.enumerated()), id: \.offset) { index, round in
                                DinoToolsVictoryRow(roundNumber: index + 1, correctDinosaur: round.dinosaur, eggType: round.eggType, scanResultEmpty: round.scanResultEmpty, isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex)
                                    .id(index)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .frame(height: min(CGFloat(victoryRounds.count) * (100 + 12) + 32, victoryListVisibleHeight))
                    .onChange(of: endHighlightIndex) { _, newValue in
                        if newValue >= 0, newValue < victoryRounds.count {
                            withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(newValue, anchor: .center) }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        successImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { playGoodJobAndCrowdThenDismiss() }
                            }
                    } else { Spacer() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryRounds.isEmpty {
                endSequenceStep = 2
            } else {
                let dino = victoryRounds[0].dinosaur
                speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if endHighlightIndex == 0, endSequenceStep == 1 { advanceVictoryHighlight() }
                }
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryRounds.count {
            let dino = victoryRounds[endHighlightIndex].dinosaur
            speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
            let currentIndex = endHighlightIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if endHighlightIndex == currentIndex, endSequenceStep == 1 { advanceVictoryHighlight() }
            }
        } else {
            endSequenceStep = 2
        }
    }

    private var successImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-tools-success") {
                Image("game-dino-tools-success")
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
}

// MARK: - Cards

private let dinoToolsCardSize: CGFloat = 100
private let dinoToolsCardSizeCompact: CGFloat = 88

private struct DinoToolsDinoCard: View {
    let dinosaur: Dinosaur
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    var compact: Bool = false
    let onTap: () -> Void

    private var size: CGFloat { compact ? dinoToolsCardSizeCompact : dinoToolsCardSize }

    private var imageName: String? {
        let name = dinosaur.imageName ?? "dino-\(dinosaur.id)"
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let name = imageName {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isIntroHighlighted ? Color.accentColor : Color.clear, lineWidth: 3))
                        .opacity(isMatched ? 0.5 : (isIntroHighlighted ? 1.0 : (hasFailedAttempt ? 0.5 : 1.0)))
                } else {
                    Text("🦖")
                        .font(.system(size: 40))
                        .frame(width: size, height: size)
                        .opacity(isMatched ? 0.5 : 1.0)
                }
                Text(dinosaur.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

private struct DinoToolsEggCard: View {
    let eggType: String
    let isSelected: Bool
    let isMatched: Bool
    let hasFailedAttempt: Bool
    var isIntroHighlighted: Bool = false
    let onTap: () -> Void

    private var imageName: String { "dino-eggs-\(eggType)" }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: dinoToolsCardSize, height: dinoToolsCardSize)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isIntroHighlighted ? Color.accentColor : Color.clear, lineWidth: 3))
                        .opacity(isMatched ? 0.5 : (isIntroHighlighted ? 1.0 : (hasFailedAttempt ? 0.5 : 1.0)))
                } else {
                    Text("🥚")
                        .font(.system(size: 40))
                        .frame(width: dinoToolsCardSize, height: dinoToolsCardSize)
                        .opacity(isMatched ? 0.5 : 1.0)
                }
                Text(eggType.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

private struct DinoToolsVictoryRow: View {
    let roundNumber: Int
    let correctDinosaur: Dinosaur
    let eggType: String
    let scanResultEmpty: Bool
    let isHighlighted: Bool

    private var scanImageName: String {
        if scanResultEmpty, ImageAssetCache.imageExists(named: "dino-eggs-scans-empty") {
            return "dino-eggs-scans-empty"
        }
        return EggMorphology.scanAssetName(forEggType: eggType)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if ImageAssetCache.imageExists(named: scanImageName) {
                Image(scanImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text("🔬")
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(correctDinosaur.name)
                    .font(.title2)
                    .fontWeight(isHighlighted ? .semibold : .regular)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: 100)
        .background(RoundedRectangle(cornerRadius: 12).fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2))
    }
}

// MARK: - Game Config

struct DinoToolsGameConfigs {
    /// PoC: 1 round for testing; revert to 3 when enhancement is decided. Loop structure preserved for rollback.
    private static let dinoToolsRoundCount = 1

    static var dinoTools: DinoToolsGameConfig {
        let pool = dinosaursWithDinoAndEgg
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        let allClades = Array(byClade.keys).filter { !(byClade[$0] ?? []).isEmpty }
        var usedIds: Set<Int> = []
        var rounds: [DinoToolsRound] = []

        for roundId in 1...dinoToolsRoundCount {
            // 1. Random clade chosen
            let availableClades = allClades.filter { clade in
                (byClade[clade] ?? []).contains { d in
                    guard !usedIds.contains(d.id), let eggType = EggMorphology.eggType(for: d) else { return false }
                    return ImageAssetCache.imageExists(named: "dino-eggs-\(eggType)")
                }
            }
            guard let chosenClade = availableClades.randomElement() else { break }
            let cladePool = (byClade[chosenClade] ?? []).filter { d in
                guard !usedIds.contains(d.id), let eggType = EggMorphology.eggType(for: d) else { return false }
                return ImageAssetCache.imageExists(named: "dino-eggs-\(eggType)")
            }
            guard let correctDino = cladePool.randomElement(),
                  let eggType = EggMorphology.eggType(for: correctDino) else { break }

            // 2. Matching egg and nesting images (paired)
            let nestingStyle = EggMorphology.nestingStyle(forEggType: eggType)
            guard ImageAssetCache.imageExists(named: "dino-eggs-nesting-\(nestingStyle)") else { continue }

            // 3. Two dinosaurs from other clades as distractors
            let distractorPool = dinosaursForDistractors(excludingClade: chosenClade)
                .filter { !usedIds.contains($0.id) && $0.id != correctDino.id }
            let distractors = Array(distractorPool.shuffled().prefix(2))
            guard distractors.count == 2 else { continue }

            usedIds.insert(correctDino.id)
            usedIds.formUnion(distractors.map(\.id))
            rounds.append(DinoToolsRound(
                id: roundId,
                correctDinosaur: correctDino,
                eggType: eggType,
                nestingStyle: nestingStyle,
                distractors: distractors
            ))
        }

        guard rounds.count >= dinoToolsRoundCount else {
            fatalError("Need at least \(dinoToolsRoundCount) rounds for Dino Tools (pool has \(pool.count) dinosaurs with dino+egg)")
        }

        return DinoToolsGameConfig(
            id: "dino-tools",
            title: "Dino Tools!",
            introAudio: "game-dino-tools",
            gameplayDirectionsAudio: "game-dino-tools-gameplay-directions",
            rounds: Array(rounds.prefix(dinoToolsRoundCount))
        )
    }

    /// PoC: only stegosaur eggs (correct dino); distractors from any other clade. Revert to nil when enhancement is decided.
    private static let dinoToolsCorrectCladeOnly: DinoClade? = .stegosaur

    /// Pool for correct dinosaur (egg must match). PoC: stegosaur only.
    private static var dinosaursWithDinoAndEgg: [Dinosaur] {
        baseDinosaursWithDinoAndEgg(allowedClades: dinoToolsCorrectCladeOnly.map { Set([$0]) })
    }

    /// Pool for distractors: any clade except the correct one.
    private static func dinosaursForDistractors(excludingClade excluded: DinoClade) -> [Dinosaur] {
        baseDinosaursWithDinoAndEgg(allowedClades: nil).filter { dino in
            LandDinosaurCladeCatalog.clade(forCreatureId: dino.id) != excluded
        }
    }

    private static func baseDinosaursWithDinoAndEgg(allowedClades: Set<DinoClade>?) -> [Dinosaur] {
        let excludedClades: Set<DinoClade> = [.spinosaurid, .pachycephalosaur]
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        return MatchingGameConfigs.allDinosaurs.filter { dino in
            let clade = cladeById[dino.id] ?? .theropod
            if let allowed = allowedClades, !allowed.contains(clade) { return false }
            guard !excludedClades.contains(clade) else { return false }
            let dinoName = dino.imageName ?? "dino-\(dino.id)"
            guard ImageAssetCache.imageExists(named: dinoName),
                  let eggType = EggMorphology.eggType(for: dino) else { return false }
            return ImageAssetCache.imageExists(named: "dino-eggs-\(eggType)")
        }
    }
}
