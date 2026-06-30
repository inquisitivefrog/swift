//
//  RacingGameView.swift
//  DinoGames
//
//  Racing Dinosaurs!: Player picks two dinosaurs from four per period; they race on an oval track.
//  Dino racer art: prefer `dino-racer-{clade}-{slug}-*` then legacy `dino-racer-{slug}-*` (slug uses trex for T-Rex).
//  Racing Pterosaurs: uses `ptero-racer-*` packs (with compatibility for older `ptero-racing-*` names); pool filters by catalog; no `ptero-*` portrait fallback.
//  Racing Marine Reptiles: eight buoys; default slalom (wide/tight weave). Classic single-ring layout preserved — see `MarineRacingTrackGeometry` and `RacingTrackLayout.marineBuoyCircle`.
//

import SwiftUI
import AVFoundation

// MARK: - Data Models

struct RacingRacer: Identifiable {
    let id: Int
    let name: String
    let icon: String // Emoji fallback when imageset missing
    let speed: Double // Estimated top speed (mph) for deterministic winner
    /// When set (e.g. for pterosaurs), used for **name audio** lookup only (`ptero-*` catalog keys); never used for Racing Pterosaurs **images**.
    let fallbackImageName: String?
    /// Racing Dinosaurs imagesets may live under `dino-racer-{clade}-{slug}`; when set, that clade segment is preferred with legacy fallback.
    let racerAssetClade: String?
    /// Racing Pterosaurs imageset base (`ptero-racer-*`, with compatibility for `ptero-racing-*`); nil for dinosaurs.
    let pteroRacingAssetBase: String?
    /// Racing Marine Reptiles imageset base (`marine-racer-*` / `marine-racing-*`); nil when using catalog body only.
    let marineRacingAssetBase: String?

    init(
        id: Int,
        name: String,
        icon: String,
        speed: Double,
        fallbackImageName: String? = nil,
        racerAssetClade: String? = nil,
        pteroRacingAssetBase: String? = nil,
        marineRacingAssetBase: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.speed = speed
        self.fallbackImageName = fallbackImageName
        self.racerAssetClade = racerAssetClade
        self.pteroRacingAssetBase = pteroRacingAssetBase
        self.marineRacingAssetBase = marineRacingAssetBase
    }

    /// Slug for asset names: lowercase, spaces → hyphens (e.g. "T-Rex" → "t-rex").
    var imageSlug: String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    /// Filename segment for dino racer/winner assets (T-Rex → trex).
    var dinoRacerSpeciesSegment: String {
        imageSlug == "t-rex" ? "trex" : imageSlug
    }

    /// Ordered `dino-racer-*` base names: legacy flat slug first when bundled, then claded migration path.
    func dinoRacerAssetBases() -> [String] {
        let seg = dinoRacerSpeciesSegment
        let legacy = "dino-racer-\(seg)"
        if let c = racerAssetClade, !c.isEmpty {
            let claded = "dino-racer-\(c)-\(seg)"
            if ImageAssetCache.imageExists(named: legacy) || ImageAssetCache.imageExists(named: "\(legacy)-ready") {
                return [legacy, claded]
            }
            return [claded, legacy]
        }
        return [legacy]
    }

    /// Ordered `dino-winner-race-*` names for finish / victory.
    func dinoWinnerRaceAssetNames() -> [String] {
        let seg = dinoRacerSpeciesSegment
        if let c = racerAssetClade, !c.isEmpty {
            return ["dino-winner-race-\(c)-\(seg)", "dino-winner-race-\(seg)"]
        }
        return ["dino-winner-race-\(seg)"]
    }

    /// Racer image name for a given asset prefix (e.g. "dino" → dino-racer-*, "ptero" → ptero-racer/ptero-racing base). Primary candidate only.
    func racerImageName(prefix: String) -> String {
        if prefix == "dino" {
            return dinoRacerAssetBases().first!
        }
        if prefix == "ptero", let b = pteroRacingAssetBase {
            return b
        }
        if prefix == "marine", let b = marineRacingAssetBase {
            return b
        }
        return "\(prefix)-racer-\(imageSlug)"
    }
    /// Ready pose: {prefix}-racer-{slug}-ready. Shown when dinosaurs are selected (grid, pre-race).
    func readyImageName(prefix: String) -> String {
        if prefix == "dino" {
            return dinoRacerAssetBases().first! + "-ready"
        }
        if prefix == "ptero", let b = pteroRacingAssetBase {
            return b + "-ready"
        }
        if prefix == "marine", let b = marineRacingAssetBase {
            return b + "-ready"
        }
        return racerImageName(prefix: prefix) + "-ready"
    }
    /// Running pose: {prefix}-racer-{slug}-run. Used during track movement.
    func runningImageName(prefix: String) -> String {
        if prefix == "dino" {
            return dinoRacerAssetBases().first! + "-run"
        }
        if prefix == "ptero", let b = pteroRacingAssetBase {
            return b + "-run"
        }
        if prefix == "marine", let b = marineRacingAssetBase {
            return b + "-run"
        }
        return racerImageName(prefix: prefix) + "-run"
    }
    /// Tripped pose: {prefix}-racer-{slug}-tripped. Shown briefly when faster dinosaur trips during race.
    func trippedImageName(prefix: String) -> String {
        if prefix == "dino" {
            return dinoRacerAssetBases().first! + "-tripped"
        }
        if prefix == "ptero", let b = pteroRacingAssetBase {
            return b + "-tripped"
        }
        if prefix == "marine", let b = marineRacingAssetBase {
            return b + "-tripped"
        }
        return racerImageName(prefix: prefix) + "-tripped"
    }
    /// Finish-line pose for winner/victory: {prefix}-winner-race-{slug}; ptero uses racing finish-excited as primary key string.
    func winnerImageName(prefix: String) -> String {
        if prefix == "dino" {
            return dinoWinnerRaceAssetNames().first!
        }
        if prefix == "ptero", let b = pteroRacingAssetBase {
            return b + "-finish-excited"
        }
        if prefix == "marine", let b = marineRacingAssetBase {
            return b + "-finish-excited"
        }
        return "\(prefix)-winner-race-\(imageSlug)"
    }
    /// Fallback image/audio name when racer/winner assets are missing. Uses fallbackImageName if set, else prefix-based (dino: dino-{slug}).
    func effectiveFallbackImageName(prefix: String) -> String {
        if let f = fallbackImageName { return f }
        let dinoSlug = imageSlug.replacingOccurrences(of: "-", with: "")
        return "dino-\(dinoSlug)"
    }
}

/// Pose: start/ready (grid, pre-race), running (track), tripped (brief pause when faster dino trips), finish (winner, victory list).
private enum RacingPose {
    case start   // {prefix}-racer-{slug}-ready
    case running // {prefix}-racer-{slug}-run
    case tripped // {prefix}-racer-{slug}-tripped
    case finish  // {prefix}-winner-race-{slug}
}

private func firstExistingAssetName(in candidates: [String]) -> String? {
    for name in candidates where ImageAssetCache.imageExists(named: name) { return name }
    return nil
}

private func dinoRacerSuffixedCandidates(for racer: RacingRacer, suffix: String) -> [String] {
    racer.dinoRacerAssetBases().map { $0 + suffix }
}

private func firstExistingPterosaurSuffix(base: String, suffixes: [String]) -> String? {
    for suffix in suffixes {
        let candidate = base + suffix
        if ImageAssetCache.imageExists(named: candidate) {
            return candidate
        }
    }
    return nil
}

private func firstExistingMarineSuffix(base: String, suffixes: [String]) -> String? {
    for suffix in suffixes {
        let name = base + suffix
        if ImageAssetCache.imageExists(named: name) { return name }
    }
    return nil
}

/// Racing Pterosaurs requires at least ready + excited + exhausted art. Running can fall back to ready for older packs.
private func hasCompletePterosaurRacingAssetPack(base: String) -> Bool {
    let hasReady = firstExistingPterosaurSuffix(base: base, suffixes: ["-ready"]) != nil
    let hasExcited = firstExistingPterosaurSuffix(base: base, suffixes: ["-finish-excited", "-finished-excited", "-excited"]) != nil
    let hasExhausted = firstExistingPterosaurSuffix(base: base, suffixes: ["-finish-exhausted", "-finished-exhausted", "-exhausted"]) != nil
    return hasReady && hasExcited && hasExhausted
}

/// Returns image name for racer at given pose. Fallback chain: pose-specific → ready → base → dino-{slug}.
private func racerDisplayImageName(for racer: RacingRacer, config: RacingGameConfig, pose: RacingPose = .start) -> String? {
    let prefix = config.assetPrefix

    if prefix == "dino" {
        switch pose {
        case .start:
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-ready")) { return n }
            if let n = firstExistingAssetName(in: racer.dinoRacerAssetBases()) { return n }
        case .running:
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-run")) { return n }
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-ready")) { return n }
            if let n = firstExistingAssetName(in: racer.dinoRacerAssetBases()) { return n }
        case .tripped:
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-tripped")) { return n }
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-run")) { return n }
            if let n = firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: racer, suffix: "-ready")) { return n }
            if let n = firstExistingAssetName(in: racer.dinoRacerAssetBases()) { return n }
        case .finish:
            if let n = firstExistingAssetName(in: racer.dinoWinnerRaceAssetNames()) { return n }
            if let n = firstExistingAssetName(in: racer.dinoRacerAssetBases()) { return n }
        }
        let fallback = racer.effectiveFallbackImageName(prefix: prefix)
        if ImageAssetCache.imageExists(named: fallback) { return fallback }
        return nil
    }

    if prefix == "ptero", let b = racer.pteroRacingAssetBase {
        switch pose {
        case .start:
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .running:
            if let n = firstExistingPterosaurSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .tripped:
            if ImageAssetCache.imageExists(named: b + "-tripped") { return b + "-tripped" }
            if let n = firstExistingPterosaurSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .finish:
            if let n = firstExistingPterosaurSuffix(base: b, suffixes: ["-finish-excited", "-finished-excited", "-excited"]) { return n }
            if let n = firstExistingPterosaurSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
        }
        return nil
    }

    if prefix == "marine", let b = racer.marineRacingAssetBase {
        switch pose {
        case .start:
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .running:
            if let n = firstExistingMarineSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .tripped:
            if ImageAssetCache.imageExists(named: b + "-tripped") { return b + "-tripped" }
            if let n = firstExistingMarineSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
            if ImageAssetCache.imageExists(named: b) { return b }
        case .finish:
            if let n = firstExistingMarineSuffix(base: b, suffixes: ["-finish-excited", "-finished-excited", "-finish-exhausted", "-finished-exhausted", "-excited"]) { return n }
            if let n = firstExistingMarineSuffix(base: b, suffixes: ["-run", "-ready"]) { return n }
            if ImageAssetCache.imageExists(named: b + "-ready") { return b + "-ready" }
        }
        let fallback = racer.effectiveFallbackImageName(prefix: prefix)
        if ImageAssetCache.imageExists(named: fallback) { return fallback }
        return nil
    }

    if prefix == "marine" {
        let fallback = racer.effectiveFallbackImageName(prefix: prefix)
        if ImageAssetCache.imageExists(named: fallback) { return fallback }
        return nil
    }

    switch pose {
    case .start:
        if ImageAssetCache.imageExists(named: racer.readyImageName(prefix: prefix)) { return racer.readyImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.racerImageName(prefix: prefix)) { return racer.racerImageName(prefix: prefix) }
    case .running:
        if ImageAssetCache.imageExists(named: racer.runningImageName(prefix: prefix)) { return racer.runningImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.readyImageName(prefix: prefix)) { return racer.readyImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.racerImageName(prefix: prefix)) { return racer.racerImageName(prefix: prefix) }
    case .tripped:
        if ImageAssetCache.imageExists(named: racer.trippedImageName(prefix: prefix)) { return racer.trippedImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.runningImageName(prefix: prefix)) { return racer.runningImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.readyImageName(prefix: prefix)) { return racer.readyImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.racerImageName(prefix: prefix)) { return racer.racerImageName(prefix: prefix) }
    case .finish:
        if ImageAssetCache.imageExists(named: racer.winnerImageName(prefix: prefix)) { return racer.winnerImageName(prefix: prefix) }
        if ImageAssetCache.imageExists(named: racer.racerImageName(prefix: prefix)) { return racer.racerImageName(prefix: prefix) }
    }
    let fallback = racer.effectiveFallbackImageName(prefix: prefix)
    if ImageAssetCache.imageExists(named: fallback) { return fallback }
    return nil
}

/// Convenience for finish pose (winner view, victory list).
private func winnerDisplayImageName(for racer: RacingRacer, config: RacingGameConfig) -> String? {
    racerDisplayImageName(for: racer, config: config, pose: .finish)
}

/// Post-race finish images: `isBroadDelta` picks excited vs exhausted winner pose (non-tie wins use triumph pose).
/// Prefers pack-specific `{prefix}-racer-referee-*` before generic `game-referee-*`.
func finishRefereeImageName(prefix: String, isBroadDelta: Bool) -> String {
    for candidate in [
        "\(prefix)-racer-referee-finished-winner",
        "\(prefix)-racer-referee-finish-winner",
    ] where ImageAssetCache.imageExists(named: candidate) {
        return candidate
    }
    let excited = "\(prefix)-racer-referee-finish-excited"
    let worried = "\(prefix)-racer-referee-finish-worried"
    if isBroadDelta, ImageAssetCache.imageExists(named: excited) { return excited }
    if !isBroadDelta, ImageAssetCache.imageExists(named: worried) { return worried }
    let packFinish = "\(prefix)-racer-referee-finish"
    if ImageAssetCache.imageExists(named: packFinish) { return packFinish }
    if ImageAssetCache.imageExists(named: "game-referee-finish") { return "game-referee-finish" }
    return packFinish
}

