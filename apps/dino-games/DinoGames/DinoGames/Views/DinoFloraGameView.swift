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
    let displayName: String
    /// Image set: dino-flora-{slug}-habitat (plant in habitat)
    let treeImageName: String
    /// Image set: dino-flora-{slug}-seeds (derived from treeImageName)
    var seedsImageName: String { treeImageName.replacingOccurrences(of: "-habitat", with: "-seeds") }
    /// Audio key for plant intro, e.g. "flora-horsetails" → Flora/Dinosaurs/dino-flora-horsetails.m4a
    let audioKey: String
}

// MARK: - Data (from DINO_FLORA_DATA_MODEL.md)

private let dinoFloraPlants: [DinoFloraPlant] = [
    DinoFloraPlant(id: "horsetails", displayName: "Horsetails", treeImageName: "dino-flora-horsetail-habitat", audioKey: "flora-horsetails"),
    DinoFloraPlant(id: "moss", displayName: "Moss", treeImageName: "dino-flora-moss-habitat", audioKey: "flora-moss"),
    DinoFloraPlant(id: "araucaria", displayName: "Araucaria", treeImageName: "dino-flora-araucaria-habitat", audioKey: "flora-araucaria"),
    DinoFloraPlant(id: "ginkgo", displayName: "Ginkgo", treeImageName: "dino-flora-ginkgo-habitat", audioKey: "flora-ginkgo"),
    DinoFloraPlant(id: "cycads", displayName: "Cycads", treeImageName: "dino-flora-cycad-habitat", audioKey: "flora-cycads"),
    DinoFloraPlant(id: "tree-fern", displayName: "Tree Fern", treeImageName: "dino-flora-tree-fern-habitat", audioKey: "flora-tree-fern"),
    DinoFloraPlant(id: "fern", displayName: "Fern", treeImageName: "dino-flora-herbaceous-fern-habitat", audioKey: "flora-fern"),
    DinoFloraPlant(id: "charophytes", displayName: "Charophytes", treeImageName: "dino-flora-charophytes-habitat", audioKey: "flora-charophytes"),
    DinoFloraPlant(id: "clubmoss", displayName: "Clubmoss", treeImageName: "dino-flora-clubmoss-habitat", audioKey: "flora-clubmoss"),
    DinoFloraPlant(id: "equisetites", displayName: "Equisetites", treeImageName: "dino-flora-jiufotang-equisetites-habitat", audioKey: "flora-equisetites"),
    DinoFloraPlant(id: "fungi", displayName: "Fungi", treeImageName: "dino-flora-fungi-habitat", audioKey: "flora-fungi"),
    DinoFloraPlant(id: "ginkgoites", displayName: "Ginkgoites", treeImageName: "dino-flora-ginkgoites-habitat", audioKey: "flora-ginkgoites"),
    DinoFloraPlant(id: "liverwort", displayName: "Liverwort", treeImageName: "dino-flora-liverwort-habitat", audioKey: "flora-liverwort"),
    DinoFloraPlant(id: "magnoliid", displayName: "Magnoliid", treeImageName: "dino-flora-magnoliid-habitat", audioKey: "flora-magnoliid"),
    DinoFloraPlant(id: "paleopus", displayName: "Paleopus", treeImageName: "dino-flora-paleopus-habitat", audioKey: "flora-paleopus"),
    DinoFloraPlant(id: "taxodium", displayName: "Taxodium", treeImageName: "dino-flora-taxodium-habitat", audioKey: "flora-taxodium"),
    DinoFloraPlant(id: "totara", displayName: "Totara", treeImageName: "dino-flora-totara-habitat", audioKey: "flora-totara"),
    DinoFloraPlant(id: "walnut", displayName: "Walnut", treeImageName: "dino-flora-walnut-habitat", audioKey: "flora-walnut"),
    DinoFloraPlant(id: "water-lilies", displayName: "Water Lilies", treeImageName: "dino-flora-water-lilies-habitat", audioKey: "flora-water-lilies"),
]

