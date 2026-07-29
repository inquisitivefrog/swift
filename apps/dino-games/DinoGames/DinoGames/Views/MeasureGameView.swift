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

// MARK: - Dinosaur height (for measure comparison; shared with Which Dino Is Taller via `LandDinosaurHeightCatalog`)

// Threshold for "about the same height": relative difference < this value. Tight (8%) so e.g. 2×Edmontonia (14m) does not match Brontosaurus (20m).
private let sameHeightRelativeThreshold = 0.08

// Size buckets for scale teaching: small ≤1.5m, medium 1.5–6m, large 6–12m, huge >12m.
// If left is not huge, adding huge → "you can't be serious" (wrong scale).
private let measureSizeBucketHugeThreshold: Double = 12

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
            guard let slots = makeRoundSlotsForDinosaurs(excluding: usedIds) else { return nil }
            return slots.map { $0.creature }
        case .pterosaurs:
            return makeRoundPterosaurs(excluding: usedIds)
        case .marineReptiles:
            return makeRoundMarineReptiles(excluding: usedIds)
        }
    }

    /// Grid slots: one per clade, clade tracked for replacement. Shuffled for random grid order.
    /// When `preferringSmallEnough` is set, ensure at least one clade contributes a creature with height <= that value (guarantees addable option).
    static func makeRoundSlotsForDinosaurs(excluding usedIds: Set<Int>, preferringSmallEnough remainingHeight: Double? = nil) -> [(clade: DinoClade, creature: MeasureCreature)]? {
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-"),
                  !usedIds.contains(d.id) else { return false }
            let measureName = "measure-\(imageName)"
            return ImageAssetCache.imageExists(named: measureName)
        }
        let byClade = Dictionary(grouping: pool) { cladeById[$0.id] ?? .theropod }
        let clades = DinoClade.allCases
        var lastSlots: [(DinoClade, MeasureCreature)] = []
        for _ in 0..<30 {
            var chosen: [Dinosaur] = []
            var slotClades: [DinoClade] = []
            let cladesWithSmall: [DinoClade]
            if let maxH = remainingHeight, maxH > 0 {
                cladesWithSmall = clades.filter { clade in
                    (byClade[clade] ?? []).contains { (LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 0) <= maxH }
                }
            } else {
                cladesWithSmall = []
            }
            let forceOneSmall = !cladesWithSmall.isEmpty ? cladesWithSmall.randomElement()! : nil
            for clade in clades {
                guard let candidates = byClade[clade], !candidates.isEmpty else { return nil }
                let d: Dinosaur
                if clade == forceOneSmall, let maxH = remainingHeight, maxH > 0 {
                    let smallEnough = candidates.filter { (LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 0) <= maxH }
                    d = smallEnough.randomElement()!
                } else if let maxH = remainingHeight, maxH > 0 {
                    let smallEnough = candidates.filter { (LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 0) <= maxH }
                    d = (smallEnough.isEmpty ? candidates : smallEnough).randomElement()!
                } else {
                    d = candidates.randomElement()!
                }
                chosen.append(d)
                slotClades.append(clade)
            }
            if isRoundWinnable(chosen) {
                let slots = zip(slotClades, chosen).map { (clade, d) in
                    (clade, MeasureCreature(id: d.id, name: d.name, imageName: d.imageName, icon: d.icon))
                }
                return slots.shuffled()
            }
            lastSlots = zip(slotClades, chosen).map { (clade, d) in
                (clade, MeasureCreature(id: d.id, name: d.name, imageName: d.imageName, icon: d.icon))
            }
        }
        return lastSlots.isEmpty ? nil : lastSlots.shuffled()
    }

    /// Replacement creature from clade, excluding current grid ids. Nil if none available.
    /// When `preferringSmallEnough` is set, prefer creatures with height <= that value (e.g. when left reference is small).
    static func replacementMeasureCreature(clade: DinoClade, excluding gridCreatureIds: Set<Int>, preferringSmallEnough maxHeight: Double? = nil) -> MeasureCreature? {
        let cladeById = LandDinosaurCladeCatalog.cladeByCreatureId
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-"),
                  !gridCreatureIds.contains(d.id) else { return false }
            let measureName = "measure-\(imageName)"
            return ImageAssetCache.imageExists(named: measureName)
        }
        let candidates = pool.filter { (cladeById[$0.id] ?? .theropod) == clade }
        guard let d: Dinosaur = {
            if let maxH = maxHeight, maxH > 0 {
                let smallEnough = candidates.filter { (LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 0) <= maxH }
                return (smallEnough.isEmpty ? candidates : smallEnough).randomElement()
            }
            return candidates.randomElement()
        }() else { return nil }
        return MeasureCreature(id: d.id, name: d.name, imageName: d.imageName, icon: d.icon)
    }

    /// True if at least one creature in the round can be matched: some subset (1–5) of the others sums to within 8% of its height.
    private static func isRoundWinnable(_ creatures: [Dinosaur]) -> Bool {
        let heights = creatures.map { (id: $0.id, h: LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 1) }
        for (refIdx, ref) in heights.enumerated() {
            let others = heights.enumerated().filter { $0.offset != refIdx }.map { $0.element }
            if canMatch(target: ref.h, from: others.map(\.h), threshold: sameHeightRelativeThreshold) {
                return true
            }
        }
        return false
    }

    /// True if some subset of `heights` (size 1–5) sums to within `threshold` of `target`.
    private static func canMatch(target: Double, from heights: [Double], threshold: Double) -> Bool {
        let maxCount = min(5, heights.count)
        for count in 1...maxCount {
            for combo in combinations(heights, count: count) {
                let sum = combo.reduce(0, +)
                let maxH = max(target, sum)
                if maxH > 0, abs(target - sum) / maxH <= threshold {
                    return true
                }
            }
        }
        return false
    }

    private static func combinations<T>(_ arr: [T], count: Int) -> [[T]] {
        guard count <= arr.count, count > 0 else { return [] }
        if count == 1 { return arr.map { [$0] } }
        var result: [[T]] = []
        for (i, x) in arr.enumerated() {
            let rest = Array(arr[(i + 1)...])
            for sub in combinations(rest, count: count - 1) {
                result.append([x] + sub)
            }
        }
        return result
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
    /// Grid slots: one per clade (dinosaurs) or creature-only (pterosaurs). Clade tracked for replacement when creature is used.
    @State private var measureGridSlots: [(clade: DinoClade?, creature: MeasureCreature)] = []
    /// Intro walk: highlight each creature and play name audio before taps are enabled. -1 = not started, 0..<count = current index, count = done.
    @State private var introWalkStep: Int = -1
    private var introWalkComplete: Bool { introWalkStep >= 0 && (measureGridSlots.isEmpty || introWalkStep >= measureGridSlots.count) }

    /// When true, grid taps are disabled (playing choose-first, choose-second, same-height, or good-job audio).
    @State private var measureTapsBlocked = false
    @State private var selectedFirst: MeasureCreature?
    /// Right side: stack of dinosaurs (tallest at bottom) to match or exceed left; we compare sum of stack heights to left.
    @State private var selectedRightStack: [MeasureCreature] = []

    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    private let gridColumns = 3
    /// Measure comparison slot: 140×340 pt to match game-specific rectangular assets (140×340 px @1x; some up to 200 wide).
    private let measureSlotWidth: CGFloat = 140
    private let measureAreaHeight: CGFloat = 340
    /// Paleontologist (tape pose): increased from 70 to 110 pt width so it displays larger (room for 2×140 slots + center).
    private let measureCenterWidth: CGFloat = 110
    private let measureHorizontalPadding: CGFloat = 24
    /// Minimal spacing so dinosaurs almost touch the paleontologist (match Who Is Taller).
    private let measureSpacing: CGFloat = 0
    /// Max dinosaurs on the right stack; after this we play "you can't be serious" and end the round.
    private let measureRightStackMax = 6
    /// Left dinosaur never drawn smaller than this (pt) so it stays identifiable.
    private let measureMinLeftHeight: CGFloat = 80
    /// Each right-stack segment never smaller than this (pt); too-small choices are grayed out and rejected with audio.
    /// Display floor is 48pt; rejection uses 32pt so small dinosaurs (e.g. Pedopenna 0.2m with Dryosaurus 2m) are allowed.
    private let measureMinSegmentHeight: CGFloat = 48
    private let measureMinSegmentHeightForRejection: CGFloat = 32
    private let playMaxScale: CGFloat = 1.75
    /// All creatures selected and played this game (left + right stack per round), for victory re-intro.
    @State private var victoryCreatures: [MeasureCreature] = []
    /// Victory sequence: -1 none, 1 = walking list (highlight + name), 2 = success image then good-job + crowd.
    @State private var measureEndSequenceStep: Int = -1
    @State private var measureEndHighlightIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let safeHeight = max(geometry.size.height, 1)
            let safeWidth = max(geometry.size.width, 1)
            let measureStageH = GameCatalogImageMetrics.scaled(340, safeWidth: safeWidth, maxScale: playMaxScale) + 20 + 8
            let grid = CreatureThreeByThreeGridMetrics.make(
                safeWidth: safeWidth,
                safeHeight: safeHeight,
                reservedStageHeight: measureStageH,
                chrome: 32
            )
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    if isGameOver {
                        measureVictoryView
                    } else {
                        VStack(spacing: 6) {
                            VStack(spacing: 4) {
                                Text(gameConfig.title)
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                Text("Round \(roundsCompleted + 1) of \(maxRounds)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: grid.titleBlockHeight)
                            .frame(maxWidth: grid.contentWidth)
                            .frame(maxWidth: .infinity)

                            if !measureGridSlots.isEmpty {
                                let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
                                LazyVGrid(columns: columns, spacing: 6) {
                                    ForEach(0..<measureGridSlots.count, id: \.self) { index in
                                        let slot = measureGridSlots[index]
                                        let creature = slot.creature
                                        MeasureCreatureCard(
                                            creature: creature,
                                            displayImageName: creature.imageName,
                                            isLeftReference: selectedFirst?.id == creature.id,
                                            isInStack: selectedRightStack.contains(where: { $0.id == creature.id }),
                                            isDisabled: !introWalkComplete || measureTapsBlocked,
                                            isTooSmallToSee: isTooSmallToChoose(creature),
                                            isBlockedAsFirstChoice: selectedFirst == nil && isSmallestInGrid(creature),
                                            isBlockedAsHugeWhenLeftNotHuge: wouldBeHugeWhenLeftIsNot(creature),
                                            isBlockedAsExceedsReferenceAlone: wouldExceedReferenceAlone(creature),
                                            isIntroHighlighted: !introWalkComplete && introWalkStep == index,
                                            imageSize: grid.imageSize, labelFontSize: grid.labelFontSize
                                        ) {
                                            handleCreatureTap(index: index, creature: creature)
                                        }
                                                                            }
                                }
                                .padding(.horizontal, 10)
                                .frame(maxWidth: grid.contentWidth)
                                .frame(maxWidth: .infinity)

                                // Bottom: left and right comparison (match Who Is Taller layout)
                                measureComparisonArea(safeWidth: safeWidth)
                                    .padding(.top, 8)
                                    .padding(.horizontal, 24)
                            } else {
                                Text("Not enough creatures for this round.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                        .frame(height: grid.blockHeight)
                        .frame(width: safeWidth)
                    }

                    Spacer(minLength: 8)
                }
            }
            .frame(minHeight: safeHeight)
        }
        .onAppear {
            startRound()
        }
    }

    /// Bottom area: left creature | center | right tower (stack tallest-at-bottom). Tight spacing; slot content aligned toward center.
    private func measureComparisonArea(safeWidth: CGFloat) -> some View {
        let slotW = GameCatalogImageMetrics.scaled(measureSlotWidth, safeWidth: safeWidth, maxScale: playMaxScale)
        let areaH = GameCatalogImageMetrics.scaled(measureAreaHeight, safeWidth: safeWidth, maxScale: playMaxScale)
        let centerW = GameCatalogImageMetrics.scaled(measureCenterWidth, safeWidth: safeWidth, maxScale: playMaxScale)
        let minSegH = GameCatalogImageMetrics.scaled(measureMinSegmentHeight, safeWidth: safeWidth, maxScale: playMaxScale)
        let leftScale = measureLeftScale(areaHeight: areaH)
        return HStack(alignment: .bottom, spacing: measureSpacing) {
            measureSlot(creature: selectedFirst, scale: leftScale, alignTowardCenter: true, slotWidth: slotW, areaHeight: areaH)
            measureCenterImage(centerWidth: centerW, areaHeight: areaH)
            measureRightTowerView(slotWidth: slotW, areaHeight: areaH, minSegmentHeight: minSegH)
        }
        .frame(maxWidth: .infinity)
        .frame(height: areaH + 20)
    }

    /// Scale for left dinosaur: 1.0 if left >= right stack total; else scaled down, but never below measureMinLeftHeight.
    private func measureLeftScale(areaHeight: CGFloat) -> CGFloat {
        guard let first = selectedFirst, !selectedRightStack.isEmpty else {
            return selectedFirst != nil ? 1.0 : 0
        }
        let hLeft = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let stackTotalH = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        let maxH = max(hLeft, stackTotalH)
        if maxH <= 0 { return 1.0 }
        let rawScale: CGFloat = hLeft >= stackTotalH ? 1.0 : CGFloat(hLeft / maxH)
        let minLeftH = areaHeight * (measureMinLeftHeight / measureAreaHeight)
        let minScale = minLeftH / areaHeight
        return max(rawScale, minScale)
    }

    /// Center image: paleontologist on ladder with tape measure (`measure-dino-paleontologist-ladder`, 110×340 pt display).
    /// Bottom-aligned so it lines up with left/right dinosaurs for height comparison.
    private func measureCenterImage(centerWidth: CGFloat, areaHeight: CGFloat) -> some View {
        let name = "measure-dino-paleontologist-ladder"
        return Group {
            if ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.5))
            }
        }
        .frame(width: centerWidth, height: areaHeight, alignment: .bottom)
    }

    /// Image for left/right of paleontologist only: prefer measure-dino-{slug} (140×340), else fall back to shared square.
    private static func measureImageName(for creature: MeasureCreature) -> String? {
        let base = creature.imageName ?? creature.name
        let measureName = "measure-\(base)"
        if ImageAssetCache.imageExists(named: measureName) { return measureName }
        if ImageAssetCache.imageExists(named: base) { return base }
        return nil
    }

    /// Left slot only: one creature at full 140×340. alignTowardCenter = true so image sits next to paleontologist (trailing in slot).
    private func measureSlot(creature: MeasureCreature?, scale: CGFloat, alignTowardCenter: Bool, slotWidth: CGFloat, areaHeight: CGFloat) -> some View {
        let s = scale > 0 ? scale : 0.3
        let contentW = slotWidth * s
        let contentH = areaHeight * s
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
                .frame(width: contentW, height: contentH, alignment: .bottom)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: contentW, height: contentH)
            }
        }
        .frame(width: slotWidth, height: areaHeight, alignment: alignment)
    }

    /// Right side: tower scaled by (stack total / left height) with head room; each segment at least measureMinSegmentHeight, then fit in area.
    /// When left >= stack, right tower is scaled down by 8% so the left reference is always visually dominant (avoids image aspect-ratio mismatch).
    private func measureRightTowerView(slotWidth: CGFloat, areaHeight: CGFloat, minSegmentHeight: CGFloat) -> some View {
        let sorted = selectedRightStack.sorted { (LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] ?? 0) > (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 0) }
        let stackTotalH = sorted.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        let leftH = selectedFirst.flatMap { LandDinosaurHeightCatalog.standingHeightMetersById[$0.id] } ?? 1
        let maxH = max(leftH, stackTotalH)
        let proportional: CGFloat = maxH > 0 ? CGFloat(stackTotalH / maxH) : 0
        let buffer: CGFloat = leftH >= stackTotalH ? 0.92 : 1.0  // right 8% smaller when left is reference
        let rawTowerHeight: CGFloat = min(areaHeight, areaHeight * proportional * buffer)
        let rawHeights: [CGFloat] = sorted.map { c in
            let h = LandDinosaurHeightCatalog.standingHeightMetersById[c.id] ?? 1
            let portion = stackTotalH > 0 ? (h / stackTotalH) : (1.0 / Double(sorted.count))
            return max(rawTowerHeight * CGFloat(portion), minSegmentHeight)
        }
        let sumRaw = rawHeights.reduce(0, +)
        let scale = sumRaw > areaHeight ? areaHeight / sumRaw : 1.0
        let cellHeights = rawHeights.map { $0 * scale }
        return Group {
            if sorted.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: slotWidth * 0.3, height: areaHeight * 0.3)
            } else {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        ForEach(Array(sorted.reversed().enumerated()), id: \.offset) { revIdx, c in
                            let sortedIdx = sorted.count - 1 - revIdx
                            // Bottom segment (touching ground) = last in VStack = revIdx == count-1; use .bottom so feet align
                            let alignBottom = (revIdx == sorted.count - 1)
                            measureTowerCell(creature: c, width: slotWidth, height: cellHeights[sortedIdx], alignBottom: alignBottom)
                        }
                    }
                }
                .clipped()
            }
        }
        .frame(width: slotWidth, height: areaHeight, alignment: .bottomLeading)
    }

    /// Each cell: alignBottom = true for the bottom segment only so images stack flush (no gap between segments).
    /// Tower cell: bottom segment uses .bottomLeading so feet touch ground and image sits next to paleontologist; upper segments use .topLeading.
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
        .frame(width: width, height: height, alignment: alignBottom ? .bottomLeading : .topLeading)
    }

    private func handleCreatureTap(index: Int, creature: MeasureCreature) {
        guard introWalkComplete, !measureTapsBlocked else { return }
        if selectedFirst == nil {
            if isSmallestInGrid(creature) {
                measureTapsBlocked = true
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.measureTapsBlocked = false
                }
                speechManager.speak("pick-another-one")
                return
            }
            selectedFirst = creature
            let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
            replaceGridSlotAfterUse(index: index, preferringSmallEnough: leftH)
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
            if selectedRightStack.isEmpty, let first = selectedFirst {
                // Same dinosaur tapped twice with empty stack: "X is as tall as X"
                let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
                replaceGridSlotAfterUse(index: index, preferringSmallEnough: leftH)
                measureTapsBlocked = true
                playMeasureSameHeightSequence(left: first, stack: [creature]) {
                    self.speechManager.onAudioFinished = nil
                    self.advanceRound()
                }
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
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(ComparisonGameLogic.thatsTooSmallToSee)
            return
        }
        if wouldBeHugeWhenLeftIsNot(creature) {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(audioKey: "game-measure-you-cant-be-serious", fallbackText: "You can't be serious.")
            return
        }
        if wouldRequireTooMany(creature) {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(audioKey: "game-measure-you-cant-be-serious", fallbackText: "You can't be serious.")
            return
        }
        if wouldExceedReferenceAlone(creature) {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(audioKey: "game-measure-you-cant-be-serious", fallbackText: "You can't be serious.")
            return
        }
        if wouldOvershoot(creature) {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(audioKey: "game-measure-that-dinosaur-is-too-tall", fallbackText: "That dinosaur is too tall.")
            return
        }
        selectedRightStack.append(creature)
        refreshGridWithSmallEnoughOptions()
        // Announce the creature just added before comparison feedback (e.g. good-job-keep-going)
        measureTapsBlocked = true
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.compareHeightsAndContinue()
        }
        speechManager.speak(audioKey: creature.imageName ?? creature.name, fallbackText: creature.name)
    }

    /// True if adding this creature to the right stack would give it a segment height < measureMinSegmentHeightForRejection.
    /// Uses a lower threshold than display floor so small dinosaurs (e.g. Pedopenna with Dryosaurus) are allowed.
    private func wouldSegmentBeTooSmall(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        let newStackTotal = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) } + creatureH
        let towerH = leftH > 0 ? min(measureAreaHeight, measureAreaHeight * CGFloat(newStackTotal / leftH)) : measureAreaHeight
        let segmentH = newStackTotal > 0 ? towerH * CGFloat(creatureH / newStackTotal) : 0
        return segmentH < measureMinSegmentHeightForRejection
    }

    /// True if left reference is not huge and creature is huge. Wrong scale → "you can't be serious."
    private func wouldBeHugeWhenLeftIsNot(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        let leftIsHuge = leftH > measureSizeBucketHugeThreshold
        let creatureIsHuge = creatureH > measureSizeBucketHugeThreshold
        return !leftIsHuge && creatureIsHuge
    }

    /// True if this creature is so small that remainingHeight / creatureH > 5 (would need >5 of that species). Reject with "you can't be serious."
    /// Only applies when stack already has dinosaurs—allow the first add so e.g. Dryosaurus can start a Camarasaurus stack.
    private let measureRatioCap = 5.0

    private func wouldRequireTooMany(_ creature: MeasureCreature) -> Bool {
        guard !selectedRightStack.isEmpty else { return false }  // Allow first add; one-per-dinosaur prevents endless stacking
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        guard creatureH > 0 else { return true }
        let currentSum = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        let remainingHeight = leftH - currentSum
        guard remainingHeight > 0 else { return false }
        return remainingHeight / creatureH > measureRatioCap
    }

    /// True if this creature alone is bigger than the entire left reference. Absurd choice → "you can't be serious" (not "too tall").
    private func wouldExceedReferenceAlone(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        return creatureH > leftH
    }

    /// True if adding this creature would make the right stack taller than the left reference (overshoot). Reject before adding so the user can try smaller dinosaurs.
    private func wouldOvershoot(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        let currentSum = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        return currentSum + creatureH > leftH
    }

    /// When a creature is used (reference or added to stack), replace its grid slot with another from the same clade.
    /// Call only after the creature has been captured in selectedFirst or selectedRightStack so the victory sequence has the reference.
    /// When `preferringSmallEnough` is set (e.g. left reference height), prefer a replacement that fits remaining stack building.
    private func replaceGridSlotAfterUse(index: Int, preferringSmallEnough maxHeight: Double? = nil) {
        guard index >= 0, index < measureGridSlots.count else { return }
        guard let clade = measureGridSlots[index].clade else { return }  // Pterosaurs: no replacement
        let gridIds = Set(measureGridSlots.map { $0.creature.id })
        guard let replacement = MeasureGameConfigs.replacementMeasureCreature(clade: clade, excluding: gridIds, preferringSmallEnough: maxHeight) else { return }
        measureGridSlots[index] = (clade, replacement)
    }

    /// Refresh the entire grid after the second dinosaur is selected (and each turn after) so some choices are small enough to add to the stack.
    private func refreshGridWithSmallEnoughOptions() {
        guard gameConfig.poolKind == .dinosaurs,
              let first = selectedFirst else { return }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let stackSum = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        let remainingHeight = leftH - stackSum
        guard remainingHeight > 0 else { return }
        var excludeIds = usedCreatureIds
        excludeIds.insert(first.id)
        for c in selectedRightStack { excludeIds.insert(c.id) }
        guard let slots = MeasureGameConfigs.makeRoundSlotsForDinosaurs(excluding: excludeIds, preferringSmallEnough: remainingHeight) else { return }
        measureGridSlots = slots.map { (clade: Optional($0.clade), creature: $0.creature) }
    }

    /// True if any creature in the grid can be added to the stack (not too tall, not too small, not wrong scale).
    private func hasAnyValidChoice() -> Bool {
        measureGridSlots.contains { slot in
            let c = slot.creature
            return !wouldOvershoot(c) && !wouldSegmentBeTooSmall(c) && !wouldBeHugeWhenLeftIsNot(c) && !wouldRequireTooMany(c) && !wouldExceedReferenceAlone(c)
        }
    }

    /// Failsafe: no valid choices left — "Close enough for government work!" first, then the comparison.
    private func playCloseEnoughFailsafe() {
        guard let first = selectedFirst else { return }
        measureTapsBlocked = true
        speechManager.onAudioFinished = nil
        speechManager.speak(audioKey: "game-measure-close-enough-for-government-work", fallbackText: "Close enough for government work!")
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.playMeasureSameHeightSequence(left: first, stack: self.selectedRightStack) {
                self.speechManager.onAudioFinished = nil
                self.advanceRound()
            }
        }
    }

    /// True when selecting first and this creature is the smallest in the grid (block to avoid nowhere-to-go).
    /// Only blocks when at least 2 distinct heights exist so the user has a valid choice.
    private func isSmallestInGrid(_ creature: MeasureCreature) -> Bool {
        let heights = measureGridSlots.map { LandDinosaurHeightCatalog.standingHeightMetersById[$0.creature.id] ?? 0 }
        guard heights.count >= 2 else { return false }
        let minH = heights.min() ?? 0
        let maxH = heights.max() ?? 0
        guard minH < maxH else { return false }  // All same size: don't block
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 0
        return creatureH <= minH
    }

    /// True when first is chosen and this creature would be too small to display (gray out in grid).
    private func isTooSmallToChoose(_ creature: MeasureCreature) -> Bool {
        guard let first = selectedFirst else { return false }
        let leftH = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let creatureH = LandDinosaurHeightCatalog.standingHeightMetersById[creature.id] ?? 1
        if leftH <= 0 { return false }
        let segmentIfAlone = measureAreaHeight * CGFloat(creatureH / leftH)
        return segmentIfAlone < measureMinSegmentHeightForRejection
    }

    /// Plays "X is as tall as [stack]": left dino name → is-as-tall-as → stack (grouped by creature, count before name when > 1, "and" between groups).
    private func playMeasureSameHeightSequence(left: MeasureCreature, stack: [MeasureCreature], onComplete: @escaping () -> Void) {
        enum SeqItem {
            case dino(key: String, fallback: String)
            case phrase(String)
        }
        var sequence: [SeqItem] = []
        sequence.append(.dino(key: left.imageName ?? left.name, fallback: left.name))
        sequence.append(.phrase("is-as-tall-as"))

        var seen = Set<Int>()
        var groups: [(creature: MeasureCreature, count: Int)] = []
        for c in stack {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                let count = stack.filter { $0.id == c.id }.count
                groups.append((c, count))
            }
        }
        for (i, (c, count)) in groups.enumerated() {
            if i > 0 { sequence.append(.phrase("and")) }
            if count > 1 { sequence.append(.phrase("\(count)")) }
            sequence.append(.dino(key: c.imageName ?? c.name, fallback: c.name))
        }

        var index = 0
        func playNext() {
            guard index < sequence.count else {
                onComplete()
                return
            }
            let item = sequence[index]
            index += 1
            speechManager.onAudioFinished = { playNext() }
            switch item {
            case .dino(let key, let fallback):
                speechManager.speak(audioKey: key, fallbackText: fallback)
            case .phrase(let text):
                speechManager.speak(text)
            }
        }
        playNext()
    }

    /// Compare sum of right-stack heights to left dinosaur: if about same → advance round; if right > left (overshot) → advance round (can't recover); else play good-job, keep stack, allow another pick.
    private func compareHeightsAndContinue() {
        guard let first = selectedFirst else { return }
        // Failsafe: if no creature in the grid can be added (all too tall or too small), end round gracefully.
        if !hasAnyValidChoice() {
            playCloseEnoughFailsafe()
            return
        }
        let hLeft = LandDinosaurHeightCatalog.standingHeightMetersById[first.id] ?? 1
        let stackSum = selectedRightStack.reduce(0.0) { $0 + (LandDinosaurHeightCatalog.standingHeightMetersById[$1.id] ?? 1) }
        let maxH = max(hLeft, stackSum)
        let relDiff = maxH > 0 ? abs(hLeft - stackSum) / maxH : 0
        if relDiff <= sameHeightRelativeThreshold {
            measureTapsBlocked = true
            playMeasureSameHeightSequence(left: first, stack: selectedRightStack) {
                self.speechManager.onAudioFinished = nil
                self.advanceRound()
            }
        } else if stackSum > hLeft {
            // Overshot: remove the last dinosaur so the player can try a smaller one instead of ending the round.
            guard !selectedRightStack.isEmpty else {
                measureTapsBlocked = true
                speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    self.advanceRound()
                }
                speechManager.speak("game-measure-stack-too-tall")
                return
            }
            _ = selectedRightStack.removeLast()
            refreshGridWithSmallEnoughOptions()
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak(audioKey: "game-measure-that-dinosaur-is-too-tall", fallbackText: "That dinosaur is too tall. Try a smaller one.")
        } else {
            measureTapsBlocked = true
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                if !self.hasAnyValidChoice() {
                    self.playCloseEnoughFailsafe()
                } else {
                    self.measureTapsBlocked = false
                }
            }
            speechManager.speak("game-measure-good-job-keep-going")
        }
    }

    private func startRound() {
        switch gameConfig.poolKind {
        case .dinosaurs:
            var slots = MeasureGameConfigs.makeRoundSlotsForDinosaurs(excluding: usedCreatureIds)?.map { (clade: Optional($0.clade), creature: $0.creature) }
            if slots == nil || slots!.isEmpty {
                slots = MeasureGameConfigs.makeRoundSlotsForDinosaurs(excluding: [])?.map { (clade: Optional($0.clade), creature: $0.creature) }
            }
            measureGridSlots = slots ?? []
        case .pterosaurs:
            let creatures = MeasureGameConfigs.makeRoundCreatures(poolKind: .pterosaurs, excluding: usedCreatureIds) ?? []
            measureGridSlots = creatures.map { (clade: nil as DinoClade?, creature: $0) }
        case .marineReptiles:
            measureGridSlots = []
        }
        introWalkStep = -1
        if !measureGridSlots.isEmpty {
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
        guard introWalkStep < measureGridSlots.count else { return }
        let creature = measureGridSlots[introWalkStep].creature
        speechManager.onAudioFinished = {
            self.speechManager.onAudioFinished = nil
            self.introWalkStep += 1
            if self.introWalkStep >= self.measureGridSlots.count {
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
        // Preserve used creatures for victory sequence before clearing; grid replacement already happened at tap time.
        if let first = selectedFirst {
            if !victoryCreatures.contains(where: { $0.id == first.id }) {
                victoryCreatures.append(first)
            }
            for c in selectedRightStack {
                if !victoryCreatures.contains(where: { $0.id == c.id }) {
                    victoryCreatures.append(c)
                }
            }
        }
        let idsUsedThisRound = [selectedFirst?.id].compactMap { $0 } + selectedRightStack.map(\.id)
        usedCreatureIds.formUnion(idsUsedThisRound)
        selectedFirst = nil
        selectedRightStack = []
        roundsCompleted += 1
        if roundsCompleted < maxRounds {
            startRound()
        }
    }

    /// Victory: top half = scrolling list of all dinosaurs played (highlight + name audio); bottom half = success image, then good-job + crowd and dismiss.
    private var measureVictoryView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text(gameConfig.title)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
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
                                .frame(height: StandardVictoryLayout.rowHeight)
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
                    .frame(height: StandardVictoryLayout.recapListScrollHeight(itemCount: victoryCreatures.count))
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
            if let name = creature.imageName, ImageAssetCache.imageExists(named: name) {
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
            if ImageAssetCache.imageExists(named: "game-measure-the-dinosaur-success") {
                Image("game-measure-the-dinosaur-success")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: "game-measure-the-dinosaur") {
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

// MARK: - Creature Card (match Who Is Taller layout: image + text, compact grid cell)

private struct MeasureCreatureCard: View {
    let creature: MeasureCreature
    let displayImageName: String?
    /// True when this creature is the left reference (encircled; cannot add to stack again).
    let isLeftReference: Bool
    /// True when this creature is in the right stack (no encircling; can add again).
    let isInStack: Bool
    let isDisabled: Bool
    /// True when this creature would be "too small to see" with the current left selection; card is grayed but tappable for feedback.
    let isTooSmallToSee: Bool
    /// True when selecting first and this is the smallest in grid (blocked; tappable for "pick another one" feedback).
    let isBlockedAsFirstChoice: Bool
    /// True when left is not huge and this creature is huge (wrong scale; tappable for "you can't be serious" feedback).
    let isBlockedAsHugeWhenLeftNotHuge: Bool
    /// True when this creature alone is bigger than the left reference (absurd choice; tappable for "you can't be serious" feedback).
    let isBlockedAsExceedsReferenceAlone: Bool
    let isIntroHighlighted: Bool
    var imageSize: CGFloat = 96
    var labelFontSize: CGFloat = 15
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Group {
                    if let name = displayImageName ?? creature.imageName, ImageAssetCache.imageExists(named: name) {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageSize, height: imageSize)
                            .clipped()
                    } else {
                        Text(creature.icon)
                            .font(.system(size: imageSize * 0.625))
                            .frame(width: imageSize, height: imageSize)
                    }
                }
                Text(creature.name)
                    .font(.system(size: labelFontSize))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
                    .frame(width: imageSize)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isLeftReference ? Color.blue.opacity(0.3) :
                    isInStack ? Color.green.opacity(0.12) :
                    (isIntroHighlighted ? Color.accentColor.opacity(0.08) : Color.clear)
                )
        )
        .overlay(
            Group {
                if isLeftReference || isIntroHighlighted {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isLeftReference ? Color.blue : Color.accentColor, lineWidth: isIntroHighlighted ? 4 : 3)
                } else if isInStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                }
            }
        )
        .opacity((isDisabled || isTooSmallToSee || isBlockedAsFirstChoice || isBlockedAsHugeWhenLeftNotHuge || isBlockedAsExceedsReferenceAlone) && !isLeftReference && !isIntroHighlighted ? 0.5 : 1.0)
        .disabled(isDisabled && !isLeftReference)
    }
}

#Preview {
    MeasureGameView(isPresented: .constant(true), gameConfig: MeasureGameConfigs.measureDinosaur)
}
