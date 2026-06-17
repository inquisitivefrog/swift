//
//  MarineFloraGameView.swift
//  DinoGames
//
//  Marine Flora!: Same mechanic as Dino/Ptero Flora — three rounds, pick 3 marine reptiles that
//  “fit” the plant for the formation. Each round picks a fresh geological formation, then a plant
//  from that formation (one per formation today; multiple taxa per formation later).
//

import SwiftUI

struct MarineFloraGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Flora (plant)

struct MarineFloraPlant: Identifiable {
    let id: String
    /// Hyphen slug, e.g. `cambridge-greensand`, `blue-lias`.
    let formation: String
    /// Folder under `Audio/Marine-Flora/`, e.g. `Cambridge_Greensand`, `Blue_Lias`.
    let formationFolder: String
    /// Plant taxon slug in the asset stem, e.g. `seagrass`, `crinoid`.
    let taxon: String
    let displayName: String

    /// Shared stem: `marine-flora-{formation}-{taxon}` (matches imagesets and `.m4a` filename).
    var assetStem: String { "marine-flora-\(formation)-\(taxon)" }
    var treeImageName: String { "\(assetStem)-habitat" }
    var seedsImageName: String { "\(assetStem)-seeds" }
    var audioKey: String { assetStem }
}

private enum MarineFloraMorphTables {
    private static func ids(in clades: Set<String>) -> Set<Int> {
        var s = Set<Int>()
        for creature in SeaMarineReptileData.allMarineReptiles {
            guard let img = creature.imageName, img.hasPrefix("marine-") else { continue }
            if clades.contains(SeaMarineReptileData.marineCladeRawValue(for: creature)) {
                s.insert(creature.id)
            }
        }
        return s
    }

    private static let seagrassEaters = ids(in: ["plesio", "testu", "ichthyo", "hali", "notho"])
    private static let seagrassNonEaters = ids(in: ["mosa", "tylo", "plio", "pliop", "teleo", "thala"])
    private static let crinoidEaters = ids(in: ["plesio", "ichthyo", "notho"])
    private static let crinoidNonEaters = ids(in: ["mosa", "tylo", "plio", "pliop", "testu", "teleo", "hali", "thala", "basal"])
    private static let algaeEaters = ids(in: ["plesio", "ichthyo", "hali", "notho", "thala", "teleo"])
    private static let algaeNonEaters = ids(in: ["mosa", "tylo", "plio", "pliop", "testu", "basal"])
    private static let mangroveEaters = ids(in: ["notho", "thala", "testu", "hali", "basal"])
    private static let mangroveNonEaters = ids(in: ["mosa", "tylo", "plio", "ichthyo", "teleo", "pliop"])

    static let eatersByPlantId: [String: Set<Int>] = [
        "blue-lias-crinoid": crinoidEaters,
        "poseidon-shale-crinoid": crinoidEaters,
        "pierre-shale-algae": algaeEaters,
        "conway-seaweed": algaeEaters,
        "carlile-shale-brown-algae": algaeEaters,
        "ouled-abdoun-seagrass": seagrassEaters,
        "navesink-seagrass": seagrassEaters,
        "muwaqqar-chalk-seagrass": seagrassEaters,
        "cambridge-greensand-thalassotaenia-seagrass": seagrassEaters,
        "nkporo-shale-mangrove": mangroveEaters,
    ]

    static let nonEatersByPlantId: [String: Set<Int>] = [
        "blue-lias-crinoid": crinoidNonEaters,
        "poseidon-shale-crinoid": crinoidNonEaters,
        "pierre-shale-algae": algaeNonEaters,
        "conway-seaweed": algaeNonEaters,
        "carlile-shale-brown-algae": algaeNonEaters,
        "ouled-abdoun-seagrass": seagrassNonEaters,
        "navesink-seagrass": seagrassNonEaters,
        "muwaqqar-chalk-seagrass": seagrassNonEaters,
        "cambridge-greensand-thalassotaenia-seagrass": seagrassNonEaters,
        "nkporo-shale-mangrove": mangroveNonEaters,
    ]
}

private let marineFloraPool: [Dinosaur] = {
    SeaMarineReptileData.allMarineReptiles.filter { $0.imageName?.hasPrefix("marine-") == true }
}()

private func marineFloraFitsPlant(_ creature: Dinosaur, _ plant: MarineFloraPlant) -> Bool {
    MarineFloraMorphTables.eatersByPlantId[plant.id]?.contains(creature.id) ?? false
}

private let marineFloraStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5,
]

private func marineFloraTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private struct MarineFloraSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private let marineFloraCircleSize: CGFloat = 96

// MARK: - View

