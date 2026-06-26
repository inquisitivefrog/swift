//
//  DinoAgesGameView.swift
//  DinoGames
//
//  Dino Ages: Pick Jurassic or Cretaceous. Three rounds; each round: 5 dinos (3 from period, 2 from other).
//  User selects the 3 that match the period. No repeat dinosaurs across rounds. Victory: walk 9 selected (scroll list), then success image + good-job + crowd-cheering.
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
    var pteroImageName: String { "ptero-ages-\(rawValue)" }
    var marineImageName: String { "marine-ages-\(rawValue)" }
    var coverAudioKey: String { "cover-\(rawValue)" }
    /// e.g. game-dino-ages-find-in-jurassic / game-dino-ages-find-in-cretaceous
    var findInPeriodAudioKey: String { "game-dino-ages-find-in-\(rawValue)" }
}

// MARK: - Dino Ages pool and period (Jurassic / Cretaceous)

/// Dino image set names (dino-*) that are Jurassic period. Used to filter the pool.
private let dinoAgesJurassicImageNames: Set<String> = [
    "dino-anchiornis", "dino-apatosaurus", "dino-archaeopteryx", "dino-brachiosaurus", "dino-camarasaurus",
    "dino-ceratosaurus", "dino-compsognathus", "dino-diplodocus", "dino-dryosaurus", "dino-eosinopteryx",
    "dino-allosaurus", "dino-pedopenna", "dino-stegosaurus", "dino-torvosaurus", "dino-xiaotingia"
]

