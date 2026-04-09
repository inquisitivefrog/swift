//
//  DinoFossilHuntGameView.swift
//  DinoGames
//
//  Dino Fossil Hunt: one quest per session (4 rounds: discovery → excavate → preserve → transport).
//  Each round: story art + directions audio, then pick 2 of 5 tools (star layout). Correct pair = random from a phase-appropriate
//  **paleontologist** pool; distractors default to **preparator + restorer** so dig vs lab vs digital reads clearly for kids.
//

import SwiftUI
import UIKit

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

/// Asset folders under `Assets.xcassets/Dinosaur-Tools/`: **paleontologist** (dig / field), **preparator** (lab prep), **restorer** (art & digital restoration).
/// Gameplay: suitable tools for a beat come from **one** group; distractors from the others so kids read dig vs prep vs screen work clearly.
enum FossilHuntToolGroup: String, CaseIterable {
    case paleontologist
    case preparator
    case restorer
}

/// One tool in the fossil-hunt palette. Thumbnails use **`dino-tools-field-*` / `lab-*` / `art-*`** (`fossilHuntAssetName`).
struct FossilHuntTool: Identifiable, Hashable {
    let id: String
    let displayLabel: String
    /// Imageset name when present; otherwise emoji fallback.
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
    /// Large story image (imageset) `dino-hunt-{storyKebab}-{phase}` — your art, not the tool thumbnails.
    let storyImageName: String
    /// `game-dino-fossil-hunt-{storyKebab}-{stage}` → `Games/game-dino-fossil-hunt-{storyKebab}-{stage}.m4a`
    let directionsAudioKey: String
    /// Paleontologist-folder tools appropriate for this story + phase; **two** are chosen at random as correct when the round starts.
    let suitableToolSlugs: [String]
    /// Suitable slugs belong to this tier; distractors are drawn from the **other** tiers (e.g. preparator + restorer when this beat is paleontologist).
    let suitableToolGroup: FossilHuntToolGroup
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

// MARK: - Tool catalogs (imagesets `dino-tools-field-*` / `lab-*` / `art-*` — see `fossilHuntAssetName`)

/// Every `dino-tools-field-*` imageset used by Fossil Hunt (see `fossilHuntAssetName`); phase pools decide what can be a correct answer.
private let fossilHuntPaleontologistToolSlugs: [String] = [
    "acid-kit", "aerial-lift", "basecamp-tent", "blm-permit", "boots", "bulk-matrix-bag",
    "cliff-scaffold", "climbing-harness", "clinometer", "data-link-cable", "data-slate", "debris-netting",
    "dental-pick", "digging-shovel", "dry-sieve-stack", "dslr-camera", "dust-blower",
    "fine-brush", "fine-chisel", "flagging-tape", "gasoline-generator", "gnss-surveyor",
    "gpr-surveyor", "gps", "grid-kit", "hand-held-sifting-screen", "headlamp", "jack-hammer",
    "journal", "lab-tent", "ladder", "laptop", "laser-scanner", "ledger", "light-tower",
    "locality-map", "long-handled-net", "medium-chisel", "mess-tent", "micro-vial-set", "notes",
    "optical-lens", "perimeter-kit", "personal-locator-beacon", "photo-scale", "pick-axe",
    "pickup-truck", "plaster-jacket", "polyurethane-foam", "ppe", "precision-awl",
    "precision-forceps", "private-land-consent", "private-landowner-gift", "reclamation-report",
    "reclamation-seeds", "reclamation-tarp", "rock-color-chart", "rock-hammer", "rock-saw",
    "satellite-phone", "satellite-terminal", "separation-layer", "shale-splitter",
    "shipping-manifest", "sifting-screen", "site-cover", "site-notice", "sledge-hammer",
    "slotted-shale-crate", "solar-array", "solar-battery", "specimen-crate", "specimen-saw",
    "specimen-stabilizer", "specimen-vial", "storage-tent", "surveyor-level", "tape-measure",
    "tool-kit", "trailer-transport", "transfer-shovel", "transport-pallet", "transport-sled",
    "tribal-permit", "vehicle-suv-4wd", "wash-cradle", "waterproof-collection", "weather-station",
    "wet-sieve-stack", "wide-brush",
]

/// Every `dino-tools-lab-*` imageset (preparator / distractor tier).
private let fossilHuntPreparatorToolSlugs: [String] = [
    "abrasive-cabinet", "abrasive-media", "acid-tank", "adhesive-station", "air-drop",
    "air-dryer", "air-scrubber", "archive-drawer", "archive-stats", "cast-saw", "compressor",
    "cradling", "ct-render", "detail-brush", "downdraft-bench", "dust-snorkel",
    "exhaust-fume-hood", "heavy-cabinet", "intake-station", "jacket-separator", "micro-blaster",
    "micro-prep", "microscope-view", "mobile-scanner", "petri-dish", "picking-brush", "pin-vise",
    "ppe", "precision-measuring", "prep-log", "pry-kit", "shipping-kit", "specimen-tag",
    "stereo-microscope", "tweezers",
]

private let fossilHuntRestorerToolSlugs: [String] = [
    "3d-printer", "digital-restoration", "ui-digital-repository", "ui-ecology-map", "ui-exhibit-label",
]

private func fossilHuntSlugs(in group: FossilHuntToolGroup) -> [String] {
    switch group {
    case .paleontologist: return fossilHuntPaleontologistToolSlugs
    case .preparator: return fossilHuntPreparatorToolSlugs
    case .restorer: return fossilHuntRestorerToolSlugs
    }
}

/// Phase-appropriate **paleontologist** (dig-site) tools, merged with per-story extras (`fossilHuntStoryPhaseExtras`).
private func fossilHuntPhaseBasePaleontologistSlugs(phase: FossilHuntPhase) -> [String] {
    switch phase {
    /// Land: `DINO_FOSSIL_HUNT_DISCOVERY_TOOLS.md` (no paperwork / site-admin). Uses `gps` for kid-friendly discovery; full catalog in Dino Tools.
    case .discovery:
        return [
            "locality-map", "tape-measure", "surveyor-level", "clinometer", "gps",
            "rock-color-chart", "grid-kit", "flagging-tape", "notes", "boots",
        ]
    /// Canonical excavate pool — see `DINO_FOSSIL_HUNT_EXCAVATE_TOOLS.md` (`hunt_phase = excavate` only).
    case .excavate:
        return [
            "dental-pick", "fine-chisel", "medium-chisel", "rock-hammer", "pick-axe", "transfer-shovel",
            "shale-splitter", "rock-saw", "hand-held-sifting-screen", "fine-brush", "wide-brush",
            "dust-blower",
        ]
    /// Packing / stabilizing only — no tools that belong in excavate or discovery (see `DINO_FOSSIL_HUNT_TOOL_IDENTIFIERS.md`).
    /// No `site-cover` (story art reads as fair weather / post-storm dry, not active rain).
    /// `separation-layer` (foil / barrier) = wrap and isolate — **preserve** only, not discovery or excavate.
    case .preserve:
        return [
            "plaster-jacket", "specimen-stabilizer", "micro-vial-set", "waterproof-collection",
            "separation-layer",
        ]
    /// Hauling — crates, sled, vehicles, lift. Imagesets `dino-tools-field-*` (helicopter TBD when art lands).
    case .transport:
        return [
            "transport-sled", "specimen-crate", "specimen-vial", "shipping-manifest", "slotted-shale-crate",
            "trailer-transport", "vehicle-suv-4wd", "pickup-truck", "aerial-lift",
        ]
    }
}

/// Basecamp / power — not “move the fossil” (transport) for this game.
private let fossilHuntCampInfrastructureSlugs: Set<String> = [
    "gasoline-generator", "light-tower", "solar-array", "solar-battery", "weather-station",
]

// MARK: - Fossil Hunt kid-friendly allowlists (full `dino-tools-*` catalog also used by future Dino Tools)

/// Dig-site tools acceptable as **correct** answers: hand tools, maps, common vehicles, packing — not advanced survey / chemistry / compliance art.
private let fossilHuntFossilHuntAllowedFieldSlugs: Set<String> = [
    "aerial-lift", "boots", "dental-pick", "dry-sieve-stack", "dust-blower", "fine-brush", "fine-chisel",
    "flagging-tape", "grid-kit", "hand-held-sifting-screen", "long-handled-net", "locality-map",
    "medium-chisel", "micro-vial-set", "notes", "pick-axe", "pickup-truck", "plaster-jacket", "gps",
    "rock-color-chart", "rock-hammer", "rock-saw", "separation-layer", "shipping-manifest",
    "shale-splitter", "sifting-screen", "slotted-shale-crate", "specimen-crate",
    "specimen-stabilizer", "specimen-vial", "surveyor-level", "tape-measure", "transfer-shovel",
    "transport-pallet", "transport-sled", "trailer-transport", "vehicle-suv-4wd",
    "waterproof-collection", "wet-sieve-stack", "wide-brush", "clinometer",
]

/// Preparator (`dino-tools-lab-*`) tools allowed as **distractors** — **must not** resemble field hand tools (no lab brushes / pry / tweezers / rulers / crates / tags that read like dig-kit).
/// Prefer fixed indoor lab gear so “wrong” taps still look like the museum prep room, not a confusing twin of a correct field icon.
private let fossilHuntFossilHuntAllowedLabSlugs: Set<String> = [
    "adhesive-station", "air-dryer", "archive-drawer", "cradling", "downdraft-bench",
    "exhaust-fume-hood", "heavy-cabinet", "microscope-view", "petri-dish", "stereo-microscope",
]

/// Restorer (`dino-tools-art-*`) distractors — concrete/familiar ideas only; defer heavy digital-restoration UI to Dino Tools.
private let fossilHuntFossilHuntAllowedArtSlugs: Set<String> = [
    "3d-printer", "ui-ecology-map", "ui-exhibit-label",
]

private func fossilHuntMergedSuitablePaleontologistSlugs(phase: FossilHuntPhase, extras: [String]) -> [String] {
    let base = fossilHuntPhaseBasePaleontologistSlugs(phase: phase)
    var merged = Array(Set(base + extras)).filter { fossilHuntPaleontologistToolSlugs.contains($0) }
    if phase == .transport {
        merged.removeAll { fossilHuntCampInfrastructureSlugs.contains($0) }
    }
    if phase == .discovery {
        /// Never treat preserve / excavate / transport tools as discovery answers (e.g. `separation-layer`).
        var notDiscovery = Set<String>()
        notDiscovery.formUnion(fossilHuntPhaseBasePaleontologistSlugs(phase: .excavate))
        notDiscovery.formUnion(fossilHuntPhaseBasePaleontologistSlugs(phase: .preserve))
        notDiscovery.formUnion(fossilHuntPhaseBasePaleontologistSlugs(phase: .transport))
        merged.removeAll { notDiscovery.contains($0) }
    }
    merged = merged.filter { fossilHuntFossilHuntAllowedFieldSlugs.contains($0) }
    return merged.sorted()
}

/// Extra **paleontologist** slugs per story + phase (expanded pool → more variety when picking 2 correct at random).
private func fossilHuntStoryPhaseExtras(storySlug: String, phase: FossilHuntPhase) -> [String] {
    switch phase {
    case .discovery:
        switch storySlug {
        /// Only underwater adds the net; all other story “extras” were leaking wrong-phase tools into discovery.
        case "underwater": return ["long-handled-net"]
        default: return []
        }
    case .excavate:
        switch storySlug {
        case "cliff": return ["shale-splitter", "pick-axe", "rock-saw"]
        case "underwater": return ["wet-sieve-stack"]
        case "bone_bed": return ["dental-pick", "medium-chisel", "rock-hammer", "sifting-screen"]
        case "colony": return ["fine-chisel", "dental-pick", "sifting-screen"]
        /// Shale layers + amber in debris (land); not the Underwater wet-sieve story.
        case "botany": return ["shale-splitter", "dry-sieve-stack", "dental-pick", "fine-chisel", "wide-brush"]
        default: return []
        }
    case .preserve:
        switch storySlug {
        case "underwater": return ["waterproof-collection", "micro-vial-set"]
        case "bone_bed": return ["plaster-jacket", "micro-vial-set"]
        default: return []
        }
    case .transport:
        switch storySlug {
        case "underwater": return ["waterproof-collection", "specimen-crate", "shipping-manifest"]
        case "colony": return []
        case "cliff": return []
        default: return []
        }
    }
}

private let fossilHuntToolLabels: [String: String] = [
    "aerial-lift": "Aerial lift",
    "boots": "Field boots",
    "gps": "GPS",
    "gpr-surveyor": "GPR surveyor",
    "pickup-truck": "Pickup truck",
    "personal-locator-beacon": "PLB",
    "trailer-transport": "Trailer",
    "vehicle-suv-4wd": "SUV (4WD)",
    "specimen-vial": "Specimen vial",
    "ui-digital-repository": "Digital repository",
    "ui-ecology-map": "Ecology map",
    "ui-exhibit-label": "Exhibit label",
]

private let fossilHuntToolEmojis: [String: String] = [:]

private func fossilHuntDisplayLabel(forSlug slug: String) -> String {
    if let custom = fossilHuntToolLabels[slug] { return custom }
    return slug.split(separator: "-").map { String($0).capitalized }.joined(separator: " ")
}

/// Matches `Dinosaur-Tools/` imagesets: `dino-tools-field-*`, `dino-tools-lab-*`, `dino-tools-art-*`.
/// Slugs that exist in both field and lab (e.g. `ppe`) need `isCorrectOption` + `roundPrimaryGroup` so correct dig-site answers keep field art.
private func fossilHuntAssetName(
    forSlug slug: String,
    isCorrectOption: Bool,
    roundPrimaryGroup: FossilHuntToolGroup
) -> String {
    if isCorrectOption {
        switch roundPrimaryGroup {
        case .paleontologist: return "dino-tools-field-\(slug)"
        case .preparator: return "dino-tools-lab-\(slug)"
        case .restorer: return "dino-tools-art-\(slug)"
        }
    }
    if fossilHuntPreparatorToolSlugs.contains(slug) { return "dino-tools-lab-\(slug)" }
    if fossilHuntRestorerToolSlugs.contains(slug) { return "dino-tools-art-\(slug)" }
    return "dino-tools-field-\(slug)"
}

private func fossilHuntTool(
    forSlug slug: String,
    isCorrectOption: Bool,
    roundPrimaryGroup: FossilHuntToolGroup
) -> FossilHuntTool {
    let name = fossilHuntAssetName(forSlug: slug, isCorrectOption: isCorrectOption, roundPrimaryGroup: roundPrimaryGroup)
    return FossilHuntTool(
        id: slug,
        displayLabel: fossilHuntDisplayLabel(forSlug: slug),
        imageName: name,
        emoji: fossilHuntToolEmojis[slug] ?? "🔧",
        introAudioKey: nil
    )
}

private func fossilHuntPickCorrectSlugs(from pool: [String], count: Int, using rng: inout SeededRNG) -> [String] {
    guard pool.count >= count else { return pool }
    var shuffled = pool
    shuffled.shuffle(using: &rng)
    return Array(shuffled.prefix(count))
}

/// Distractors come from **other** tiers first, so preparator/restorer icons read as “not dig-site tools” for young players.
/// Never falls back to arbitrary field tools — that showed e.g. `separation-layer` during discovery.
private func fossilHuntPickDistractorSlugs(
    count: Int,
    excluding: Set<String>,
    primaryGroup: FossilHuntToolGroup,
    using rng: inout SeededRNG
) -> [String] {
    var pool = FossilHuntToolGroup.allCases
        .filter { $0 != primaryGroup }
        .flatMap { fossilHuntSlugs(in: $0) }
        .filter { !excluding.contains($0) }
    let simple = pool.filter { slug in
        if fossilHuntPreparatorToolSlugs.contains(slug) { return fossilHuntFossilHuntAllowedLabSlugs.contains(slug) }
        if fossilHuntRestorerToolSlugs.contains(slug) { return fossilHuntFossilHuntAllowedArtSlugs.contains(slug) }
        return false
    }
    if simple.count >= count { pool = simple }
    guard !pool.isEmpty else { return [] }
    pool.shuffle(using: &rng)
    var out: [String] = []
    while out.count < count {
        for s in pool where out.count < count {
            if !out.contains(s) { out.append(s) }
        }
        if out.count < count {
            let s = pool[Int.random(in: 0..<pool.count, using: &rng)]
            out.append(s)
        }
    }
    return Array(out.prefix(count))
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

// MARK: - Story library — audio / art + tool logic
//
// **Directions audio:** `Games/game-dino-fossil-hunt-{storyKebab}-{phase}.m4a`
// **Story art:** `dino-hunt-{storyKebab}-{phase}`
//
// **Tools:** Each round has `suitableToolSlugs` (paleontologist). When the round **starts**, two correct tools are chosen **at random**
// from that pool (so repeats feel different). The star’s other three icons are **preparator + restorer** only (`dino-tools-lab-*` / `art-*`).

/// `big_fossil` → `big-fossil` for audio keys and image name segments.
private func fossilHuntKebabStorySlug(_ slug: String) -> String {
    slug.replacingOccurrences(of: "_", with: "-")
}

/// Imagesets: `dino-hunt-{storyKebab}-{phase}` (e.g. `dino-hunt-big-fossil-discovery`).
private func fossilHuntStoryImageName(storySlug: String, phase: FossilHuntPhase) -> String {
    let kebab = fossilHuntKebabStorySlug(storySlug)
    return "dino-hunt-\(kebab)-\(phase.rawValue)"
}

private struct FossilHuntStoryDefinition {
    let storyNumber: Int
    let storySlug: String
    let title: String
}

private let fossilHuntStoryLibrary: [FossilHuntStoryDefinition] = [
    FossilHuntStoryDefinition(storyNumber: 1, storySlug: "big_fossil", title: "Big Fossil"),
    FossilHuntStoryDefinition(storyNumber: 2, storySlug: "small_tooth", title: "Small Tooth"),
    FossilHuntStoryDefinition(storyNumber: 3, storySlug: "skull", title: "Skull"),
    FossilHuntStoryDefinition(storyNumber: 4, storySlug: "skeleton", title: "Skeleton"),
    FossilHuntStoryDefinition(storyNumber: 5, storySlug: "bone_bed", title: "Bone Bed"),
    FossilHuntStoryDefinition(storyNumber: 6, storySlug: "botany", title: "Botany"),
    FossilHuntStoryDefinition(storyNumber: 7, storySlug: "cliff", title: "Cliff"),
    FossilHuntStoryDefinition(storyNumber: 8, storySlug: "colony", title: "Colony"),
    FossilHuntStoryDefinition(storyNumber: 9, storySlug: "underwater", title: "Underwater"),
]

private func fossilHuntQuest(from def: FossilHuntStoryDefinition) -> DinoFossilHuntQuestConfig {
    let storyKebab = fossilHuntKebabStorySlug(def.storySlug)
    let rounds: [DinoFossilHuntRoundConfig] = FossilHuntPhase.allCases.map { phase in
        let extras = fossilHuntStoryPhaseExtras(storySlug: def.storySlug, phase: phase)
        let suitable = fossilHuntMergedSuitablePaleontologistSlugs(phase: phase, extras: extras)
        precondition(suitable.count >= 2, "Story \(def.storySlug) phase \(phase) needs ≥2 paleontologist tools in suitable pool")
        return DinoFossilHuntRoundConfig(
            storyNumber: def.storyNumber,
            phase: phase,
            storyImageName: fossilHuntStoryImageName(storySlug: def.storySlug, phase: phase),
            directionsAudioKey: "game-dino-fossil-hunt-\(storyKebab)-\(phase.rawValue)",
            suitableToolSlugs: suitable,
            suitableToolGroup: .paleontologist,
        )
    }
    return DinoFossilHuntQuestConfig(id: def.storySlug, displayName: def.title, rounds: rounds)
}

private let dinoFossilHuntAllQuests: [DinoFossilHuntQuestConfig] = fossilHuntStoryLibrary.map { fossilHuntQuest(from: $0) }

/// When non-nil, only this story runs (local testing). Use `nil` for all stories in sessions.
private let fossilHuntSingleStoryTestingSlug: String? = nil

private var dinoFossilHuntPlayableQuests: [DinoFossilHuntQuestConfig] {
    if let slug = fossilHuntSingleStoryTestingSlug,
       let q = dinoFossilHuntAllQuests.first(where: { $0.id == slug }) {
        return [q]
    }
    return dinoFossilHuntAllQuests
}

// MARK: - View

struct DinoFossilHuntGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: DinoFossilHuntGameConfig

    @StateObject private var speechManager = SpeechManager()
    @State private var hasStartedGame = false
    @State private var currentRoundIndex = 0
    @State private var toolSlots: [FossilHuntTool] = []
    /// Two slugs picked at random from `roundConfig.suitableToolSlugs` (paleontologist pool) when the round is prepared.
    @State private var roundCorrectToolIds: Set<String> = []
    @State private var matchedToolIds: Set<String> = []
    @State private var isGameComplete = false
    @State private var endSequenceStep = -1
    @State private var endHighlightIndex = 0
    @State private var introWalkIndex: Int?
    @State private var displayedToolLabel: String?
    /// Full-screen hints (same pattern as Dino Footprints).
    @State private var showFossilHuntHints = false

    private var quest: DinoFossilHuntQuestConfig { gameConfig.quest }
    private var totalRounds: Int { quest.rounds.count }
    private var roundConfig: DinoFossilHuntRoundConfig? {
        guard currentRoundIndex < quest.rounds.count else { return nil }
        return quest.rounds[currentRoundIndex]
    }

    private var correctIdsThisRound: Set<String> { roundCorrectToolIds }

    var body: some View {
        NavigationView {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    if !isGameComplete, roundConfig != nil {
                        Button {
                            showFossilHuntHints = true
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
                .fullScreenCover(isPresented: $showFossilHuntHints) {
                    SourceFossilHuntHintsView(onDismiss: { showFossilHuntHints = false })
                }
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
        prepareToolsForCurrentRound()
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

    private func prepareToolsForCurrentRound() {
        guard let r = roundConfig else {
            toolSlots = []
            roundCorrectToolIds = []
            return
        }
        var seed = fossilHuntTimeSeed()
        seed ^= UInt64(bitPattern: Int64(r.storyNumber &* 0x9E37_79B9))
        seed ^= UInt64(bitPattern: Int64(currentRoundIndex &* 0x85EB_CA6B))
        seed ^= UInt64(bitPattern: Int64(r.phase.rawValue.hashValue))
        var rng = SeededRNG(seed: seed)
        let correct = fossilHuntPickCorrectSlugs(from: r.suitableToolSlugs, count: 2, using: &rng)
        roundCorrectToolIds = Set(correct)
        let distractors = fossilHuntPickDistractorSlugs(
            count: 3,
            excluding: roundCorrectToolIds,
            primaryGroup: r.suitableToolGroup,
            using: &rng
        )
        var fiveSlugs = correct + distractors
        /// Unbiased star order (LCG `SeededRNG` is poor for permutations).
        var orderRng = SystemRandomNumberGenerator()
        fiveSlugs.shuffle(using: &orderRng)
        toolSlots = fiveSlugs.map { slug in
            fossilHuntTool(
                forSlug: slug,
                isCorrectOption: roundCorrectToolIds.contains(slug),
                roundPrimaryGroup: r.suitableToolGroup
            )
        }
    }

    private func startIntroWalk() {
        guard toolSlots.count >= 5 else { return }
        introWalkIndex = 0
        displayedToolLabel = toolSlots[0].displayLabel
        speechManager.onAudioFinished = { advanceIntroWalk() }
        playToolIntro(toolSlots[0])
    }

    private func playToolIntro(_ tool: FossilHuntTool) {
        if let url = speechManager.urlForToolsAudio(slug: tool.id) {
            speechManager.playAudioFile(url: url)
        } else if let key = tool.introAudioKey, let url = speechManager.urlForAudio(key: key) {
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

        /// Show green ring immediately on correct taps so both picks stay visible during tool + `great-match` audio.
        /// (Deferring insert until after feedback caused the second match to call `finishRound` in the same turn, clearing state before the UI could draw.)
        if isCorrect {
            matchedToolIds.insert(tool.id)
        }

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
            if correct, self.matchedToolIds.isSuperset(of: self.correctIdsThisRound) {
                self.finishRound()
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
        prepareToolsForCurrentRound()
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

// MARK: - Fossil Hunt hints (Dino Footprints–style full-screen grid)

/// Phase hint cards use imagesets `source-hunt-{phase}` (Dinosaur-Sources / Dino Fossil Hunt). Uses `UIImage(named:)` like Dino Footprints hints so tiles work even if `ImageAssetNames.generated.swift` was not regenerated.
/// Audio: `Assets/Audio/Fossil/{phase}.m4a` via `SpeechManager` keys `game-dino-fossil-hunt-hint-{phase}`.
private struct SourceFossilHuntHint: Identifiable {
    let id: String
    let imageName: String?
    let displayName: String
    let audioKey: String
    let fallbackExplanation: String
    let placeholderEmoji: String
}

private let sourceFossilHuntHints: [SourceFossilHuntHint] = [
    SourceFossilHuntHint(
        id: "discovery",
        imageName: "source-hunt-discovery",
        displayName: "Discovery",
        audioKey: "game-dino-fossil-hunt-hint-discovery",
        fallbackExplanation: "Discovery is when scientists figure out where to look and mark the dig site before big digging starts.",
        placeholderEmoji: "🔎"
    ),
    SourceFossilHuntHint(
        id: "excavate",
        imageName: "source-hunt-excavate",
        displayName: "Excavate",
        audioKey: "game-dino-fossil-hunt-hint-excavate",
        fallbackExplanation: "Excavate means carefully loosening rock and dirt around a fossil so it can come out safely.",
        placeholderEmoji: "⛏️"
    ),
    SourceFossilHuntHint(
        id: "preserve",
        imageName: "source-hunt-preserve",
        displayName: "Preserve",
        audioKey: "game-dino-fossil-hunt-hint-preserve",
        fallbackExplanation: "Preserve is wrapping and supporting the fossil so it does not crack or crumble when it moves.",
        placeholderEmoji: "📦"
    ),
    SourceFossilHuntHint(
        id: "transport",
        imageName: "source-hunt-transport",
        displayName: "Transport",
        audioKey: "game-dino-fossil-hunt-hint-transport",
        fallbackExplanation: "Transport is moving the packed fossil from the dig site to the truck, lab, or museum without bumps.",
        placeholderEmoji: "🚚"
    ),
]

private struct SourceFossilHuntHintsView: View {
    let onDismiss: () -> Void
    @State private var speechManager = SpeechManager()
    @State private var selectedHint: SourceFossilHuntHint?
    @State private var introPlayed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if selectedHint == nil {
                gridView
            } else {
                detailView
            }

            Button {
                speechManager.stopCurrentAudio()
                speechManager.onAudioFinished = nil
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
        .onDisappear {
            speechManager.onAudioFinished = nil
            speechManager.stopCurrentAudio()
        }
    }

    private var gridView: some View {
        VStack(spacing: 20) {
            Text("Dino Fossil Hunt")
                .font(.title2.weight(.semibold))
                .padding(.top, 44)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(sourceFossilHuntHints) { hint in
                    Button {
                        showHintDetail(hint)
                    } label: {
                        Group {
                            if let name = hint.imageName, UIImage(named: name) != nil {
                                Image(name)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.25))
                                    .frame(height: 120)
                                    .overlay(
                                        VStack(spacing: 6) {
                                            Text(hint.placeholderEmoji)
                                                .font(.system(size: 40))
                                            Text(hint.displayName)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(8)
                                    )
                            }
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
                if let name = hint.imageName, UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 320, maxHeight: 320)
                } else {
                    Text(hint.placeholderEmoji)
                        .font(.system(size: 120))
                }
                Text(hint.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func playIntroOnce() {
        guard !introPlayed else { return }
        introPlayed = true
        speechManager.onAudioFinished = nil
        if let url = speechManager.urlForAudio(key: "game-dino-fossil-hunt-hint-intro") {
            speechManager.playAudioFile(url: url)
        } else if let url = speechManager.urlForAudio(key: "game-hint") {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak("Tap a picture to hear a tip about discovery, excavate, preserve, and transport.")
        }
    }

    private func showHintDetail(_ hint: SourceFossilHuntHint) {
        selectedHint = hint
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            speechManager.onAudioFinished = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedHint = nil
            }
        }
        if let url = speechManager.urlForAudio(key: hint.audioKey) {
            speechManager.playAudioFile(url: url)
        } else {
            speechManager.speak(hint.fallbackExplanation)
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
    /// Picks a random story each session from `dinoFossilHuntPlayableQuests` (see `fossilHuntSingleStoryTestingSlug`).
    static var dinoFossilHunt: DinoFossilHuntGameConfig {
        var rng = SeededRNG(seed: fossilHuntTimeSeed())
        let quest = dinoFossilHuntPlayableQuests.randomElement(using: &rng) ?? dinoFossilHuntPlayableQuests[0]
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
