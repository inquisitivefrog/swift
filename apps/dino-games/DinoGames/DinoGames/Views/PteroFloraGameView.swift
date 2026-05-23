//
//  PteroFloraGameView.swift
//  DinoGames
//
//  Ptero Flora!: Same mechanic as Dino Flora — three rounds, pick 3 pterosaurs that “fit” the plant for the formation.
//  Karabastau formation (first shipped set): plants use `ptero-flora-{slug}-habitat` / `-seeds` imagesets.
//  Eater/decoy sets are morphotype-based heuristics until per-plant JSON is wired.
//

import SwiftUI

struct PteroFloraGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Flora (plant)

struct PteroFloraPlant: Identifiable {
    let id: String
    let displayName: String
    let treeImageName: String
    var seedsImageName: String { treeImageName.replacingOccurrences(of: "-habitat", with: "-seeds") }
    /// Prefer `ptero-flora-{slug}` → `Flora/Pterosaurs/karabastau/ptero-flora-{slug}.m4a` (see `SpeechManager` / `urlForAudio`); falls back to flat `Flora/Pterosaurs/…`, then spoken `displayName`.
    let audioKey: String
}

private enum PteroFloraMorphTables {
    private static func ids(in groups: Set<PterosaurGuessGroup>) -> Set<Int> {
        var s = Set<Int>()
        for d in MatchingGameConfigs.allPterosaurs {
            guard let img = d.imageName, let g = PterosaurGuessGroup.guessGroup(forImageName: img), groups.contains(g) else { continue }
            s.insert(d.id)
        }
        return s
    }

    /// Karabastau plants: who “fits” vs decoys (disjoint morphotype buckets for stable rounds).
    static let eatersByPlantId: [String: Set<Int>] = [
        "cycad": ids(in: [.basal, .tapejarid, .thalassodromid]),
        "ginkgoales": ids(in: [.transitional, .basal, .tapejarid]),
        "equisetites": ids(in: [.basal, .thalassodromid]),
        "araucariaceae": ids(in: [.azhdarchid, .ornithocheiroid]),
        "palm-like-leaves": ids(in: [.tapejarid, .basal]),
        "conifer": ids(in: [.azhdarchid, .basal, .tapejarid]),
        "early-angiosperm": ids(in: [.specialist, .basal, .thalassodromid]),
    ]

    static let nonEatersByPlantId: [String: Set<Int>] = [
        "cycad": ids(in: [.azhdarchid, .ornithocheiroid, .specialist, .transitional]),
        "ginkgoales": ids(in: [.azhdarchid, .ornithocheiroid, .specialist]),
        "equisetites": ids(in: [.azhdarchid, .ornithocheiroid, .specialist, .transitional, .tapejarid]),
        "araucariaceae": ids(in: [.basal, .tapejarid, .thalassodromid, .specialist, .transitional]),
        "palm-like-leaves": ids(in: [.azhdarchid, .ornithocheiroid, .specialist, .thalassodromid, .transitional]),
        "conifer": ids(in: [.specialist, .thalassodromid, .transitional, .ornithocheiroid]),
        "early-angiosperm": ids(in: [.azhdarchid, .ornithocheiroid, .tapejarid, .transitional]),
    ]
}

/// Karabastau formation — matches bundled `ptero-flora-*` habitat/seeds art for this formation.
private let pteroKarabastauPlants: [PteroFloraPlant] = [
    PteroFloraPlant(id: "cycad", displayName: "Cycads", treeImageName: "ptero-flora-cycad-habitat", audioKey: "ptero-flora-cycad"),
    PteroFloraPlant(id: "ginkgoales", displayName: "Ginkgoales", treeImageName: "ptero-flora-ginkgoales-habitat", audioKey: "ptero-flora-ginkgoales"),
    PteroFloraPlant(id: "equisetites", displayName: "Equisetites", treeImageName: "ptero-flora-karabastau-equisetites-habitat", audioKey: "ptero-flora-equisetites"),
    /// Imagesets use stem `ptero-flora-araucariacea-*` (catalog spelling); keep `id` / audioKey `araucariaceae` for logic + `Flora/Pterosaurs` audio.
    PteroFloraPlant(id: "araucariaceae", displayName: "Araucariaceae", treeImageName: "ptero-flora-araucariacea-habitat", audioKey: "ptero-flora-araucariaceae"),
    PteroFloraPlant(id: "palm-like-leaves", displayName: "Palm-like leaves", treeImageName: "ptero-flora-palm-like-leaves-habitat", audioKey: "ptero-flora-palm-like-leaves"),
    PteroFloraPlant(id: "conifer", displayName: "Conifer", treeImageName: "ptero-flora-karabastau-conifer-habitat", audioKey: "ptero-flora-conifer"),
    PteroFloraPlant(id: "early-angiosperm", displayName: "Early angiosperm", treeImageName: "ptero-flora-early-angiosperm-habitat", audioKey: "ptero-flora-early-angiosperm"),
]

private let pteroFloraPool: [Dinosaur] = {
    MatchingGameConfigs.allPterosaurs.filter { $0.imageName?.hasPrefix("ptero-") == true }
}()

private func pteroFloraEatsPlant(_ dino: Dinosaur, _ plant: PteroFloraPlant) -> Bool {
    PteroFloraMorphTables.eatersByPlantId[plant.id]?.contains(dino.id) ?? false
}

private let pteroFormationsStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5,
]

private func pteroFloraTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private struct PteroFloraSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private let pteroFloraCircleSize: CGFloat = 96

// MARK: - View

