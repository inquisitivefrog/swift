//
//  DinoFormationsGameView.swift
//  DinoGames
//
//  Dino Formations: Pick a named formation. Three rounds; each round: 5 dinos (3 from formation, 2 from elsewhere).
//  Player selects the 3 that are found in the formation shown. No repeat dinosaurs across rounds. Victory: walk 9 selected (~4 visible), then game card + good-job + crowd-cheering.
//

import SwiftUI

struct DinoFormationsGameConfig {
    let id: String
    let title: String
    let introAudio: String?
}

// MARK: - Formation (named fossil formation)

/// Same pool as Name That Dinosaur: all bundled `dino-*` portraits from `LandDinosaurData`.
private let dinoFormationsPool: [Dinosaur] = LandDinosaurData.allDinosaurs.filter {
    $0.imageName?.hasPrefix("dino-") == true
}

/// Formation → dinosaurs: loaded from `json/dino-formations` + `json/dinosaurs/char_*.json`.
private let dinoFormationsList: [DinoFormation] = {
    let poolImageNames = Set(dinoFormationsPool.compactMap(\.imageName))
    return DinoFormationsCatalog.playableFormations.filter { formation in
        formation.dinoImageNames.filter { poolImageNames.contains($0) }.count >= 3
    }
}()

/// Dinosaur belongs to formation if its imageName is in that formation's set.
private func dinoFormationsIsInFormation(_ dino: Dinosaur, _ formation: DinoFormation) -> Bool {
    guard let name = dino.imageName else { return false }
    return formation.dinoImageNames.contains(name)
}

/// Diameter of each dinosaur circle (match Dino Ages).
private let dinoFormationsCircleSize: CGFloat = 96

private let dinoFormationsStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5
]

