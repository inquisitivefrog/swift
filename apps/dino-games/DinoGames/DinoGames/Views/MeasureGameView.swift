//
//  MeasureGameView.swift
//  DinoGames
//
//  Measure the Dinosaur! / Measure the Pterosaur! / Measure the Mosasaur! (config-driven).
//  Stack creatures on the right to match the height of a reference on the left.
//  Each round begins with N creatures (one per group/clade) in a 3-column grid; used creatures are tracked to prevent repeat use in future rounds.
//  Designed for expansion: config.poolKind selects dinosaurs, pterosaurs, or marine reptiles.
//

import SwiftUI

// MARK: - Category-agnostic creature (for display and round logic)

/// A creature that can be shown in the measure game grid. Used for dinosaurs, pterosaurs, or marine reptiles so the view stays pool-agnostic.
struct MeasureCreature: Identifiable {
    let id: Int
    let name: String
    let imageName: String?
    let icon: String
}

// MARK: - Pool kind (expansion: add .pterosaurs, .marineReptiles)

enum MeasurePoolKind: String {
    case dinosaurs
    case pterosaurs
    case marineReptiles
}

// MARK: - Game Configuration

struct MeasureGameConfig {
    let id: String
    let title: String
    let introAudio: String
    /// Which creature pool and grouping to use (dinosaurs = 9 clades, pterosaurs/marine reptiles = TBD).
    let poolKind: MeasurePoolKind
}

// MARK: - Dinosaur height (for measure comparison; same IDs as Weigh game)

/// Estimated body length in meters per dinosaur id (1–54). Used to compare heights and scale images.
private let dinosaurEstimatedHeightMetersById: [Int: Double] = [
    1: 12,  2: 9,   3: 9,   4: 0.6,  5: 12,  6: 15,  7: 22,  8: 8,
    9: 9,   10: 8,  11: 9,  12: 1.5, 13: 9,  14: 18, 15: 2,  16: 5,
    17: 4,  18: 6,  19: 0.2, 20: 0.2, 21: 26, 22: 6,  23: 20, 24: 5,
    25: 7,  26: 0.5, 27: 3,  28: 18, 29: 1,  30: 0.2, 31: 16, 32: 6,
    33: 0.4, 34: 0.2, 35: 8,  36: 4,  37: 0.2, 38: 0.6, 39: 6,  40: 18,
    41: 7,  42: 6,  43: 1.2, 44: 20, 45: 6,  46: 7,  47: 9,  48: 7,
    49: 1.2, 50: 2,  51: 7,  52: 5,  53: 6,  54: 7,
]

// Threshold for "about the same height": relative difference < this value. Tight (8%) so e.g. 2×Edmontonia (14m) does not match Brontosaurus (20m).
private let sameHeightRelativeThreshold = 0.08

// MARK: - Configs and round selection

enum MeasureGameConfigs {
    /// Intro/game name audio: Audio/Games/game-measure-the-dinosaur.m4a (same naming as game card for consistency).
    static let measureDinosaur = MeasureGameConfig(
        id: "measure-the-dinosaur",
        title: "Measure the Dinosaur!",
        introAudio: "game-measure-the-dinosaur",
        poolKind: .dinosaurs
    )

    // Future: add when pterosaur/marine reptile pools and grouping are defined.
    // static let measurePterosaur = MeasureGameConfig(id: "measure-the-pterosaur", title: "Measure the Pterosaur!", introAudio: "game-intro-measure-pterosaur", poolKind: .pterosaurs)
    // static let measureMosasaur = MeasureGameConfig(id: "measure-the-mosasaur", title: "Measure the Mosasaur!", introAudio: "game-intro-measure-mosasaur", poolKind: .marineReptiles)

    /// Returns one creature per group (e.g. 9 for dinosaurs = 9 clades), excluding any already used this game. Order is shuffled for display.
    /// Returns nil if the pool can't fill a full round (e.g. not enough groups or not enough unused creatures per group).
    static func makeRoundCreatures(poolKind: MeasurePoolKind, excluding usedIds: Set<Int>) -> [MeasureCreature]? {
        switch poolKind {
        case .dinosaurs:
            guard let dinos = makeRoundDinosaurs(excluding: usedIds) else { return nil }
            return dinos.map { d in MeasureCreature(id: d.id, name: d.name, imageName: d.imageName, icon: d.icon) }
        case .pterosaurs:
            return makeRoundPterosaurs(excluding: usedIds)
        case .marineReptiles:
            return makeRoundMarineReptiles(excluding: usedIds)
        }
    }