/// Dino image set names (dino-*) that are Cretaceous period. Used to filter the pool.
private let dinoAgesCretaceousImageNames: Set<String> = [
    "dino-albertosaurus", "dino-ankylosaurus", "dino-argentinosaurus", "dino-baryonyx", "dino-chasmosaurus",
    "dino-corythosaurus", "dino-deinonychus", "dino-dromaeosaurus", "dino-edmontosaurus", "dino-gallimimus",
    "dino-giganotosaurus", "dino-iguanodon", "dino-kosmoceratops", "dino-majungasaurus", "dino-masiakasaurus",
    "dino-microraptor", "dino-pachycephalosaurus", "dino-parasaurolophus", "dino-rapetosaurus", "dino-spinosaurus",
    "dino-therizinosaurus", "dino-torosaurus", "dino-trex", "dino-triceratops", "dino-troodon",
    "dino-oviraptor", "dino-utahraptor", "dino-velociraptor"
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

/// Dinosaur id → period. Derived from Jurassic/Cretaceous image-name sets.
private let dinoAgesPeriodById: [Int: DinoAgesPeriod] = {
    var map: [Int: DinoAgesPeriod] = [:]
    for d in dinoAgesPool {
        guard let name = d.imageName else { continue }
        map[d.id] = dinoAgesJurassicImageNames.contains(name) ? .jurassic : .cretaceous
    }
    return map
}()

/// Pterosaur pool: all bundled pterosaur portraits.
private let pteroAgesPool: [Dinosaur] = AirPterosaurData.allPterosaurs.filter { $0.imageName?.hasPrefix("ptero-") == true }

/// Pterosaur id → period for Ptero Ages.
/// Species marked `.both` are treated as Jurassic for this game so each card still has one target period.
private let pteroAgesPeriodById: [Int: DinoAgesPeriod] = {
    var map: [Int: DinoAgesPeriod] = [:]
    for p in pteroAgesPool {
        guard let span = AirPterosaurData.mesozoicSpanForRacing(pterosaurId: p.id) else { continue }
        switch span {
        case .jurassic, .both:
            map[p.id] = .jurassic
        case .cretaceous:
            map[p.id] = .cretaceous
        }
    }
    return map
}()

/// Marine reptile pool: bundled marine portraits with period mapping for Marine Ages.
private let marineAgesPool: [Dinosaur] = SeaMarineReptileData.allMarineReptiles.filter {
    $0.imageName?.hasPrefix("marine-") == true
        && SeaMarineReptileData.mesozoicSpanForAges(creature: $0) != nil
}

private let marineAgesPeriodById: [Int: DinoAgesPeriod] = {
    var map: [Int: DinoAgesPeriod] = [:]
    for creature in marineAgesPool {
        guard let span = SeaMarineReptileData.mesozoicSpanForAges(creature: creature) else { continue }
        switch span {
        case .jurassic, .both:
            map[creature.id] = .jurassic
        case .cretaceous:
            map[creature.id] = .cretaceous
        }
    }
    return map
}()

fileprivate enum DinoAgesVariant {
    case dino
    case ptero
    case marine

    init(configId: String) {
        switch configId {
        case "ptero-ages": self = .ptero
        case "marine-ages": self = .marine
        default: self = .dino
        }
    }

    /// Shared hint-button narration (blue circle → Source Ages / Source Footprints).
    static let hintCircleAudioKey = "game-hint"

    var audioPrefix: String {
        switch self {
        case .dino: return "dino"
        case .ptero: return "ptero"
        case .marine: return "marine"
        }
    }

    func periodGridIntroAudioKey() -> String {
        "game-\(audioPrefix)-ages-tap-the-period-to-hear-description"
    }
}

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

    @StateObject private var speechManager = SpeechManager()
    @State private var period: DinoAgesPeriod?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    /// True during scripted sequences (intro walk, round transitions, victory recap) including gaps between chained clips.
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
    /// When the player may answer this round; used for great-match vs wow-that-was-tricky.
    @State private var guessChoiceTimer = GuessChoiceTimer()
    /// When true, show the Source Ages hints overlay.
    @State private var showSourceAgesHints = false

    private var agesVariant: DinoAgesVariant { DinoAgesVariant(configId: gameConfig.id) }
    private var currentPool: [Dinosaur] {
        switch agesVariant {
        case .ptero: return pteroAgesPool
        case .marine: return marineAgesPool
        case .dino: return dinoAgesPool
        }
    }
    private var currentPeriodById: [Int: DinoAgesPeriod] {
        switch agesVariant {
        case .ptero: return pteroAgesPeriodById
        case .marine: return marineAgesPeriodById
        case .dino: return dinoAgesPeriodById
        }
    }

    private func findInPeriodAudioKey(for period: DinoAgesPeriod) -> String {
        "game-\(agesVariant.audioPrefix)-ages-find-in-\(period.rawValue)"
    }

    private var successImageCandidates: [String] {
        let prefix = agesVariant.audioPrefix
        return ["game-\(prefix)-ages-success", "game-\(prefix)-ages"]
    }

    /// Matched dinosaurs this round in the order they were tapped (for adding to victory walk).
    private var matchedDinosaursThisRoundInTapOrder: [Dinosaur] {
        matchedOrderThisRound.compactMap { id in slots.first { $0.id == id } }
    }

    /// Block taps while any clip is playing or a scripted sequence has not finished (audio before input).
    private var blocksUserInput: Bool {
        if isGameComplete { return isAudioPlaying }
        return isAudioPlaying || speechManager.isPlaying
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
                .allowsHitTesting(!blocksUserInput)
                .opacity(blocksUserInput ? 0.85 : 1.0)
                .overlay(alignment: .topTrailing) {
                    if period != nil, !isGameComplete {
                        Button {
                            guessChoiceTimer.pauseForHints()
                            showSourceAgesHints = true
                        } label: {
                            Text("Hints")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Circle().fill(Color.blue))
                                .frame(width: 72, height: 72)
                        }
                        .disabled(blocksUserInput)
                        .opacity(blocksUserInput ? 0.45 : 1.0)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                }
                .fullScreenCover(isPresented: $showSourceAgesHints) {
                    SourceAgesHintsView(
                        agesVariant: agesVariant,
                        title: SourceHintsTitles.ages,
                        onDismiss: {
                        guessChoiceTimer.resumeAfterHints()
                        showSourceAgesHints = false
                    })
                }
        }
        .gameSheetDismissDisabledWhileAudioPlaying(blocksUserInput)
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
            // Fixed-height slot for dinosaur name to prevent layout stretch/shrink when name appears
            ZStack {
                if let name = displayedDinoName {
                    Text(name)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .lineLimit(1)
                }
            }
            .frame(height: 28)
            fiveStarLayout
        } else if isGameComplete {
            dinoAgesEndSequenceView
        } else {
            ProgressView("Loading…")
                .padding()
        }
    }

    private func periodImage(_ p: DinoAgesPeriod) -> some View {
        let preferredImageName: String = {
            switch agesVariant {
            case .ptero: return p.pteroImageName
            case .marine: return p.marineImageName
            case .dino: return p.imageName
            }
        }()
        let fallbackImageName = p.imageName
        return Group {
            if ImageAssetCache.imageExists(named: preferredImageName) {
                Image(preferredImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 180)
            } else if ImageAssetCache.imageExists(named: fallbackImageName) {
                Image(fallbackImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 180)
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
        guard !blocksUserInput else { return }
        guard let p = period, let dinoPeriod = currentPeriodById[dino.id] else { return }
        let isCorrect = (dinoPeriod == p)
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
        isAudioPlaying = true
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
            self.isAudioPlaying = false
            if correct {
                self.guessChoiceTimer.start()
                if self.matchedIds.count >= self.matchesNeededPerRound {
                    self.finishRound()
                }
            }
        }
        if correct {
            let key = OrderedTouchFeedback.successMatchAudio(elapsed: elapsed)
            OrderedTouchFeedback.speak(key, speechManager: speechManager, onFinished: finish)
        } else {
            OrderedTouchFeedback.speak(OrderedTouchFeedback.tryAgain, speechManager: speechManager, onFinished: finish)
        }
    }

    /// Build slots for one round: 3 from chosen period, 2 from other period. Prefer dinosaurs not yet used; allow reuse if pool is small.
    private func buildSlotsForRound(using rng: inout SeededRandomNumberGenerator) {
        guard let p = period else { return }
        let inPeriodPool = currentPool.filter { currentPeriodById[$0.id] == p }
        let outOfPeriodPool = currentPool.filter { currentPeriodById[$0.id] != p }
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
            // chainDelay: skip rate limit so cover always plays after prior clip (e.g. great-match).
            speechManager.speak(p.coverAudioKey, chainDelay: true)
        }
    }

    private func playFindInPeriodInstructionThenWalk() {
        guard let p = period else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playHintReminderThenStartIntroWalk()
        }
        let findKey = findInPeriodAudioKey(for: p)
        if let url = speechManager.urlForAudio(key: findKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(findKey, chainDelay: true)
        }
    }

    /// Before the dinosaur intro walk: point to the Hints circle (`game-hint`), not the period grid.
    private func playHintReminderThenStartIntroWalk() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk()
        }
        if let url = speechManager.urlForAudio(key: DinoAgesVariant.hintCircleAudioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            startIntroWalk()
        }
    }

    /// Walk the five circles, speaking each dinosaur’s name; then allow taps.
    private func startIntroWalk() {
        guard slots.count >= 5 else {
            displayedDinoName = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = 0
        displayedDinoName = slots[0].name
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceIntroWalk() }
        // chainDelay: after a short hint/find clip, lastPlayTime can be under 0.3s ago; without this, speak skips audio and fires onAudioFinished immediately, fast-forwarding the whole walk.
        speechManager.speak(audioKey: slots[0].imageName ?? slots[0].name, fallbackText: slots[0].name, chainDelay: true)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedDinoName = nil
            isAudioPlaying = false
            guessChoiceTimer.start()
            return
        }
        introWalkIndex = next
        displayedDinoName = slots[next].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[next].imageName ?? slots[next].name, fallbackText: slots[next].name, chainDelay: true)
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
        playFindInPeriodThenAllowTaps()
    }

    // MARK: - End sequence (victory: walk selected dinosaurs, then success card + optional stinger → good-job + crowd)

    private var dinoAgesEndSequenceView: some View {
        VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: victoryWalkDinosaurs.count),
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            recapItemCount: victoryWalkDinosaurs.count,
            scrollRows: {
                ForEach(Array(victoryWalkDinosaurs.enumerated()), id: \.offset) { index, dino in
                    let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                    StandardVictoryRecapRowView(
                        item: VictoryRecapDisplayItem(
                            id: "\(dino.id)",
                            title: dino.name,
                            imageAssetName: dino.imageName,
                            fallbackEmoji: dino.icon
                        ),
                        isHighlighted: isHighlighted
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: successImageCandidates,
                    catalogGameIdForStinger: gameConfig.id,
                    speechManager: speechManager,
                    onContinue: playGoodJobAndCrowdThenDismiss
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            isAudioPlaying = true
            endSequenceStep = 1
            endHighlightIndex = 0
            if victoryWalkDinosaurs.isEmpty {
                isAudioPlaying = false
                endSequenceStep = 2
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
            isAudioPlaying = false
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
            ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
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
    var size: CGFloat = dinoAgesCircleSize

    var body: some View {
        circleContent
            .overlay(circleStroke)
            .opacity(isMatched ? 0.9 : 1.0)
    }

    @ViewBuilder
    private var circleContent: some View {
        let fallback = Circle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: size, height: size)
            .overlay(Text(dino.icon).font(.system(size: size > 80 ? 32 : 24)))
            .overlay(Circle().stroke(Color.gray.opacity(0.6), lineWidth: 2))
        if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
            ZStack {
                fallback
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        } else {
            fallback
        }
    }

    private var circleStroke: some View {
        Circle()
            .stroke(strokeColor, lineWidth: strokeLineWidth)
            .frame(width: size, height: size)
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

// MARK: - Source Ages Hints (Dino Ages)

private struct SourceAgesPeriodHint: Identifiable {
    let id: String
    let imageName: String
    let displayName: String
    let audioKey: String
}

private var sourceAgesHintPeriods: [SourceAgesPeriodHint] {
    LandGameDisplayMomentCatalog.agesSourceHints.map {
        SourceAgesPeriodHint(id: $0.id, imageName: $0.imageAssetName, displayName: $0.displayText, audioKey: $0.audioKey)
    }
}

fileprivate struct SourceAgesHintsView: View {
    var agesVariant: DinoAgesVariant = .dino
    var title: String = SourceHintsTitles.ages
    let onDismiss: () -> Void
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedPeriod: SourceAgesPeriodHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedPeriod == nil {
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
            SourceHintsScreenTitle(title: title)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(hintPeriods) { period in
                    Button {
                        showPeriodDetail(period)
                    } label: {
                        if UIImage(named: period.imageName) != nil {
                            Image(period.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 140)
                                .overlay(Text(period.displayName).font(.title3).foregroundColor(.secondary))
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
        if let period = selectedPeriod {
            VStack(spacing: 20) {
                Spacer()
                if UIImage(named: period.imageName) != nil {
                    Image(period.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 340, maxHeight: 220)
                }
                Text(period.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var hintPeriods: [SourceAgesPeriodHint] {
        switch agesVariant {
        case .ptero:
            return [
                SourceAgesPeriodHint(id: "jurassic", imageName: "source-ptero-ages-jurassic", displayName: "Jurassic", audioKey: "game-ptero-ages-jurassic-pterosaurs"),
                SourceAgesPeriodHint(id: "cretaceous", imageName: "source-ptero-ages-cretaceous", displayName: "Cretaceous", audioKey: "game-ptero-ages-cretaceous-pterosaurs"),
            ]
        case .marine:
            return [
                SourceAgesPeriodHint(id: "jurassic", imageName: "marine-ages-jurassic", displayName: "Jurassic", audioKey: "game-marine-ages-jurassic-marine-reptiles"),
                SourceAgesPeriodHint(id: "cretaceous", imageName: "marine-ages-cretaceous", displayName: "Cretaceous", audioKey: "game-marine-ages-cretaceous-marine-reptiles"),
            ]
        case .dino:
            return sourceAgesHintPeriods
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        let introKey = agesVariant.periodGridIntroAudioKey()
        if let url = speechManager.urlForAudio(key: introKey) {
            speechManager.onAudioFinished = nil
            speechManager.playAudioFile(url: url)
        }
    }

    private func showPeriodDetail(_ period: SourceAgesPeriodHint) {
        guard !speechManager.isPlaying else { return }
        selectedPeriod = period
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedPeriod = nil
            }
        }
        if let url = speechManager.urlForAudio(key: period.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(period.displayName)
        }
    }
}

// MARK: - Configs

enum DinoAgesGameConfigs {
    static let dinoAges = DinoAgesGameConfig(
        id: "dino-ages",
        title: "Dino Ages!",
        introAudio: "game-dino-ages"
    )
    static let pteroAges = DinoAgesGameConfig(
        id: "ptero-ages",
        title: "Ptero Ages!",
        introAudio: "game-ptero-ages"
    )
    static let marineAges = DinoAgesGameConfig(
        id: "marine-ages",
        title: "Marine Ages!",
        introAudio: "game-marine-ages"
    )

    static func config(for category: GameCategory) -> DinoAgesGameConfig {
        switch category {
        case .air: return pteroAges
        case .marineReptiles: return marineAges
        default: return dinoAges
        }
    }
}

#Preview {
    DinoAgesGameView(isPresented: .constant(true), gameConfig: DinoAgesGameConfigs.dinoAges)
}
