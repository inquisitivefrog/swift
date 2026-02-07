//
//  DinoAgesGameView.swift
//  DinoGames
//
//  Dino Ages: Pick Jurassic or Cretaceous. Three rounds; each round: 5 dinos (3 from period, 2 from other).
//  User selects the 3 that match the period. No repeat dinosaurs across rounds. Victory: walk 9 selected, then crowd-cheering.
//

import SwiftUI

struct DinoAgesGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Period

private enum DinoAgesPeriod: String, CaseIterable {
    case jurassic
    case cretaceous

    var imageName: String { "period-\(rawValue)" }
    var coverAudioKey: String { "cover-\(rawValue)" }
    /// e.g. game-dino-ages-find-in-jurassic / game-dino-ages-find-in-cretaceous
    var findInPeriodAudioKey: String { "game-dino-ages-find-in-\(rawValue)" }
}

// MARK: - Dino Ages pool and period (Jurassic / Cretaceous)

/// Dino image set names (dino-*) that are Jurassic period. Used to filter the pool.
private let dinoAgesJurassicImageNames: Set<String> = [
    "dino-anchiornis", "dino-apatosaurus", "dino-archaeopteryx", "dino-brachiosaurus", "dino-camarasaurus",
    "dino-ceratosaurus", "dino-compsognathus", "dino-diplodocus", "dino-dryosaurus", "dino-eosinopteryx",
    "dino-pedopenna", "dino-stegosaurus", "dino-xiaotingia"
]

/// Dino image set names (dino-*) that are Cretaceous period. Used to filter the pool.
private let dinoAgesCretaceousImageNames: Set<String> = [
    "dino-albertosaurus", "dino-ankylosaurus", "dino-argentinosaurus", "dino-baryonyx", "dino-chasmosaurus",
    "dino-corythosaurus", "dino-deinonychus", "dino-dromeosaurus", "dino-edmontosaurus", "dino-gallimimus",
    "dino-giganotosaurus", "dino-iguanodon", "dino-kosmoceratops", "dino-microraptor", "dino-pachycephalosaurus",
    "dino-parasaurolophus", "dino-spinosaurus", "dino-therizinosaurus", "dino-torosaurus", "dino-trex",
    "dino-triceratops", "dino-troodon", "dino-utahraptor", "dino-velociraptor"
]

/// All dinosaurs that have a dino- imageset: catalog (ids 1–13) + extras (ids 14–37) so all 37 asset sets are included.
private let dinoAgesPool: [Dinosaur] = {
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
        Dinosaur(id: 29, name: "Dromaeosaurus", icon: "🦖", imageName: "dino-dromeosaurus", characteristicIds: []),
        Dinosaur(id: 30, name: "Eosinopteryx", icon: "🦅", imageName: "dino-eosinopteryx", characteristicIds: []),
        Dinosaur(id: 31, name: "Giganotosaurus", icon: "🦖", imageName: "dino-giganotosaurus", characteristicIds: []),
        Dinosaur(id: 32, name: "Kosmoceratops", icon: "🦏", imageName: "dino-kosmoceratops", characteristicIds: []),
        Dinosaur(id: 33, name: "Microraptor", icon: "🦅", imageName: "dino-microraptor", characteristicIds: []),
        Dinosaur(id: 34, name: "Pedopenna", icon: "🦅", imageName: "dino-pedopenna", characteristicIds: []),
        Dinosaur(id: 35, name: "Torosaurus", icon: "🦏", imageName: "dino-torosaurus", characteristicIds: []),
        Dinosaur(id: 36, name: "Utahraptor", icon: "🦖", imageName: "dino-utahraptor", characteristicIds: []),
        Dinosaur(id: 37, name: "Xiaotingia", icon: "🦅", imageName: "dino-xiaotingia", characteristicIds: []),
    ]
    return fromCatalog + extras
}()