    /// Dinosaurs: 9 clades, one dinosaur per clade. Uses MatchingGameConfigs.dinosaurCladeById and allDinosaurs.
    private static func makeRoundDinosaurs(excluding usedIds: Set<Int>) -> [Dinosaur]? {
        let cladeById = MatchingGameConfigs.dinosaurCladeById
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            d.imageName != nil && d.imageName!.hasPrefix("dino-") && !usedIds.contains(d.id)
        }
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        let clades = DinoClade.allCases
        var chosen: [Dinosaur] = []
        for clade in clades {
            guard let candidates = byClade[clade], !candidates.isEmpty else { return nil }
            chosen.append(candidates.randomElement()!)
        }
        return chosen.shuffled()
    }

    /// Pterosaurs: one per group when grouping is defined (e.g. by family). Stub until pterosaur groups exist — returns nil so UI can show "not enough" or we add a simple shuffled take.
    private static func makeRoundPterosaurs(excluding usedIds: Set<Int>) -> [MeasureCreature]? {
        let pool = MatchingGameConfigs.allPterosaurs.filter { d in
            d.imageName != nil && d.imageName!.hasPrefix("ptero-") && !usedIds.contains(d.id)
        }
        guard pool.count >= 6 else { return nil }
        // No pterosaur "clade" map yet; take up to 9 random for variety. When pterosaur groups exist, use one-per-group like dinosaurs.
        let chosen = Array(pool.shuffled().prefix(9))
        return chosen.map { d in MeasureCreature(id: d.id, name: d.name, imageName: d.imageName, icon: d.icon) }
    }

    /// Marine reptiles: stub for future (ichthyosaurs, plesiosaurs, mosasaurs). Returns nil until pool and grouping exist.
    private static func makeRoundMarineReptiles(excluding usedIds: Set<Int>) -> [MeasureCreature]? {
        // TODO: add marine reptile pool and grouping (e.g. by family or type), then one-per-group.
        return nil
    }
}

// MARK: - Main View (pool-agnostic: works with any MeasurePoolKind)
//
// Selection (like Weigh the Dinosaur): one dinosaur per clade chosen randomly → 9 in a 3×3 grid.
// Used dinosaurs are remembered (usedCreatureIds) so no repeat in future rounds.
// Within each round, any of the 9 can be tapped repeatedly to build the right stack (e.g. 3 T-Rex vs one sauropod).
// Stack is capped at 5; if a sixth is chosen we play "you can't be serious" and end the round.

