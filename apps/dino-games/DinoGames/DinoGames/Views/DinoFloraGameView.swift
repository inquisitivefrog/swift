//
//  DinoFloraGameView.swift
//  DinoGames
//
//  Dino Flora: Pick a plant. Three rounds; each round: 5 dinos (3 that ate it, 2 that didn't).
//  Player selects the 3 that ate the plant. No repeat dinosaurs across rounds. Victory: shared `VictorySplitColumnView` + `LandGameVictorySuccessStingerThenContinue`.
//

import SwiftUI

struct DinoFloraGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Flora (plant)

struct DinoFloraPlant: Identifiable {
    let id: String
    /// Hyphen slug matching images/audio stem, e.g. `morrison`, `lance-hell-creek`.
    let formation: String
    /// Folder under `Audio/Dino-Flora/`, e.g. `Morrison`, `Lance_Hell_Creek`.
    let formationFolder: String
    /// Plant taxon slug in the asset stem, e.g. `cycad`, `herbaceous-fern`.
    let taxon: String
    let displayName: String

    /// Shared stem: `dino-flora-{formation}-{taxon}` (matches imagesets and `.m4a` filename).
    var assetStem: String { "dino-flora-\(formation)-\(taxon)" }
    var treeImageName: String { "\(assetStem)-habitat" }
    var seedsImageName: String { "\(assetStem)-seeds" }
    var audioKey: String { assetStem }
}

// MARK: - Data (from DINO_FLORA_DATA_MODEL.md; plant list in `LandGameDisplayMoment.swift`)

private let dinoFloraLowEaters: Set<Int> = [2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]
private let dinoFloraLowNonEaters: Set<Int> = [7, 14, 21, 23, 40, 43, 44]
private let dinoFloraTreeEaters: Set<Int> = [7, 14, 21, 23, 40, 44]
private let dinoFloraTreeNonEaters: Set<Int> = [2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 43, 45, 46, 47, 48, 49, 50, 51, 52, 53]
private let dinoFloraTreeFernEaters: Set<Int> = [2, 5, 7, 9, 10, 11, 13, 14, 21, 23, 25, 32, 35, 40, 44, 47, 48, 53]
private let dinoFloraTreeFernNonEaters: Set<Int> = [3, 8, 15, 16, 17, 43, 45, 46, 49, 50, 51, 52]
private let dinoFloraFernEaters: Set<Int> = [2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 43, 45, 46, 47, 48, 49, 50, 51, 52, 53]
private let dinoFloraFernNonEaters: Set<Int> = [7, 14, 21, 23, 40, 44]
private let dinoFloraMixedEaters: Set<Int> = [2, 5, 7, 9, 10, 11, 13, 14, 21, 23, 25, 32, 35, 40, 44, 47, 48, 53]
private let dinoFloraMixedNonEaters: Set<Int> = [3, 8, 15, 16, 17, 43, 45, 46, 49, 50, 51, 52]

/// Plant slug → dinosaur IDs that eat it. Low/ground plants: low browsers; tree plants: high browsers (sauropods).
private let floraEatersByPlant: [String: Set<Int>] = [
    "horsetails": dinoFloraLowEaters,
    "moss": dinoFloraLowEaters,
    "araucaria": dinoFloraTreeEaters,
    "ginkgo": dinoFloraTreeEaters,
    "cycads": dinoFloraLowEaters,
    "tree-fern": dinoFloraTreeFernEaters,
    "fern": dinoFloraFernEaters,
    "charophytes": dinoFloraLowEaters,
    "clubmoss": dinoFloraLowEaters,
    "equisetites": dinoFloraLowEaters,
    "fungi": dinoFloraLowEaters,
    "ginkgoites": dinoFloraTreeEaters,
    "liverwort": dinoFloraLowEaters,
    "magnoliid": dinoFloraTreeEaters,
    "paleopus": dinoFloraMixedEaters,
    "taxodium": dinoFloraTreeEaters,
    "totara": dinoFloraTreeEaters,
    "walnut": dinoFloraTreeEaters,
    "water-lilies": dinoFloraLowEaters,
    "azolla": dinoFloraLowEaters,
    "bennettitales": dinoFloraLowEaters,
    "birch": dinoFloraTreeEaters,
    "brachyphyllum": dinoFloraTreeEaters,
    "cypress": dinoFloraTreeEaters,
    "kauri": dinoFloraTreeEaters,
    "kelp": dinoFloraLowEaters,
    "laurel": dinoFloraTreeEaters,
    "magnolia": dinoFloraTreeEaters,
    "mamaku": dinoFloraTreeFernEaters,
    "metasequoia": dinoFloraTreeEaters,
    "oak": dinoFloraTreeEaters,
    "palm": dinoFloraTreeEaters,
    "ponga": dinoFloraTreeFernEaters,
    "redwood": dinoFloraTreeEaters,
    "rimu": dinoFloraTreeEaters,
    "sycamore": dinoFloraTreeEaters,
]

