//
//  DinoFossilHuntGameView.swift
//  DinoGames
//
//  Dino Fossil Hunt: one quest per session (4 rounds: discovery → excavate → preserve → transport).
//  Each round shows a story image and directions audio, then the player picks 2 of 5 tools (same star layout as Dino Flora).
//

import SwiftUI

// MARK: - Config types (public for GameType / catalog)

enum FossilHuntPhase: String, CaseIterable, Identifiable {
    case discovery
    case excavate
    case preserve
    case transport

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .discovery: return "Discovery"
        case .excavate: return "Excavate"
        case .preserve: return "Preserve"
        case .transport: return "Transport"
        }
    }
}

/// One tool in the fossil-hunt palette. Thumbnails use **`dino-tools-{slug}`** imagesets.
struct FossilHuntTool: Identifiable, Hashable {
    let id: String
    let displayLabel: String
    /// Imageset name `dino-tools-{slug}` when present; otherwise emoji fallback.
    let imageName: String?
    let emoji: String
    /// Optional intro audio key (e.g. tool name clip). Falls back to `displayLabel` TTS.
    let introAudioKey: String?
}

struct DinoFossilHuntRoundConfig: Identifiable {
    var id: String { "\(storyNumber)-\(phase.rawValue)" }
    /// Story index 1…N (N = `fossilHuntStoryLibrary.count`).
    let storyNumber: Int
    let phase: FossilHuntPhase
    /// Large story image (imageset) for this beat — your art, not the tool thumbnails.
    let storyImageName: String
    /// `game-dino-fossil-hunt-{story}-{stage}` → `Games/game-dino-fossil-hunt-{story}-{stage}.m4a`
    let directionsAudioKey: String
    /// Exactly two tool slugs matching **`dino-tools-{slug}`** (the two critical tools).
    let correctToolIds: [String]

    var correctIdSet: Set<String> { Set(correctToolIds) }
}

struct DinoFossilHuntQuestConfig {
    let id: String
    let displayName: String
    let rounds: [DinoFossilHuntRoundConfig]
}

struct DinoFossilHuntGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let quest: DinoFossilHuntQuestConfig
}

// MARK: - Tool palette (5 tools: imagesets `dino-tools-{slug}`)

/// Fixed order for star layout; slugs must match your `dino-tools-*` imagesets.
private let fossilHuntToolSlugs: [String] = ["magnifier", "sem", "scanner", "rock-hammer", "brush"]

private let fossilHuntToolLabels: [String: String] = [
    "magnifier": "Magnifying glass",
    "sem": "SEM microscope",
    "scanner": "CT scanner",
    "rock-hammer": "Rock hammer",
    "brush": "Brush",
]

private let fossilHuntToolEmojis: [String: String] = [
    "magnifier": "🔍",
    "sem": "🔬",
    "scanner": "📡",
    "rock-hammer": "🔨",
    "brush": "🖌️",
]

private func fossilHuntTool(forSlug slug: String) -> FossilHuntTool {
    let name = "dino-tools-\(slug)"
    return FossilHuntTool(
        id: slug,
        displayLabel: fossilHuntToolLabels[slug] ?? slug,
        imageName: name,
        emoji: fossilHuntToolEmojis[slug] ?? "🔧",
        introAudioKey: nil
    )
}

private var fossilHuntToolPalette: [FossilHuntTool] {
    fossilHuntToolSlugs.map { fossilHuntTool(forSlug: $0) }
}

/// The three tools that are wrong answers for this beat (palette minus the two critical slugs).
private func fossilHuntDistractionSlugs(critical: [String]) -> [String] {
    let c = Set(critical)
    return fossilHuntToolSlugs.filter { !c.contains($0) }
}

// MARK: - Star layout (same pentagon as Dino Flora)

private let fossilHuntStarAngles: [Double] = [
    -Double.pi / 2,
    -Double.pi / 2 + 2 * Double.pi / 5,
    -Double.pi / 2 + 4 * Double.pi / 5,
    -Double.pi / 2 + 6 * Double.pi / 5,
    -Double.pi / 2 + 8 * Double.pi / 5,
]

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private func fossilHuntTimeSeed() -> UInt64 {
    UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1_000_000))
}

private let fossilHuntToolCircleSize: CGFloat = 88

