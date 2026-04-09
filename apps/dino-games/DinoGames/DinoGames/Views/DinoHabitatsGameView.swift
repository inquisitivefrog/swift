//
//  DinoHabitatsGameView.swift
//  DinoGames
//
//  Dino Habitats: Three rounds; each round shows a habitat image with text and audio. Player identifies which of 3 dinosaurs prefers that habitat.
//  No repeat habitats across rounds. Wrong choice = warning; right choice = compliment. After 3 correct dinosaurs, victory: walk list, crowd cheers, success card.
//

import SwiftUI

struct DinoHabitatsGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Habitat

struct DinoHabitat: Identifiable {
    let id: String
    /// Scientific/technical display name, e.g. "Seasonal River Plains"
    let name: String
    /// Kid-friendly nickname (forest, desert, beach, meadow, etc.) for 4–6 year olds. Prefer when audio exists.
    let nickname: String?
    /// Asset name for habitat image, e.g. "dino-habitats-seasonal-river-plains"
    let imageName: String
    /// Audio key for habitat name, e.g. "habitat-name-seasonal-river-plains"
    let habitatNameAudioKey: String
    /// Audio key for nickname. Uses nickname (e.g. "meadow") when present so Habitats/nickname-meadow.m4a is found; else id.
    var habitatNicknameAudioKey: String {
        if let nick = nickname, !nick.isEmpty {
            return "habitat-nickname-\(nick.lowercased())"
        }
        return "habitat-nickname-\(id)"
    }
    /// Dino image set names (dino-*) that prefer this habitat.
    let dinoImageNames: Set<String>
}

/// JSON format for habitat files. Supports both:
/// - json/habitats format: habitat_id, substrate, visuals; optional name, dinoImageNames
/// - Game format: name, dinoImageNames (required for playable)
private struct HabitatJSON: Decodable {
    let habitat_id: String?
    let name: String?
    let dinoImageNames: [String]?
    let substrate: String?
    let physics: [String: String]?
    let visuals: HabitatVisuals?
}
private struct HabitatVisuals: Decodable {
    let ground: String?
    let water: String?
}

/// Derive display name from habitat_id (e.g. "DESERT_DUNE_FIELDS" → "Desert Dune Fields").
private func habitatDisplayName(from habitatId: String) -> String {
    habitatId.lowercased()
        .replacingOccurrences(of: "_", with: " ")
        .split(separator: " ")
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined(separator: " ")
}

/// Habitats: load from json/habitats/*.json first, then Habitats/*.json. Each habitat needs dinoImageNames (≥1) to be playable.
private let dinoHabitatsList: [DinoHabitat] = {
    var list: [DinoHabitat] = []
    let subdirs = ["json/habitats", "Habitats"]
    for subdir in subdirs {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subdir) else { continue }
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let id = url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "_", with: "-")
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONDecoder().decode(HabitatJSON.self, from: data) else { continue }
            let dinoNames = json.dinoImageNames ?? []
            guard !dinoNames.isEmpty else { continue }
            let name = json.name ?? (json.habitat_id.map { habitatDisplayName(from: $0) } ?? id)
            list.append(DinoHabitat(
                id: id,
                name: name,
                nickname: nil,
                imageName: "dino-habitat-\(id)",
                habitatNameAudioKey: "habitat-name-\(id)",
                dinoImageNames: Set(dinoNames)
            ))
        }
        if !list.isEmpty { break }
    }
    let poolImageNames = Set(dinoHabitatsPool.compactMap(\.imageName))
    list = list.filter { habitat in
        habitat.dinoImageNames.contains { poolImageNames.contains($0) }
    }
    return list.isEmpty ? fallbackHabitatsList : list
}()

/// Derive display name from habitat id (e.g. "seasonal-river-plains" → "Seasonal River Plains").
private func habitatDisplayNameFromId(_ id: String) -> String {
    id.replacingOccurrences(of: "-", with: " ")
        .split(separator: " ")
        .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        .joined(separator: " ")
}