func tieRefereeImageName(prefix: String) -> String {
    for candidate in [
        "\(prefix)-racer-referee-finished-tie",
        "\(prefix)-racer-referee-finish-tie",
    ] where ImageAssetCache.imageExists(named: candidate) {
        return candidate
    }
    let packFinish = "\(prefix)-racer-referee-finish"
    if ImageAssetCache.imageExists(named: packFinish) { return packFinish }
    if ImageAssetCache.imageExists(named: "game-referee-finish") { return "game-referee-finish" }
    return packFinish
}

func startRefereeImageName(prefix: String) -> String {
    let packStart = "\(prefix)-racer-referee-start"
    if ImageAssetCache.imageExists(named: packStart) { return packStart }
    if ImageAssetCache.imageExists(named: "game-referee-start") { return "game-referee-start" }
    return packStart
}

private func finishWinnerImageName(for racer: RacingRacer, config: RacingGameConfig, isBroadDelta: Bool) -> String? {
    let prefix = config.assetPrefix
    if prefix == "dino" {
        for base in racer.dinoRacerAssetBases() {
            let excited = base + "-finish-excited"
            let exhausted = base + "-finish-exhausted"
            if isBroadDelta, ImageAssetCache.imageExists(named: excited) { return excited }
            if !isBroadDelta, ImageAssetCache.imageExists(named: exhausted) { return exhausted }
        }
        if let w = firstExistingAssetName(in: racer.dinoWinnerRaceAssetNames()) { return w }
        if let b = firstExistingAssetName(in: racer.dinoRacerAssetBases()) { return b }
        let fallback = racer.effectiveFallbackImageName(prefix: prefix)
        return ImageAssetCache.imageExists(named: fallback) ? fallback : nil
    }
    if prefix == "ptero", let b = racer.pteroRacingAssetBase {
        if isBroadDelta,
           let excited = firstExistingPterosaurSuffix(base: b, suffixes: ["-finish-excited", "-finished-excited", "-excited"]) {
            return excited
        }
        if !isBroadDelta,
           let exhausted = firstExistingPterosaurSuffix(base: b, suffixes: ["-finish-exhausted", "-finished-exhausted", "-exhausted"]) {
            return exhausted
        }
        return nil
    }
    if prefix == "marine", let b = racer.marineRacingAssetBase {
        if isBroadDelta,
           let excited = firstExistingMarineSuffix(base: b, suffixes: ["-finish-excited", "-finished-excited", "-excited"]) {
            return excited
        }
        if !isBroadDelta,
           let exhausted = firstExistingMarineSuffix(base: b, suffixes: ["-finish-exhausted", "-finished-exhausted", "-exhausted"]) {
            return exhausted
        }
        return nil
    }
    let base = racer.racerImageName(prefix: prefix)
    let excited = base + "-finish-excited"
    let exhausted = base + "-finish-exhausted"
    let winnerRace = racer.winnerImageName(prefix: prefix)
    if isBroadDelta {
        if ImageAssetCache.imageExists(named: excited) { return excited }
    } else {
        if ImageAssetCache.imageExists(named: exhausted) { return exhausted }
    }
    if ImageAssetCache.imageExists(named: winnerRace) { return winnerRace }
    if ImageAssetCache.imageExists(named: racer.racerImageName(prefix: prefix)) { return racer.racerImageName(prefix: prefix) }
    let fallback = racer.effectiveFallbackImageName(prefix: prefix)
    return ImageAssetCache.imageExists(named: fallback) ? fallback : nil
}

/// Course geometry for the live race and referee finish preview.
enum RacingTrackLayout: Equatable {
    case ovalDualLane
    case airportHop
    /// Preserved Feb 2026 design: buoys and wide legs share one outer ring; inner legs inset 36pt. Revert config to this if slalom is unwanted.
    case marineBuoyCircle(buoyCount: Int = 8)
    /// Buoys on outer ring; racers alternate wide legs (may clip frame edge) and tight inner legs.
    case marineBuoySlalom(buoyCount: Int = 8)
}

private extension RacingTrackLayout {
    var marineTrackStyle: MarineRacingTrackStyle? {
        switch self {
        case .marineBuoyCircle: return .classic
        case .marineBuoySlalom: return .slalom
        default: return nil
        }
    }

    var marineBuoyCount: Int? {
        switch self {
        case .marineBuoyCircle(let count), .marineBuoySlalom(let count): return count
        default: return nil
        }
    }
}

struct RacingGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let assetPrefix: String // "dino", "ptero", or "marine" for racer/winner/referee image names
    let racers: [RacingRacer] // All pool dinosaurs (6) for dinosaur racing; 4 for pterosaurs
    /// Pool's min/max speeds for "max delta" trip logic. Nil when pool unknown.
    let poolMinSpeed: Double?
    let poolMaxSpeed: Double?
    let trackLayout: RacingTrackLayout
}

private func racingSuccessImageCandidates(for config: RacingGameConfig) -> [String] {
    if config.id.contains("marine") {
        return ["game-\(config.id)-success", "game-racing-marine-reptiles-success", "game-racing-marine-reptiles"]
    }
    if config.id.contains("ptero") {
        return ["game-\(config.id)-success", "game-racing-pterosaurs-success", "game-racing-pterosaurs"]
    }
    return ["game-\(config.id)-success", "game-racing-dinosaurs-success", "game-racing-dinosaurs"]
}

// MARK: - Main View

private let tickInterval: TimeInterval = 0.5
private let stepPerTick: Double = 0.05 // Progress per tick; faster racer gains more (speed/maxSpeed) * stepPerTick
private let tripDuration: TimeInterval = 3.0 // 3 ticks (seconds) the faster dino is paused when tripped