// MARK: - Story map (draft) — critical vs distraction tools
//
// **Small circles (always 5):** imagesets `dino-tools-{slug}` for slug in `fossilHuntToolSlugs`.
//
// **Audio (directions each beat):** `Games/game-dino-fossil-hunt-{story}-{stage}.m4a`
//   with story ∈ 1…N (N = number of stories in `fossilHuntStoryLibrary`) and stage ∈ discovery | excavate | preserve | transport.
//
// For each cell: **Critical** = the two tools players must tap. **Distractions** = the other three slugs
// (computed by `fossilHuntDistractionSlugs(critical:)` — not stored separately).
//
// ```
// Story │ Stage      │ Story image (large)          │ Critical (dino-tools-*)     │ Distractions (implicit)
// ------+------------+------------------------------+-----------------------------+---------------------------
// 1     │ discovery  │ fossil-hunt-1-discovery      │ magnifier, scanner          │ sem, rock-hammer, brush
// 1     │ excavate   │ fossil-hunt-1-excavate       │ rock-hammer, brush          │ magnifier, sem, scanner
// 1     │ preserve   │ fossil-hunt-1-preserve       │ sem, brush                  │ magnifier, scanner, rock-hammer
// 1     │ transport  │ fossil-hunt-1-transport      │ scanner, rock-hammer        │ magnifier, sem, brush
// 2     │ discovery  │ fossil-hunt-2-discovery      │ scanner, sem                │ magnifier, rock-hammer, brush
// 2     │ excavate   │ fossil-hunt-2-excavate       │ magnifier, rock-hammer      │ sem, scanner, brush
// 2     │ preserve   │ fossil-hunt-2-preserve       │ brush, scanner              │ magnifier, sem, rock-hammer
// 2     │ transport  │ fossil-hunt-2-transport      │ magnifier, brush            │ sem, scanner, rock-hammer
// 3     │ discovery  │ fossil-hunt-3-discovery      │ magnifier, brush            │ sem, scanner, rock-hammer
// 3     │ excavate   │ fossil-hunt-3-excavate       │ scanner, sem                │ magnifier, rock-hammer, brush
// 3     │ preserve   │ fossil-hunt-3-preserve       │ rock-hammer, scanner        │ magnifier, sem, brush
// 3     │ transport  │ fossil-hunt-3-transport      │ sem, rock-hammer            │ magnifier, scanner, brush
// 4     │ discovery  │ fossil-hunt-4-discovery      │ rock-hammer, magnifier      │ sem, scanner, brush
// 4     │ excavate   │ fossil-hunt-4-excavate       │ brush, scanner              │ magnifier, sem, rock-hammer
// 4     │ preserve   │ fossil-hunt-4-preserve       │ magnifier, sem              │ scanner, rock-hammer, brush
// 4     │ transport  │ fossil-hunt-4-transport      │ scanner, brush              │ magnifier, sem, rock-hammer
// ```
//
// Rename `fossil-hunt-{story}-{stage}` imagesets or edit `FossilHuntStoryDefinition` below to match your art.

private struct FossilHuntBeatDef {
    let storyImageName: String
    /// Two slugs — must be distinct and each ∈ `fossilHuntToolSlugs`.
    let criticalToolSlugs: [String]
}

private struct FossilHuntStoryDefinition {
    let storyId: Int
    let title: String
    let beats: [FossilHuntPhase: FossilHuntBeatDef]
}