struct PteroFloraGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: PteroFloraGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var plant: PteroFloraPlant?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedCreatureIds: Set<Int> = []
    @State private var usedPlantIds: Set<String> = []
    @State private var victoryWalkPlants: [PteroFloraPlant] = []
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
                        onDismiss: { showSourceFloraHints = false },
                        hintGridIntroAudioKey: "game-ptero-flora-tap-the-plant-to-hear-description"
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
                .id("ptero-flora-victory")
        } else {
            VStack(spacing: 16) {
                if ImageAssetCache.imageExists(named: "game-ptero-flora") {
                    Image("game-ptero-flora")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                }
                ProgressView("Loading…")
                    .padding()
            }
        }
    }

    private func plantImage(_ p: PteroFloraPlant) -> some View {
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
        PteroFloraStarLayoutView(slots: slots, matchedIds: matchedIds, introHighlightIndex: introWalkIndex, tapHandler: PteroFloraTapHandler(perform: handleTap))
            .frame(height: 320)
            .padding(.horizontal)
    }

    private func handleTap(creature: Dinosaur) {
        guard !speechManager.isPlaying, let p = plant else { return }
        let isCorrect = pteroFloraEatsPlant(creature, p)
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

    private func pickPlantForRound(using rng: inout PteroFloraSeededRandomNumberGenerator) -> PteroFloraPlant {
        let notYetUsed = pteroKarabastauPlants.filter { !usedPlantIds.contains($0.id) }
        let pool = notYetUsed.isEmpty ? pteroKarabastauPlants : notYetUsed
        let withEnoughUnused = pool.filter { p in
            let eaters = PteroFloraMorphTables.eatersByPlantId[p.id] ?? []
            let nonEaters = PteroFloraMorphTables.nonEatersByPlantId[p.id] ?? []
            let inPool = pteroFloraPool.filter { eaters.contains($0.id) }
            let outPool = pteroFloraPool.filter { nonEaters.contains($0.id) }
            let inUnused = inPool.filter { !usedCreatureIds.contains($0.id) }
            let outUnused = outPool.filter { !usedCreatureIds.contains($0.id) }
            return inUnused.count >= 3 && outUnused.count >= 2
        }
        return (withEnoughUnused.randomElement(using: &rng) ?? pool.randomElement(using: &rng))!
    }

    private func buildSlotsForRound(using rng: inout PteroFloraSeededRandomNumberGenerator) {
        guard let p = plant else { return }
        let eaters = Set(PteroFloraMorphTables.eatersByPlantId[p.id] ?? [])
        let nonEaters = Set(PteroFloraMorphTables.nonEatersByPlantId[p.id] ?? [])
        let inPool = pteroFloraPool.filter { eaters.contains($0.id) }
        let outPool = pteroFloraPool.filter { nonEaters.contains($0.id) }
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
        var rng = PteroFloraSeededRandomNumberGenerator(seed: pteroFloraTimeSeed())
        plant = pickPlantForRound(using: &rng)
        usedPlantIds.insert(plant!.id)
        buildSlotsForRound(using: &rng)
        playPlantIntroThenWhichThreePterosaurs()
    }

    private func playPlantIntroThenWhichThreePterosaurs() {
        guard let p = plant else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playWhichThreePterosaursThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: p.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(p.displayName)
        }
    }

    private func playWhichThreePterosaursThenStartWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFloraHintThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-ptero-flora-which-three-pterosaurs") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Which three pterosaurs fit this plant?")
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
        var rng = PteroFloraSeededRandomNumberGenerator(seed: pteroFloraTimeSeed())
        usedPlantIds = []
        plant = pickPlantForRound(using: &rng)
        usedPlantIds.insert(plant!.id)
        currentRound = 1
        usedCreatureIds = []
        victoryWalkPlants = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        guard plant != nil else { return }
        playPlantIntroThenWhichThreePterosaurs()
    }

    // MARK: - End sequence (shared victory pipeline)

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
                    candidateSuccessImageNames: ["game-ptero-flora-success", "game-ptero-flora"],
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

    private func speakVictoryPlant(_ flora: PteroFloraPlant) {
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
                PterosaurProgress.notifyCompletionIfPterosaurGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                PterosaurProgress.notifyCompletionIfPterosaurGame(configId: self.gameConfig.id)
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            PterosaurProgress.notifyCompletionIfPterosaurGame(configId: gameConfig.id)
            isPresented = false
        }
    }
}

// MARK: - Star layout

private struct PteroFloraTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct PteroFloraStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: PteroFloraTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, creature in
                    PteroFloraCircleView(creature: creature, isMatched: matchedIds.contains(creature.id), isIntroHighlighted: introHighlightIndex == index)
                        .position(
                            x: geo.size.width / 2 + radius * CGFloat(cos(pteroFormationsStarAngles[index])),
                            y: geo.size.height / 2 + 20 + radius * CGFloat(sin(pteroFormationsStarAngles[index]))
                        )
                        .onTapGesture { tapHandler.perform(creature) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct PteroFloraCircleView: View {
    let creature: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = creature.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: pteroFloraCircleSize, height: pteroFloraCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: pteroFloraCircleSize, height: pteroFloraCircleSize)
                    .overlay(Text(creature.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2).frame(width: pteroFloraCircleSize, height: pteroFloraCircleSize))
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

enum PteroFloraGameConfigs {
    static let pteroFloraKarabastau = PteroFloraGameConfig(
        id: "ptero-flora",
        title: "Ptero Flora!",
        introAudio: "game-ptero-flora"
    )
}

#Preview("Ptero Flora") {
    PteroFloraGameView(isPresented: .constant(true), gameConfig: PteroFloraGameConfigs.pteroFloraKarabastau)
}