struct MeasureGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: MeasureGameConfig

    @State private var speechManager = SpeechManager()
    @State private var roundsCompleted = 0
    private let maxRounds = 3
    /// Creatures used in any completed round this game; never reuse in a future round.
    @State private var usedCreatureIds: Set<Int> = []
    /// The N creatures for the current round (one per group), displayed in a 3-column grid.
    @State private var currentRoundCreatures: [MeasureCreature] = []
    /// Intro walk: highlight each creature and play name audio before taps are enabled. -1 = not started, 0..<count = current index, count = done.
    @State private var introWalkStep: Int = -1
    private var introWalkComplete: Bool { introWalkStep >= 0 && (currentRoundCreatures.isEmpty || introWalkStep >= currentRoundCreatures.count) }

    /// When true, grid taps are disabled (playing choose-first, choose-second, same-height, or good-job audio).
    @State private var measureTapsBlocked = false
    @State private var selectedFirst: MeasureCreature?
    /// Right side: stack of dinosaurs (tallest at bottom) to match or exceed left; we compare sum of stack heights to left.
    @State private var selectedRightStack: [MeasureCreature] = []

    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    private let gridColumns = 3
    /// Measure comparison slot: 140×340 pt to match game-specific rectangular assets (140×340 px @1x). Fits on screen (2×140 + 70 + spacing).
    private let measureSlotWidth: CGFloat = 140
    private let measureAreaHeight: CGFloat = 340
    private let measureCenterWidth: CGFloat = 70
    private let measureHorizontalPadding: CGFloat = 24
    private let measureSpacing: CGFloat = 2
    /// Max dinosaurs on the right stack; after this we play "you can't be serious" and end the round.
    private let measureRightStackMax = 5
    /// Left dinosaur never drawn smaller than this (pt) so it stays identifiable.
    private let measureMinLeftHeight: CGFloat = 80
    /// Each right-stack segment never smaller than this (pt); too-small choices are grayed out and rejected with audio.
    private let measureMinSegmentHeight: CGFloat = 48
    /// All creatures selected and played this game (left + right stack per round), for victory re-intro.
    @State private var victoryCreatures: [MeasureCreature] = []
    /// Victory sequence: -1 none, 1 = walking list (highlight + name), 2 = success image then good-job + crowd.
    @State private var measureEndSequenceStep: Int = -1
    @State private var measureEndHighlightIndex: Int = 0
    private let victoryRowHeight: CGFloat = 92
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height: geometry.size.height * 0.05)

                if isGameOver {
                    measureVictoryView
                } else {
                    VStack(spacing: 16) {
                        Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if !currentRoundCreatures.isEmpty {
                            // Grid: 3 columns, as many rows as needed (e.g. 9 → 3 rows, 6 → 2 rows)
                            let rows = (currentRoundCreatures.count + gridColumns - 1) / gridColumns
                            VStack(spacing: 12) {
                                ForEach(0..<rows, id: \.self) { row in
                                    HStack(spacing: 12) {
                                        ForEach(0..<gridColumns, id: \.self) { col in
                                            let index = row * gridColumns + col
                                            if index < currentRoundCreatures.count {
                                                creatureCard(currentRoundCreatures[index], index: index)
                                            } else {
                                                Color.clear
                                                    .aspectRatio(1, contentMode: .fit)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.top, 8)

                            // Bottom: left and right comparison (320pt full size; one side scaled when heights differ)
                            measureComparisonArea(geometry: geometry)
                                .padding(.top, 12)
                        } else {
                            Text("Not enough creatures for this round.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .frame(width: geometry.size.width)
                }

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            startRound()
        }
    }

    /// Grid card: always uses shared square image (dino-{slug}). Grayed out when too small to compare with left.
    private func creatureCard(_ creature: MeasureCreature, index: Int) -> some View {
        let isIntroHighlighted = !introWalkComplete && introWalkStep == index
        let tooSmall = selectedFirst != nil && isTooSmallToChoose(creature)
        return Group {
            if let name = creature.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text(creature.icon)
                    .font(.largeTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isIntroHighlighted ? Color.accentColor : Color.clear, lineWidth: 4)
        )
        .opacity(tooSmall ? 0.4 : (isIntroHighlighted ? 1.0 : 0.9))
        .contentShape(Rectangle())
        .onTapGesture {
            handleCreatureTap(creature)
        }
        .allowsHitTesting(introWalkComplete && !measureTapsBlocked && !tooSmall)
    }

    /// Bottom area: left creature | center | right tower (stack tallest-at-bottom). Tight spacing; slot content aligned toward center.
    private func measureComparisonArea(geometry: GeometryProxy) -> some View {
        let leftScale = measureLeftScale()
        return HStack(alignment: .bottom, spacing: measureSpacing) {
            measureSlot(creature: selectedFirst, scale: leftScale, alignTowardCenter: true)
            measureCenterImage
            measureRightTowerView
        }
        .frame(maxWidth: .infinity)
        .frame(height: measureAreaHeight + 20)
    }

    /// Scale for left dinosaur: 1.0 if left >= right stack total; else scaled down, but never below measureMinLeftHeight.
    private func measureLeftScale() -> CGFloat {
        guard let first = selectedFirst, !selectedRightStack.isEmpty else {
            return selectedFirst != nil ? 1.0 : 0
        }
        let hLeft = dinosaurEstimatedHeightMetersById[first.id] ?? 1
        let stackTotalH = selectedRightStack.reduce(0.0) { $0 + (dinosaurEstimatedHeightMetersById[$1.id] ?? 1) }
        let maxH = max(hLeft, stackTotalH)
        if maxH <= 0 { return 1.0 }
        let rawScale: CGFloat = hLeft >= stackTotalH ? 1.0 : CGFloat(hLeft / maxH)
        let minScale = measureMinLeftHeight / measureAreaHeight
        return max(rawScale, minScale)
    }

    /// Center image: paleontologist on ladder holding tape measure. Use asset "measure-paleontologist-ladder" (e.g. 70×340 pt).
    private var measureCenterImage: some View {
        let name = "measure-paleontologist-ladder"
        return Group {
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.5))
            }
        }
        .frame(width: measureCenterWidth, height: measureAreaHeight)
    }

    /// Image for left/right of paleontologist only: prefer measure-dino-{slug} (140×340), else fall back to shared square.
    private static func measureImageName(for creature: MeasureCreature) -> String? {
        let base = creature.imageName ?? creature.name
        let measureName = "measure-\(base)"
        if UIImage(named: measureName) != nil { return measureName }
        if UIImage(named: base) != nil { return base }
        return nil
    }

    /// Left slot only: one creature at full 140×340. alignTowardCenter = true so image sits next to paleontologist (trailing in slot).
    private func measureSlot(creature: MeasureCreature?, scale: CGFloat, alignTowardCenter: Bool) -> some View {
        let s = scale > 0 ? scale : 0.3
        let contentW = measureSlotWidth * s
        let contentH = measureAreaHeight * s
        let alignment: Alignment = alignTowardCenter ? .bottomTrailing : .bottomLeading
        return Group {
            if let c = creature, scale > 0 {
                Group {
                    if let name = Self.measureImageName(for: c) {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Text(c.icon)
                            .font(.system(size: 120))
                    }
                }
                .frame(width: contentW, height: contentH)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: contentW, height: contentH)
            }
        }
        .frame(width: measureSlotWidth, height: measureAreaHeight, alignment: alignment)
    }

    /// Right side: tower scaled by (stack total / left height) with head room; each segment at least measureMinSegmentHeight, then fit in 340pt.
    private var measureRightTowerView: some View {
        let sorted = selectedRightStack.sorted { (dinosaurEstimatedHeightMetersById[$0.id] ?? 0) > (dinosaurEstimatedHeightMetersById[$1.id] ?? 0) }
        let stackTotalH = sorted.reduce(0.0) { $0 + (dinosaurEstimatedHeightMetersById[$1.id] ?? 1) }
        let leftH = selectedFirst.flatMap { dinosaurEstimatedHeightMetersById[$0.id] } ?? 1
        let maxH = max(leftH, stackTotalH)
        let rawTowerHeight: CGFloat = maxH > 0 ? min(measureAreaHeight, measureAreaHeight * CGFloat(stackTotalH / maxH)) : 0
        let rawHeights: [CGFloat] = sorted.map { c in
            let h = dinosaurEstimatedHeightMetersById[c.id] ?? 1
            let portion = stackTotalH > 0 ? (h / stackTotalH) : (1.0 / Double(sorted.count))
            return max(rawTowerHeight * CGFloat(portion), measureMinSegmentHeight)
        }
        let sumRaw = rawHeights.reduce(0, +)
        let scale = sumRaw > measureAreaHeight ? measureAreaHeight / sumRaw : 1.0
        let cellHeights = rawHeights.map { $0 * scale }
        return Group {
            if sorted.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: measureSlotWidth * 0.3, height: measureAreaHeight * 0.3)
            } else {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        ForEach(Array(sorted.reversed().enumerated()), id: \.offset) { revIdx, c in
                            let sortedIdx = sorted.count - 1 - revIdx
                            let alignBottom = (revIdx == 0 || revIdx == sorted.count - 1)
                            measureTowerCell(creature: c, width: measureSlotWidth, height: cellHeights[sortedIdx], alignBottom: alignBottom)
                        }
                    }
                }
                .clipped()
            }
        }
        .frame(width: measureSlotWidth, height: measureAreaHeight, alignment: .bottomLeading)
    }

    /// Each cell: alignBottom = true for the bottom segment only so images stack flush (no gap between segments).
    private func measureTowerCell(creature: MeasureCreature, width: CGFloat, height: CGFloat, alignBottom: Bool = true) -> some View {
        Group {
            if let name = Self.measureImageName(for: creature) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text(creature.icon)
                    .font(.system(size: 60))
            }
        }
        .frame(width: width, height: height, alignment: alignBottom ? .bottom : .top)
    }

    private func handleCreatureTap(_ creature: MeasureCreature) {
        guard introWalkComplete, !measureTapsBlocked else { return }
        if selectedFirst == nil {
            selectedFirst = creature
            speechManager.onAudioFinished = nil
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.onAudioFinished = {
                    self.measureTapsBlocked = false
                    self.speechManager.onAudioFinished = nil
                }
                self.speechManager.speak("game-choose-your-second-dinosaur")
            }
            speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
            return
        }
        if creature.id == selectedFirst?.id {
            if selectedRightStack.isEmpty {
                measureTapsBlocked = true
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.advanceRound()
                }
                speechManager.speak("they-are-about-the-same-height")
            } else {
                measureTapsBlocked = true
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.measureTapsBlocked = false
                }
                speechManager.speak("you-cannot-choose-that-one-now")
            }
            return
        }
        if selectedRightStack.count >= measureRightStackMax {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.advanceRound()
            }
            speechManager.speak("you-cant-be-serious-that-will-take-forever")
            return
        }
        if wouldSegmentBeTooSmall(creature) {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.measureTapsBlocked = false
            }
            speechManager.speak("thats-too-small-to-see")
            return
        }
        selectedRightStack.append(creature)
        compareHeightsAndContinue()
    }

    /// True if adding this creature to the right stack would give it a segment height < measureMinSegmentHeight.
    private func wouldSegmentBeTooSmall(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = dinosaurEstimatedHeightMetersById[first.id] ?? 1
        let creatureH = dinosaurEstimatedHeightMetersById[creature.id] ?? 1
        let newStackTotal = selectedRightStack.reduce(0.0) { $0 + (dinosaurEstimatedHeightMetersById[$1.id] ?? 1) } + creatureH
        let towerH = leftH > 0 ? min(measureAreaHeight, measureAreaHeight * CGFloat(newStackTotal / leftH)) : measureAreaHeight
        let segmentH = newStackTotal > 0 ? towerH * CGFloat(creatureH / newStackTotal) : 0
        return segmentH < measureMinSegmentHeight
    }

    /// True when first is chosen and this creature would be too small to display (gray out in grid).
    private func isTooSmallToChoose(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = dinosaurEstimatedHeightMetersById[first.id] ?? 1
        let creatureH = dinosaurEstimatedHeightMetersById[creature.id] ?? 1
        if leftH <= 0 { return false }
        let segmentIfAlone = measureAreaHeight * CGFloat(creatureH / leftH)
        return segmentIfAlone < measureMinSegmentHeight
    }

    /// Compare sum of right-stack heights to left dinosaur: if about same → advance round; else play good-job, keep stack, allow another pick.
    private func compareHeightsAndContinue() {
        guard let first = selectedFirst else { return }
        let hLeft = dinosaurEstimatedHeightMetersById[first.id] ?? 1
        let stackSum = selectedRightStack.reduce(0.0) { $0 + (dinosaurEstimatedHeightMetersById[$1.id] ?? 1) }
        let maxH = max(hLeft, stackSum)
        let relDiff = maxH > 0 ? abs(hLeft - stackSum) / maxH : 0
        if relDiff <= sameHeightRelativeThreshold {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.advanceRound()
            }
            speechManager.speak("they-are-about-the-same-height")
        } else {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.measureTapsBlocked = false
            }
            speechManager.speak("game-balance-good-job-keep-going")
        }
    }

    private func startRound() {
        let next = MeasureGameConfigs.makeRoundCreatures(poolKind: gameConfig.poolKind, excluding: usedCreatureIds)
        currentRoundCreatures = next ?? []
        introWalkStep = -1
        if !currentRoundCreatures.isEmpty {
            startIntroWalk()
        }
    }

    private func startIntroWalk() {
        introWalkStep = 0
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.speakCurrentIntroCreatureAndAdvance()
        }
        speechManager.speak(gameConfig.introAudio)
    }

    /// Speaks creature at introWalkStep, then when finished increments and speaks next (or starts measure flow).
    private func speakCurrentIntroCreatureAndAdvance() {
        guard introWalkStep < currentRoundCreatures.count else { return }
        let creature = currentRoundCreatures[introWalkStep]
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.introWalkStep += 1
            if self.introWalkStep >= self.currentRoundCreatures.count {
                self.startChooseFirstDinosaur()
                return
            }
            self.speakCurrentIntroCreatureAndAdvance()
        }
        speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
    }

    /// Block taps, play "choose your first dinosaur", then unblock so user can tap.
    private func startChooseFirstDinosaur() {
        measureTapsBlocked = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.measureTapsBlocked = false
        }
        speechManager.speak("game-choose-your-first-dinosaur")
    }

    private func advanceRound() {
        if let first = selectedFirst {
            victoryCreatures.append(first)
            for c in selectedRightStack {
                victoryCreatures.append(c)
            }
        }
        selectedFirst = nil
        selectedRightStack = []
        usedCreatureIds.formUnion(currentRoundCreatures.map(\.id))
        roundsCompleted += 1
        if roundsCompleted < maxRounds {
            startRound()
        }
    }

    /// Victory: top half = scrolling list of all dinosaurs played (highlight + name audio); bottom half = success image, then good-job + crowd and dismiss.
    private var measureVictoryView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(victoryCreatures.enumerated()), id: \.offset) { index, creature in
                                let isHighlighted = measureEndSequenceStep >= 1 && index == measureEndHighlightIndex
                                HStack(spacing: 16) {
                                    measureVictoryRowImage(creature: creature, isHighlighted: isHighlighted)
                                    Text(creature.name)
                                        .font(.title2)
                                        .fontWeight(isHighlighted ? .semibold : .regular)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .opacity(isHighlighted ? 1.0 : 0.5)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(height: victoryRowHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .id(index)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    .frame(height: victoryListVisibleHeight)
                    .onChange(of: measureEndHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Group {
                    if measureEndSequenceStep == 2 {
                        measureSuccessImageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    playMeasureGoodJobAndCrowdThenDismiss()
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
            guard measureEndSequenceStep == -1 else { return }
            measureEndSequenceStep = 1
            measureEndHighlightIndex = 0
            if victoryCreatures.isEmpty {
                measureEndSequenceStep = 2
            } else {
                let c = victoryCreatures[0]
                speechManager.speak(audioKey: c.imageName ?? c.name, fallbackText: c.name)
                speechManager.onAudioFinished = { advanceMeasureEndHighlight() }
            }
        }
    }

    private func measureVictoryRowImage(creature: MeasureCreature, isHighlighted: Bool) -> some View {
        Group {
            if let name = creature.imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(isHighlighted ? 1.0 : 0.4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                Text(creature.icon)
                    .font(.system(size: 40))
                    .frame(width: 72, height: 72)
                    .opacity(isHighlighted ? 1.0 : 0.4)
            }
        }
    }

    private func advanceMeasureEndHighlight() {
        speechManager.onAudioFinished = nil
        measureEndHighlightIndex += 1
        if measureEndHighlightIndex < victoryCreatures.count {
            let c = victoryCreatures[measureEndHighlightIndex]
            speechManager.speak(audioKey: c.imageName ?? c.name, fallbackText: c.name)
            speechManager.onAudioFinished = { advanceMeasureEndHighlight() }
        } else {
            measureEndSequenceStep = 2
        }
    }

    private var measureSuccessImageView: some View {
        Group {
            if UIImage(named: "game-measure-the-dinosaur-success") != nil {
                Image("game-measure-the-dinosaur-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if UIImage(named: "game-measure-the-dinosaur") != nil {
                Image("game-measure-the-dinosaur")
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

    private func playMeasureGoodJobAndCrowdThenDismiss() {
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

#Preview {
    MeasureGameView(isPresented: .constant(true), gameConfig: MeasureGameConfigs.measureDinosaur)
}