/// Kid-friendly nicknames for habitats (forest, desert, beach, meadow, etc.) — familiar from Dinosaur Train, Wild Kratts.
/// Prefer nickname when Habitats/nickname-{slug}.m4a exists; else fall back to scientific name.
private let fallbackHabitatsList: [DinoHabitat] = [
    DinoHabitat(id: "seasonal-river-plains", name: habitatDisplayNameFromId("seasonal-river-plains"), nickname: "Meadow", imageName: "dino-habitats-open-woodland-plains", habitatNameAudioKey: "habitat-name-seasonal-river-plains", dinoImageNames: ["dino-edmontosaurus", "dino-triceratops", "dino-ankylosaurus", "dino-parasaurolophus", "dino-pachycephalosaurus"]),
    DinoHabitat(id: "seasonal-tropical-scrub", name: habitatDisplayNameFromId("seasonal-tropical-scrub"), nickname: "Rainforest", imageName: "dino-habitats-seasonal-tropical-scrub", habitatNameAudioKey: "habitat-name-seasonal-tropical-scrub", dinoImageNames: ["dino-gallimimus", "dino-velociraptor", "dino-deinonychus", "dino-oviraptor", "dino-majungasaurus"]),
    DinoHabitat(id: "semi-arid-floodplains", name: habitatDisplayNameFromId("semi-arid-floodplains"), nickname: "Valley", imageName: "dino-habitats-semi-arid-floodplains", habitatNameAudioKey: "habitat-name-semi-arid-floodplains", dinoImageNames: ["dino-edmontosaurus", "dino-parasaurolophus", "dino-iguanodon", "dino-triceratops", "dino-ankylosaurus"]),
    DinoHabitat(id: "semi-arid-plains", name: habitatDisplayNameFromId("semi-arid-plains"), nickname: "Desert", imageName: "dino-habitats-semi-arid-plains", habitatNameAudioKey: "habitat-name-semi-arid-plains", dinoImageNames: ["dino-gallimimus", "dino-velociraptor", "dino-deinonychus", "dino-oviraptor", "dino-majungasaurus"]),
    DinoHabitat(id: "semi-arid-seasonal-floodplains", name: habitatDisplayNameFromId("semi-arid-seasonal-floodplains"), nickname: "Plains", imageName: "dino-habitats-semi-arid-seasonal-floodplains", habitatNameAudioKey: "habitat-name-semi-arid-seasonal-floodplains", dinoImageNames: ["dino-triceratops", "dino-edmontosaurus", "dino-ankylosaurus", "dino-pachycephalosaurus", "dino-torosaurus"]),
    DinoHabitat(id: "subtropical-coastal-plains", name: habitatDisplayNameFromId("subtropical-coastal-plains"), nickname: "Beach", imageName: "dino-habitats-subtropical-coastal-plains", habitatNameAudioKey: "habitat-name-subtropical-coastal-plains", dinoImageNames: ["dino-spinosaurus", "dino-baryonyx", "dino-iguanodon", "dino-parasaurolophus", "dino-edmontosaurus"]),
    DinoHabitat(id: "tropical-island-lagoon", name: habitatDisplayNameFromId("tropical-island-lagoon"), nickname: "Lagoon", imageName: "dino-habitats-tropical-island-lagoon", habitatNameAudioKey: "habitat-name-tropical-island-lagoon", dinoImageNames: ["dino-spinosaurus", "dino-baryonyx", "dino-iguanodon", "dino-parasaurolophus", "dino-edmontosaurus"]),
    DinoHabitat(id: "warm-fluvial-plains", name: habitatDisplayNameFromId("warm-fluvial-plains"), nickname: "River", imageName: "dino-habitats-warm-fluvial-plains", habitatNameAudioKey: "habitat-name-warm-fluvial-plains", dinoImageNames: ["dino-trex", "dino-triceratops", "dino-edmontosaurus", "dino-ankylosaurus", "dino-torosaurus"]),
    DinoHabitat(id: "woodland-floodplains", name: habitatDisplayNameFromId("woodland-floodplains"), nickname: "Forest", imageName: "dino-habitats-woodland-floodplains", habitatNameAudioKey: "habitat-name-woodland-floodplains", dinoImageNames: ["dino-stegosaurus", "dino-apatosaurus", "dino-brachiosaurus", "dino-diplodocus", "dino-camarasaurus"]),
    DinoHabitat(id: "savannah", name: "Savannah", nickname: "Savannah", imageName: "dino-habitats-savannah", habitatNameAudioKey: "habitat-name-savannah", dinoImageNames: ["dino-gallimimus", "dino-edmontosaurus", "dino-parasaurolophus", "dino-triceratops", "dino-ankylosaurus"]),
    DinoHabitat(id: "lakeshore", name: "Lakeshore", nickname: "Lakeshore", imageName: "dino-habitats-lakeshore", habitatNameAudioKey: "habitat-name-lakeshore", dinoImageNames: ["dino-spinosaurus", "dino-baryonyx", "dino-iguanodon", "dino-parasaurolophus", "dino-edmontosaurus"]),
    DinoHabitat(id: "rainforest", name: "Rainforest", nickname: "Rainforest", imageName: "dino-habitats-dense-conifer-jungle", habitatNameAudioKey: "habitat-name-rainforest", dinoImageNames: ["dino-velociraptor", "dino-deinonychus", "dino-oviraptor", "dino-majungasaurus", "dino-gallimimus"]),
]