/// Plant slug → dinosaur IDs that don't eat it (decoys)
private let floraNonEatersByPlant: [String: Set<Int>] = [
    "horsetails": dinoFloraLowNonEaters,
    "moss": dinoFloraLowNonEaters,
    "araucaria": dinoFloraTreeNonEaters,
    "ginkgo": dinoFloraTreeNonEaters,
    "cycads": dinoFloraLowNonEaters,
    "tree-fern": dinoFloraTreeFernNonEaters,
    "fern": dinoFloraFernNonEaters,
    "charophytes": dinoFloraLowNonEaters,
    "clubmoss": dinoFloraLowNonEaters,
    "equisetites": dinoFloraLowNonEaters,
    "fungi": dinoFloraLowNonEaters,
    "ginkgoites": dinoFloraTreeNonEaters,
    "liverwort": dinoFloraLowNonEaters,
    "magnoliid": dinoFloraTreeNonEaters,
    "paleopus": dinoFloraMixedNonEaters,
    "taxodium": dinoFloraTreeNonEaters,
    "totara": dinoFloraTreeNonEaters,
    "walnut": dinoFloraTreeNonEaters,
    "water-lilies": dinoFloraLowNonEaters,
    "azolla": dinoFloraLowNonEaters,
    "bennettitales": dinoFloraLowNonEaters,
    "birch": dinoFloraTreeNonEaters,
    "brachyphyllum": dinoFloraTreeNonEaters,
    "cypress": dinoFloraTreeNonEaters,
    "kauri": dinoFloraTreeNonEaters,
    "kelp": dinoFloraLowNonEaters,
    "laurel": dinoFloraTreeNonEaters,
    "magnolia": dinoFloraTreeNonEaters,
    "mamaku": dinoFloraTreeFernNonEaters,
    "metasequoia": dinoFloraTreeNonEaters,
    "oak": dinoFloraTreeNonEaters,
    "palm": dinoFloraTreeNonEaters,
    "ponga": dinoFloraTreeFernNonEaters,
    "redwood": dinoFloraTreeNonEaters,
    "rimu": dinoFloraTreeNonEaters,
    "sycamore": dinoFloraTreeNonEaters,
]

/// Herbivore/omnivore pool for Dino Flora (IDs from data model)
private let dinoFloraPoolIds: Set<Int> = [2, 3, 5, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 21, 23, 25, 32, 35, 40, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53]

private let dinoFloraPool: [Dinosaur] = {
    MatchingGameConfigs.allDinosaurs.filter { dinoFloraPoolIds.contains($0.id) && ($0.imageName?.hasPrefix("dino-") == true) }
}()

private func dinoFloraEatsPlant(_ dino: Dinosaur, _ plant: DinoFloraPlant) -> Bool {
    floraEatersByPlant[plant.id]?.contains(dino.id) ?? false
}

private let dinoFormationsStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5
]

private func dinoFloraTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private let dinoFloraCircleSize: CGFloat = 96

// MARK: - View

