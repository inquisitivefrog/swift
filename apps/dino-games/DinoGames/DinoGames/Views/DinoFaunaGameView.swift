//
//  DinoFaunaGameView.swift
//  DinoGames
//
//  Dino Fauna: Pick a small animal. Five rounds; each round: 5 dinos (3 that could prey on / interact with it, 2 that don't fit).
//  Player selects the 3 correct dinosaurs. No repeat dinosaurs across rounds. Victory: list 15 selected, success card, crowd cheer.
//

import SwiftUI

struct DinoFaunaGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Fauna species

struct DinoFaunaSpecies: Identifiable {
    let id: String
    /// Image set: fauna-{id}-habitat
    var habitatImageName: String { "fauna-\(id)-habitat" }
    /// Image set: fauna-{id}-behavior
    var behaviorImageName: String { "fauna-\(id)-behavior" }
    /// SpeechManager key → Audio/Fauna/{id}.m4a
    var audioKey: String { "fauna-\(id)" }
    var displayName: String {
        id.split(separator: "-").map(\.localizedCapitalized).joined(separator: " ")
    }
}

private enum FaunaPreyCategory {
    /// Insects and similar land prey: carnivores, insectivores, omnivores.
    case landInvertebrate
    /// Fish: piscivores and carnivores.
    case fish
    /// Turtles, crocs, etc.: carnivores, piscivores, omnivores.
    case aquaticSmallVertebrate
    /// Lizards, snakes, birds, small mammals: carnivores, omnivores, insectivores.
    case landSmallVertebrate
}

private func faunaPreyCategory(for slug: String) -> FaunaPreyCategory {
    switch slug {
    case "lungfish": return .fish
    case "chelid-turtle", "cretaceous-crocodylomorph", "araripesuchus": return .aquaticSmallVertebrate
    case "cretaceous-squamate", "najash", "lepidosaur", "dinilysia", "cretaceous-enantiornithes", "cronopio",
         "buitreraptor", "gaspirinisaura", "meridiolestidan":
        return .landSmallVertebrate
    default:
        return .landInvertebrate
    }
}

/// Prompt after species intro: bugs vs other small fauna → `Games/game-dino-fauna-which-three-dinosaurs-{bugs|animals}.m4a`.
private func whichThreeFaunaPromptAudioKey(for species: DinoFaunaSpecies) -> String {
    switch faunaPreyCategory(for: species.id) {
    case .landInvertebrate:
        return "game-dino-fauna-which-three-dinosaurs-bugs"
    case .fish, .aquaticSmallVertebrate, .landSmallVertebrate:
        return "game-dino-fauna-which-three-dinosaurs-animals"
    }
}

private func faunaDietSets(for category: FaunaPreyCategory) -> (eaters: Set<String>, nonEaters: Set<String>) {
    switch category {
    case .landInvertebrate:
        return (Set(["Carnivore", "Insectivore", "Omnivore"]), Set(["Herbivore", "Piscivore"]))
    case .fish:
        return (Set(["Carnivore", "Piscivore"]), Set(["Herbivore", "Insectivore"]))
    case .aquaticSmallVertebrate:
        return (Set(["Carnivore", "Piscivore", "Omnivore"]), Set(["Herbivore", "Insectivore"]))
    case .landSmallVertebrate:
        return (Set(["Carnivore", "Omnivore", "Insectivore"]), Set(["Herbivore", "Piscivore"]))
    }
}

private let dinoFaunaSpeciesIds: [String] = [
    "araripesuchus", "buitreraptor", "caddisfly", "chelid-turtle", "cockroach", "cretaceous-antlions",
    "cretaceous-beetle-carabidae", "cretaceous-beetle-coleoptera", "cretaceous-cicada", "cretaceous-cranefly",
    "cretaceous-crocodylomorph", "cretaceous-dragonfly", "cretaceous-enantiornithes", "cretaceous-predatory-wasp",
    "cretaceous-scorpion", "cretaceous-squamate", "cretaceous-termite", "cretaceous-wasp-hymenoptera",
    "cronopio", "dinilysia", "gaspirinisaura", "giant-waterbug", "lepidosaur", "lungfish", "meridiolestidan",
    "najash", "primitive-bee", "primitive-sphecomyrminae", "sand-burrowing-beetle", "water-beetle",
]

private let dinoFaunaSpeciesList: [DinoFaunaSpecies] = dinoFaunaSpeciesIds.map { DinoFaunaSpecies(id: $0) }

private let dinoFaunaPool: [Dinosaur] = {
    MatchingGameConfigs.allDinosaurs.filter { dino in
        guard dino.imageName?.hasPrefix("dino-") == true else { return false }
        return MatchingGameConfigs.dinosaurDietById[dino.id] != nil
    }
}()

private func dinoFaunaIdsEatingSpecies(_ species: DinoFaunaSpecies) -> Set<Int> {
    let diets = faunaDietSets(for: faunaPreyCategory(for: species.id)).eaters
    return Set(dinoFaunaPool.compactMap { dino in
        guard let d = MatchingGameConfigs.dinosaurDietById[dino.id], diets.contains(d) else { return nil }
        return dino.id
    })
}