/// Dinosaur id → period. Derived from Jurassic/Cretaceous image-name sets.
private let dinoAgesPeriodById: [Int: DinoAgesPeriod] = {
    var map: [Int: DinoAgesPeriod] = [:]
    for d in dinoAgesPool {
        guard let name = d.imageName else { continue }
        map[d.id] = dinoAgesJurassicImageNames.contains(name) ? .jurassic : .cretaceous
    }
    return map
}()

/// Diameter of each dinosaur circle in the star layout (and victory list).
private let dinoAgesCircleSize: CGFloat = 96

/// Five angles for star layout: start at top (-π/2), then every 72°.
private let dinoAgesStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5
]

// MARK: - Seeded RNG (system clock for uniqueness each run)

private func dinoAgesTimeSeed() -> UInt64 {
    let t = Date().timeIntervalSince1970
    return UInt64(bitPattern: Int64(t * 1_000_000))
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        state = seed
    }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - View

struct DinoAgesGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoAgesGameConfig

    @State private var speechManager = SpeechManager()
    @State private var period: DinoAgesPeriod?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedDinosaurIds: Set<Int> = []
    /// All 9 correctly selected dinosaurs in order (3 per round) for victory walk.
    @State private var victoryWalkDinosaurs: [Dinosaur] = []

    private let totalRounds = 3
    private let matchesNeededPerRound = 3

    /// Order in which correct dinosaurs were tapped this round (ids). Used to build victory walk order.
    @State private var matchedOrderThisRound: [Int] = []

    /// During intro, index of the circle being introduced (0..<5). nil when not walking.
    @State private var introWalkIndex: Int? = nil
    /// Dinosaur name shown after tap (before feedback).
    @State private var displayedDinoName: String? = nil

    /// Matched dinosaurs this round in the order they were tapped (for adding to victory walk).
    private var matchedDinosaursThisRoundInTapOrder: [Dinosaur] {
        matchedOrderThisRound.compactMap { id in slots.first { $0.id == id } }
    }

    var body: some View {
        NavigationView {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { startGame() }
                .onDisappear {
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
        if let p = period, !isGameComplete {
            periodImage(p)
            Text(p.rawValue.capitalized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("Round \(currentRound) of \(totalRounds)")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            if let name = displayedDinoName {
                Text(name)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            fiveStarLayout
        } else if isGameComplete {
            dinoAgesEndSequenceView
        } else {
            ProgressView("Loading…")
                .padding()
        }
    }

    private func periodImage(_ p: DinoAgesPeriod) -> some View {
        Group {
            if UIImage(named: p.imageName) != nil {
                Image(p.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 140)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 200, height: 80)
                    .overlay(Text(p.rawValue.capitalized).font(.title2))
            }
        }
        .padding(.horizontal)
    }

    private var fiveStarLayout: some View {
        DinoAgesStarLayoutView(slots: slots, matchedIds: matchedIds, introHighlightIndex: introWalkIndex, tapHandler: DinoAgesTapHandler(perform: handleTap))
            .frame(height: 320)
            .padding(.horizontal)
    }

    private func dinoCircle(dino: Dinosaur, isMatched: Bool) -> some View {
        Group {
            if let name = dino.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isMatched ? Color.green : Color.gray.opacity(0.4), lineWidth: isMatched ? 4 : 2))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
                    .overlay(Circle().stroke(isMatched ? Color.green : Color.gray.opacity(0.4), lineWidth: isMatched ? 4 : 2))
            }
        }
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private func handleTap(dino: Dinosaur) {
        guard !isAudioPlaying else { return }
        guard let p = period, let dinoPeriod = dinoAgesPeriodById[dino.id] else { return }
        let isCorrect = (dinoPeriod == p)
        if isCorrect {
            if matchedIds.contains(dino.id) { return }
            matchedIds.insert(dino.id)
            matchedOrderThisRound.append(dino.id)
        }
        displayedDinoName = dino.name
        isAudioPlaying = true
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
            self.isAudioPlaying = false
            if correct, self.matchedIds.count >= self.matchesNeededPerRound {
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
            if let url = speechManager.urlForAudio(key: "not-that-one") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("not-that-one")
            }
        }
    }

    /// Build slots for one round: 3 from chosen period, 2 from other period. Prefer dinosaurs not yet used; allow reuse if pool is small.
    private func buildSlotsForRound(using rng: inout SeededRandomNumberGenerator) {
        guard let p = period else { return }
        let inPeriodPool = dinoAgesPool.filter { dinoAgesPeriodById[$0.id] == p }
        let outOfPeriodPool = dinoAgesPool.filter { dinoAgesPeriodById[$0.id] != p }
        let inPeriodPreferred = inPeriodPool.filter { !usedDinosaurIds.contains($0.id) }
        let outOfPeriodPreferred = outOfPeriodPool.filter { !usedDinosaurIds.contains($0.id) }
        let inPeriod = inPeriodPreferred.count >= 3 ? inPeriodPreferred : inPeriodPool
        let outOfPeriod = outOfPeriodPreferred.count >= 2 ? outOfPeriodPreferred : outOfPeriodPool
        let corrects = Array(inPeriod.shuffled(using: &rng).prefix(3))
        let wrongs = Array(outOfPeriod.shuffled(using: &rng).prefix(2))
        guard corrects.count == 3, wrongs.count == 2 else {
            isGameComplete = true
            return
        }
        for d in corrects + wrongs { usedDinosaurIds.insert(d.id) }
        slots = (corrects + wrongs).shuffled(using: &rng)
        matchedIds = []
        matchedOrderThisRound = []
    }

    /// Called when user has selected all 3 correct dinosaurs this round. Append them to victory walk; advance round or show victory.
    private func finishRound() {
        let matchedOrdered = matchedDinosaursThisRoundInTapOrder
        victoryWalkDinosaurs.append(contentsOf: matchedOrdered)
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        var rng = SeededRandomNumberGenerator(seed: dinoAgesTimeSeed())
        // Pick the other period so rounds 2 and 3 are different from the previous round (guaranteed mix of Jurassic and Cretaceous).
        if let current = period {
            period = current == .jurassic ? .cretaceous : .jurassic
        } else {
            period = DinoAgesPeriod.allCases.randomElement(using: &rng)!
        }
        buildSlotsForRound(using: &rng)
        playFindInPeriodThenAllowTaps()
    }

    /// Reminder: play period name audio, then find-in-period instruction, then walk the dinosaur list.
    private func playFindInPeriodThenAllowTaps() {
        guard let p = period else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFindInPeriodInstructionThenWalk()
        }
        if let url = speechManager.urlForAudio(key: p.coverAudioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(p.coverAudioKey)
        }
    }

    private func playFindInPeriodInstructionThenWalk() {
        guard let p = period else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk()
        }
        if let url = speechManager.urlForAudio(key: p.findInPeriodAudioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(p.findInPeriodAudioKey)
        }
    }

    /// Walk the five circles, speaking each dinosaur’s name; then allow taps.
    private func startIntroWalk() {
        guard slots.count >= 5 else {
            isAudioPlaying = false
            return
        }
        introWalkIndex = 0
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[0].imageName ?? slots[0].name, fallbackText: slots[0].name)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = next
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[next].imageName ?? slots[next].name, fallbackText: slots[next].name)
    }

    private func startGame() {
        var rng = SeededRandomNumberGenerator(seed: dinoAgesTimeSeed())
        period = DinoAgesPeriod.allCases.randomElement(using: &rng)!
        currentRound = 1
        usedDinosaurIds = []
        victoryWalkDinosaurs = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        guard let p = period else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.startIntroWalk()
            }
            if let url = self.speechManager.urlForAudio(key: p.findInPeriodAudioKey) {
                self.speechManager.playAudioFile(url: url)
            } else {
                self.speechManager.speak(p.findInPeriodAudioKey)
            }
        }
        speechManager.speak(p.coverAudioKey)
    }

    // MARK: - End sequence (victory: walk 9 selected dinosaurs, then crowd-cheering)

    private var dinoAgesEndSequenceView: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(victoryWalkDinosaurs.enumerated()), id: \.element.id) { index, dino in
                        DinoAgesEndRowView(
                            dino: dino,
                            isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text("Good job!")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryWalkDinosaurs.isEmpty {
                playCrowdThenDismiss()
            } else {
                let d = victoryWalkDinosaurs[0]
                speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
                speechManager.onAudioFinished = { advanceEndHighlight() }
            }
        }
    }

    private func advanceEndHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < victoryWalkDinosaurs.count {
            let d = victoryWalkDinosaurs[endHighlightIndex]
            speechManager.speak(audioKey: d.imageName ?? d.name, fallbackText: d.name)
            speechManager.onAudioFinished = { advanceEndHighlight() }
        } else {
            playCrowdThenDismiss()
        }
    }

    private func playCrowdThenDismiss() {
        endSequenceStep = 2
        if let crowdURL = speechManager.urlForAudio(key: "crowd-cheering") {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
            speechManager.playAudioFile(url: crowdURL)
        } else {
            speechManager.speak("crowd-cheering")
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
        }
    }
}