struct MarineFloraGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: MarineFloraGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var plant: MarineFloraPlant?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedCreatureIds: Set<Int> = []
    @State private var usedFormationSlugs: Set<String> = []
    @State private var victoryWalkPlants: [MarineFloraPlant] = []
    @State private var matchedOrderThisRound: [Int] = []
    @State private var introWalkIndex: Int? = nil
    @State private var displayedCreatureName: String? = nil
    @State private var hasStartedGame = false
    @State private var showSourceFloraHints = false
    @State private var showPlantHabitatImage = true

    private let totalRounds = 3
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
                    SourceFloraHintsView(
                        hints: LandGameDisplayMomentCatalog.marineFloraCategoryHints,
                        title: SourceHintsTitles.plants,
                        hintGridIntroAudioKey: "game-marine-flora-tap-the-plant-to-hear-description",
                        onDismiss: { showSourceFloraHints = false }
                    )
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
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
                ZStack {
                    if let name = displayedCreatureName {
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
                .id("marine-flora-victory")
        } else {
            VStack(spacing: 16) {
                if ImageAssetCache.imageExists(named: "game-marine-flora") {
                    Image("game-marine-flora")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                }
                ProgressView("Loading…")
                    .padding()
            }
        }
    }

    private func plantImage(_ p: MarineFloraPlant) -> some View {
        let imageName = showPlantHabitatImage ? p.treeImageName : p.seedsImageName
        return Group {
            if ImageAssetCache.imageExists(named: imageName) {
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
        MarineFloraStarLayoutView(
            slots: slots,
            matchedIds: matchedIds,
            introHighlightIndex: introWalkIndex,
            tapHandler: MarineFloraTapHandler(perform: handleTap)
        )
        .frame(height: 320)
        .padding(.horizontal)
    }

    private func handleTap(creature: Dinosaur) {
        guard !speechManager.isPlaying, let p = plant else { return }
        let isCorrect = marineFloraFitsPlant(creature, p)
        if isCorrect {
            if matchedIds.contains(creature.id) { return }
            matchedIds.insert(creature.id)
            matchedOrderThisRound.append(creature.id)
        }
        displayedCreatureName = creature.name
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(correct: isCorrect)
        }
        speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
    }

    private func playFeedbackAfterTap(correct: Bool) {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.displayedCreatureName = nil
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

    private func pickPlantForRound(using rng: inout MarineFloraSeededRandomNumberGenerator) -> MarineFloraPlant? {
        let unusedFormations = MarineFloraMechanics.shippedFormationSlugs.filter { !usedFormationSlugs.contains($0) }
        let formationPool = unusedFormations.isEmpty ? MarineFloraMechanics.shippedFormationSlugs : unusedFormations
        let viableFormations = formationPool.filter { formation in
            MarineFloraMechanics.shippedPlants(forFormation: formation).contains { plant in
                MarineFloraMechanics.plantHasRoundCapacity(plant, usedCreatureIds: usedCreatureIds)
            }
        }
        guard let formation = (viableFormations.randomElement(using: &rng) ?? formationPool.randomElement(using: &rng)) else {
            return nil
        }
        let plantsInFormation = MarineFloraMechanics.shippedPlants(forFormation: formation)
        let viablePlants = plantsInFormation.filter {
            MarineFloraMechanics.plantHasRoundCapacity($0, usedCreatureIds: usedCreatureIds)
        }
        return (viablePlants.randomElement(using: &rng) ?? plantsInFormation.randomElement(using: &rng))
    }

    private func buildSlotsForRound(using rng: inout MarineFloraSeededRandomNumberGenerator) {
        guard let p = plant else { return }
        let eaters = Set(MarineFloraMorphTables.eatersByPlantId[p.id] ?? [])
        let nonEaters = Set(MarineFloraMorphTables.nonEatersByPlantId[p.id] ?? [])
        let inPool = marineFloraPool.filter { eaters.contains($0.id) }
        let outPool = marineFloraPool.filter { nonEaters.contains($0.id) }
        let inPreferred = inPool.filter { !usedCreatureIds.contains($0.id) }
        let outPreferred = outPool.filter { !usedCreatureIds.contains($0.id) }
        let inCandidates = inPreferred.count >= 3 ? inPreferred : inPool
        let outCandidates = outPreferred.count >= 2 ? outPreferred : outPool
        let corrects = Array(inCandidates.shuffled(using: &rng).prefix(3))
        let wrongs = Array(outCandidates.shuffled(using: &rng).prefix(2))
        guard corrects.count == 3, wrongs.count == 2 else {
            isGameComplete = true
            return
        }
        for d in corrects + wrongs { usedCreatureIds.insert(d.id) }
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
        var rng = MarineFloraSeededRandomNumberGenerator(seed: marineFloraTimeSeed())
        guard let nextPlant = pickPlantForRound(using: &rng) else {
            isGameComplete = true
            return
        }
        plant = nextPlant
        usedFormationSlugs.insert(nextPlant.formation)
        buildSlotsForRound(using: &rng)
        playPlantIntroThenWhichThreeMarineReptiles()
    }

    private func playPlantIntroThenWhichThreeMarineReptiles() {
        guard let p = plant else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playWhichThreeMarineReptilesThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: p.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(p.displayName)
        }
    }

    private func playWhichThreeMarineReptilesThenStartWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFloraHintThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-marine-flora-which-three-marine-reptiles") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Which three marine reptiles fit this plant?")
        }
    }

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
        guard slots.count >= 5 else { return }
        introWalkIndex = 0
        displayedCreatureName = slots[0].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[0].imageName ?? slots[0].name, fallbackText: slots[0].name)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedCreatureName = nil
            return
        }
        introWalkIndex = next
        displayedCreatureName = slots[next].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[next].imageName ?? slots[next].name, fallbackText: slots[next].name)
    }

    private func startGame() {
        var rng = MarineFloraSeededRandomNumberGenerator(seed: marineFloraTimeSeed())
        usedFormationSlugs = []
        guard let firstPlant = pickPlantForRound(using: &rng) else {
            isGameComplete = true
            return
        }
        plant = firstPlant
        usedFormationSlugs.insert(firstPlant.formation)
        currentRound = 1
        usedCreatureIds = []
        victoryWalkPlants = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        playPlantIntroThenWhichThreeMarineReptiles()
    }

    // MARK: - End sequence

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
                    candidateSuccessImageNames: ["game-marine-flora-success", "game-marine-flora"],
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

    private func speakVictoryPlant(_ flora: MarineFloraPlant) {
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

private struct MarineFloraTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct MarineFloraStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: MarineFloraTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, creature in
                    MarineFloraCircleView(
                        creature: creature,
                        isMatched: matchedIds.contains(creature.id),
                        isIntroHighlighted: introHighlightIndex == index
                    )
                    .position(
                        x: geo.size.width / 2 + radius * CGFloat(cos(marineFloraStarAngles[index])),
                        y: geo.size.height / 2 + 20 + radius * CGFloat(sin(marineFloraStarAngles[index]))
                    )
                    .onTapGesture { tapHandler.perform(creature) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct MarineFloraCircleView: View {
    let creature: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = creature.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: marineFloraCircleSize, height: marineFloraCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: marineFloraCircleSize, height: marineFloraCircleSize)
                    .overlay(Text(creature.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2)
                .frame(width: marineFloraCircleSize, height: marineFloraCircleSize)
        )
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

// MARK: - Mechanics (test + catalog surface)

enum MarineFloraMechanics {
    /// Plants with bundled habitat + seeds art (gameplay pool grows as imagesets ship).
    static var shippedPlants: [MarineFloraPlant] {
        marineFloraPlants.filter { plant in
            ImageAssetCache.imageExists(named: plant.treeImageName)
                && ImageAssetCache.imageExists(named: plant.seedsImageName)
        }
    }

    /// Formation slugs that have at least one bundled plant (one round = one fresh formation).
    static var shippedFormationSlugs: [String] {
        Array(Set(shippedPlants.map(\.formation))).sorted()
    }

    static func shippedPlants(forFormation formation: String) -> [MarineFloraPlant] {
        shippedPlants.filter { $0.formation == formation }
    }

    static var shippedPlantIds: Set<String> { Set(shippedPlants.map(\.id)) }
    static var registryFormationSlugs: Set<String> { Set(marineFloraPlants.map(\.formation)) }
    static var eaterMapPlantIds: Set<String> { Set(MarineFloraMorphTables.eatersByPlantId.keys) }
    static var registryPlantIds: Set<String> { Set(marineFloraPlants.map(\.id)) }

    static func plantHasRoundCapacity(_ plant: MarineFloraPlant, usedCreatureIds: Set<Int>) -> Bool {
        let eaters = eaterIds(forPlantId: plant.id)
        let nonEaters = nonEaterIds(forPlantId: plant.id)
        let inUnused = marineFloraPool.filter { eaters.contains($0.id) && !usedCreatureIds.contains($0.id) }
        let outUnused = marineFloraPool.filter { nonEaters.contains($0.id) && !usedCreatureIds.contains($0.id) }
        let inPool = marineFloraPool.filter { eaters.contains($0.id) }
        let outPool = marineFloraPool.filter { nonEaters.contains($0.id) }
        let inCandidates = inUnused.count >= 3 ? inUnused : inPool
        let outCandidates = outUnused.count >= 2 ? outUnused : outPool
        return inCandidates.count >= 3 && outCandidates.count >= 2
    }

    static func eaterIds(forPlantId id: String) -> Set<Int> {
        MarineFloraMorphTables.eatersByPlantId[id] ?? []
    }

    static func nonEaterIds(forPlantId id: String) -> Set<Int> {
        MarineFloraMorphTables.nonEatersByPlantId[id] ?? []
    }

    static func poolEaterCount(forPlantId id: String) -> Int {
        let eaters = eaterIds(forPlantId: id)
        return marineFloraPool.filter { eaters.contains($0.id) }.count
    }

    static func poolNonEaterCount(forPlantId id: String) -> Int {
        let nonEaters = nonEaterIds(forPlantId: id)
        return marineFloraPool.filter { nonEaters.contains($0.id) }.count
    }
}

enum MarineFloraGameConfigs {
    static let marineFlora = MarineFloraGameConfig(
        id: "marine-flora",
        title: "Marine Flora!",
        introAudio: "game-marine-flora"
    )

    static var isPlayable: Bool {
        MarineFloraMechanics.shippedFormationSlugs.count >= 3
    }
}

#Preview("Marine Flora") {
    MarineFloraGameView(isPresented: .constant(true), gameConfig: MarineFloraGameConfigs.marineFlora)
}