/// Same pool as Dino Ages/Formations: all dinosaurs with dino-* image sets, deduplicated.
private let dinoHabitatsPool: [Dinosaur] = {
    let fromCatalog = MatchingGameConfigs.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
    let extras: [Dinosaur] = [
        Dinosaur(id: 14, name: "Camarasaurus", icon: "🦕", imageName: "dino-camarasaurus", characteristicIds: []),
        Dinosaur(id: 15, name: "Dryosaurus", icon: "🦎", imageName: "dino-dryosaurus", characteristicIds: []),
        Dinosaur(id: 16, name: "Gallimimus", icon: "🦵", imageName: "dino-gallimimus", characteristicIds: []),
        Dinosaur(id: 17, name: "Pachycephalosaurus", icon: "🦏", imageName: "dino-pachycephalosaurus", characteristicIds: []),
        Dinosaur(id: 18, name: "Albertosaurus", icon: "🦖", imageName: "dino-albertosaurus", characteristicIds: []),
        Dinosaur(id: 19, name: "Anchiornis", icon: "🦅", imageName: "dino-anchiornis", characteristicIds: []),
        Dinosaur(id: 20, name: "Archaeopteryx", icon: "🦅", imageName: "dino-archaeopteryx", characteristicIds: []),
        Dinosaur(id: 21, name: "Argentinosaurus", icon: "🦕", imageName: "dino-argentinosaurus", characteristicIds: []),
        Dinosaur(id: 22, name: "Baryonyx", icon: "🦖", imageName: "dino-baryonyx", characteristicIds: []),
        Dinosaur(id: 23, name: "Brachiosaurus", icon: "🦕", imageName: "dino-brachiosaurus", characteristicIds: []),
        Dinosaur(id: 24, name: "Ceratosaurus", icon: "🦖", imageName: "dino-ceratosaurus", characteristicIds: []),
        Dinosaur(id: 25, name: "Chasmosaurus", icon: "🦏", imageName: "dino-chasmosaurus", characteristicIds: []),
        Dinosaur(id: 26, name: "Compsognathus", icon: "🦎", imageName: "dino-compsognathus", characteristicIds: []),
        Dinosaur(id: 27, name: "Deinonychus", icon: "🦖", imageName: "dino-deinonychus", characteristicIds: []),
        Dinosaur(id: 28, name: "Diplodocus", icon: "🦕", imageName: "dino-diplodocus", characteristicIds: []),
        Dinosaur(id: 29, name: "Dromaeosaurus", icon: "🦖", imageName: "dino-dromaeosaurus", characteristicIds: []),
        Dinosaur(id: 30, name: "Eosinopteryx", icon: "🦅", imageName: "dino-eosinopteryx", characteristicIds: []),
        Dinosaur(id: 31, name: "Giganotosaurus", icon: "🦖", imageName: "dino-giganotosaurus", characteristicIds: []),
        Dinosaur(id: 32, name: "Kosmoceratops", icon: "🦏", imageName: "dino-kosmoceratops", characteristicIds: []),
        Dinosaur(id: 33, name: "Microraptor", icon: "🦅", imageName: "dino-microraptor", characteristicIds: []),
        Dinosaur(id: 34, name: "Pedopenna", icon: "🦅", imageName: "dino-pedopenna", characteristicIds: []),
        Dinosaur(id: 35, name: "Torosaurus", icon: "🦏", imageName: "dino-torosaurus", characteristicIds: []),
        Dinosaur(id: 36, name: "Utahraptor", icon: "🦖", imageName: "dino-utahraptor", characteristicIds: []),
        Dinosaur(id: 37, name: "Xiaotingia", icon: "🦅", imageName: "dino-xiaotingia", characteristicIds: []),
        Dinosaur(id: 38, name: "Masiakasaurus", icon: "🦖", imageName: "dino-masiakasaurus", characteristicIds: []),
        Dinosaur(id: 39, name: "Torvosaurus", icon: "🦖", imageName: "dino-torvosaurus", characteristicIds: []),
        Dinosaur(id: 40, name: "Rapetosaurus", icon: "🦕", imageName: "dino-rapetosaurus", characteristicIds: []),
        Dinosaur(id: 41, name: "Majungasaurus", icon: "🦖", imageName: "dino-majungasaurus", characteristicIds: []),
        Dinosaur(id: 42, name: "Allosaurus", icon: "🦖", imageName: "dino-allosaurus", characteristicIds: []),
        Dinosaur(id: 43, name: "Oviraptor", icon: "🦅", imageName: "dino-oviraptor", characteristicIds: []),
    ]
    let combined = fromCatalog + extras
    var seen: Set<Int> = []
    return combined.filter { seen.insert($0.id).inserted }
}()