private let fossilHuntStoryLibrary: [FossilHuntStoryDefinition] = [
    FossilHuntStoryDefinition(
        storyId: 1,
        title: "Story 1",
        beats: [
            .discovery: FossilHuntBeatDef(storyImageName: "fossil-hunt-1-discovery", criticalToolSlugs: ["magnifier", "scanner"]),
            .excavate: FossilHuntBeatDef(storyImageName: "fossil-hunt-1-excavate", criticalToolSlugs: ["rock-hammer", "brush"]),
            .preserve: FossilHuntBeatDef(storyImageName: "fossil-hunt-1-preserve", criticalToolSlugs: ["sem", "brush"]),
            .transport: FossilHuntBeatDef(storyImageName: "fossil-hunt-1-transport", criticalToolSlugs: ["scanner", "rock-hammer"]),
        ]
    ),
    FossilHuntStoryDefinition(
        storyId: 2,
        title: "Story 2",
        beats: [
            .discovery: FossilHuntBeatDef(storyImageName: "fossil-hunt-2-discovery", criticalToolSlugs: ["scanner", "sem"]),
            .excavate: FossilHuntBeatDef(storyImageName: "fossil-hunt-2-excavate", criticalToolSlugs: ["magnifier", "rock-hammer"]),
            .preserve: FossilHuntBeatDef(storyImageName: "fossil-hunt-2-preserve", criticalToolSlugs: ["brush", "scanner"]),
            .transport: FossilHuntBeatDef(storyImageName: "fossil-hunt-2-transport", criticalToolSlugs: ["magnifier", "brush"]),
        ]
    ),
    FossilHuntStoryDefinition(
        storyId: 3,
        title: "Story 3",
        beats: [
            .discovery: FossilHuntBeatDef(storyImageName: "fossil-hunt-3-discovery", criticalToolSlugs: ["magnifier", "brush"]),
            .excavate: FossilHuntBeatDef(storyImageName: "fossil-hunt-3-excavate", criticalToolSlugs: ["scanner", "sem"]),
            .preserve: FossilHuntBeatDef(storyImageName: "fossil-hunt-3-preserve", criticalToolSlugs: ["rock-hammer", "scanner"]),
            .transport: FossilHuntBeatDef(storyImageName: "fossil-hunt-3-transport", criticalToolSlugs: ["sem", "rock-hammer"]),
        ]
    ),
    FossilHuntStoryDefinition(
        storyId: 4,
        title: "Story 4",
        beats: [
            .discovery: FossilHuntBeatDef(storyImageName: "fossil-hunt-4-discovery", criticalToolSlugs: ["rock-hammer", "magnifier"]),
            .excavate: FossilHuntBeatDef(storyImageName: "fossil-hunt-4-excavate", criticalToolSlugs: ["brush", "scanner"]),
            .preserve: FossilHuntBeatDef(storyImageName: "fossil-hunt-4-preserve", criticalToolSlugs: ["magnifier", "sem"]),
            .transport: FossilHuntBeatDef(storyImageName: "fossil-hunt-4-transport", criticalToolSlugs: ["scanner", "brush"]),
        ]
    ),
]

private func fossilHuntQuest(from def: FossilHuntStoryDefinition) -> DinoFossilHuntQuestConfig {
    let rounds: [DinoFossilHuntRoundConfig] = FossilHuntPhase.allCases.map { phase in
        guard let beat = def.beats[phase] else {
            fatalError("Missing beat story \(def.storyId) phase \(phase)")
        }
        let critical = beat.criticalToolSlugs
        assert(Set(critical).count == 2, "Story \(def.storyId) \(phase) must have two distinct critical tools")
        return DinoFossilHuntRoundConfig(
            storyNumber: def.storyId,
            phase: phase,
            storyImageName: beat.storyImageName,
            directionsAudioKey: "game-dino-fossil-hunt-\(def.storyId)-\(phase.rawValue)",
            correctToolIds: critical
        )
    }
    return DinoFossilHuntQuestConfig(id: "\(def.storyId)", displayName: def.title, rounds: rounds)
}

private let dinoFossilHuntAllQuests: [DinoFossilHuntQuestConfig] = fossilHuntStoryLibrary.map { fossilHuntQuest(from: $0) }

// MARK: - View