private func dinoFormationsTimeSeed() -> UInt64 {
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

struct DinoFormationsGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoFormationsGameConfig

    @State private var speechManager = SpeechManager()
    @State private var formation: DinoFormation?
    @State private var slots: [Dinosaur] = []
    @State private var matchedIds: Set<Int> = []
    @State private var isAudioPlaying = false
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var currentRound = 1
    @State private var usedDinosaurIds: Set<Int> = []
    @State private var usedFormationIds: Set<String> = []
    @State private var victoryWalkDinosaurs: [Dinosaur] = []
    @State private var matchedOrderThisRound: [Int] = []
    @State private var introWalkIndex: Int? = nil
    /// Current dinosaur name shown during intro walk or after tap (before feedback).
    @State private var displayedDinoName: String? = nil
    /// Prevents intro from playing twice when onAppear fires more than once.
    @State private var hasStartedGame = false
    /// When true, show the formation hints overlay (location + period).
    @State private var showFormationHints = false

    private let totalRounds = 3
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
        .overlay(alignment: .topTrailing) {
            if formation != nil, !isGameComplete {
                Button {
                    showFormationHints = true
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
        .fullScreenCover(isPresented: $showFormationHints) {
            if let f = formation {
                FormationHintsView(formation: f, onDismiss: { showFormationHints = false })
            }
        }
    }

    @ViewBuilder
    private var gameBody: some View {
        if let f = formation, !isGameComplete {
            VStack(spacing: 6) {
                formationImage(f)
                Text(f.name)
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
                fiveStarLayout
            }
        } else if isGameComplete {
            endSequenceView
                .id("dino-formations-victory")
        } else {
            ProgressView("Loading…")
                .padding()
        }
    }

    private func formationImage(_ f: DinoFormation) -> some View {
        Group {
            if ImageAssetCache.imageExists(named: f.imageName) {
                Image(f.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.2))
                    .frame(width: 260, height: 130)
                    .overlay(Text(f.name).font(.title2))
            }
        }
        .padding(.horizontal)
    }

    private var fiveStarLayout: some View {
        DinoFormationsStarLayoutView(slots: slots, matchedIds: matchedIds, introHighlightIndex: introWalkIndex, tapHandler: DinoFormationsTapHandler(perform: handleTap))
            .frame(height: 320)
            .padding(.horizontal)
    }

    private func handleTap(dino: Dinosaur) {
        guard !isAudioPlaying, let f = formation else { return }
        let isCorrect = dinoFormationsIsInFormation(dino, f)
        if isCorrect {
            if matchedIds.contains(dino.id) { return }
            matchedIds.insert(dino.id)
            matchedOrderThisRound.append(dino.id)
        }
        // Play dinosaur name and show text first, then give feedback.
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
            if let url = speechManager.urlForAudio(key: "try-again") {
                speechManager.playAudioFile(url: url)
            } else {
                speechManager.speak("try-again")
            }
        }
    }

    /// IDs excluded from round 1 only (so round 1 favors other formations; rounds 2–3 can use any).
    private static let formationsExcludedFromRoundOne: Set<String> = ["morrison", "hell-creek"]

    /// Picks a formation for the next round. Prefers formations not yet used this game; among those, prefers ones with enough unused dinosaurs so we avoid re-using dinos when possible.
    /// When excludeMorrisonAndHellCreek is true (round 1), Morrison and Hell Creek are not allowed.
    private func pickFormationForRound(using rng: inout SeededRandomNumberGenerator, excludeMorrisonAndHellCreek: Bool = false) -> DinoFormation {
        let baseList = excludeMorrisonAndHellCreek
            ? dinoFormationsList.filter { !Self.formationsExcludedFromRoundOne.contains($0.id) }
            : dinoFormationsList
        let list = baseList.isEmpty ? dinoFormationsList : baseList
        let notYetUsed = list.filter { !usedFormationIds.contains($0.id) }
        let pool = notYetUsed.isEmpty ? list : notYetUsed
        let withEnoughUnused = pool.filter { f in
            let inF = dinoFormationsPool.filter { dinoFormationsIsInFormation($0, f) }
            let outF = dinoFormationsPool.filter { !dinoFormationsIsInFormation($0, f) }
            let inUnused = inF.filter { !usedDinosaurIds.contains($0.id) }
            let outUnused = outF.filter { !usedDinosaurIds.contains($0.id) }
            return inUnused.count >= 3 && outUnused.count >= 2
        }
        return withEnoughUnused.randomElement(using: &rng) ?? pool.randomElement(using: &rng)!
    }

    private func buildSlotsForRound(using rng: inout SeededRandomNumberGenerator) {
        guard let f = formation else { return }
        let inFormation = dinoFormationsPool.filter { dinoFormationsIsInFormation($0, f) }
        let outFormation = dinoFormationsPool.filter { !dinoFormationsIsInFormation($0, f) }
        let inPreferred = inFormation.filter { !usedDinosaurIds.contains($0.id) }
        let outPreferred = outFormation.filter { !usedDinosaurIds.contains($0.id) }
        // Prefer unused dinosaurs; fall back to any in/out so we can always fill round 2 and 3 (exactly three rounds).
        let inPool = inPreferred.count >= 3 ? inPreferred : inFormation
        let outPool = outPreferred.count >= 2 ? outPreferred : outFormation
        let corrects = Array(inPool.shuffled(using: &rng).prefix(3))
        let wrongs = Array(outPool.shuffled(using: &rng).prefix(2))
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
        // Only three rounds: if we just finished round 3, go to victory.
        if currentRound >= totalRounds {
            isGameComplete = true
            return
        }
        currentRound += 1
        var rng = SeededRandomNumberGenerator(seed: dinoFormationsTimeSeed())
        formation = pickFormationForRound(using: &rng)
        usedFormationIds.insert(formation!.id)
        buildSlotsForRound(using: &rng)
        playFormationsHintThenFindInFormation()
    }

    /// Play game-hint then start round (formation name → choose-a-dinosaur → walk dinosaur names). Same pattern as Dino Footprints hint.
    private func playFormationsHintThenFindInFormation() {
        guard formation != nil else { return }
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFindInFormationThenAllowTaps()
        }
        if let url = speechManager.urlForAudio(key: "game-hint") {
            speechManager.playAudioFile(url: url)
        } else {
            playFindInFormationThenAllowTaps()
        }
    }

    /// Round begin: play formation name (Audio/Formations/{slug}.m4a), then invitation (choose three dinosaurs...), then walk the five dinosaur names with text.
    private func playFindInFormationThenAllowTaps() {
        guard let f = formation else { return }
        isAudioPlaying = true
        // 1. Formation name from Audio/Formations/{slug}.m4a
        let formationNameKey = "formation-name-\(f.id)"
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playChooseDinosaurThenStartWalk()
        }
        if let url = speechManager.urlForAudio(key: formationNameKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(f.name)
        }
    }

    private func playChooseDinosaurThenStartWalk() {
        // 2. Invitation: "choose three dinosaurs whose fossils are found in this formation" — Audio/Games/game-dino-formations-choose-a-dinosaur.m4a
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.startIntroWalk()
        }
        if let url = speechManager.urlForAudio(key: "game-dino-formations-choose-a-dinosaur") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("game-dino-formations-choose-a-dinosaur")
        }
    }

    /// Walk the five dinosaurs: play each name and display text; then allow taps.
    private func startIntroWalk() {
        guard slots.count >= 5 else {
            isAudioPlaying = false
            return
        }
        introWalkIndex = 0
        displayedDinoName = slots[0].name
        isAudioPlaying = true
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[0].imageName ?? slots[0].name, fallbackText: slots[0].name)
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedDinoName = nil
            isAudioPlaying = false
            return
        }
        introWalkIndex = next
        displayedDinoName = slots[next].name
        speechManager.onAudioFinished = { advanceIntroWalk() }
        speechManager.speak(audioKey: slots[next].imageName ?? slots[next].name, fallbackText: slots[next].name)
    }

    private func startGame() {
        var rng = SeededRandomNumberGenerator(seed: dinoFormationsTimeSeed())
        usedFormationIds = []
        formation = pickFormationForRound(using: &rng, excludeMorrisonAndHellCreek: true)
        usedFormationIds.insert(formation!.id)
        currentRound = 1
        usedDinosaurIds = []
        victoryWalkDinosaurs = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        buildSlotsForRound(using: &rng)
        guard formation != nil else { return }
        // Skip playing game name here; it was already played when the user selected the game. Play game-hint then formation name → choose-a-dinosaur → walk dinosaur names.
        isAudioPlaying = true
        playFormationsHintThenFindInFormation()
    }

    // MARK: - End sequence (victory list ~3–4 rows visible, then game card + good-job + crowd-cheering)

    private let victoryRowHeight: CGFloat = 100
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

    private var endSequenceView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                // Top: scrolling list (fixed height ~4 rows)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(uniqueVictoryDinosaurs.enumerated()), id: \.element.id) { index, dino in
                                DinoFormationsEndRowView(dino: dino, isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex)
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

                // Bottom: after walk, show game card (success image if exists, else main game card)
                Group {
                    if endSequenceStep == 2 {
                        dinoFormationsSuccessImageView
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
                speechManager.onAudioFinished = { self.advanceEndHighlight() }
            }
        }
    }

    /// Game card at end: prefer game-dino-formations-success; fall back to game-dino-formations until success image is added.
    private var dinoFormationsSuccessImageView: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-formations-success") {
                Image("game-dino-formations-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: "game-dino-formations") {
                Image("game-dino-formations")
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

    /// Victory list with duplicates removed by id (first occurrence kept) so we don't show the same dinosaur twice.
    private var uniqueVictoryDinosaurs: [Dinosaur] {
        var seen = Set<Int>()
        return victoryWalkDinosaurs.filter { seen.insert($0.id).inserted }
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

// MARK: - Star layout

private struct DinoFormationsTapHandler {
    let perform: (Dinosaur) -> Void
}

private struct DinoFormationsStarLayoutView: View {
    let slots: [Dinosaur]
    let matchedIds: Set<Int>
    let introHighlightIndex: Int?
    let tapHandler: DinoFormationsTapHandler
    private let radius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(slots.enumerated()), id: \.offset) { index, dino in
                    DinoFormationsCircleView(dino: dino, isMatched: matchedIds.contains(dino.id), isIntroHighlighted: introHighlightIndex == index)
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

private struct DinoFormationsCircleView: View {
    let dino: Dinosaur
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = dino.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: dinoFormationsCircleSize, height: dinoFormationsCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: dinoFormationsCircleSize, height: dinoFormationsCircleSize)
                    .overlay(Text(dino.icon).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2).frame(width: dinoFormationsCircleSize, height: dinoFormationsCircleSize))
        .opacity(isMatched ? 0.9 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.4)
    }
}