struct DinoFloraGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoFloraGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var plant: DinoFloraPlant?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedDinosaurIds: Set<Int> = []
    @State private var usedPlantIds: Set<String> = []
    @State private var victoryWalkPlants: [DinoFloraPlant] = []
    @State private var matchedOrderThisRound: [Int] = []
    @State private var introWalkIndex: Int? = nil
    @State private var displayedDinoName: String? = nil
    @State private var guessChoiceTimer = GuessChoiceTimer()
    @State private var hasStartedGame = false
    /// When true, show the Source Plants hints overlay (browsers, periods, diets).
    @State private var showSourceFloraHints = false
    /// When true, show habitat image; oscillates between habitat and seeds every N seconds.
    @State private var showPlantHabitatImage = true

    private let totalRounds = 3
    /// Seconds to show each image before toggling. Oscillates habitat ↔ seeds until round ends. 3s is well below photosensitive epilepsy trigger range (5–30 Hz); 0.4s fade is safe.
    private let plantHabitatDisplaySeconds: Double = 3.0
    private let matchesNeededPerRound = 3

    var body: some View {
        NavigationView {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    guard !hasStartedGame else { return }
                    hasStartedGame = true
                    startGame()
                }
                .onDisappear {
                    hasStartedGame = false
                    speechManager.onAudioFinished = nil
                    speechManager.stopCurrentAudio()
                }
                .allowsHitTesting(!speechManager.isPlaying)
                .opacity(speechManager.isPlaying ? 0.85 : 1.0)
                .overlay(alignment: .topTrailing) {
                    if plant != nil, !isGameComplete {
                        GeometryReader { geo in
                            let safeWidth = max(geo.size.width, 1)
                            let playMaxScale: CGFloat = 1.85
                            let hintSide = GameCatalogImageMetrics.scaled(72, safeWidth: safeWidth, maxScale: playMaxScale)
                            let hintFont = GameCatalogImageMetrics.scaled(12, safeWidth: safeWidth, maxScale: playMaxScale)
                            Button {
                                guessChoiceTimer.pauseForHints()
                                showSourceFloraHints = true
                            } label: {
                                Text("Hints")
                                    .font(.system(size: hintFont, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: hintSide, height: hintSide)
                                    .background(Circle().fill(Color.blue))
                            }
                            .disabled(speechManager.isPlaying)
                            .opacity(speechManager.isPlaying ? 0.45 : 1.0)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                        }
                    }
                }
                .fullScreenCover(isPresented: $showSourceFloraHints) {
                    SourceFloraHintsView(
                        hints: LandGameDisplayMomentCatalog.dinoFloraCategoryHints,
                        title: SourceHintsTitles.plants,
                        onDismiss: {
                        guessChoiceTimer.resumeAfterHints()
                        showSourceFloraHints = false
                    })
                }
        }
        .gameSheetDismissDisabledWhileAudioPlaying(speechManager.isPlaying)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
            // Hidden during victory — `VictorySplitColumnView` shows `gameTitle` in recap; success card art includes the title.
            if !isGameComplete {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .padding(.top, 8)
            }
            gameBody
        }
    }

    @ViewBuilder
    private var gameBody: some View {
        if let p = plant, !isGameComplete {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let safeHeight = max(geometry.size.height, 1)
                // Phone-tuned baselines; grow on iPad when width/height allow (same idea as Dino Ages).
                let playMaxScale: CGFloat = 1.85
                let isPadCanvas = safeWidth > GameCatalogImageMetrics.phoneReferenceWidth
                let plantHeightFraction: CGFloat = isPadCanvas ? 0.40 : 0.30
                let plantWidthFraction: CGFloat = isPadCanvas ? 0.92 : 0.88
                let plantMaxW = min(
                    GameCatalogImageMetrics.scaled(isPadCanvas ? 460 : 380, safeWidth: safeWidth, maxScale: playMaxScale),
                    safeWidth * plantWidthFraction
                )
                let plantMaxH = min(
                    GameCatalogImageMetrics.scaled(isPadCanvas ? 280 : 240, safeWidth: safeWidth, maxScale: playMaxScale),
                    safeHeight * plantHeightFraction
                )
                let gridH = min(
                    GameCatalogImageMetrics.scaled(360, safeWidth: safeWidth, maxScale: playMaxScale),
                    safeHeight * (isPadCanvas ? 0.44 : 0.50)
                )
                let circleSize = GameCatalogImageMetrics.scaled(dinoFloraCircleSize, safeWidth: safeWidth, maxScale: playMaxScale)
                let starRadius = GameCatalogImageMetrics.scaled(100, safeWidth: safeWidth, maxScale: playMaxScale)
                let plantLabelFont = GameCatalogImageMetrics.scaled(22, safeWidth: safeWidth, maxScale: playMaxScale)
                let roundFont = GameCatalogImageMetrics.scaled(17, safeWidth: safeWidth, maxScale: playMaxScale)
                let critterNameFont = GameCatalogImageMetrics.scaled(20, safeWidth: safeWidth, maxScale: playMaxScale)
                let critterNameSlotH = max(28, critterNameFont + 12)
                let stackSpacing = GameCatalogImageMetrics.scaled(16, safeWidth: safeWidth, maxScale: playMaxScale)
                VStack(spacing: stackSpacing) {
                    plantImage(p, maxWidth: plantMaxW, maxHeight: plantMaxH)
                        .id(p.id)
                    Text(p.displayName)
                        .font(.system(size: plantLabelFont, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Round \(currentRound) of \(totalRounds)")
                        .font(.system(size: roundFont, weight: .semibold))
                        .foregroundColor(.secondary)
                    // Fixed-height slot for dinosaur name to prevent layout shift when name appears/disappears
                    ZStack {
                        if let name = displayedDinoName {
                            Text(name)
                                .font(.system(size: critterNameFont, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                    }
                    .frame(height: critterNameSlotH)
                    fiveStarLayout(height: gridH, circleSize: circleSize, radius: starRadius)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        } else if isGameComplete {
            endSequenceView
                .id("dino-flora-victory")
        } else {
            VStack(spacing: 16) {
                if ImageAssetCache.imageExists(named: "game-dino-flora") {
                    Image("game-dino-flora")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                }
                ProgressView("Loading…")
                    .padding()
            }
        }
    }

    private func dinoFloraResolvedAssetName(for p: DinoFloraPlant, habitat: Bool) -> String? {
        let name = habitat ? p.treeImageName : p.seedsImageName
        return ImageAssetCache.imageExists(named: name) ? name : nil
    }

    private func plantImage(_ p: DinoFloraPlant, maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        let habitat = showPlantHabitatImage
        let imageName = dinoFloraResolvedAssetName(for: p, habitat: habitat)
        return Group {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: min(260, maxWidth * 0.76), height: min(130, maxHeight * 0.6))
                    .overlay(Text(p.displayName).font(.title2))
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.4), value: showPlantHabitatImage)
        .onAppear {
            showPlantHabitatImage = true
        }
        .onChange(of: p.id) { _, _ in
            showPlantHabitatImage = true
        }
        .task(id: p.id) {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(plantHabitatDisplaySeconds * 1_000_000_000))
                if Task.isCancelled { break }
                showPlantHabitatImage.toggle()
            }
        }
    }

    private func fiveStarLayout(height: CGFloat, circleSize: CGFloat, radius: CGFloat) -> some View {
        DinoFloraStarLayoutView(
            slots: slots,
            matchedIds: matchedIds,
            introHighlightIndex: introWalkIndex,
            circleSize: circleSize,
            radius: radius,
            tapHandler: DinoFloraTapHandler(perform: handleTap)
        )
            .frame(height: height)
            .padding(.horizontal)
    }

    private func handleTap(dino: Dinosaur) {
        guard !speechManager.isPlaying, let p = plant else { return }
        let isCorrect = dinoFloraEatsPlant(dino, p)
        if isCorrect, matchedIds.contains(dino.id) {
            OrderedTouchFeedback.speak(OrderedTouchFeedback.pickAnotherOne, speechManager: speechManager)
            return
        }
        let elapsed = guessChoiceTimer.elapsed()
        if isCorrect {
            matchedIds.insert(dino.id)
            matchedOrderThisRound.append(dino.id)
        }
        displayedDinoName = dino.name
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(correct: isCorrect, elapsed: elapsed)
        }
        speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
    }

    private func playFeedbackAfterTap(correct: Bool, elapsed: TimeInterval) {
        let finish: () -> Void = {
            self.speechManager.onAudioFinished = nil
            self.displayedDinoName = nil
            if correct {
                self.guessChoiceTimer.start()
                if self.matchedIds.count >= self.matchesNeededPerRound {
                    self.finishRound()
                }
            }
        }
        if correct {
            OrderedTouchFeedback.speak(
                OrderedTouchFeedback.successMatchAudio(elapsed: elapsed),
                speechManager: speechManager,
                onFinished: finish
            )
        } else {
            OrderedTouchFeedback.speak(OrderedTouchFeedback.tryAgain, speechManager: speechManager, onFinished: finish)
        }
    }

    private func pickPlantForRound(using rng: inout SeededRandomNumberGenerator) -> DinoFloraPlant {
        let notYetUsed = dinoFloraPlants.filter { !usedPlantIds.contains($0.id) }
        let pool = notYetUsed.isEmpty ? dinoFloraPlants : notYetUsed
        let withEnoughUnused = pool.filter { p in
            let eaters = floraEatersByPlant[p.id] ?? []
            let nonEaters = floraNonEatersByPlant[p.id] ?? []
            let inPool = dinoFloraPool.filter { eaters.contains($0.id) }
            let outPool = dinoFloraPool.filter { nonEaters.contains($0.id) }
            let inUnused = inPool.filter { !usedDinosaurIds.contains($0.id) }
            let outUnused = outPool.filter { !usedDinosaurIds.contains($0.id) }
            return inUnused.count >= 3 && outUnused.count >= 2
        }
        return (withEnoughUnused.randomElement(using: &rng) ?? pool.randomElement(using: &rng))!
    }

    private func buildSlotsForRound(using rng: inout SeededRandomNumberGenerator) {
        guard let p = plant else { return }
        let eaters = Set(floraEatersByPlant[p.id] ?? [])
        let nonEaters = Set(floraNonEatersByPlant[p.id] ?? [])
        let inPool = dinoFloraPool.filter { eaters.contains($0.id) }
        let outPool = dinoFloraPool.filter { nonEaters.contains($0.id) }
        let inPreferred = inPool.filter { !usedDinosaurIds.contains($0.id) }
        let outPreferred = outPool.filter { !usedDinosaurIds.contains($0.id) }
        let inCandidates = inPreferred.count >= 3 ? inPreferred : inPool
        let outCandidates = outPreferred.count >= 2 ? outPreferred : outPool
        let corrects = Array(inCandidates.shuffled(using: &rng).prefix(3))
        let wrongs = Array(outCandidates.shuffled(using: &rng).prefix(2))
        guard corrects.count == 3, wrongs.count == 2 else {
            isGameComplete = true
            return
        }
        for d in corrects + wrongs { usedDinosaurIds.insert(d.id) }
        slots = (corrects + wrongs).shuffled(using: &rng)
        matchedIds = []
        matchedOrderThisRound = []
    }

    private func finishRound() {
        if let p = plant {
            victoryWalkPlants.append(p)
        }
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        var rng = SeededRandomNumberGenerator(seed: dinoFloraTimeSeed())
        plant = pickPlantForRound(using: &rng)
        usedPlantIds.insert(plant!.id)
        buildSlotsForRound(using: &rng)
        playPlantIntroThenWhichThreeDinosaurs()
    }

    private func playPlantIntroThenWhichThreeDinosaurs() {
        guard let p = plant else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playWhichThreeDinosaursThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: p.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(p.displayName)
        }
    }

    private func playWhichThreeDinosaursThenStartWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFloraHintThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-dino-flora-which-three-dinosaurs") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Which three dinosaurs ate this plant?")
        }
    }

    /// Plays game-hint then starts the dinosaur intro walk.
    private func playFloraHintThenStartWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-hint") {
            speechManager.playAudioFile(url: url)
        } else {
            startIntroWalk()
        }
    }

    private func startIntroWalk() {
        guard slots.count >= 5 else {
            return
        }
        introWalkIndex = 0
        displayedDinoName = slots[0].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[0].imageName ?? slots[0].name, fallbackText: slots[0].name)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedDinoName = nil
            guessChoiceTimer.start()
            return
        }
        introWalkIndex = next
        displayedDinoName = slots[next].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[next].imageName ?? slots[next].name, fallbackText: slots[next].name)
    }

    private func startGame() {
        var rng = SeededRandomNumberGenerator(seed: dinoFloraTimeSeed())
        usedPlantIds = []
        plant = pickPlantForRound(using: &rng)
        usedPlantIds.insert(plant!.id)
        currentRound = 1
        usedDinosaurIds = []
        victoryWalkPlants = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        guard plant != nil else { return }
        playPlantIntroThenWhichThreeDinosaurs()
    }

    // MARK: - End sequence (shared victory: recap walk → success stinger → good-job + crowd)

    private var endSequenceView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: victoryWalkPlants.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            scrollRows: {
                ForEach(Array(victoryWalkPlants.enumerated()), id: \.element.id) { index, flora in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: flora.id,
                            title: flora.displayName,
                            imageAssetName: flora.treeImageName,
                            fallbackEmoji: "🌿"
                        ),
                        isHighlighted: isHighlighted
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: ["game-dino-flora-success", "game-dino-flora"],
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
            if victoryWalkPlants.isEmpty {
                endSequenceStep = 2
            } else {
                speakVictoryPlant(victoryWalkPlants[0])
                speechManager.onAudioFinished = { self.advanceEndHighlight() }
            }
        }
    }

    private func speakVictoryPlant(_ flora: DinoFloraPlant) {
        if let url = speechManager.urlForAudio(key: flora.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(flora.displayName)
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryWalkPlants.count {
            speakVictoryPlant(victoryWalkPlants[endHighlightIndex])
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: gameConfig.id,
            isPresented: $isPresented,
            speechManager: speechManager
        )
    }
}