struct DinoFossilHuntGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoFossilHuntGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var hasStartedGame = false
    @State private var currentRoundIndex = 0
    @State private var toolSlots: [FossilHuntTool] = []
    @State private var matchedToolIds: Set<String> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var introWalkIndex: Int?
    @State private var displayedToolLabel: String?

    private let matchesNeededPerRound = 2

    private var quest: DinoFossilHuntQuestConfig { gameConfig.quest }
    private var totalRounds: Int { quest.rounds.count }
    private var roundConfig: DinoFossilHuntRoundConfig? {
        guard currentRoundIndex < quest.rounds.count else { return nil }
        return quest.rounds[currentRoundIndex]
    }

    private var correctIdsThisRound: Set<String> {
        roundConfig?.correctIdSet ?? []
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
        VStack(spacing: 18) {
            Text(gameConfig.title)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            if isGameComplete {
                endSequenceView
            } else if let r = roundConfig {
                activeRoundStack(round: r)
            } else {
                ProgressView("Loading…")
            }
        }
    }

    @ViewBuilder
    private func activeRoundStack(round r: DinoFossilHuntRoundConfig) -> some View {
        VStack(spacing: 10) {
            storyImageView(r)
            Text(r.phase.displayTitle)
                .font(.title2.weight(.semibold))
            Text("Round \(currentRoundIndex + 1) of \(totalRounds)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Pick any two tools that help for this step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ZStack {
                if let label = displayedToolLabel {
                    Text(label)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 32)

            fossilHuntStarLayout
                .frame(height: 300)
                .padding(.horizontal)
        }
    }

    private func storyImageView(_ r: DinoFossilHuntRoundConfig) -> some View {
        Group {
            if ImageAssetCache.imageExists(named: r.storyImageName) {
                Image(r.storyImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 220)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 280, height: 160)
                    .overlay(
                        VStack(spacing: 6) {
                            Text(r.phase.displayTitle)
                                .font(.title3.weight(.semibold))
                            Text(r.storyImageName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
        .padding(.horizontal)
    }

    private var fossilHuntStarLayout: some View {
        GeometryReader { geo in
            let radius: CGFloat = 96
            ZStack(alignment: .center) {
                ForEach(Array(toolSlots.enumerated()), id: \.offset) { index, tool in
                    FossilHuntToolCircleView(
                        tool: tool,
                        isMatched: matchedToolIds.contains(tool.id),
                        isIntroHighlighted: introWalkIndex == index
                    )
                    .position(
                        x: geo.size.width / 2 + radius * CGFloat(cos(fossilHuntStarAngles[index])),
                        y: geo.size.height / 2 + 18 + radius * CGFloat(sin(fossilHuntStarAngles[index]))
                    )
                    .onTapGesture { handleToolTap(tool) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func startGame() {
        currentRoundIndex = 0
        matchedToolIds = []
        isGameComplete = false
        endSequenceStep = -1
        endHighlightIndex = 0
        introWalkIndex = nil
        displayedToolLabel = nil
        shuffleToolSlots()
        playIntroThenFirstRound()
    }

    private func playIntroThenFirstRound() {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.beginCurrentRoundDirections()
        }
        if let url = speechManager.urlForAudio(key: gameConfig.introAudio) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(gameConfig.title)
        }
    }

    private func beginCurrentRoundDirections() {
        guard let r = roundConfig else { return }
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playHintThenToolWalk()
        }
        if let url = speechManager.urlForAudio(key: r.directionsAudioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Listen for the tools that help in this step. Then tap two correct tools.")
        }
    }

    private func playHintThenToolWalk() {
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

    private func shuffleToolSlots() {
        var rng = SeededRNG(seed: fossilHuntTimeSeed() &+ UInt64(currentRoundIndex * 17))
        toolSlots = fossilHuntToolPalette.shuffled(using: &rng)
    }

    private func startIntroWalk() {
        guard toolSlots.count >= 5 else { return }
        introWalkIndex = 0
        displayedToolLabel = toolSlots[0].displayLabel
        speechManager.onAudioFinished = { advanceIntroWalk() }
        playToolIntro(toolSlots[0])
    }

    private func playToolIntro(_ tool: FossilHuntTool) {
        if let key = tool.introAudioKey, let url = speechManager.urlForAudio(key: key) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(tool.displayLabel)
        }
    }

    private func advanceIntroWalk() {
        speechManager.onAudioFinished = nil
        let next = (introWalkIndex ?? 0) + 1
        if next >= 5 {
            introWalkIndex = nil
            displayedToolLabel = nil
            return
        }
        introWalkIndex = next
        displayedToolLabel = toolSlots[next].displayLabel
        speechManager.onAudioFinished = { advanceIntroWalk() }
        playToolIntro(toolSlots[next])
    }

    private func handleToolTap(_ tool: FossilHuntTool) {
        guard introWalkIndex == nil, !speechManager.isPlaying else { return }

        if matchedToolIds.contains(tool.id) { return }

        let isCorrect = correctIdsThisRound.contains(tool.id)
        displayedToolLabel = tool.displayLabel

        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playFeedbackAfterTap(tool: tool, correct: isCorrect)
        }
        playToolIntro(tool)
    }

    private func playFeedbackAfterTap(tool: FossilHuntTool, correct: Bool) {
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.displayedToolLabel = nil
            if correct {
                self.matchedToolIds.insert(tool.id)
                if self.matchedToolIds.isSuperset(of: self.correctIdsThisRound) {
                    self.finishRound()
                }
            }
        }
        if correct {
            speechManager.speak("great-match")
        } else {
            speechManager.speak("try-again")
        }
    }

    private func finishRound() {
        if currentRoundIndex + 1 >= totalRounds {
            isGameComplete = true
            return
        }
        currentRoundIndex += 1
        matchedToolIds = []
        introWalkIndex = nil
        displayedToolLabel = nil
        shuffleToolSlots()
        beginCurrentRoundDirections()
    }

    // MARK: - Victory (mirror Dino Flora: recap rows + success art + crowd)

    private let victoryRowHeight: CGFloat = 72

    private var victoryListVisibleHeight: CGFloat {
        let n = min(4, totalRounds)
        let rowCount = CGFloat(max(1, n))
        let gaps = CGFloat(max(0, n - 1))
        return 16 + rowCount * victoryRowHeight + gaps * 10 + 16
    }

    private var endSequenceView: some View {
        GeometryReader { _ in
            endSequenceRootVStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: endSequenceOnAppear)
    }

    private var endSequenceRootVStack: some View {
        VStack(spacing: 0) {
            Text("You finished the quest!")
                .font(.title2.weight(.semibold))
                .padding(.top, 8)
            endSequenceScrollBlock
            endSequenceBottomGroup
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var endSequenceScrollBlock: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(quest.rounds.enumerated()), id: \.offset) { index, r in
                        FossilHuntVictoryRow(
                            phase: r.phase,
                            isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.visible)
            .frame(height: victoryListVisibleHeight)
            .onChange(of: endHighlightIndex) { _, newValue in
                scrollVictoryToIndex(proxy: proxy, index: newValue)
            }
        }
    }

    private func scrollVictoryToIndex(proxy: ScrollViewProxy, index: Int) {
        guard index < quest.rounds.count else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(index, anchor: .center)
        }
    }

    @ViewBuilder
    private var endSequenceBottomGroup: some View {
        if endSequenceStep == 2 {
            successImage
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

    private func endSequenceOnAppear() {
        guard endSequenceStep == -1 else { return }
        endSequenceStep = 1
        endHighlightIndex = 0
        if quest.rounds.isEmpty {
            endSequenceStep = 2
        } else {
            let r = quest.rounds[0]
            speechManager.speak(r.phase.displayTitle)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
        }
    }

    private var successImage: some View {
        Group {
            if ImageAssetCache.imageExists(named: "game-dino-fossil-hunt-success") {
                Image("game-dino-fossil-hunt-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🏆")
                    .font(.system(size: 100))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < quest.rounds.count {
            let r = quest.rounds[endHighlightIndex]
            speechManager.speak(r.phase.displayTitle)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
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
                self.isPresented = false
            }
        } else if let u = goodJobURL ?? crowdURL {
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.isPresented = false
            }
            speechManager.playAudioFile(url: u)
        } else {
            isPresented = false
        }
    }
}

// MARK: - Subviews

private struct FossilHuntToolCircleView: View {
    let tool: FossilHuntTool
    let isMatched: Bool
    var isIntroHighlighted: Bool = false

    var body: some View {
        Group {
            if let name = tool.imageName, ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: fossilHuntToolCircleSize, height: fossilHuntToolCircleSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: fossilHuntToolCircleSize, height: fossilHuntToolCircleSize)
                    .overlay(Text(tool.emoji).font(.system(size: 32)))
            }
        }
        .scaleEffect(isIntroHighlighted ? 1.06 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isIntroHighlighted)
        .overlay(Circle().stroke(strokeColor, lineWidth: isMatched || isIntroHighlighted ? 4 : 2)
            .frame(width: fossilHuntToolCircleSize, height: fossilHuntToolCircleSize))
        .opacity(isMatched ? 0.92 : 1.0)
    }

    private var strokeColor: Color {
        if isMatched { return .green }
        if isIntroHighlighted { return Color.accentColor }
        return Color.gray.opacity(0.35)
    }
}

private struct FossilHuntVictoryRow: View {
    let phase: FossilHuntPhase
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(phaseEmoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .opacity(isHighlighted ? 1 : 0.45)
            Text(phase.displayTitle)
                .font(.title3.weight(isHighlighted ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isHighlighted ? 1 : 0.55)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2))
    }

    private var phaseEmoji: String {
        switch phase {
        case .discovery: return "🔎"
        case .excavate: return "⛏️"
        case .preserve: return "🧪"
        case .transport: return "🚚"
        }
    }
}

// MARK: - Catalog entry

enum DinoFossilHuntGameConfigs {
    /// Picks a random story each session. Add entries to `fossilHuntStoryLibrary` to grow N.
    static var dinoFossilHunt: DinoFossilHuntGameConfig {
        var rng = SeededRNG(seed: fossilHuntTimeSeed())
        let quest = dinoFossilHuntAllQuests.randomElement(using: &rng) ?? dinoFossilHuntAllQuests[0]
        return DinoFossilHuntGameConfig(
            id: "dino-fossil-hunt",
            title: "Dino Fossil Hunt!",
            introAudio: "game-dino-fossil-hunt",
            quest: quest
        )
    }
}

#Preview {
    DinoFossilHuntGameView(isPresented: .constant(true), gameConfig: DinoFossilHuntGameConfigs.dinoFossilHunt)
}