private func dinoHabitatsPrefersHabitat(_ dino: Dinosaur, _ habitat: DinoHabitat) -> Bool {
    guard let name = dino.imageName else { return false }
    return habitat.dinoImageNames.contains(name)
}

private let dinoHabitatsCircleSize: CGFloat = 96

/// Three angles for layout: top, bottom-left, bottom-right (triangle).
private let dinoHabitatsOptionAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 3,
    -Double.pi / 2 + 4 * Double.pi / 3
]

private func dinoHabitatsTimeSeed() -> UInt64 {
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

// MARK: - View

struct DinoHabitatsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoHabitatsGameConfig

    @State private var speechManager = SpeechManager()
    @State private var habitat: DinoHabitat?
    @State private var options: [Dinosaur] = []
    @State private var selectedDinosaurId: Int? = nil
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedHabitatIds: Set<String> = []
    @State private var victoryDinosaurs: [Dinosaur] = []
    @State private var displayedDinoName: String? = nil
    @State private var hasStartedGame = false
    /// Intro walk: 0..<3 = current dinosaur index; nil = not walking.
    @State private var introWalkIndex: Int? = nil

    private let totalRounds = 3
    private let matchNeededPerRound = 1

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
                .allowsHitTesting(!isAudioPlaying)
                .opacity(isAudioPlaying ? 0.85 : 1.0)
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
        if let h = habitat, !isGameComplete {
            VStack(spacing: 12) {
                habitatImage(h)
                Text(habitatDisplayNameForView(h))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Round \(currentRound) of \(totalRounds)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                if let name = displayedDinoName {
                    Text(name)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                threeOptionsLayout
            }
        } else if isGameComplete {
            endSequenceView
                .id("dino-habitats-victory")
        } else {
            ProgressView()
                .padding()
        }
    }

    /// Display name for habitat: prefer kid-friendly nickname when nickname audio exists; else scientific name.
    private func habitatDisplayNameForView(_ h: DinoHabitat) -> String {
        if let nick = h.nickname, speechManager.urlForAudio(key: h.habitatNicknameAudioKey) != nil {
            return nick
        }
        return h.name
    }

    /// Habitat image: try explicit imageName first, then dino-habitats-{id}, then dino-habitat-{id}.
    private func habitatImageName(_ h: DinoHabitat) -> String? {
        if ImageAssetCache.imageExists(named: h.imageName) { return h.imageName }
        let plural = "dino-habitats-\(h.id)"
        let singular = "dino-habitat-\(h.id)"
        if ImageAssetCache.imageExists(named: plural) { return plural }
        if ImageAssetCache.imageExists(named: singular) { return singular }
        return nil
    }

    private func habitatImage(_ h: DinoHabitat) -> some View {
        Group {
            if let name = habitatImageName(h) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 200)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 260, height: 140)
                    .overlay(Text(h.name).font(.title2))
            }
        }
        .padding(.horizontal)
    }

    private var threeOptionsLayout: some View {
        DinoHabitatsOptionsLayoutView(
            options: options,
            selectedDinosaurId: selectedDinosaurId,
            introHighlightIndex: introWalkIndex,
            tapHandler: DinoHabitatsTapHandler(perform: handleTap)
        )
        .frame(height: 320)
        .padding(.horizontal)
    }

    private func handleTap(dino: Dinosaur) {
        guard !isAudioPlaying, let h = habitat else { return }
        let isCorrect = dinoHabitatsPrefersHabitat(dino, h)
        selectedDinosaurId = dino.id
        displayedDinoName = dino.name
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(correct: isCorrect)
        }
        speechManager.speak(audioKey: dino.imageName ?? dino.name, fallbackText: dino.name)
    }

    private func playFeedbackAfterTap(correct: Bool) {
        let tappedId = selectedDinosaurId
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.displayedDinoName = nil
            self.selectedDinosaurId = nil
            self.isAudioPlaying = false
            if correct, let id = tappedId, let d = self.options.first(where: { $0.id == id }) {
                if !self.victoryDinosaurs.contains(where: { $0.id == d.id }) {
                    self.victoryDinosaurs.append(d)
                }
                self.finishRound()
            }
        }
        if correct {
            if let url = speechManager.urlForAudio(key: "great-match") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("great-match")
            }
        } else {
            if let url = speechManager.urlForAudio(key: "try-again") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("try-again")
            }
        }
    }

    private func finishRound() {
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        var rng = SeededRandomNumberGenerator(seed: dinoHabitatsTimeSeed())
        habitat = pickHabitatForRound(using: &rng)
        guard habitat != nil else {
            isGameComplete = true
            return
        }
        usedHabitatIds.insert(habitat!.id)
        buildOptionsForRound(using: &rng)
        selectedDinosaurId = nil
        playHabitatThenAllowTaps()
    }

    private func pickHabitatForRound(using rng: inout SeededRandomNumberGenerator) -> DinoHabitat? {
        let notYetUsed = dinoHabitatsList.filter { !usedHabitatIds.contains($0.id) }
        let pool = notYetUsed.isEmpty ? dinoHabitatsList : notYetUsed
        let playable = pool.filter { h in
            let inH = dinoHabitatsPool.filter { dinoHabitatsPrefersHabitat($0, h) }
            let outH = dinoHabitatsPool.filter { !dinoHabitatsPrefersHabitat($0, h) }
            return !inH.isEmpty && outH.count >= 2
        }
        return (playable.isEmpty ? pool : playable).randomElement(using: &rng)
    }

    private func buildOptionsForRound(using rng: inout SeededRandomNumberGenerator) {
        guard let h = habitat else { return }
        let inHabitat = dinoHabitatsPool.filter { dinoHabitatsPrefersHabitat($0, h) }
        let outHabitat = dinoHabitatsPool.filter { !dinoHabitatsPrefersHabitat($0, h) }
        guard let correct = inHabitat.randomElement(using: &rng),
              outHabitat.count >= 2 else {
            isGameComplete = true
            return
        }
        let wrongs = Array(outHabitat.shuffled(using: &rng).prefix(2))
        options = ([correct] + wrongs).shuffled(using: &rng)
    }

    private func playHabitatThenAllowTaps() {
        guard let h = habitat else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playChooseDinosaurThenAllowTaps()
        }
        // Prefer kid-friendly nickname audio when it exists; else fall back to scientific name
        if h.nickname != nil,
           let url = speechManager.urlForAudio(key: h.habitatNicknameAudioKey) {
            speechManager.playAudioFile(url: url)
        } else if let url = speechManager.urlForAudio(key: h.habitatNameAudioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(h.nickname ?? h.name)
        }
    }

    private func playChooseDinosaurThenAllowTaps() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-dino-habitats-choose-dinosaur") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Which dinosaur prefers this habitat?")
        }
    }

    /// Walk the 3 dinosaurs: play each name, highlight, show label; then allow taps.
    private func startIntroWalk() {
        guard options.count >= 3 else {
            introWalkIndex = nil
            displayedDinoName = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = 0
        displayedDinoName = options[0].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: options[0].imageName ?? options[0].name, fallbackText: options[0].name)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 3 {
            introWalkIndex = nil
            displayedDinoName = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = next
        displayedDinoName = options[next].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: options[next].imageName ?? options[next].name, fallbackText: options[next].name)
    }

    private func startGame() {
        var rng = SeededRandomNumberGenerator(seed: dinoHabitatsTimeSeed())
        usedHabitatIds = []
        habitat = pickHabitatForRound(using: &rng)
        guard habitat != nil else { return }
        usedHabitatIds.insert(habitat!.id)
        currentRound = 1
        victoryDinosaurs = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildOptionsForRound(using: &rng)
        playHabitatThenAllowTaps()
    }

    // MARK: - End sequence (victory list with square images like Match the Dinosaur, then success card + good-job + crowd-cheering)

    private let victoryRowHeight: CGFloat = 72
    private var victoryListVisibleHeight: CGFloat { 16 + 3 * victoryRowHeight + 2 * 12 + 16 }

    private var endSequenceView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(uniqueVictoryDinosaurs.enumerated()), id: \.offset) { index, dino in
                                DinoHabitatsEndRowView(dino: dino, isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .scrollIndicators(.visible)
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: endHighlightIndex) { _, newValue in
                        guard newValue < uniqueVictoryDinosaurs.count else { return }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if endSequenceStep == 2 {
                        dinoHabitatsSuccessImageView
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
            if uniqueVictoryDinosaurs.isEmpty {
                endSequenceStep = 2
            } else {
                let d = uniqueVictoryDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    /// Game card at end: prefer success image (asset is game-dino-habitat-success), fall back to main game card (game-dino-habitats).
    private var dinoHabitatsSuccessImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-habitat-success") {
                Image("game-dino-habitat-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: "game-dino-habitats-success") {
                Image("game-dino-habitats-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: "game-dino-habitats") {
                Image("game-dino-habitats")
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

    private var uniqueVictoryDinosaurs: [Dinosaur] {
        var seen = Set<Int>()
        return victoryDinosaurs.filter { seen.insert($0.id).inserted }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < uniqueVictoryDinosaurs.count {
            let d = uniqueVictoryDinosaurs[endHighlightIndex]
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

// MARK: - Options layout (3 circles)

private struct DinoHabitatsTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoHabitatsOptionsLayoutView: View {
    let options: [Dinosaur]
    let selectedDinosaurId: Int?
    let introHighlightIndex: Int?
    let tapHandler: DinoHabitatsTapHandler
    private let radius: CGFloat = 90

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, dino in
                    VStack(spacing: 6) {
                        DinoHabitatsCircleView(dino: dino, isSelected: selectedDinosaurId == dino.id, isIntroHighlighted: introHighlightIndex == index)
                        Text(dino.name)
                            .font(.subheadline)
                            .fontWeight(introHighlightIndex == index ? .semibold : .regular)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .position(
                        x: geo.size.width / 2 + radius * CGFloat(cos(dinoHabitatsOptionAngles[index])),
                        y: geo.size.height / 2 + 24 + radius * CGFloat(sin(dinoHabitatsOptionAngles[index]))
                    )
                    .onTapGesture { tapHandler.perform(dino) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct DinoHabitatsCircleView: View {
    let dino: Dinosaur
    let isSelected: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoHabitatsCircleSize, height: dinoHabitatsCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoHabitatsCircleSize, height: dinoHabitatsCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
            }
        }
        .overlay(Circle().stroke(strokeColor, lineWidth: isSelected || isIntroHighlighted ? 4 : 2).frame(width: dinoHabitatsCircleSize, height: dinoHabitatsCircleSize))
        .opacity(isSelected ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isSelected { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

/// Victory row: square image (72×72) like Match the Dinosaur, not circle — saves space for game card below.
private struct DinoHabitatsEndRowView: View {
    let dino: Dinosaur
    let isHighlighted: Bool
    private let rowHeight: CGFloat = 72
    private let imageSize: CGFloat = 72

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                } else {
                    Text(dino.icon)
                        .font(.system(size: 40))
                        .frame(width: imageSize, height: imageSize)
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

enum DinoHabitatsGameConfigs {
    static let dinoHabitats = DinoHabitatsGameConfig(
        id: "dino-habitats",
        title: "Dino Habitats!",
        introAudio: "game-dino-habitats"
    )
}

#Preview {
    DinoHabitatsGameView(isPresented: .constant(true), gameConfig: DinoHabitatsGameConfigs.dinoHabitats)
}