// MARK: - Star layout

private struct DinoFloraTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoFloraStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let circleSize: CGFloat
    let radius: CGFloat
    let tapHandler: DinoFloraTapHandler

    var body: some View {
        GeometryReader { geo in
            // Keep the star inside the allocated frame when circles grow on iPad.
            let maxRadius = max(0, min(geo.size.width, geo.size.height) / 2 - circleSize / 2 - 8)
            let fittedRadius = min(radius, maxRadius)
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
                    DinoFloraCircleView(
                        dino: dino,
                        isMatched: matchedIds.contains(dino.id),
                        isIntroHighlighted: introHighlightIndex == index,
                        size: circleSize
                    )
                        .position(
                            x: geo.size.width / 2 + fittedRadius * CGFloat(cos(dinoFormationsStarAngles[index])),
                            y: geo.size.height / 2 + 20 + fittedRadius * CGFloat(sin(dinoFormationsStarAngles[index]))
                        )
                        .onTapGesture { tapHandler.perform(dino) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct DinoFloraCircleView: View {
    let dino: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false
    var size: CGFloat = dinoFloraCircleSize

    var body: some View {
        Group {
            if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(Text(dino.icon).font(.system(size: size > 80 ? 32 : 24)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2).frame(width: size, height: size))
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

// MARK: - Source Plants Hints (Dino / Ptero / Marine Flora)

struct SourceFloraHintsView: View {
    var title: String = SourceHintsTitles.plants
    let hints: [LandGameDisplayTriad]
    let onDismiss: () -> Void
    /// Optional audio when the hints grid opens (e.g. Dino Flora `game-dino-flora-tap-the-image`, Ptero Flora `game-ptero-flora-tap-the-plant-to-hear-description`). nil = silent.
    var hintGridIntroAudioKey: String? = "game-dino-flora-tap-the-image"
    @State private var speechManager = SpeechManager()
    @State private var selectedHint: LandGameDisplayTriad?
    @State private var introPlayed = false

    init(
        hints: [LandGameDisplayTriad] = LandGameDisplayMomentCatalog.dinoFloraCategoryHints,
        title: String = SourceHintsTitles.plants,
        hintGridIntroAudioKey: String? = "game-dino-flora-tap-the-image",
        onDismiss: @escaping () -> Void
    ) {
        self.hints = hints
        self.title = title
        self.hintGridIntroAudioKey = hintGridIntroAudioKey
        self.onDismiss = onDismiss
    }

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
                SourceHintsScreenTitle(title: title, fontSize: titleFont)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                    ForEach(hints) { hint in
                        Button {
                            showHintDetail(hint)
                        } label: {
                            if ImageAssetCache.imageExists(named: hint.imageAssetName) {
                                Image(hint.imageAssetName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cardHeight)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: cardHeight)
                                    .overlay(Text(hint.displayText).font(.system(size: fallbackFont)).foregroundColor(.secondary))
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
        if let hint = selectedHint {
            GeometryReader { geometry in
                let safeWidth = max(geometry.size.width, 1)
                let detailSide = SourceHintsLayout.detailImageSide(safeWidth: safeWidth)
                let labelFont = SourceHintsLayout.detailLabelFont(safeWidth: safeWidth)
                VStack(spacing: 20) {
                    Spacer()
                    if ImageAssetCache.imageExists(named: hint.imageAssetName) {
                        Image(hint.imageAssetName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: detailSide, maxHeight: detailSide)
                    }
                    Text(hint.displayText)
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
        if let key = hintGridIntroAudioKey, let url = speechManager.urlForAudio(key: key) {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showHintDetail(_ hint: LandGameDisplayTriad) {
        selectedHint = hint
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            // Brief pause after audio so user can absorb the image before returning to grid
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                selectedHint = nil
            }
        }
        if let url = speechManager.urlForAudio(key: hint.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(hint.displayText)
        }
    }
}

// MARK: - Mechanics (test + catalog surface)

enum DinoFloraMechanics {
    static var registryFormationSlugs: Set<String> { Set(dinoFloraPlants.map(\.formation)) }
    static var registryPlantIds: Set<String> { Set(dinoFloraPlants.map(\.id)) }

    static var eaterMapPlantIds: Set<String> { Set(floraEatersByPlant.keys) }
    static var nonEaterMapPlantIds: Set<String> { Set(floraNonEatersByPlant.keys) }

    static func eaterIds(forPlantId id: String) -> Set<Int> {
        floraEatersByPlant[id] ?? []
    }

    static func nonEaterIds(forPlantId id: String) -> Set<Int> {
        floraNonEatersByPlant[id] ?? []
    }

    static func poolEaterCount(forPlantId id: String) -> Int {
        let eaters = eaterIds(forPlantId: id)
        return dinoFloraPool.filter { eaters.contains($0.id) }.count
    }

    static func poolNonEaterCount(forPlantId id: String) -> Int {
        let nonEaters = nonEaterIds(forPlantId: id)
        return dinoFloraPool.filter { nonEaters.contains($0.id) }.count
    }
}

// MARK: - Configs

enum DinoFloraGameConfigs {
    static let dinoFlora = DinoFloraGameConfig(
        id: "dino-flora",
        title: "Dino Flora!",
        introAudio: "game-dino-flora"
    )
}

#Preview {
    DinoFloraGameView(isPresented: .constant(true), gameConfig: DinoFloraGameConfigs.dinoFlora)
}