// MARK: - Star layout (extracted for type-checker)

/// Wraps the dino tap callback so views store a concrete type instead of (Dinosaur) -> Void.
private struct DinoAgesTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoAgesStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: DinoAgesTapHandler

    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            DinoAgesStarLayoutContent(
                width: geo.size.width,
                height: geo.size.height,
                slots: slots,
                matchedIds: matchedIds,
                introHighlightIndex: introHighlightIndex,
                radius: radius,
                angles: dinoAgesStarAngles,
                tapHandler: tapHandler
            )
        }
    }
}

private struct DinoAgesStarLayoutContent: View {
    let width: CGFloat
    let height: CGFloat
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let radius: CGFloat
    let angles: [Double]
    let tapHandler: DinoAgesTapHandler

    var body: some View {
        ZStack(alignment: .center) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, dino in
                DinoAgesCircleView(
                    dino: dino,
                    isMatched: matchedIds.contains(dino.id),
                    isIntroHighlighted: introHighlightIndex == index
                )
                .position(
                    x: width / 2 + radius * CGFloat(cos(angles[index])),
                    y: height / 2 + 20 + radius * CGFloat(sin(angles[index]))
                )
                .onTapGesture { tapHandler.perform(dino) }
            }
        }
        .frame(width: width, height: height)
    }
}