/// Victory list: square images (72×72) like Match the Dinosaur, not circles — consistent across all games.
private let dinoFormationsVictoryImageSize: CGFloat = 72

private struct DinoFormationsEndRowView: View {
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
                        .frame(width: dinoFormationsVictoryImageSize, height: dinoFormationsVictoryImageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                } else {
                    Text(dino.icon)
                        .font(.system(size: 40))
                        .frame(width: dinoFormationsVictoryImageSize, height: dinoFormationsVictoryImageSize)
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

// MARK: - Formation Hints (location + period)

struct FormationHintsView: View {
    let formation: DinoFormation
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 24) {
                Text("Formation Hints")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 44)
                VStack(alignment: .leading, spacing: 16) {
                    Text(formation.name)
                        .font(.title3.weight(.semibold))
                    if let loc = formation.hintLocation, !loc.isEmpty {
                        Label(loc, systemImage: "mappin.circle.fill")
                            .font(.body)
                    }
                    if let period = formation.hintPeriod, !period.isEmpty {
                        Label(period, systemImage: "clock.fill")
                            .font(.body)
                    }
                    if (formation.hintLocation ?? "").isEmpty && (formation.hintPeriod ?? "").isEmpty {
                        Text("No hint data for this formation.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))

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
    }
}

// MARK: - Configs

enum DinoFormationsGameConfigs {
    static let dinoFormations = DinoFormationsGameConfig(
        id: "dino-formations",
        title: "Dino Formations!",
        introAudio: "game-dino-formations"
    )
}

#Preview {
    DinoFormationsGameView(isPresented: .constant(true), gameConfig: DinoFormationsGameConfigs.dinoFormations)
}