struct RacingGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: RacingGameConfig

    /// When gameConfig has empty racers (racing-dinosaurs needs period), we show period selection first; effectiveConfig updates when period is chosen.
    @State private var effectiveConfig: RacingGameConfig?

    @StateObject private var speechManager = SpeechManager()
    @State private var selectedLane1: RacingRacer?
    @State private var selectedLane2: RacingRacer?
    /// Second racer chosen but name audio still playing; we don't transition to pre-race until audio finishes.
    @State private var pendingRacer2: RacingRacer?
    @State private var canSelectSecond = false
    @State private var isRacing = false
    @State private var progress1: Double = 0
    @State private var progress2: Double = 0
    @State private var raceTimer: Timer?
    @State private var winner: RacingRacer?
    @State private var isTie = false
    /// Pre-race: 0 = first position (name + first-position audio), 1 = second position (name + second-position audio), 2 = Ready/Set/Go + referee + whistle on same contestants screen
    @State private var preRaceStep: Int? = nil
    /// Ensures each contestants lane (0 / 1) starts audio exactly once; `onAppear` can skip step 1 when `preRaceStep` advances.
    @State private var preRaceContestantsLaneStarted: Int? = nil
    /// Post-race: "referee-track" = referee with both racers at finish, then "announce" = winner/tie announcement screen.
    @State private var postRaceStep: String? = nil
    @State private var hasPlayedStartingGun = false
    @State private var preRaceCountdownWord: String? = nil
    @State private var hasPlayedWeHaveAWinner = false
    /// When non-nil, show large image + name and play racer name audio; on finish apply selection and return to grid.
    @State private var showingExpandedRacer: RacingRacer? = nil
    @State private var hasPlayedFirstRacerPrompt = false
    @State private var roundsCompleted = 0
    private let maxRounds = 3
    @State private var winners: [RacingRacer] = []
    @State private var showVictory = false
    @State private var endSequenceStep: Int = -1  // -1 none, 1 = walk winners, 2 = success image
    @State private var endHighlightIndex: Int = 0
    /// When non-nil, this racer is tripped: progress paused, tripped image shown. Cleared after trip duration.
    @State private var trippedRacerId: Int? = nil
    /// Racer who tripped; used to display effective speed (reduced) instead of top speed.
    @State private var trippedRacerIdForPenalty: Int? = nil
    @State private var hasTrippedThisRace = false
    @State private var raceElapsedSeconds: Int = 0
    @State private var hasPlayedFirstFinishCheering = false
    /// When set, that racer crossed the finish line at this tick; clock stops for them.
    @State private var finishTime1: Int? = nil
    @State private var finishTime2: Int? = nil
    /// Last rendered pterosaur track size; used so hop-waypoint stop points match the visual course geometry.
    @State private var pteroTrackWidth: CGFloat = 300
    @State private var pteroTrackHeight: CGFloat = 200

    /// Config used for play: either period-specific (when chosen) or initial (when racers already set).
    private var config: RacingGameConfig {
        effectiveConfig ?? gameConfig
    }

    private var firstRacerSelectionPromptKey: String {
        switch config.assetPrefix {
        case "ptero": return "game-racer-choose-your-first-pterosaur-to-race"
        case "marine": return "game-choose-your-first-marine-reptile"
        default: return "game-racer-choose-your-first-dinosaur-to-race"
        }
    }

    private var secondRacerSelectionPromptKey: String {
        switch config.assetPrefix {
        case "ptero": return "game-racer-choose-your-second-pterosaur-to-race"
        case "marine": return "game-choose-your-second-marine-reptile"
        default: return "game-racer-choose-your-second-dinosaur-to-race"
        }
    }

    private var chooseFirstRacerLabel: String {
        switch config.assetPrefix {
        case "ptero": return "Choose your first pterosaur to race"
        case "marine": return "Choose your first marine reptile to race"
        default: return "Choose your first dinosaur to race"
        }
    }

    private var chooseSecondRacerLabel: String {
        switch config.assetPrefix {
        case "ptero": return "Choose your second pterosaur to race"
        case "marine": return "Choose your second marine reptile to race"
        default: return "Choose your second dinosaur to race"
        }
    }

    /// True when we need to show period selection first (racing-dinosaurs / pterosaurs / marine with empty racers).
    private var needsPeriodSelection: Bool {
        gameConfig.racers.isEmpty && (
            gameConfig.id == "racing-dinosaurs"
                || gameConfig.id == "racing-pterosaurs"
                || gameConfig.id == "racing-marine-reptiles"
        )
    }

    private var showSelection: Bool {
        selectedLane1 == nil || ((selectedLane2 == nil && pendingRacer2 == nil) && !isRacing && preRaceStep == nil)
    }
    private var showPreRace: Bool { preRaceStep != nil }
    private var showRace: Bool {
        selectedLane1 != nil && selectedLane2 != nil && isRacing && preRaceStep == nil && postRaceStep == nil
    }
    private var showRefereeFinishTrack: Bool { postRaceStep == "referee-track" }
    private var showPostRaceAnnouncement: Bool { postRaceStep == "announce" }

    private var blocksUserInput: Bool { speechManager.isPlaying }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if needsPeriodSelection && effectiveConfig == nil {
                        embeddedPeriodSelectionView(geometry: geometry)
                    } else if showVictory {
                        victoryView
                    } else if showSelection {
                        if let racer = showingExpandedRacer {
                            expandedRacerView(geometry: geometry, racer: racer)
                        } else {
                            selectionGrid(geometry: geometry)
                                .onAppear {
                                    if selectedLane1 == nil && !hasPlayedFirstRacerPrompt {
                                        hasPlayedFirstRacerPrompt = true
                                        let firstPrompt = firstRacerSelectionPromptKey
                                        speechManager.speak(firstPrompt)
                                    }
                                }
                        }
                    } else if showPreRace, let r1 = selectedLane1, let r2 = selectedLane2 {
                        preRaceView(geometry: geometry, racer1: r1, racer2: r2)
                    } else if showRace {
                        raceTrack(geometry: geometry)
                    } else if showRefereeFinishTrack {
                        refereeFinishTrackView(geometry: geometry)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                    self.postRaceStep = "announce"
                                }
                            }
                    } else if showPostRaceAnnouncement {
                        if isTie, let r1 = selectedLane1, let r2 = selectedLane2 {
                            postRaceTieView(geometry: geometry, racer1: r1, racer2: r2)
                        } else if let w = winner {
                            postRaceFinishView(geometry: geometry, winner: w)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(showVictory ? "" : config.title)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                stopRace()
                speechManager.stopCurrentAudio()
            }
            .allowsHitTesting(!blocksUserInput)
            .gameSheetDismissDisabledWhileAudioPlaying(blocksUserInput)
        }
    }

    /// Period selection shown when gameConfig has empty racers (racing-dinosaurs from catalog). No sheet dismiss/present.
    private func embeddedPeriodSelectionView(geometry: GeometryProxy) -> some View {
        RacingPeriodSelectionView(isPresented: $isPresented, onSelectPeriod: { config in
            effectiveConfig = config
        }, gameFamily: racingPeriodGameFamily(for: gameConfig.id), embedMode: true)
    }

    private func racingPeriodGameFamily(for configId: String) -> RacingPeriodSelectionView.RacingGameFamily {
        if configId == "racing-pterosaurs" { return .pterosaurs }
        if configId == "racing-marine-reptiles" { return .marineReptiles }
        return .dinosaurs
    }
    
    // MARK: - Selection (2×4 grid, emoji only)
    
    private func selectionGrid(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if selectedLane1 == nil {
                Text(chooseFirstRacerLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if selectedLane2 == nil && pendingRacer2 == nil {
                Text(chooseSecondRacerLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(config.racers) { racer in
                        RacingRacerCard(
                            racer: racer,
                            gameConfig: config,
                            isSelected: selectedLane1?.id == racer.id || selectedLane2?.id == racer.id || pendingRacer2?.id == racer.id,
                            isDisabled: (selectedLane1 != nil && selectedLane2 == nil && pendingRacer2 == nil && !canSelectSecond) || (selectedLane1 != nil && (selectedLane2 != nil || pendingRacer2 != nil))
                        ) {
                            handleRacerTap(racer)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 8)
            }
        }
        .padding()
    }
    
    private func handleRacerTap(_ racer: RacingRacer) {
        if selectedLane1 == nil {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.dismissExpandedAndSetFirstRacer(racer)
                }
            }
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
        } else if selectedLane2 == nil && pendingRacer2 == nil && selectedLane1?.id == racer.id {
            speechManager.speak("you-cannot-choose-that-one-now")
        } else if selectedLane2 == nil && pendingRacer2 == nil && selectedLane1?.id != racer.id && canSelectSecond {
            showingExpandedRacer = racer
            canSelectSecond = false
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.dismissExpandedAndSetSecondRacer(racer)
                }
            }
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
        }
    }

    private func dismissExpandedAndSetFirstRacer(_ racer: RacingRacer) {
        speechManager.onAudioFinished = nil
        speechManager.stopCurrentAudio()
        showingExpandedRacer = nil
        selectedLane1 = racer
        canSelectSecond = true
        let secondPrompt = secondRacerSelectionPromptKey
        speechManager.speak(secondPrompt)
    }

    private func dismissExpandedAndSetSecondRacer(_ racer: RacingRacer) {
        speechManager.onAudioFinished = nil
        speechManager.stopCurrentAudio()
        showingExpandedRacer = nil
        selectedLane2 = racer
        beginPreRaceSequence()
    }

    /// Temporary large view: racer image + full name below; plays racer name audio, then on finish caller returns to grid. Tap to dismiss immediately if audio stalls.
    private func expandedRacerView(geometry: GeometryProxy, racer: RacingRacer) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.45
        return VStack(spacing: 20) {
            if let imageName = racerDisplayImageName(for: racer, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size * 0.8))
            }
            Text(racer.name)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pre-race (first position → second position → Ready/Set/Go + referee + whistle → track)

    private func beginPreRaceSequence() {
        progress1 = 0
        progress2 = 0
        preRaceContestantsLaneStarted = nil
        preRaceCountdownWord = nil
        preRaceStep = 0
    }

    /// Step 2 on the same contestants screen: flash Ready -> Set -> Go!, then whistle and launch race.
    private func runPreRaceReadySetGoIfNeeded(racer1: RacingRacer, racer2: RacingRacer) {
        guard !hasPlayedStartingGun else { return }
        hasPlayedStartingGun = true
        preRaceContestantsLaneStarted = 2

        func showWord(_ word: String) {
            withAnimation(.easeInOut(duration: 0.18)) {
                preRaceCountdownWord = word
            }
        }

        let steps: [(word: String, key: String)] = {
            switch config.assetPrefix {
            case "ptero":
                return [
                    ("Ready", "game-racing-pterosaurs-ready"),
                    ("Set", "game-racing-pterosaurs-set"),
                    ("Go!", "game-racing-pterosaurs-go"),
                ]
            case "marine":
                return [
                    ("Ready", "game-racing-marine-reptiles-ready"),
                    ("Set", "game-racing-marine-reptiles-set"),
                    ("Go!", "game-racing-marine-reptiles-go"),
                ]
            default:
                return [
                    ("Ready", "game-racing-dinosaurs-ready"),
                    ("Set", "game-racing-dinosaurs-set"),
                    ("Go!", "game-racing-dinosaurs-go"),
                ]
            }
        }()

        func playStep(_ index: Int) {
            guard index < steps.count else {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak("starting-whistle")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.speechManager.onAudioFinished = nil
                    self.preRaceStep = nil
                    self.preRaceCountdownWord = nil
                    self.isRacing = true
                    self.fireRaceTimer(r1: racer1, r2: racer2)
                }
                return
            }
            let step = steps[index]
            showWord(step.word)
            self.speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    playStep(index + 1)
                }
            }
            self.speechManager.speak(audioKey: step.key, fallbackText: step.word)
        }

        playStep(0)
    }

    /// Drives the “Contestants” audio for first position (0) then second position (1). Triggered from `onChange(of: preRaceStep)` so step 1 cannot be skipped when SwiftUI omits `onAppear`.
    private func runPreRaceContestantsLaneIfNeeded(step: Int, outsideRacer: RacingRacer, insideRacer: RacingRacer) {
        guard step == 0 || step == 1 else { return }
        guard preRaceContestantsLaneStarted != step else { return }
        preRaceContestantsLaneStarted = step

        if step == 0 {
            // Defer so stray AVAudioPlayer delegate completions from `stopCurrentAudio` / the prior selection clip
            // cannot fire after we register `onAudioFinished` and incorrectly chain straight to “first position”
            // without playing the outside racer’s name (second lane does not hit this race as often).
            let prefix = config.assetPrefix
            let nameKey = outsideRacer.effectiveFallbackImageName(prefix: prefix)
            let nameFallback = outsideRacer.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Task { @MainActor in
                    guard self.preRaceStep == 0, self.preRaceContestantsLaneStarted == 0 else { return }
                    self.speechManager.onAudioFinished = {
                        Task { @MainActor in
                            self.speechManager.onAudioFinished = nil
                            if let url = self.speechManager.urlForAudio(key: "game-racing-first-position")
                                ?? self.speechManager.urlForAudio(key: "game-racing-outside-track") {
                                self.speechManager.onAudioFinished = {
                                    Task { @MainActor in
                                        self.speechManager.onAudioFinished = nil
                                        self.preRaceStep = 1
                                    }
                                }
                                self.speechManager.playAudioFile(url: url)
                            } else {
                                self.preRaceStep = 1
                            }
                        }
                    }
                    self.speechManager.speak(audioKey: nameKey, fallbackText: nameFallback, chainDelay: true)
                }
            }
        } else {
            // Same defer as step 0: stray delegate completions from the first-position clip must not
            // fire after we register `onAudioFinished` and skip straight to “second position” without the name.
            let prefix = config.assetPrefix
            let nameKey = insideRacer.effectiveFallbackImageName(prefix: prefix)
            let nameFallback = insideRacer.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Task { @MainActor in
                    guard self.preRaceStep == 1, self.preRaceContestantsLaneStarted == 1 else { return }
                    self.speechManager.onAudioFinished = {
                        Task { @MainActor in
                            self.speechManager.onAudioFinished = nil
                            if let url = self.speechManager.urlForAudio(key: "game-racing-second-position")
                                ?? self.speechManager.urlForAudio(key: "game-racing-inside-track") {
                                self.speechManager.onAudioFinished = {
                                    Task { @MainActor in
                                        self.speechManager.onAudioFinished = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            self.preRaceStep = 2
                                        }
                                    }
                                }
                                self.speechManager.playAudioFile(url: url)
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    self.preRaceStep = 2
                                }
                            }
                        }
                    }
                    self.speechManager.speak(audioKey: nameKey, fallbackText: nameFallback, chainDelay: true)
                }
            }
        }
    }

    private func preRaceView(geometry: GeometryProxy, racer1: RacingRacer, racer2: RacingRacer) -> some View {
        let step = preRaceStep ?? 0
        let (outsideRacer, insideRacer) = (racer1, racer2)
        return Group {
            preRaceContestantsView(
                geometry: geometry,
                outsideRacer: outsideRacer,
                insideRacer: insideRacer,
                highlightedRacer: step == 0 ? outsideRacer : (step == 1 ? insideRacer : nil),
                showCountdownArea: step >= 2,
                countdownWord: preRaceCountdownWord
            )
            .id(step)
            .onAppear {
                guard let s = preRaceStep else { return }
                if s == 0 || s == 1 {
                    runPreRaceContestantsLaneIfNeeded(step: s, outsideRacer: outsideRacer, insideRacer: insideRacer)
                } else {
                    runPreRaceReadySetGoIfNeeded(racer1: racer1, racer2: racer2)
                }
            }
            .onChange(of: preRaceStep) { _, newStep in
                guard let s = newStep else { return }
                if s == 0 || s == 1 {
                    runPreRaceContestantsLaneIfNeeded(step: s, outsideRacer: outsideRacer, insideRacer: insideRacer)
                } else {
                    runPreRaceReadySetGoIfNeeded(racer1: racer1, racer2: racer2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Both contestants in one view, labeled "Contestants"; highlight the one whose audio is playing.
    private func preRaceContestantsView(geometry: GeometryProxy, outsideRacer: RacingRacer, insideRacer: RacingRacer, highlightedRacer: RacingRacer?, showCountdownArea: Bool, countdownWord: String?) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.32
        return VStack(spacing: 12) {
            Text("Contestants")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 4)
            HStack(spacing: 20) {
                contestantCell(racer: outsideRacer, size: size, isHighlighted: highlightedRacer?.id == outsideRacer.id, laneLabel: "First position")
                contestantCell(racer: insideRacer, size: size, isHighlighted: highlightedRacer?.id == insideRacer.id, laneLabel: "Second position")
            }
            .padding(.horizontal, 8)
            if showCountdownArea {
                Text(countdownWord ?? "Ready")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(countdownWord == nil ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: countdownWord)
                    .padding(.top, 8)
                refereeImageView(startRefereeImageName(prefix: config.assetPrefix))
                    .frame(maxHeight: 280)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func contestantCell(racer: RacingRacer, size: CGFloat, isHighlighted: Bool, laneLabel: String) -> some View {
        VStack(spacing: 6) {
            Group {
                if let imageName = racerDisplayImageName(for: racer, config: config) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text(racer.icon)
                        .font(.system(size: size * 0.8))
                }
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 4)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .opacity(isHighlighted ? 1.0 : 0.6)
            Text(laneLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(racer.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func racerImageFullView(racer: RacingRacer, size: CGFloat) -> some View {
        Group {
            if let imageName = racerDisplayImageName(for: racer, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size * 0.8))
            }
        }
    }

    private func refereeImageViewSmall(_ imageName: String, size: CGFloat) -> some View {
        Group {
            if ImageAssetCache.imageExists(named: imageName) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Text("🏁")
                    .font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
    }

    private func refereeImageView(_ imageName: String) -> some View {
        Group {
            if ImageAssetCache.imageExists(named: imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 280)
            } else {
                Text("🏁")
                    .font(.system(size: 120))
            }
        }
    }

    /// Post-race: clear screen with final clock, referee (excited/worried by delta), and winner dinosaur (excited/exhausted or winner-race fallback).
    private func postRaceFinishView(geometry: GeometryProxy, winner w: RacingRacer) -> some View {
        let r1 = selectedLane1 ?? w
        let r2 = selectedLane2 ?? w
        let loser = r1.id == w.id ? r2 : r1
        let maxSpeed = max(w.speed, loser.speed)
        let winnerTime = w.id == r1.id ? finishTime1 : finishTime2
        let loserTime = w.id == r1.id ? finishTime2 : finishTime1
        // Finish times are whole race ticks (~0.5s wall-clock each). Requiring a 2+ tick gap made almost every
        // close finish use exhausted; any clear ordering (loser strictly later) should get the triumph pose.
        let isBroadDelta: Bool = {
            if let wt = winnerTime, let lt = loserTime {
                return lt > wt
            }
            let speedDelta = abs(w.speed - loser.speed)
            return maxSpeed > 0 && (speedDelta / maxSpeed) >= 0.25
        }()

        let refereeName = finishRefereeImageName(prefix: config.assetPrefix, isBroadDelta: isBroadDelta)
        let dinosaurName = finishWinnerImageName(for: w, config: config, isBroadDelta: isBroadDelta)

        func format(_ sec: Int) -> String { String(format: "%d:%02d", sec / 60, sec % 60) }
        let t1 = finishTime1 ?? raceElapsedSeconds
        let t2 = finishTime2 ?? raceElapsedSeconds
        return VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(r1.name): \(format(t1))")
                    .font(.system(size: nameLength(r1.name) > 10 ? 20 : 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(r2.name): \(format(t2))")
                    .font(.system(size: nameLength(r2.name) > 10 ? 20 : 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            VStack(spacing: 16) {
                refereeImageView(refereeName)
                    .frame(maxWidth: .infinity)
                Group {
                    if let name = dinosaurName {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 280, maxHeight: 280)
                    } else {
                        Text(w.icon)
                            .font(.system(size: 120))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Text("\(w.name) – \(formatSpeed(displayedSpeed(racer: w, finishTime: w.id == r1.id ? finishTime1 : finishTime2, maxSpeed: maxSpeed))) mph")
                .font(.system(size: nameLength(w.name) > 10 ? 18 : 22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            playWinnerAnnouncement(winner: w)
        }
    }

    /// Track with dinosaurs at finish and referee off the track at lower infield near the edge.
    private func refereeFinishTrackView(geometry: GeometryProxy) -> some View {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return AnyView(EmptyView()) }
        let cfg = config
        let finishHeadline = isTie ? "It's a tie!" : "We have a winner!"
        let finishRefereeName = isTie
            ? tieRefereeImageName(prefix: cfg.assetPrefix)
            : finishRefereeImageName(prefix: cfg.assetPrefix, isBroadDelta: true)
        switch cfg.trackLayout {
        case .airportHop:
            let padding: CGFloat = 24
            let trackWidth = max(1, geometry.size.width - padding * 2)
            let trackHeight = max(120, geometry.size.height - 140)
            let racerSize: CGFloat = 48
            let refereeSize: CGFloat = 64

            let outerPath = airportPath(width: trackWidth, height: trackHeight, inset: 0)
            let pos1 = pointOnAirportCourse(progress: 1.0, width: trackWidth, height: trackHeight, inset: 0)
            let pos2 = pointOnAirportCourse(progress: 1.0, width: trackWidth, height: trackHeight, inset: 0)
            let stagger1 = pteroSharedCourseRacerOffset(forRacerIndex: 0)
            let stagger2 = pteroSharedCourseRacerOffset(forRacerIndex: 1)
            let half = racerSize / 2
            let margin: CGFloat = 24
            let finishLineHeight: CGFloat = 12
            let finishLineX = margin - 2

            return AnyView(
                VStack(spacing: 8) {
                    Text(finishHeadline)
                        .font(.headline)
                    ZStack(alignment: .topLeading) {
                        AirportCourseWaterBackground(width: trackWidth, height: trackHeight)
                        outerPath
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                            .foregroundColor(Color.white.opacity(0.42))
                            .frame(width: trackWidth, height: trackHeight)
                        Rectangle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 4, height: finishLineHeight)
                            .offset(x: finishLineX, y: trackHeight - margin - finishLineHeight / 2)

                        Text("🌲").font(.caption).offset(x: margin - 8, y: trackHeight - margin - 6)
                        Text("🪨").font(.caption).offset(x: trackWidth - margin - 8, y: margin - 4)
                        Text("🌴").font(.caption).offset(x: trackWidth - margin - 8, y: trackHeight - margin - 6)
                        Text("⛰️").font(.caption).offset(x: margin - 8, y: margin - 4)
                        Text("🗿").font(.caption).offset(x: trackWidth * 0.5 - 8, y: trackHeight * 0.5 - 10)

                        racerView(racer: r1, size: racerSize, pose: .finish)
                            .offset(x: pos1.x - half + stagger1.width, y: pos1.y - half + stagger1.height)
                        racerView(racer: r2, size: racerSize, pose: .finish)
                            .offset(x: pos2.x - half + stagger2.width, y: pos2.y - half + stagger2.height)

                        refereeImageViewSmall(finishRefereeName, size: refereeSize)
                        .offset(x: trackWidth / 2 - refereeSize / 2, y: trackHeight * 0.5 + 20)
                    }
                    .frame(width: trackWidth, height: trackHeight)
                }
                .padding(.horizontal, padding)
            )
        case .marineBuoyCircle(let buoyCount), .marineBuoySlalom(let buoyCount):
            let style = cfg.trackLayout.marineTrackStyle ?? .slalom
            let padding: CGFloat = 24
            let trackWidth = max(1, geometry.size.width - padding * 2)
            let trackHeight = max(120, geometry.size.height - 140)
            let racerSize: CGFloat = 48
            let classic = MarineRacingTrackGeometry.classicRadii(width: trackWidth, height: trackHeight)
            let slalom = MarineRacingTrackGeometry.slalomRadii(width: trackWidth, height: trackHeight)
            let count = max(3, buoyCount)
            let pos1 = MarineRacingTrackGeometry.pointOnCourse(
                progress: 1.0, width: trackWidth, height: trackHeight,
                style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
            )
            let pos2 = pos1
            let off1 = MarineRacingTrackGeometry.racerOffset(
                progress: 1.0, racerIndex: 0, width: trackWidth, height: trackHeight,
                style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
            )
            let off2 = MarineRacingTrackGeometry.racerOffset(
                progress: 1.0, racerIndex: 1, width: trackWidth, height: trackHeight,
                style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
            )
            let half = racerSize / 2
            let finishLineWidth: CGFloat = 4
            let finishLineHeight: CGFloat = 10
            let finishLineX = trackWidth / 2 - finishLineWidth / 2
            let refereeSize: CGFloat = 64
            return AnyView(
                VStack(spacing: 8) {
                    Text(finishHeadline)
                        .font(.headline)
                    marineRacewayZStack(
                        trackWidth: trackWidth,
                        trackHeight: trackHeight,
                        buoyCount: count,
                        style: style,
                        waypointSize: 36,
                        clipWideLegs: style == .slalom,
                        finishLineWidth: finishLineWidth,
                        finishLineHeight: finishLineHeight,
                        finishLineX: finishLineX,
                        racerOverlays: {
                            racerView(racer: r1, size: racerSize, pose: .finish)
                                .offset(x: pos1.x - half + off1.width, y: pos1.y - half + off1.height)
                            racerView(racer: r2, size: racerSize, pose: .finish)
                                .offset(x: pos2.x - half + off2.width, y: pos2.y - half + off2.height)
                            refereeImageViewSmall(finishRefereeName, size: refereeSize)
                                .offset(x: trackWidth / 2 - refereeSize / 2, y: trackHeight / 2 - refereeSize / 2)
                        }
                    )
                }
                .padding(.horizontal, padding)
            )
        case .ovalDualLane:
        let padding: CGFloat = 24
        let trackInset: CGFloat = 44
        let ovalWidth = max(trackInset * 2 + 4, geometry.size.width - padding * 2)
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let cornerRadius = min(min(ovalWidth, ovalHeight) * 0.18, min(ovalWidth, ovalHeight) / 4)
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerCornerRadius = max(0, cornerRadius - trackInset / 2)
        let refereeSize: CGFloat = 64
        let outerPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        let innerPath = RoundedRectangle(cornerRadius: innerCornerRadius).path(in: CGRect(x: 0, y: 0, width: innerW, height: innerH))
        let innerR = min(innerCornerRadius, min(innerW, innerH) / 2)
        let pt1Outer = pointOnRoundedRect(progress: 1.0, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnRoundedRect(progress: 1.0, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnRoundedRect(progress: 1.0, width: innerW, height: innerH, cornerRadius: innerR)
        let pt2InnerRaw = pointOnRoundedRect(progress: 1.0, width: innerW, height: innerH, cornerRadius: innerR)
        let pt1Inner = CGPoint(x: pt1InnerRaw.x + trackInset, y: pt1InnerRaw.y + trackInset)
        let pt2Inner = CGPoint(x: pt2InnerRaw.x + trackInset, y: pt2InnerRaw.y + trackInset)
        let racer1OnInner = r1.speed <= r2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner
        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineRowHeight: CGFloat = 10
        let finishLineX = ovalWidth / 2 - finishLineWidth / 2
        // Referee off the track, at lower bottom of infield near the track edge—close to racers to detect cheating, not blocking or in their path
        let refereeFinishX = ovalWidth / 2 - refereeSize / 2
        let refereeFinishY = trackInset + innerH - refereeSize - 16
        return AnyView(VStack(spacing: 8) {
            Text(finishHeadline)
                .font(.headline)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: innerW, height: innerH)
                    .offset(x: trackInset, y: trackInset)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: ovalHeight - finishLineRowHeight)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: trackInset + innerH - finishLineRowHeight)
                racerView(racer: r1, size: racerSize, pose: .finish)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: r2, size: racerSize, pose: .finish)
                    .offset(x: pos2.x - half, y: pos2.y - half)
                refereeImageViewSmall(finishRefereeName, size: refereeSize)
                    .offset(x: refereeFinishX, y: refereeFinishY)
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding))
        }
    }
    
    // MARK: - Race (oval / airport hop / marine buoy circle)

    private func raceTrack(geometry: GeometryProxy) -> some View {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return AnyView(EmptyView()) }
        switch config.trackLayout {
        case .airportHop:
            return AnyView(airportTrackView(geometry: geometry, progress1: progress1, progress2: progress2, racer1: r1, racer2: r2, trippedRacerId: trippedRacerId, raceElapsedSeconds: raceElapsedSeconds))
        case .marineBuoyCircle(let buoyCount), .marineBuoySlalom(let buoyCount):
            let style = config.trackLayout.marineTrackStyle ?? .slalom
            return AnyView(marineRacewayTrackView(
                geometry: geometry,
                progress1: progress1,
                progress2: progress2,
                racer1: r1,
                racer2: r2,
                trippedRacerId: trippedRacerId,
                raceElapsedSeconds: raceElapsedSeconds,
                buoyCount: buoyCount,
                style: style
            ))
        case .ovalDualLane:
            return AnyView(ovalTrackView(geometry: geometry, progress1: progress1, progress2: progress2, racer1: r1, racer2: r2, trippedRacerId: trippedRacerId, raceElapsedSeconds: raceElapsedSeconds))
        }
    }

    // MARK: - Marine raceway (classic preserved in `MarineRacingTrackGeometry`; slalom is default)

    @ViewBuilder
    private func buoyMarkerView(index: Int, size: CGFloat) -> some View {
        let numberedAsset = "marine-raceway-buoy-\(index + 1)"
        let sharedAsset = "marine-raceway-buoy"
        if ImageAssetCache.imageExists(named: numberedAsset) {
            Image(numberedAsset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else if ImageAssetCache.imageExists(named: sharedAsset) {
            Image(sharedAsset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text("🛟")
                .font(.system(size: size * 0.72))
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func marineRacewayZStack<RacerOverlays: View>(
        trackWidth: CGFloat,
        trackHeight: CGFloat,
        buoyCount: Int,
        style: MarineRacingTrackStyle,
        waypointSize: CGFloat,
        clipWideLegs: Bool,
        finishLineWidth: CGFloat,
        finishLineHeight: CGFloat,
        finishLineX: CGFloat,
        @ViewBuilder racerOverlays: () -> RacerOverlays
    ) -> some View {
        let classic = MarineRacingTrackGeometry.classicRadii(width: trackWidth, height: trackHeight)
        let slalom = MarineRacingTrackGeometry.slalomRadii(width: trackWidth, height: trackHeight)
        let count = max(3, buoyCount)
        let buoyR = MarineRacingTrackGeometry.buoyMarkerRadius(style: style, radiiClassic: classic, radiiSlalom: slalom)
        let courseStack = ZStack(alignment: .topLeading) {
            AirportCourseWaterBackground(width: trackWidth, height: trackHeight)
            if style == .slalom {
                Circle()
                    .stroke(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 2, dash: [5, 7]))
                    .frame(width: slalom.tightRadius * 2, height: slalom.tightRadius * 2)
                    .offset(x: trackWidth / 2 - slalom.tightRadius, y: trackHeight / 2 - slalom.tightRadius)
            }
            Circle()
                .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                .frame(width: buoyR * 2, height: buoyR * 2)
                .offset(x: trackWidth / 2 - buoyR, y: trackHeight / 2 - buoyR)
            MarineRacingTrackGeometry.coursePath(
                width: trackWidth,
                height: trackHeight,
                style: style,
                radiiClassic: classic,
                radiiSlalom: slalom,
                buoyCount: count
            )
            .stroke(Color.white.opacity(style == .slalom ? 0.52 : 0.38), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            ForEach(0..<count, id: \.self) { index in
                let buoyProgress = Double(index) / Double(count)
                let buoyPoint = MarineRacingTrackGeometry.pointOnBuoyCircle(
                    progress: buoyProgress,
                    width: trackWidth,
                    height: trackHeight,
                    buoyRadius: buoyR
                )
                let halfBuoy = waypointSize / 2
                buoyMarkerView(index: index, size: waypointSize)
                    .offset(x: buoyPoint.x - halfBuoy, y: buoyPoint.y - halfBuoy)
            }
            Rectangle()
                .fill(Color.white.opacity(0.95))
                .frame(width: finishLineWidth, height: finishLineHeight)
                .offset(x: finishLineX, y: trackHeight - finishLineHeight)
            racerOverlays()
        }
        .frame(width: trackWidth, height: trackHeight)

        if clipWideLegs {
            courseStack.clipped()
        } else {
            courseStack
        }
    }

    private func marineRacewayTrackView(
        geometry: GeometryProxy,
        progress1: Double,
        progress2: Double,
        racer1: RacingRacer,
        racer2: RacingRacer,
        trippedRacerId: Int?,
        raceElapsedSeconds: Int,
        buoyCount: Int,
        style: MarineRacingTrackStyle
    ) -> some View {
        let padding: CGFloat = 24
        let trackWidth = max(1, geometry.size.width - padding * 2)
        let trackHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let waypointSize: CGFloat = 36
        let classic = MarineRacingTrackGeometry.classicRadii(width: trackWidth, height: trackHeight)
        let slalom = MarineRacingTrackGeometry.slalomRadii(width: trackWidth, height: trackHeight)
        let count = max(3, buoyCount)
        let pos1 = MarineRacingTrackGeometry.pointOnCourse(
            progress: progress1, width: trackWidth, height: trackHeight,
            style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
        )
        let pos2 = MarineRacingTrackGeometry.pointOnCourse(
            progress: progress2, width: trackWidth, height: trackHeight,
            style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
        )
        let off1 = MarineRacingTrackGeometry.racerOffset(
            progress: progress1, racerIndex: 0, width: trackWidth, height: trackHeight,
            style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
        )
        let off2 = MarineRacingTrackGeometry.racerOffset(
            progress: progress2, racerIndex: 1, width: trackWidth, height: trackHeight,
            style: style, radiiClassic: classic, radiiSlalom: slalom, buoyCount: count
        )
        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineHeight: CGFloat = 10
        let finishLineX = trackWidth / 2 - finishLineWidth / 2
        let refereeSize: CGFloat = 64

        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            speedClockView(
                racer1: racer1,
                racer2: racer2,
                raceElapsedSeconds: raceElapsedSeconds,
                finishTime1: finishTime1,
                finishTime2: finishTime2,
                maxWidth: trackWidth
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            marineRacewayZStack(
                trackWidth: trackWidth,
                trackHeight: trackHeight,
                buoyCount: count,
                style: style,
                waypointSize: waypointSize,
                clipWideLegs: style == .slalom,
                finishLineWidth: finishLineWidth,
                finishLineHeight: finishLineHeight,
                finishLineX: finishLineX,
                racerOverlays: {
                    racerView(racer: racer1, size: racerSize, pose: trippedRacerId == racer1.id ? .tripped : .running)
                        .offset(x: pos1.x - half + off1.width, y: pos1.y - half + off1.height)
                    racerView(racer: racer2, size: racerSize, pose: trippedRacerId == racer2.id ? .tripped : .running)
                        .offset(x: pos2.x - half + off2.width, y: pos2.y - half + off2.height)
                    refereeImageViewSmall(startRefereeImageName(prefix: config.assetPrefix), size: refereeSize)
                        .offset(x: trackWidth / 2 - refereeSize / 2, y: trackHeight / 2 - refereeSize / 2)
                }
            )
        }
        .padding(.horizontal, padding)
    }

    /// Airport hop course for pterosaurs: A → E → B → C → E → D → A.
    /// Returns point on path for progress in [0, 1]. inset > 0 gives inner (shorter) path.
    private func pointOnAirportCourse(progress: Double, width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> CGPoint {
        let p = max(0, min(1, progress))
        let m = 24 + inset
        let w = width
        let h = height
        let A = CGPoint(x: m, y: h - m)
        let E = CGPoint(x: w * 0.5, y: h * 0.5)
        let B = CGPoint(x: w - m, y: m)
        let C = CGPoint(x: w - m, y: h - m)
        let D = CGPoint(x: m, y: m)
        func len(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot(b.x - a.x, b.y - a.y)
        }
        let L_AE = len(A, E)
        let L_EB = len(E, B)
        let L_BC = len(B, C)
        let L_CE = len(C, E)
        let L_ED = len(E, D)
        let L_DA = len(D, A)
        let total = L_AE + L_EB + L_BC + L_CE + L_ED + L_DA
        let d = CGFloat(p) * total
        func lerp(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y))
        }
        if d < L_AE { return lerp(A, E, t: d / L_AE) }
        let d2 = d - L_AE
        if d2 < L_EB { return lerp(E, B, t: d2 / L_EB) }
        let d3 = d2 - L_EB
        if d3 < L_BC { return lerp(B, C, t: d3 / L_BC) }
        let d4 = d3 - L_BC
        if d4 < L_CE { return lerp(C, E, t: d4 / L_CE) }
        let d5 = d4 - L_CE
        if d5 < L_ED { return lerp(E, D, t: d5 / L_ED) }
        let d6 = d5 - L_ED
        return lerp(D, A, t: d6 / L_DA)
    }

    /// Path for airport hop course (same nodes as pointOnAirportCourse with inset 0).
    private func airportPath(width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> Path {
        let m = 24 + inset
        let w = width
        let h = height
        let A = CGPoint(x: m, y: h - m)
        let E = CGPoint(x: w * 0.5, y: h * 0.5)
        let B = CGPoint(x: w - m, y: m)
        let C = CGPoint(x: w - m, y: h - m)
        let D = CGPoint(x: m, y: m)
        var path = Path()
        path.move(to: A)
        path.addLine(to: E)
        path.addLine(to: B)
        path.addLine(to: C)
        path.addLine(to: E)
        path.addLine(to: D)
        path.closeSubpath()
        return path
    }

    private enum AirportHopNode {
        case e, b, c, d
    }

    private func airportWaypointProgresses(width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> [(progress: Double, node: AirportHopNode)] {
        let m = 24 + inset
        let w = width
        let h = height
        let A = CGPoint(x: m, y: h - m)
        let E = CGPoint(x: w * 0.5, y: h * 0.5)
        let B = CGPoint(x: w - m, y: m)
        let C = CGPoint(x: w - m, y: h - m)
        let D = CGPoint(x: m, y: m)
        func len(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
        let L_AE = len(A, E)
        let L_EB = len(E, B)
        let L_BC = len(B, C)
        let L_CE = len(C, E)
        let L_ED = len(E, D)
        let L_DA = len(D, A)
        let total = L_AE + L_EB + L_BC + L_CE + L_ED + L_DA
        return [
            ((L_AE) / total, .e),
            ((L_AE + L_EB) / total, .b),
            ((L_AE + L_EB + L_BC) / total, .c),
            ((L_AE + L_EB + L_BC + L_CE) / total, .e),
            ((L_AE + L_EB + L_BC + L_CE + L_ED) / total, .d),
        ]
    }

    /// Default fraction along the **incoming** segment where landing lag begins (open-water approach), not on the waypoint icon.
    private let airportHopLagApproachAlongSegmentDefault: Double = 0.88

    /// B→C is a long vertical leg; the default fraction leaves racers visibly short of the bottom-right (C) marker.
    private func airportHopLagApproachAlongSegment(for node: AirportHopNode) -> Double {
        switch node {
        case .c: return 0.95
        default: return airportHopLagApproachAlongSegmentDefault
        }
    }

    /// Course progress where hop lag triggers — slightly **before** each landmark along the path.
    private func airportLagTriggerProgress(waypointIndex: Int, width: CGFloat, height: CGFloat, inset: CGFloat = 0) -> Double {
        let wps = airportWaypointProgresses(width: width, height: height, inset: inset)
        guard waypointIndex >= 0, waypointIndex < wps.count else { return 1.0 }
        let landmark = wps[waypointIndex].progress
        let prev = waypointIndex == 0 ? 0.0 : wps[waypointIndex - 1].progress
        let span = landmark - prev
        guard span > 1e-9 else { return landmark }
        return prev + span * airportHopLagApproachAlongSegment(for: wps[waypointIndex].node)
    }

    /// Species-specific landing/takeoff lag ticks at hop nodes.
    private func hopLagTicks(for racer: RacingRacer, at node: AirportHopNode) -> Int {
        let seed = abs(racer.id * 31 + racer.name.count * 17)
        switch node {
        case .e: return 3 + ((seed + 1) % 2) // 3-4 ticks
        case .b: return 4 + ((seed + 3) % 3) // 4-6 ticks
        case .c: return 3 + ((seed + 5) % 2) // 3-4 ticks
        case .d: return 4 + ((seed + 7) % 3) // 4-6 ticks
        }
    }

    /// Both pterosaurs use one airport course; when progress matches they share the same point — slight diagonal nudge so neither sprite fully hides the other (neck-and-neck).
    private func pteroSharedCourseRacerOffset(forRacerIndex index: Int) -> CGSize {
        let d: CGFloat = 9
        switch index {
        case 0:
            return CGSize(width: -d * 0.78, height: -d * 0.56)
        default:
            return CGSize(width: d * 0.78, height: d * 0.56)
        }
    }

    private func airportTrackView(geometry: GeometryProxy, progress1: Double, progress2: Double, racer1: RacingRacer, racer2: RacingRacer, trippedRacerId: Int?, raceElapsedSeconds: Int) -> some View {
        let padding: CGFloat = 24
        let trackWidth = max(1, geometry.size.width - padding * 2)
        let trackHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        // Keep timer waypoint math aligned with current rendered course dimensions.
        DispatchQueue.main.async {
            if abs(self.pteroTrackWidth - trackWidth) > 0.5 || abs(self.pteroTrackHeight - trackHeight) > 0.5 {
                self.pteroTrackWidth = trackWidth
                self.pteroTrackHeight = trackHeight
            }
        }
        let outerPath = airportPath(width: trackWidth, height: trackHeight, inset: 0)
        let pos1 = pointOnAirportCourse(progress: progress1, width: trackWidth, height: trackHeight, inset: 0)
        let pos2 = pointOnAirportCourse(progress: progress2, width: trackWidth, height: trackHeight, inset: 0)
        let stagger1 = config.assetPrefix == "ptero" ? pteroSharedCourseRacerOffset(forRacerIndex: 0) : .zero
        let stagger2 = config.assetPrefix == "ptero" ? pteroSharedCourseRacerOffset(forRacerIndex: 1) : .zero

        let half = racerSize / 2
        let margin: CGFloat = 24
        let finishLineHeight: CGFloat = 12
        let finishLineX = margin - 2
        let nearingFinish = max(progress1, progress2) >= 0.88
        // Last segment (includes D→A): tie pose only for a close race — not whenever anyone crosses ~88% progress.
        let neckAndNeck = abs(progress1 - progress2) < 0.04
        let refereeImageName: String = {
            guard nearingFinish else { return startRefereeImageName(prefix: config.assetPrefix) }
            if neckAndNeck { return tieRefereeImageName(prefix: config.assetPrefix) }
            return finishRefereeImageName(prefix: config.assetPrefix, isBroadDelta: true)
        }()
        let waypointSize: CGFloat = 36
        let refereeSize: CGFloat = 66
        // Keep referee beside the course (right side), not on start node A.
        let refereeX = trackWidth - refereeSize - 8
        let refereeY = max(8, (trackHeight * 0.5) - (refereeSize * 0.5))
        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            speedClockView(
                racer1: racer1,
                racer2: racer2,
                raceElapsedSeconds: raceElapsedSeconds,
                finishTime1: finishTime1,
                finishTime2: finishTime2,
                maxWidth: trackWidth
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            ZStack(alignment: .topLeading) {
                AirportCourseWaterBackground(width: trackWidth, height: trackHeight)
                outerPath
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundColor(Color.white.opacity(0.42))
                    .frame(width: trackWidth, height: trackHeight)
                // Start/finish at airport A (left)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 4, height: finishLineHeight)
                    .offset(x: finishLineX, y: trackHeight - margin - finishLineHeight / 2)
                // Raceway points A→E use dedicated waypoint assets (1...5).
                Group {
                    if ImageAssetCache.imageExists(named: "ptero-raceway-point-1") {
                        Image("ptero-raceway-point-1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: waypointSize, height: waypointSize)
                    } else {
                        Text("🌲").font(.caption)
                    }
                }
                .offset(x: margin - 17, y: trackHeight - margin - 15)
                Group {
                    if ImageAssetCache.imageExists(named: "ptero-raceway-point-2") {
                        Image("ptero-raceway-point-2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: waypointSize, height: waypointSize)
                    } else {
                        Text("🪨").font(.caption)
                    }
                }
                .offset(x: trackWidth - margin - 17, y: margin - 13)
                Group {
                    if ImageAssetCache.imageExists(named: "ptero-raceway-point-3") {
                        Image("ptero-raceway-point-3")
                            .resizable()
                            .scaledToFit()
                            .frame(width: waypointSize, height: waypointSize)
                    } else {
                        Text("🌴").font(.caption)
                    }
                }
                .offset(x: trackWidth - margin - 17, y: trackHeight - margin - 15)
                Group {
                    if ImageAssetCache.imageExists(named: "ptero-raceway-point-4") {
                        Image("ptero-raceway-point-4")
                            .resizable()
                            .scaledToFit()
                            .frame(width: waypointSize, height: waypointSize)
                    } else {
                        Text("⛰️").font(.caption)
                    }
                }
                .offset(x: margin - 17, y: margin - 13)
                Group {
                    if ImageAssetCache.imageExists(named: "ptero-raceway-point-5") {
                        Image("ptero-raceway-point-5")
                            .resizable()
                            .scaledToFit()
                            .frame(width: waypointSize, height: waypointSize)
                    } else {
                        Text("🗿").font(.caption)
                    }
                }
                .offset(x: trackWidth * 0.5 - 17, y: trackHeight * 0.5 - 19)
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 6, height: 6)
                    .offset(x: trackWidth * 0.5 - 3, y: trackHeight * 0.5 - 3)
                racerView(racer: racer1, size: racerSize, pose: trippedRacerId == racer1.id ? .tripped : .running)
                    .offset(x: pos1.x - half + stagger1.width, y: pos1.y - half + stagger1.height)
                racerView(racer: racer2, size: racerSize, pose: trippedRacerId == racer2.id ? .tripped : .running)
                    .offset(x: pos2.x - half + stagger2.width, y: pos2.y - half + stagger2.height)
                refereeImageViewSmall(refereeImageName, size: refereeSize)
                    .offset(x: refereeX, y: refereeY)
            }
            .frame(width: trackWidth, height: trackHeight)
        }
        .padding(.horizontal, padding)
    }

    /// Total path length for oval (rounded rect). Same segment breakdown as `pointOnRoundedRect`.
    private func ovalPathLength(width: CGFloat, height: CGFloat, cornerRadius: CGFloat? = nil) -> CGFloat {
        let w = width
        let h = height
        let cx = w / 2
        let r = cornerRadius ?? min(min(w, h) * 0.18, min(w, h) / 4)
        let arcLen = .pi * r / 2
        let L1 = (w - r) - cx
        let L2 = h - 2 * r
        let L3 = w - 2 * r
        let L4 = cx - r
        return L1 + arcLen + L2 + arcLen + L3 + arcLen + L2 + arcLen + L4
    }

    /// Fraction of one outer lap that equals the extra arc length vs inner (0…1). Outer runner starts this far ahead so both lanes run the same distance per lap (track-and-field stagger).
    private func ovalOuterLaneStaggerFraction(innerPathLength: CGFloat, outerPathLength: CGFloat) -> Double {
        guard outerPathLength > 0, innerPathLength > 0, outerPathLength > innerPathLength else { return 0 }
        return 1.0 - Double(innerPathLength / outerPathLength)
    }

    /// Map race progress [0,1] to outer-lane path progress so outer covers the same distance as inner from gun to finish (`stagger` = head start as a fraction of one outer lap).
    private func ovalOuterPathProgress(raceProgress: Double, outerStart: Double, outerSpan: Double, staggerFraction: Double) -> Double {
        let p = max(0, min(1, raceProgress))
        let s = max(0, min(0.95, staggerFraction))
        return outerStart + (p * (1.0 - s) + s) * outerSpan
    }

    /// Progress offset so race progress 0 = finish line (center bottom). Path origin is center bottom for both lanes.
    private func ovalPathStartOffset(width: CGFloat, height: CGFloat) -> Double {
        0
    }

    /// Rounded-rectangle path: start/finish at center bottom; clockwise lap (right → up → left → down → right to center).
    /// Returns point on path for progress in [0, 1]. Pass explicit cornerRadius to match drawn track (e.g. inner lane).
    private func pointOnRoundedRect(progress: Double, width: CGFloat, height: CGFloat, cornerRadius: CGFloat? = nil) -> CGPoint {
        let p = max(0, min(1, progress))
        let w = width
        let h = height
        let cx = w / 2
        let r = cornerRadius ?? min(min(w, h) * 0.18, min(w, h) / 4)
        let arcLen = .pi * r / 2
        let L1 = (w - r) - cx
        let L2 = h - 2 * r
        let L3 = w - 2 * r
        let L4 = cx - r
        let total = L1 + arcLen + L2 + arcLen + L3 + arcLen + L2 + arcLen + L4
        let d = p * total
        let t1 = d / L1
        if d < L1 { return CGPoint(x: cx + t1 * (w - r - cx), y: h) }
        let d2 = d - L1
        if d2 < arcLen {
            let t = CGFloat(d2 / arcLen)
            let angle = CGFloat.pi / 2 * (1 - t)
            return CGPoint(x: (w - r) + r * cos(angle), y: (h - r) + r * sin(angle))
        }
        let d3 = d2 - arcLen
        if d3 < L2 { return CGPoint(x: w, y: (h - r) - d3 / L2 * (h - 2 * r)) }
        let d4 = d3 - L2
        if d4 < arcLen {
            let t = CGFloat(d4 / arcLen)
            let angle = -CGFloat.pi / 2 * t
            return CGPoint(x: (w - r) + r * cos(angle), y: r + r * sin(angle))
        }
        let d5 = d4 - arcLen
        if d5 < L3 { return CGPoint(x: (w - r) - d5 / L3 * (w - 2 * r), y: 0) }
        let d6 = d5 - L3
        if d6 < arcLen {
            let t = CGFloat(d6 / arcLen)
            let angle = -CGFloat.pi / 2 - (CGFloat.pi / 2) * t
            return CGPoint(x: r + r * cos(angle), y: r + r * sin(angle))
        }
        let d7 = d6 - arcLen
        if d7 < L2 { return CGPoint(x: 0, y: r + d7 / L2 * (h - 2 * r)) }
        let d8 = d7 - L2
        if d8 < arcLen {
            let t = CGFloat(d8 / arcLen)
            let angle = CGFloat.pi - CGFloat.pi / 2 * t
            return CGPoint(x: r + r * cos(angle), y: (h - r) + r * sin(angle))
        }
        let d9 = d8 - arcLen
        let t9 = d9 / L4
        return CGPoint(x: r + t9 * (cx - r), y: h)
    }

    private func ovalTrackView(geometry: GeometryProxy, progress1: Double, progress2: Double, racer1: RacingRacer, racer2: RacingRacer, trippedRacerId: Int?, raceElapsedSeconds: Int) -> some View {
        let padding: CGFloat = 24
        let trackInset: CGFloat = 44
        let ovalWidth = max(trackInset * 2 + 4, geometry.size.width - padding * 2)
        let ovalHeight = max(120, geometry.size.height - 140)
        let racerSize: CGFloat = 48
        let cornerRadius = min(min(ovalWidth, ovalHeight) * 0.18, min(ovalWidth, ovalHeight) / 4)

        // Rounded-rectangle tracks (outer and inner)
        let outerPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: CGRect(x: 0, y: 0, width: ovalWidth, height: ovalHeight))
        let innerW = ovalWidth - trackInset * 2
        let innerH = ovalHeight - trackInset * 2
        let innerCornerRadius = max(0, cornerRadius - trackInset / 2)
        let innerPath = RoundedRectangle(cornerRadius: innerCornerRadius).path(in: CGRect(x: 0, y: 0, width: innerW, height: innerH))

        // Outer and inner positions: progress 0 = finish line (center bottom), progress 1 = finish line after one lap.
        // Outer lane is longer; outer runner gets a staggered start (same arc distance per lap as inner — like track and field).
        let innerR = min(innerCornerRadius, min(innerW, innerH) / 2)
        let innerPathLength = ovalPathLength(width: innerW, height: innerH, cornerRadius: innerR)
        let outerPathLength = ovalPathLength(width: ovalWidth, height: ovalHeight, cornerRadius: cornerRadius)
        let stagger = ovalOuterLaneStaggerFraction(innerPathLength: innerPathLength, outerPathLength: outerPathLength)

        let outerStart = ovalPathStartOffset(width: ovalWidth, height: ovalHeight)
        let innerStart = ovalPathStartOffset(width: innerW, height: innerH)
        let outerSpan = 1.0 - outerStart
        let innerSpan = 1.0 - innerStart
        let p1Outer = ovalOuterPathProgress(raceProgress: progress1, outerStart: outerStart, outerSpan: outerSpan, staggerFraction: stagger)
        let p2Outer = ovalOuterPathProgress(raceProgress: progress2, outerStart: outerStart, outerSpan: outerSpan, staggerFraction: stagger)
        let p1Inner = innerStart + progress1 * innerSpan
        let p2Inner = innerStart + progress2 * innerSpan
        let pt1Outer = pointOnRoundedRect(progress: p1Outer, width: ovalWidth, height: ovalHeight)
        let pt2Outer = pointOnRoundedRect(progress: p2Outer, width: ovalWidth, height: ovalHeight)
        let pt1InnerRaw = pointOnRoundedRect(progress: p1Inner, width: innerW, height: innerH, cornerRadius: innerR)
        let pt2InnerRaw = pointOnRoundedRect(progress: p2Inner, width: innerW, height: innerH, cornerRadius: innerR)
        let pt1Inner = CGPoint(x: pt1InnerRaw.x + trackInset, y: pt1InnerRaw.y + trackInset)
        let pt2Inner = CGPoint(x: pt2InnerRaw.x + trackInset, y: pt2InnerRaw.y + trackInset)

        // Slower racer on inner (shorter) track, faster on outer (longer) track
        let racer1OnInner = racer1.speed <= racer2.speed
        let pos1 = racer1OnInner ? pt1Inner : pt1Outer
        let pos2 = racer1OnInner ? pt2Outer : pt2Inner

        let half = racerSize / 2
        let finishLineWidth: CGFloat = 4
        let finishLineRowHeight: CGFloat = 10 // One row at center bottom
        let finishLineX = ovalWidth / 2 - finishLineWidth / 2
        let refereeSize: CGFloat = 64
        return VStack(spacing: 8) {
            Text("Race!")
                .font(.headline)
            speedClockView(
                racer1: racer1,
                racer2: racer2,
                raceElapsedSeconds: raceElapsedSeconds,
                finishTime1: finishTime1,
                finishTime2: finishTime2,
                maxWidth: ovalWidth
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            ZStack(alignment: .topLeading) {
                outerPath
                    .stroke(Color.gray.opacity(0.5), lineWidth: 6)
                    .frame(width: ovalWidth, height: ovalHeight)
                innerPath
                    .stroke(Color.gray.opacity(0.35), lineWidth: 6)
                    .frame(width: innerW, height: innerH)
                    .offset(x: trackInset, y: trackInset)
                // Start/finish line on outer track (one row at center bottom)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: ovalHeight - finishLineRowHeight)
                // Start/finish line on inner track (one row at center bottom)
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: finishLineWidth, height: finishLineRowHeight)
                    .offset(x: finishLineX, y: trackInset + innerH - finishLineRowHeight)
                racerView(racer: racer1, size: racerSize, pose: trippedRacerId == racer1.id ? .tripped : .running)
                    .offset(x: pos1.x - half, y: pos1.y - half)
                racerView(racer: racer2, size: racerSize, pose: trippedRacerId == racer2.id ? .tripped : .running)
                    .offset(x: pos2.x - half, y: pos2.y - half)
                // Referee off the track, at lower bottom of infield near the track edge—close to racers to detect cheating, not blocking or in their path
                refereeImageViewSmall(startRefereeImageName(prefix: config.assetPrefix), size: refereeSize)
                    .offset(x: ovalWidth / 2 - refereeSize / 2, y: trackInset + innerH - refereeSize - 16)
            }
            .frame(width: ovalWidth, height: ovalHeight)
        }
        .padding(.horizontal, padding)
    }

    private func formatSpeed(_ mph: Double) -> String {
        String(format: "%.1f", mph)
    }

    /// Effective speed when tripped: distance/time = 10*maxSpeed/finishTime (ideal ticks = 10*maxSpeed/speed).
    private func displayedSpeed(racer: RacingRacer, finishTime: Int?, maxSpeed: Double) -> Double {
        if trippedRacerIdForPenalty == racer.id, let t = finishTime, t > 0 {
            return 10 * maxSpeed / Double(t)
        }
        return racer.speed
    }

    private func nameLength(_ name: String) -> Int { name.count }

    private func racingNameFontSize(_ name: String) -> CGFloat {
        switch name.count {
        case ...8: return 18
        case ...12: return 16
        case ...16: return 14
        default: return 12
        }
    }

    private func speedClockView(
        racer1: RacingRacer,
        racer2: RacingRacer,
        raceElapsedSeconds: Int,
        finishTime1: Int?,
        finishTime2: Int?,
        maxWidth: CGFloat
    ) -> some View {
        let t1 = finishTime1 ?? raceElapsedSeconds
        let t2 = finishTime2 ?? raceElapsedSeconds
        let maxSpeed = max(racer1.speed, racer2.speed)
        func format(_ sec: Int) -> String { String(format: "%d:%02d", sec / 60, sec % 60) }

        func racerRow(_ racer: RacingRacer, seconds: Int) -> some View {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(racer.name)
                    .font(.system(size: racingNameFontSize(racer.name), weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: max(120, maxWidth * 0.68), alignment: .leading)
                Spacer(minLength: 4)
                Text(format(seconds))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                    .layoutPriority(1)
            }
        }

        return VStack(alignment: .leading, spacing: 4) {
            racerRow(racer1, seconds: t1)
            racerRow(racer2, seconds: t2)
            Text("\(formatSpeed(displayedSpeed(racer: racer1, finishTime: finishTime1, maxSpeed: maxSpeed))) / \(formatSpeed(displayedSpeed(racer: racer2, finishTime: finishTime2, maxSpeed: maxSpeed))) mph")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: maxWidth, alignment: .leading)
    }

    private func racerView(racer: RacingRacer, size: CGFloat, pose: RacingPose = .start) -> some View {
        Group {
            if let imageName = racerDisplayImageName(for: racer, config: config, pose: pose) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Text(racer.icon)
                    .font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
    }

    private func laneView(racer: RacingRacer, progress: Double, trackWidth: CGFloat, laneHeight: CGFloat, emojiSize: CGFloat) -> some View {
        let racerX = max(0, progress * (trackWidth - emojiSize - CGFloat(4)))
        return ZStack(alignment: .leading) {
            // Track background (full width so both lanes align)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: trackWidth, height: laneHeight)
            // Finish line (right)
            Rectangle()
                .fill(Color.red)
                .frame(width: 4, height: laneHeight)
                .frame(maxWidth: .infinity, alignment: .trailing)
            // Racer: left-justified at start (progress 0 = x 0), same formula for both lanes
            Group {
                if let imageName = racerDisplayImageName(for: racer, config: config) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: emojiSize, height: emojiSize)
                } else {
                    Text(racer.icon)
                        .font(.system(size: emojiSize))
                }
            }
            .frame(width: emojiSize, height: emojiSize, alignment: .leading)
            .offset(x: racerX)
        }
        .frame(width: trackWidth, height: laneHeight)
    }
    
    private func startRace() {
        guard let r1 = selectedLane1, let r2 = selectedLane2 else { return }
        isRacing = true
        progress1 = 0
        progress2 = 0
        speechManager.speak("starting-whistle")
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.fireRaceTimer(r1: r1, r2: r2)
            }
        }
    }

    private func fireRaceTimer(r1: RacingRacer, r2: RacingRacer) {
        raceElapsedSeconds = 0
        hasPlayedFirstFinishCheering = false
        finishTime1 = nil
        finishTime2 = nil
        trippedRacerIdForPenalty = nil
        let maxSpeed = max(r1.speed, r2.speed)
        let (fasterRacer, slowerRacer) = r1.speed >= r2.speed ? (r1, r2) : (r2, r1)
        let speedDelta = abs(r1.speed - r2.speed)
        let canTripFaster: Bool = {
            switch config.assetPrefix {
            case "dino":
                return firstExistingAssetName(in: dinoRacerSuffixedCandidates(for: fasterRacer, suffix: "-tripped")) != nil
            case "ptero":
                if let b = fasterRacer.pteroRacingAssetBase {
                    return ImageAssetCache.imageExists(named: b + "-tripped")
                }
                return ImageAssetCache.imageExists(named: fasterRacer.trippedImageName(prefix: "ptero"))
            case "marine":
                if let b = fasterRacer.marineRacingAssetBase {
                    return ImageAssetCache.imageExists(named: b + "-tripped")
                }
                return false
            default:
                return ImageAssetCache.imageExists(named: fasterRacer.trippedImageName(prefix: config.assetPrefix))
            }
        }()
        let isMaxDelta = config.poolMinSpeed.map { slowerRacer.speed <= $0 } ?? false
            && config.poolMaxSpeed.map { fasterRacer.speed >= $0 } ?? false
        let hopWaypoints = config.assetPrefix == "ptero"
            ? airportWaypointProgresses(width: pteroTrackWidth, height: pteroTrackHeight, inset: 0)
            : []
        var lagTicksRemainingByRacerId: [Int: Int] = [:]
        var nextLagWaypointIndexByRacerId: [Int: Int] = [r1.id: 0, r2.id: 0]

        raceTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                let isTripped = trippedRacerId != nil
                if let ticks = lagTicksRemainingByRacerId[r1.id], ticks > 0 {
                    lagTicksRemainingByRacerId[r1.id] = ticks - 1
                }
                if let ticks = lagTicksRemainingByRacerId[r2.id], ticks > 0 {
                    lagTicksRemainingByRacerId[r2.id] = ticks - 1
                }
                let r1LagPaused = (lagTicksRemainingByRacerId[r1.id] ?? 0) > 0
                let r2LagPaused = (lagTicksRemainingByRacerId[r2.id] ?? 0) > 0
                let r1Paused = (isTripped && trippedRacerId == r1.id) || r1LagPaused
                let r2Paused = (isTripped && trippedRacerId == r2.id) || r2LagPaused

                let rawP1 = r1Paused ? progress1 : progress1 + stepPerTick * (r1.speed / maxSpeed)
                let rawP2 = r2Paused ? progress2 : progress2 + stepPerTick * (r2.speed / maxSpeed)
                var newP1 = min(1.0, rawP1)
                var newP2 = min(1.0, rawP2)

                // Pterosaur hops: pause **short of** each waypoint (open-water approach), then continue past the landmark — species-specific lag length.
                // Fast racers can skip the narrow [trigger, landmark) window in one tick; treat crossing the landmark from below as “snap to trigger” too.
                if config.assetPrefix == "ptero", !hopWaypoints.isEmpty {
                    if let idx = nextLagWaypointIndexByRacerId[r1.id], idx < hopWaypoints.count {
                        let waypoint = hopWaypoints[idx]
                        let landmark = waypoint.progress
                        let trigger = airportLagTriggerProgress(waypointIndex: idx, width: pteroTrackWidth, height: pteroTrackHeight, inset: 0)
                        if progress1 < landmark {
                            if newP1 >= landmark {
                                newP1 = trigger
                                lagTicksRemainingByRacerId[r1.id] = hopLagTicks(for: r1, at: waypoint.node)
                                nextLagWaypointIndexByRacerId[r1.id] = idx + 1
                            } else if newP1 >= trigger && progress1 < trigger {
                                newP1 = trigger
                                lagTicksRemainingByRacerId[r1.id] = hopLagTicks(for: r1, at: waypoint.node)
                                nextLagWaypointIndexByRacerId[r1.id] = idx + 1
                            }
                        }
                    }
                    if let idx = nextLagWaypointIndexByRacerId[r2.id], idx < hopWaypoints.count {
                        let waypoint = hopWaypoints[idx]
                        let landmark = waypoint.progress
                        let trigger = airportLagTriggerProgress(waypointIndex: idx, width: pteroTrackWidth, height: pteroTrackHeight, inset: 0)
                        if progress2 < landmark {
                            if newP2 >= landmark {
                                newP2 = trigger
                                lagTicksRemainingByRacerId[r2.id] = hopLagTicks(for: r2, at: waypoint.node)
                                nextLagWaypointIndexByRacerId[r2.id] = idx + 1
                            } else if newP2 >= trigger && progress2 < trigger {
                                newP2 = trigger
                                lagTicksRemainingByRacerId[r2.id] = hopLagTicks(for: r2, at: waypoint.node)
                                nextLagWaypointIndexByRacerId[r2.id] = idx + 1
                            }
                        }
                    }
                }

                // Random trip: faster dinosaur can trip once per race. Max delta = 50% chance; else scaled by speed ratio.
                if !hasTrippedThisRace, canTripFaster, trippedRacerId == nil,
                   speedDelta > 1.0, newP1 < 1.0, newP2 < 1.0 {
                    let fasterProgress = fasterRacer.id == r1.id ? newP1 : newP2
                    if fasterProgress >= 0.25 && fasterProgress <= 0.75 {
                        let tripChance = isMaxDelta ? 0.5 : (0.10 * min(1.0, speedDelta / maxSpeed))
                        if Double.random(in: 0..<1) < tripChance {
                            hasTrippedThisRace = true
                            trippedRacerId = fasterRacer.id
                            trippedRacerIdForPenalty = fasterRacer.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + tripDuration) {
                                trippedRacerId = nil
                            }
                        }
                    }
                }

                progress1 = newP1
                progress2 = newP2
                let tickEndSeconds = raceElapsedSeconds + 1
                if newP1 >= 1.0 && finishTime1 == nil { finishTime1 = tickEndSeconds }
                if newP2 >= 1.0 && finishTime2 == nil { finishTime2 = tickEndSeconds }
                raceElapsedSeconds = tickEndSeconds

                // Cheer when first crosses; keep race running until both finish
                let firstCrossed = (newP1 >= 1.0 || newP2 >= 1.0) && !hasPlayedFirstFinishCheering
                if firstCrossed {
                    hasPlayedFirstFinishCheering = true
                    if let url = speechManager.urlForAudio(key: "crowd-cheering") {
                        speechManager.playAudioFile(url: url)
                    } else {
                        speechManager.speak("crowd-cheering")
                    }
                }

                // Stop only when both have finished; pause briefly so final time is visible
                if newP1 >= 1.0 && newP2 >= 1.0 {
                    stopRace()
                    let t1 = finishTime1 ?? tickEndSeconds
                    let t2 = finishTime2 ?? tickEndSeconds
                    // Primary winner decision is finish tick. If both cross in the same tick,
                    // use in-tick overflow past 1.0 to break apparent visual ties.
                    if t1 < t2 {
                        winner = r1
                        isTie = false
                    } else if t2 < t1 {
                        winner = r2
                        isTie = false
                    } else {
                        let overflow1 = max(0, rawP1 - 1.0)
                        let overflow2 = max(0, rawP2 - 1.0)
                        if overflow1 > overflow2 + 0.0001 {
                            winner = r1
                            isTie = false
                        } else if overflow2 > overflow1 + 0.0001 {
                            winner = r2
                            isTie = false
                        } else {
                            winner = nil
                            isTie = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        postRaceStep = "referee-track"
                    }
                }
            }
        }
        // Let first motion happen on the first timer tick so racers visibly start at A.
    }

    /// Post-race tie: both dinosaurs, times, "It's a tie!"
    private func postRaceTieView(geometry: GeometryProxy, racer1 r1: RacingRacer, racer2 r2: RacingRacer) -> some View {
        func format(_ sec: Int) -> String { String(format: "%d:%02d", sec / 60, sec % 60) }
        let t1 = finishTime1 ?? raceElapsedSeconds
        let t2 = finishTime2 ?? raceElapsedSeconds
        return VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(r1.name): \(format(t1))")
                    .font(.system(size: nameLength(r1.name) > 10 ? 20 : 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(r2.name): \(format(t2))")
                    .font(.system(size: nameLength(r2.name) > 10 ? 20 : 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Text("It's a tie!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                refereeImageView(tieRefereeImageName(prefix: config.assetPrefix))
                    .frame(maxWidth: .infinity)
                HStack(spacing: 16) {
                    Group {
                        if let name = finishWinnerImageName(for: r1, config: config, isBroadDelta: false) {
                            Image(name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Text(r1.icon)
                                .font(.system(size: 80))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Group {
                        if let name = finishWinnerImageName(for: r2, config: config, isBroadDelta: false) {
                            Image(name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Text(r2.icon)
                                .font(.system(size: 80))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: 220)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Text("\(r1.name) & \(r2.name) – \(formatSpeed(r1.speed)) / \(formatSpeed(r2.speed)) mph")
                .font(.system(size: nameLength(r1.name) + nameLength(r2.name) > 16 ? 16 : 20, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            playTieAnnouncement(racer1: r1, racer2: r2)
        }
    }

    private func playTieAnnouncement(racer1 r1: RacingRacer, racer2 r2: RacingRacer) {
        let tieURL = speechManager.urlForAudio(key: "game-racing-its-a-tie")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")

        func afterCrowd() {
            winners.append(r1)
            winners.append(r2)
            roundsCompleted += 1
            if roundsCompleted < maxRounds {
                advanceToNextRound()
            } else {
                showVictory = true
            }
        }

        func playCrowdThenAdvance() {
            if let url = crowdURL {
                speechManager.playAudioFile(url: url)
                speechManager.onAudioFinished = {
                    Task { @MainActor in
                        self.speechManager.onAudioFinished = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            afterCrowd()
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    afterCrowd()
                }
            }
        }

        if let url = tieURL {
            speechManager.playAudioFile(url: url)
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    playCrowdThenAdvance()
                }
            }
        } else {
            playCrowdThenAdvance()
        }
    }

    private func stopRace() {
        raceTimer?.invalidate()
        raceTimer = nil
    }
    
    // MARK: - Winner (announce by text + audio: game-racing-the-winner-is, then dino name, then crowd-cheering)
    private func winnerView(winner w: RacingRacer) -> some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 60))
            Text("The winner is")
                .font(.title3)
                .foregroundColor(.secondary)
            if let imageName = winnerDisplayImageName(for: w, config: config) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(w.icon)
                    .font(.system(size: 80))
            }
            Text("\(w.name) – \(formatSpeed(w.speed)) mph")
                .font(.system(size: nameLength(w.name) > 10 ? 18 : 22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding()
        .onAppear {
            playWinnerAnnouncement(winner: w)
        }
    }

    private func playWinnerAnnouncement(winner w: RacingRacer) {
        let announceURL = speechManager.urlForAudio(key: "game-racing-the-winner-is")
        let crowdURL = speechManager.urlForAudio(key: "crowd-cheering")

        func afterCrowd() {
            winners.append(w)
            roundsCompleted += 1
            if roundsCompleted < maxRounds {
                advanceToNextRound()
            } else {
                showVictory = true
            }
        }

        func playCrowdThenAdvance() {
            if let url = crowdURL {
                speechManager.playAudioFile(url: url)
                speechManager.onAudioFinished = {
                    Task { @MainActor in
                        self.speechManager.onAudioFinished = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            afterCrowd()
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    afterCrowd()
                }
            }
        }

        func playWinnerNameThenCrowd() {
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    playCrowdThenAdvance()
                }
            }
            speechManager.speak(audioKey: w.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: w.name)
        }

        if let url = announceURL {
            speechManager.playAudioFile(url: url)
            speechManager.onAudioFinished = {
                Task { @MainActor in
                    self.speechManager.onAudioFinished = nil
                    playWinnerNameThenCrowd()
                }
            }
        } else {
            playWinnerNameThenCrowd()
        }
    }

    private func advanceToNextRound() {
        winner = nil
        isTie = false
        postRaceStep = nil
        selectedLane1 = nil
        selectedLane2 = nil
        pendingRacer2 = nil
        showingExpandedRacer = nil
        isRacing = false
        canSelectSecond = false
        hasPlayedFirstRacerPrompt = false
        hasPlayedStartingGun = false
        hasPlayedWeHaveAWinner = false
        trippedRacerId = nil
        trippedRacerIdForPenalty = nil
        hasTrippedThisRace = false
        raceElapsedSeconds = 0
        hasPlayedFirstFinishCheering = false
        finishTime1 = nil
        finishTime2 = nil
    }

    // MARK: - Victory (walk unique winners, then success image + good-job + crowd + dismiss)

    /// Deduplicated by racer id (first occurrence kept) so we don't show the same dinosaur twice.
    private var uniqueWinners: [RacingRacer] {
        var seen: Set<Int> = []
        return winners.filter { seen.insert($0.id).inserted }
    }

    /// Victory recap: winner portrait + speed subtitle (concepts introduced during play).
    private var racingVictoryRecapItems: [VictoryRecapDisplayItem] {
        uniqueWinners.map { racer in
            VictoryRecapDisplayItem(
                id: "\(racer.id)",
                title: racer.name,
                subtitle: "\(formatSpeed(racer.speed)) mph",
                imageAssetName: winnerDisplayImageName(for: racer, config: config)
                    ?? racerDisplayImageName(for: racer, config: config),
                fallbackEmoji: racer.icon
            )
        }
    }

    /// Matches row layout in `victoryView` (`92` row height); list viewport caps at `maxVisibleRecapRows` (3) then scrolls.
    private func victoryScrollHeight(forWinnerCount count: Int, maxHeight: CGFloat) -> CGFloat {
        StandardVictoryLayout.listScrollHeightRacing(rowCount: count, maxScreenHeight: maxHeight)
    }

    private var victoryView: some View {
        GeometryReader { geo in
            let listH = victoryScrollHeight(forWinnerCount: racingVictoryRecapItems.count, maxHeight: geo.size.height)
            VictorySplitColumnView(
                listScrollHeight: listH,
                showSuccessPhase: endSequenceStep == 2,
                endHighlightIndex: endHighlightIndex,
                gameTitle: config.title,
                scrollRows: {
                    ForEach(Array(racingVictoryRecapItems.enumerated()), id: \.element.id) { index, item in
                        StandardVictoryRecapRowView(
                            item: item,
                            isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                        )
                        .id(index)
                    }
                },
                successPhase: {
                    LandGameVictorySuccessStingerThenContinue(
                        candidateSuccessImageNames: racingSuccessImageCandidates(for: config),
                        catalogGameIdForStinger: config.id,
                        imageSide: GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
                        missingPolicy: .empty,
                        speechManager: speechManager,
                        onContinue: playGoodJobAndCrowdThenDismiss
                    )
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            let unique = uniqueWinners
            if unique.isEmpty {
                endSequenceStep = 2
            } else {
                let racer = unique[0]
                speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        let unique = uniqueWinners
        if endHighlightIndex < unique.count {
            let racer = unique[endHighlightIndex]
            speechManager.speak(audioKey: racer.effectiveFallbackImageName(prefix: config.assetPrefix), fallbackText: racer.name)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
        } else {
            endSequenceStep = 2
        }
    }

    private func playGoodJobAndCrowdThenDismiss() {
        StandardVictorySequence.dismissAfterVictory(
            configId: config.id,
            isPresented: $isPresented,
            speechManager: speechManager
        )
    }
}

// MARK: - Pterosaur airport course background (procedural water — no bundled image required)

private struct AirportCourseWaterBackground: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.45, green: 0.74, blue: 0.88), location: 0),
                    .init(color: Color(red: 0.22, green: 0.55, blue: 0.78), location: 0.42),
                    .init(color: Color(red: 0.12, green: 0.38, blue: 0.62), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            ForEach(0..<7, id: \.self) { i in
                Ellipse()
                    .fill(Color.white.opacity(0.07 + Double(i % 3) * 0.02))
                    .frame(width: width * 1.35, height: 22 + CGFloat(i % 4) * 8)
                    .offset(x: CGFloat(i % 3) * 18 - 18, y: CGFloat(i) * (height / 7) + 8)
                    .rotationEffect(.degrees(-6))
            }
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Racer Card (dino-racer-[clade-]{slug} image when present, else emoji)

struct RacingRacerCard: View {
    let racer: RacingRacer
    let gameConfig: RacingGameConfig
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let imageName = racerDisplayImageName(for: racer, config: gameConfig) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 84, height: 84)
                } else {
                    Text(racer.icon)
                        .font(.system(size: 84))
                }
                Text(racer.name)
                    .font(.footnote.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(width: 150, height: 150)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled && !isSelected)
    }
}

// MARK: - Game Configuration (pools per period; all pool dinosaurs shown per game)

enum RacingPeriod: String, CaseIterable {
    case jurassic
    case cretaceous
    case both
}

/// Pool entry: add more over time; each game shows all pool dinosaurs (no random subset).
private struct RacingRacerPoolEntry {
    let name: String
    let icon: String
    let speed: Double
    /// Folder/clade slug for `dino-racer-{clade}-{species}` assets (must match imageset naming).
    let racerAssetClade: String
}

private struct PterosaurRacerPoolEntry {
    let creatureId: Int
    let name: String
    let icon: String
    let speed: Double
    /// Catalog audio / spoken-name key (`ptero-{group}-{species}`); not used for racing **images**.
    let imageName: String
    let mesozoicSpan: AirPterosaurData.MesozoicSpan
    /// `ptero-racing-{clade}-{slug}` base; must match imagesets in the asset catalog.
    let racingAssetBase: String
}

private func dinosaurRacerPool(for period: RacingPeriod) -> [RacingRacerPoolEntry] {
    let span: LandDinosaurRacingCatalog.MesozoicSpan = switch period {
    case .jurassic: .jurassic
    case .cretaceous: .cretaceous
    case .both: .both
    }
    return LandDinosaurRacingCatalog.dinosaurRacersForRacing(mesozoicSpan: span).map { entry in
        RacingRacerPoolEntry(
            name: entry.displayName,
            icon: entry.icon,
            speed: entry.speed,
            racerAssetClade: entry.racerAssetClade
        )
    }
}

/// Pterosaur pool for Racing Pterosaurs: only species that have a full `ptero-racing-*` art pack in the catalog (`ImageAssetNames`).
private let pterosaurRacerPool: [PterosaurRacerPoolEntry] = {
    MatchingGameConfigs.allPterosaurs.compactMap { p in
        guard let img = p.imageName,
              let span = AirPterosaurData.mesozoicSpanForRacing(pterosaurId: p.id),
              let base = AirPterosaurData.pteroRacingAssetBase(fromCatalogImageName: img),
              hasCompletePterosaurRacingAssetPack(base: base) else { return nil }
        return PterosaurRacerPoolEntry(
            creatureId: p.id,
            name: p.name,
            icon: p.icon,
            speed: pterosaurSpeedEstimate(name: p.name),
            imageName: img,
            mesozoicSpan: span,
            racingAssetBase: base
        )
    }
}()

private func pterosaurSpeedEstimate(name: String) -> Double {
    switch name {
    case "Pteranodon", "Nyctosaurus": return 25
    case "Rhamphorhynchus", "Dsungaripterus", "Tapejara": return 22
    case "Pterodactylus", "Quetzalcoatlus", "Anurognathus", "Tupandactylus": return 20
    case "Dimorphodon": return 18
    default: return 20
    }
}

struct RacingGameConfigs {
    /// Config used for the game list card only (id "racing-dinosaurs" matches imageset game-racing-dinosaurs). Period choice then loads Jurassic or Cretaceous.
    static let racingDinosaurs: RacingGameConfig = {
        makeConfig(for: .cretaceous)
    }()

    /// Config with empty racers: RacingGameView shows period selection first, then dinosaur selection. Avoids sheet dismiss/present flash.
    static let racingDinosaursNeedsPeriod: RacingGameConfig = RacingGameConfig(
        id: "racing-dinosaurs",
        title: "Racing Dinosaurs!",
        introAudio: "racing-dinosaurs",
        assetPrefix: "dino",
        racers: [],
        poolMinSpeed: nil,
        poolMaxSpeed: nil,
        trackLayout: .ovalDualLane
    )

    /// Config with empty racers: RacingGameView shows period selection first, then pterosaur selection.
    static var racingPterosaursCardConfig: RacingGameConfig {
        racingPterosaursNeedsPeriod
    }

    static let racingPterosaursNeedsPeriod: RacingGameConfig = RacingGameConfig(
        id: "racing-pterosaurs",
        title: "Racing Pterosaurs!",
        introAudio: "racing-pterosaurs",
        assetPrefix: "ptero",
        racers: [],
        poolMinSpeed: nil,
        poolMaxSpeed: nil,
        trackLayout: .airportHop
    )

    /// Racing Marine Reptiles card config (Both-period preview). Launch uses `racingMarineReptilesNeedsPeriod`.
    static let racingMarineReptiles: RacingGameConfig = {
        makeMarineConfig(for: .both)
    }()

    /// Config with empty racers: RacingGameView shows period selection first, then marine reptile selection.
    static let racingMarineReptilesNeedsPeriod: RacingGameConfig = RacingGameConfig(
        id: "racing-marine-reptiles",
        title: "Racing Marine Reptiles!",
        introAudio: "racing-marine-reptiles",
        assetPrefix: "marine",
        racers: [],
        poolMinSpeed: nil,
        poolMaxSpeed: nil,
        trackLayout: .marineBuoySlalom(buoyCount: 8)
    )

    static func makeMarineConfig(for period: RacingPeriod) -> RacingGameConfig {
        let mesozoicSpan: SeaMarineReptileData.MesozoicSpan = switch period {
        case .jurassic: .jurassic
        case .cretaceous: .cretaceous
        case .both: .both
        }
        let pool = SeaMarineReptileData.marineRacersForRacing(mesozoicSpan: mesozoicSpan)
        guard !pool.isEmpty else {
            return racingMarineReptilesNeedsPeriod
        }
        let periodId = period == .both ? "both" : period.rawValue
        let titleSuffix = period == .both ? "Both" : period.rawValue.capitalized
        let speeds = pool.map(\.speed)
        let racers = pool.map { entry in
            RacingRacer(
                id: entry.creature.id,
                name: entry.creature.name,
                icon: entry.icon,
                speed: entry.speed,
                fallbackImageName: entry.creature.imageName,
                marineRacingAssetBase: entry.racingAssetBase
            )
        }
        return RacingGameConfig(
            id: "racing-marine-reptiles-\(periodId)",
            title: "Racing Marine Reptiles! (\(titleSuffix))",
            introAudio: "racing-marine-reptiles",
            assetPrefix: "marine",
            racers: racers,
            poolMinSpeed: speeds.min(),
            poolMaxSpeed: speeds.max(),
            trackLayout: .marineBuoySlalom(buoyCount: 8)
        )
    }

    private static func pterosaurPool(for period: RacingPeriod) -> [PterosaurRacerPoolEntry] {
        switch period {
        case .jurassic:
            return pterosaurRacerPool.filter { $0.mesozoicSpan == .jurassic || $0.mesozoicSpan == .both }
        case .cretaceous:
            return pterosaurRacerPool.filter { $0.mesozoicSpan == .cretaceous || $0.mesozoicSpan == .both }
        case .both:
            return pterosaurRacerPool
        }
    }

    static func makePterosaurConfig(for period: RacingPeriod) -> RacingGameConfig {
        let pool = pterosaurPool(for: period)
        guard !pool.isEmpty else {
            return racingPterosaursNeedsPeriod
        }
        let periodId = period == .both ? "both" : period.rawValue
        let titleSuffix = period == .both ? "Both" : period.rawValue.capitalized
        let speeds = pool.map(\.speed)
        let racers = pool.map { entry in
            RacingRacer(
                id: entry.creatureId,
                name: entry.name,
                icon: entry.icon,
                speed: entry.speed,
                fallbackImageName: entry.imageName,
                pteroRacingAssetBase: entry.racingAssetBase
            )
        }
        return RacingGameConfig(
            id: "racing-pterosaurs-\(periodId)",
            title: "Racing Pterosaurs! (\(titleSuffix))",
            introAudio: "racing-pterosaurs",
            assetPrefix: "ptero",
            racers: racers,
            poolMinSpeed: speeds.min(),
            poolMaxSpeed: speeds.max(),
            trackLayout: .airportHop
        )
    }

    /// Returns a new config from the period's pool. Call when user picks a period so each game has a fresh set.
    static func makeConfig(for period: RacingPeriod) -> RacingGameConfig {
        let pool: [RacingRacerPoolEntry]
        let idBase: Int
        let title: String
        switch period {
        case .jurassic:
            pool = dinosaurRacerPool(for: .jurassic)
            idBase = 100
            title = "Racing Dinosaurs! (Jurassic)"
        case .cretaceous:
            pool = dinosaurRacerPool(for: .cretaceous)
            idBase = 200
            title = "Racing Dinosaurs! (Cretaceous)"
        case .both:
            pool = dinosaurRacerPool(for: .both)
            idBase = 0
            title = "Racing Dinosaurs! (Both)"
        }
        let speeds = pool.map(\.speed)
        let racers = pool.enumerated().map { index, entry in
            RacingRacer(
                id: idBase + index + 1,
                name: entry.name,
                icon: entry.icon,
                speed: entry.speed,
                racerAssetClade: entry.racerAssetClade
            )
        }
        let periodId = period == .both ? "both" : period.rawValue
        return RacingGameConfig(
            id: "racing-dinosaurs-\(periodId)",
            title: title,
            introAudio: "racing-dinosaurs",
            assetPrefix: "dino",
            racers: Array(racers),
            poolMinSpeed: speeds.min(),
            poolMaxSpeed: speeds.max(),
            trackLayout: .ovalDualLane
        )
    }
}

// MARK: - Period Selection (Jurassic / Cretaceous / Both)

struct RacingPeriodSelectionView: View {
    @Binding var isPresented: Bool
    var onSelectPeriod: (RacingGameConfig) -> Void
    var gameFamily: RacingGameFamily = .dinosaurs
    /// When true, period selection is embedded in RacingGameView; selecting a period does not dismiss.
    var embedMode: Bool = false

    @State private var speechManager = SpeechManager()
    @State private var enabledJurassic = false
    @State private var enabledCretaceous = false
    @State private var enabledBoth = false
    @State private var hasStartedSequence = false
    @State private var showText = false

    enum RacingGameFamily {
        case dinosaurs
        case pterosaurs
        case marineReptiles
    }

    private var periodSelectionSubtitle: String {
        switch gameFamily {
        case .pterosaurs: return "Only pterosaurs from that period can race."
        case .marineReptiles: return "Only marine reptiles from that period can race."
        case .dinosaurs: return "Only dinosaurs from that period can race."
        }
    }

    private func config(for period: RacingPeriod) -> RacingGameConfig {
        switch gameFamily {
        case .pterosaurs: return RacingGameConfigs.makePterosaurConfig(for: period)
        case .marineReptiles: return RacingGameConfigs.makeMarineConfig(for: period)
        case .dinosaurs: return RacingGameConfigs.makeConfig(for: period)
        }
    }

    private let periods: [(name: String, imageAssetName: String, emoji: String, period: RacingPeriod)] = [
        ("Jurassic", "period-jurassic", "🦕", .jurassic),
        ("Cretaceous", "period-cretaceous", "🦖", .cretaceous),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a period")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 24)
                    .opacity(showText ? 1 : 0)
                Text(periodSelectionSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(showText ? 1 : 0)
                Text("Mesozoic Age")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 8)
                    .opacity(showText ? 1 : 0)
                VStack(spacing: 16) {
                    periodCard(name: periods[0].name, imageAssetName: periods[0].imageAssetName, emoji: periods[0].emoji, period: periods[0].period, isEnabled: enabledJurassic)
                    periodCard(name: periods[1].name, imageAssetName: periods[1].imageAssetName, emoji: periods[1].emoji, period: periods[1].period, isEnabled: enabledCretaceous)
                    bothPeriodCard(isEnabled: enabledBoth)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                showText = true
                if !hasStartedSequence {
                    hasStartedSequence = true
                    startPeriodSequence()
                }
            }
            .onDisappear {
                speechManager.stopCurrentAudio()
            }
            .allowsHitTesting(enabledJurassic || enabledCretaceous || enabledBoth)
        }
    }

    /// Both period: Jurassic and Cretaceous images side by side, smaller.
    private func bothPeriodCard(isEnabled: Bool) -> some View {
        Button {
            onSelectPeriod(config(for: .both))
            if !embedMode { isPresented = false }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    if ImageAssetCache.imageExists(named: "period-jurassic") {
                        Image("period-jurassic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                    } else {
                        Text("🦕")
                            .font(.system(size: 40))
                            .frame(height: 60)
                    }
                    if ImageAssetCache.imageExists(named: "period-cretaceous") {
                        Image("period-cretaceous")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                    } else {
                        Text("🦖")
                            .font(.system(size: 40))
                            .frame(height: 60)
                    }
                }
                Text("Both")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.12)))
            .opacity(isEnabled ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func periodCard(name: String, imageAssetName: String, emoji: String, period: RacingPeriod, isEnabled: Bool) -> some View {
        Button {
            onSelectPeriod(config(for: period))
            if !embedMode { isPresented = false }
        } label: {
            VStack(spacing: 8) {
                if ImageAssetCache.imageExists(named: imageAssetName) {
                    Image(imageAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                } else {
                    Text(emoji)
                        .font(.system(size: 64))
                        .frame(height: 100)
                }
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.12)))
            .opacity(isEnabled ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    /// Four-step sequence: cover-choose-a-period → enable Jurassic + cover-jurassic → enable Cretaceous + cover-cretaceous → enable Both.
    private func startPeriodSequence() {
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.periodIntroDone()
            }
        }
        speechManager.speak("cover-choose-a-period")
    }

    private func periodIntroDone() {
        enabledJurassic = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.jurassicDone()
            }
        }
        speechManager.speak("cover-jurassic", chainDelay: true)
    }

    private func jurassicDone() {
        enabledCretaceous = true
        speechManager.onAudioFinished = {
            Task { @MainActor in
                self.speechManager.onAudioFinished = nil
                self.cretaceousDone()
            }
        }
        speechManager.speak("cover-cretaceous", chainDelay: true)
    }

    private func cretaceousDone() {
        enabledBoth = true
        speechManager.onAudioFinished = nil
        if speechManager.urlForAudio(key: "cover-both") != nil {
            speechManager.speak("cover-both", chainDelay: true)
        }
    }
}

#Preview {
    RacingGameView(isPresented: .constant(true), gameConfig: RacingGameConfigs.racingDinosaurs)
}