private struct DinoAgesCircleView: View {
    let dino: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        circleContent
            .overlay(circleStroke)
            .opacity(isMatched ? 0.9 : 1.0)
    }

    @ViewBuilder
    private var circleContent: some View {
        if let name = dino.imageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
                .overlay(Text(dino.icon).font(.system(size: 32)))
        }
    }

    private var circleStroke: some View {
        Circle()
            .stroke(strokeColor, lineWidth: strokeLineWidth)
            .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }

    private var strokeLineWidth: CGFloat {
        if isMatched || isIntroHighlighted { return 4 }
        return 2
    }
}

private struct DinoAgesEndRowView: View {
    let dino: Dinosaur
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 16) {
            DinoAgesCircleView(dino: dino, isMatched: true)
                .frame(width: dinoAgesCircleSize, height: dinoAgesCircleSize)
                .opacity(isHighlighted ? 1.0 : 0.4)
            Text(dino.name)
                .font(.title2)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isHighlighted ? 1.0 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Configs

enum DinoAgesGameConfigs {
    static let dinoAges = DinoAgesGameConfig(
        id: "dino-ages",
        title: "Dino Ages!",
        introAudio: "game-dino-ages"
    )
}

#Preview {
    DinoAgesGameView(isPresented: .constant(true), gameConfig: DinoAgesGameConfigs.dinoAges)
}