/// Plant slug → dinosaur IDs that eat it. Low/ground plants: low browsers; tree plants: high browsers (sauropods).
private let floraEatersByPlant: [String: Set<Int>] = [
    "horsetails": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "moss": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "araucaria": Set([7, 14, 21, 23, 40, 44]),
    "ginkgo": Set([7, 14, 21, 23, 40, 44]),
    "cycads": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "tree-fern": Set([2, 5, 7, 9, 10, 11, 13, 14, 21, 23, 25, 32, 35, 40, 44, 47, 48, 53]),
    "fern": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 43, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "charophytes": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "clubmoss": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "equisetites": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "fungi": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "ginkgoites": Set([7, 14, 21, 23, 40, 44]),
    "liverwort": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
    "magnoliid": Set([7, 14, 21, 23, 40, 44]),
    "paleopus": Set([2, 5, 7, 9, 10, 11, 13, 14, 21, 23, 25, 32, 35, 40, 44, 47, 48, 53]),
    "taxodium": Set([7, 14, 21, 23, 40, 44]),
    "totara": Set([7, 14, 21, 23, 40, 44]),
    "walnut": Set([7, 14, 21, 23, 40, 44]),
    "water-lilies": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53]),
]

/// Plant slug → dinosaur IDs that don't eat it (decoys)
private let floraNonEatersByPlant: [String: Set<Int>] = [
    "horsetails": Set([7, 14, 21, 23, 40, 43, 44]),
    "moss": Set([7, 14, 21, 23, 40, 43, 44]),
    "araucaria": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "ginkgo": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "cycads": Set([7, 14, 21, 23, 40, 43, 44]),
    "tree-fern": Set([3, 8, 15, 16, 17, 43, 45, 46, 49, 50, 51, 52]),
    "fern": Set([7, 14, 21, 23, 40, 44]),
    "charophytes": Set([7, 14, 21, 23, 40, 43, 44]),
    "clubmoss": Set([7, 14, 21, 23, 40, 43, 44]),
    "equisetites": Set([7, 14, 21, 23, 40, 43, 44]),
    "fungi": Set([7, 14, 21, 23, 40, 43, 44]),
    "ginkgoites": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "liverwort": Set([7, 14, 21, 23, 40, 43, 44]),
    "magnoliid": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "paleopus": Set([3, 8, 15, 16, 17, 43, 45, 46, 49, 50, 51, 52]),
    "taxodium": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "totara": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "walnut": Set([2, 3, 5, 8, 9, 10, 11, 13, 15, 16, 17, 25, 32, 35, 45, 46, 47, 48, 49, 50, 51, 52, 53, 43]),
    "water-lilies": Set([7, 14, 21, 23, 40, 43, 44]),
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
    @State private var hasStartedGame = false
    /// When true, show the Source Flora hints overlay (browsers, periods, diets).
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
                        Button {
                            showSourceFloraHints = true
                        } label: {
                            Text("Hints")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Circle().fill(Color.blue))
                                .frame(width: 72, height: 72)
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                }
                .fullScreenCover(isPresented: $showSourceFloraHints) {
                    SourceFloraHintsView(onDismiss: { showSourceFloraHints = false })
                }
        }
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
            VStack(spacing: 6) {
                plantImage(p)
                    .id(p.id)
                Text(p.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                // Fixed-height slot for dinosaur name to prevent layout shift when name appears/disappears
                ZStack {
                    if let name = displayedDinoName {
                        Text(name)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .lineLimit(1)
                    }
                }
                .frame(height: 32)
                fiveStarLayout
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

    /// Jiufotang Equisetites imagesets use `dino-flora-jiufotang-equisetites-*`; keep legacy `dino-flora-equisetites-*` as fallback for older catalogs.
    private func dinoFloraResolvedAssetName(for p: DinoFloraPlant, habitat: Bool) -> String? {
        let primaryHabitat = p.treeImageName
        let primarySeeds = p.seedsImageName
        let candidates: [String] = {
            if p.id == "equisetites" {
                let legacyHabitat = "dino-flora-equisetites-habitat"
                let legacySeeds = "dino-flora-equisetites-seeds"
                return habitat ? [primaryHabitat, legacyHabitat] : [primarySeeds, legacySeeds]
            }
            return [habitat ? primaryHabitat : primarySeeds]
        }()
        return candidates.first { ImageAssetCache.imageExists(named: $0) }
    }

    private func plantImage(_ p: DinoFloraPlant) -> some View {
        let habitat = showPlantHabitatImage
        let imageName = dinoFloraResolvedAssetName(for: p, habitat: habitat)
        return Group {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 260, height: 130)
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

    private var fiveStarLayout: some View {
        DinoFloraStarLayoutView(slots: slots, matchedIds: matchedIds, introHighlightIndex: introWalkIndex, tapHandler: DinoFloraTapHandler(perform: handleTap))
            .frame(height: 320)
            .padding(.horizontal)
    }

    private func handleTap(dino: Dinosaur) {
        guard !speechManager.isPlaying, let p = plant else { return }
        let isCorrect = dinoFloraEatsPlant(dino, p)
        if isCorrect {
            if matchedIds.contains(dino.id) { return }
            matchedIds.insert(dino.id)
            matchedOrderThisRound.append(dino.id)
        }
        displayedDinoName = dino.name
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(correct: isCorrect)
        }
        speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
    }

    private func playFeedbackAfterTap(correct: Bool) {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.displayedDinoName = nil
            if correct, self.matchedIds.count >= self.matchesNeededPerRound {
                self.finishRound()
            }
        }
        if correct {
            speechManager.speak("great-match")
        } else {
            speechManager.speak("try-again")
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

// MARK: - Star layout

private struct DinoFloraTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoFloraStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: DinoFloraTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
                    DinoFloraCircleView(dino: dino, isMatched: matchedIds.contains(dino.id), isIntroHighlighted: introHighlightIndex == index)
                        .position(
                            x: geo.size.width / 2 + radius * CGFloat(cos(dinoFormationsStarAngles[index])),
                            y: geo.size.height / 2 + 20 + radius * CGFloat(sin(dinoFormationsStarAngles[index]))
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

    var body: some View {
        Group {
            if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoFloraCircleSize, height: dinoFloraCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoFloraCircleSize, height: dinoFloraCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2).frame(width: dinoFloraCircleSize, height: dinoFloraCircleSize))
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

// MARK: - Source Flora Hints (Dino Flora)

/// One hint category for the Source Flora hints grid. Uses image set source-flora-{id} and audio Flora/hint-{id}.m4a.
private struct SourceFloraHint: Identifiable {
    let id: String
    let imageName: String  // e.g. source-flora-browsers
    let displayName: String
    let audioKey: String  // e.g. flora-hint-browsers → Flora/hint-browsers.m4a
}

private let sourceFloraHints: [SourceFloraHint] = [
    SourceFloraHint(id: "browsers", imageName: "source-flora-browsers", displayName: "Browsers", audioKey: "flora-hint-browsers"),
    SourceFloraHint(id: "periods", imageName: "source-flora-periods", displayName: "Periods", audioKey: "flora-hint-periods"),
    SourceFloraHint(id: "diets", imageName: "source-flora-diets", displayName: "Diets", audioKey: "flora-hint-diets"),
]

struct SourceFloraHintsView: View {
    let onDismiss: () -> Void
    /// Optional audio when the hints grid opens (e.g. Dino Flora `game-dino-flora-tap-the-image`, Ptero Flora `game-ptero-flora-tap-the-plant-to-hear-description`). nil = silent.
    var hintGridIntroAudioKey: String? = "game-dino-flora-tap-the-image"
    @State private var speechManager = SpeechManager()
    @State private var selectedHint: SourceFloraHint?
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
        VStack(spacing: 20) {
            Text("Source Flora")
                .font(.title2.weight(.semibold))
                .padding(.top, 44)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(sourceFloraHints) { hint in
                    Button {
                        showHintDetail(hint)
                    } label: {
                        if ImageAssetCache.imageExists(named: hint.imageName) {
                            Image(hint.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 120)
                                .overlay(Text(hint.displayName).font(.caption).foregroundColor(.secondary))
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
                        .frame(maxWidth: 320, maxHeight: 320)
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
        if let key = hintGridIntroAudioKey, let url = speechManager.urlForAudio(key: key) {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showHintDetail(_ hint: SourceFloraHint) {
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
            speechManager.speak(hint.displayName)
        }
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