private func dinoFaunaIdsNotEatingSpecies(_ species: DinoFaunaSpecies) -> Set<Int> {
    let diets = faunaDietSets(for: faunaPreyCategory(for: species.id)).nonEaters
    return Set(dinoFaunaPool.compactMap { dino in
        guard let d = MatchingGameConfigs.dinosaurDietById[dino.id], diets.contains(d) else { return nil }
        return dino.id
    })
}

private func dinoFaunaWouldInteract(_ dino: Dinosaur, _ species: DinoFaunaSpecies) -> Bool {
    dinoFaunaIdsEatingSpecies(species).contains(dino.id)
}

private let dinoFaunaStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5,
]

private func dinoFaunaTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private struct FaunaSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private let dinoFaunaCircleSize: CGFloat = 96

// MARK: - View

struct DinoFaunaGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoFaunaGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var species: DinoFaunaSpecies?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedDinosaurIds: Set<Int> = []
    @State private var usedSpeciesIds: Set<String> = []
    @State private var victoryWalkDinosaurs: [Dinosaur] = []
    @State private var matchedOrderThisRound: [Int] = []
    @State private var introWalkIndex: Int? = nil
    @State private var displayedDinoName: String? = nil
    @State private var hasStartedGame = false
    /// Habitat vs behavior image toggle.
    @State private var showFaunaHabitatImage = true

    private let totalRounds = 5
    private let faunaHabitatDisplaySeconds: Double = 3.0
    private let matchesNeededPerRound = 3

    private var matchedDinosaursThisRoundInTapOrder: [Dinosaur] {
        matchedOrderThisRound.compactMap { id in slots.first { $0.id == id } }
    }

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
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 20) {
            Text(gameConfig.title)
                .font(.largeTitle)
                .padding(.top, 8)
            gameBody
        }
    }

    @ViewBuilder
    private var gameBody: some View {
        if let s = species, !isGameComplete {
            VStack(spacing: 6) {
                faunaImagePair(s)
                    .id(s.id)
                Text(s.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
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
                .id("dino-fauna-victory")
        } else {
            VStack(spacing: 16) {
                if ImageAssetCache.imageExists(named: "game-dino-fauna") {
                    Image("game-dino-fauna")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                }
                ProgressView("Loading…")
                    .padding()
            }
        }
    }

    private func faunaImagePair(_ s: DinoFaunaSpecies) -> some View {
        let imageName = showFaunaHabitatImage ? s.habitatImageName : s.behaviorImageName
        return Group {
            if ImageAssetCache.imageExists(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 260, height: 130)
                    .overlay(Text(s.displayName).font(.title2))
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.4), value: showFaunaHabitatImage)
        .onAppear {
            showFaunaHabitatImage = true
        }
        .onChange(of: s.id) { _, _ in
            showFaunaHabitatImage = true
        }
        .task(id: s.id) {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(faunaHabitatDisplaySeconds * 1_000_000_000))
                if Task.isCancelled { break }
                showFaunaHabitatImage.toggle()
            }
        }
    }

    private var fiveStarLayout: some View {
        DinoFaunaStarLayoutView(slots: slots, matchedIds: matchedIds, introHighlightIndex: introWalkIndex, tapHandler: DinoFaunaTapHandler(perform: handleTap))
            .frame(height: 320)
            .padding(.horizontal)
    }

    private func handleTap(dino: Dinosaur) {
        guard !speechManager.isPlaying, let s = species else { return }
        let isCorrect = dinoFaunaWouldInteract(dino, s)
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

    private func pickSpeciesForRound(using rng: inout FaunaSeededRandomNumberGenerator) -> DinoFaunaSpecies {
        let notYetUsed = dinoFaunaSpeciesList.filter { !usedSpeciesIds.contains($0.id) }
        let pool = notYetUsed.isEmpty ? dinoFaunaSpeciesList : notYetUsed
        let withEnoughUnused = pool.filter { s in
            let eaters = dinoFaunaIdsEatingSpecies(s)
            let nonEaters = dinoFaunaIdsNotEatingSpecies(s)
            let inPool = dinoFaunaPool.filter { eaters.contains($0.id) }
            let outPool = dinoFaunaPool.filter { nonEaters.contains($0.id) }
            let inUnused = inPool.filter { !usedDinosaurIds.contains($0.id) }
            let outUnused = outPool.filter { !usedDinosaurIds.contains($0.id) }
            return inUnused.count >= 3 && outUnused.count >= 2
        }
        return (withEnoughUnused.randomElement(using: &rng) ?? pool.randomElement(using: &rng))!
    }

    private func buildSlotsForRound(using rng: inout FaunaSeededRandomNumberGenerator) {
        guard let s = species else { return }
        let eaters = dinoFaunaIdsEatingSpecies(s)
        let nonEaters = dinoFaunaIdsNotEatingSpecies(s)
        let inPool = dinoFaunaPool.filter { eaters.contains($0.id) }
        let outPool = dinoFaunaPool.filter { nonEaters.contains($0.id) }
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
        let matchedOrdered = matchedDinosaursThisRoundInTapOrder
        victoryWalkDinosaurs.append(contentsOf: matchedOrdered)
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        var rng = FaunaSeededRandomNumberGenerator(seed: dinoFaunaTimeSeed())
        species = pickSpeciesForRound(using: &rng)
        usedSpeciesIds.insert(species!.id)
        buildSlotsForRound(using: &rng)
        playSpeciesIntroThenWhichThreeDinosaurs()
    }

    private func playSpeciesIntroThenWhichThreeDinosaurs() {
        guard let s = species else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playWhichThreeDinosaursThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: s.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(s.displayName)
        }
    }

    private func playWhichThreeDinosaursThenStartWalk() {
        guard let s = species else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFaunaHintThenStartWalk()
        }
        let key = whichThreeFaunaPromptAudioKey(for: s)
        if let url = speechManager.urlForAudio(key: key) {
            speechManager.playAudioFile(url: url)
        } else if let url = speechManager.urlForAudio(key: "game-dino-fauna-which-three-dinosaurs") {
            speechManager.playAudioFile(url: url)
        } else if faunaPreyCategory(for: s.id) == .landInvertebrate {
            speechManager.speak("Which three dinosaurs would eat these bugs?")
        } else {
            speechManager.speak("Which three dinosaurs would eat these animals?")
        }
    }

    private func playFaunaHintThenStartWalk() {
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
        var rng = FaunaSeededRandomNumberGenerator(seed: dinoFaunaTimeSeed())
        usedSpeciesIds = []
        species = pickSpeciesForRound(using: &rng)
        usedSpeciesIds.insert(species!.id)
        currentRound = 1
        usedDinosaurIds = []
        victoryWalkDinosaurs = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        guard species != nil else { return }
        playSpeciesIntroThenWhichThreeDinosaurs()
    }

    // MARK: - End sequence

    private let victoryRowHeight: CGFloat = 72
    private var victoryListVisibleHeight: CGFloat { 16 + 3 * victoryRowHeight + 2 * 12 + 16 }

    private var endSequenceView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(victoryListDinosaurs.enumerated()), id: \.offset) { index, dino in
                                DinoFaunaEndRowView(dino: dino, isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .scrollIndicators(.visible)
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: endHighlightIndex) { _, newValue in
                        guard newValue < victoryListDinosaurs.count else { return }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        dinoFaunaSuccessImageView
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
            if victoryListDinosaurs.isEmpty {
                endSequenceStep = 2
            } else {
                let d = victoryListDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { self.advanceEndHighlight() }
            }
        }
    }

    private var dinoFaunaSuccessImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-fauna-success") {
                Image("game-dino-fauna-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🦎")
                    .font(.system(size: 100))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var victoryListDinosaurs: [Dinosaur] { victoryWalkDinosaurs }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryListDinosaurs.count {
            let d = victoryListDinosaurs[endHighlightIndex]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
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

private struct DinoFaunaTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoFaunaStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: DinoFaunaTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
                    DinoFaunaCircleView(dino: dino, isMatched: matchedIds.contains(dino.id), isIntroHighlighted: introHighlightIndex == index)
                        .position(
                            x: geo.size.width / 2 + radius * CGFloat(cos(dinoFaunaStarAngles[index])),
                            y: geo.size.height / 2 + 20 + radius * CGFloat(sin(dinoFaunaStarAngles[index]))
                        )
                        .onTapGesture { tapHandler.perform(dino) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct DinoFaunaCircleView: View {
    let dino: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoFaunaCircleSize, height: dinoFaunaCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoFaunaCircleSize, height: dinoFaunaCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2).frame(width: dinoFaunaCircleSize, height: dinoFaunaCircleSize))
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

private let dinoFaunaVictoryImageSize: CGFloat = 72

private struct DinoFaunaEndRowView: View {
    let dino: Dinosaur
    let isHighlighted: Bool
    private let rowHeight: CGFloat = 92

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: dinoFaunaVictoryImageSize, height: dinoFaunaVictoryImageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                } else {
                    Text(dino.icon)
                        .font(.system(size: 40))
                        .frame(width: dinoFaunaVictoryImageSize, height: dinoFaunaVictoryImageSize)
                        .opacity(isHighlighted ? 1.0 : 0.4)
                }
            }
            Text(dino.name)
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
}

// MARK: - Configs

enum DinoFaunaGameConfigs {
    static let dinoFauna = DinoFaunaGameConfig(
        id: "dino-fauna",
        title: "Dino Fauna!",
        introAudio: "game-dino-fauna"
    )
}

#Preview {
    DinoFaunaGameView(isPresented: .constant(true), gameConfig: DinoFaunaGameConfigs.dinoFauna)
}
