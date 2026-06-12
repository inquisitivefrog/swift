//
//  WhoIsTallerGameView.swift
//  DinoGames
//
//  Who Is Taller?: Compare two creatures by height. Three rounds; 3×3 grid (dino-* or ptero-*); comparison slots use measure-dino-* or ptero-measure-{clade}-{slug} when bundled.
//  Player selects two; both creatures and the paleontologist scale from max(creature₁, creature₂, reference human height). "Too small" pairs are rejected.
//

import SwiftUI
import UIKit

// MARK: - Data Models

struct WhoIsTallerItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let imageName: String?
    let emoji: String
    let heightMeters: Double
}

enum WhoIsTallerPoolKind {
    case dinosaurs
    case pterosaurs
    case marineReptiles
}

struct WhoIsTallerGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [WhoIsTallerItem]
    let poolKind: WhoIsTallerPoolKind
}

// MARK: - Height Data (shared with Measure)

/// Standing / at-the-hip height (m) for game scaling — keep in sync with `dinosaurEstimatedHeightMetersById` in MeasureGameView.
private let whoIsTallerHeightMetersById: [Int: Double] = [
    1: 12,  2: 9,   3: 9,   4: 0.55,  5: 12,  6: 15,  7: 22,  8: 8,
    9: 9,   10: 8,  11: 9,  12: 1.5, 13: 9,  14: 18, 15: 2,  16: 5,
    17: 4,  18: 6,  19: 0.25, 20: 0.22, 21: 26, 22: 6,  23: 20, 24: 5,
    25: 7,  26: 0.35, 27: 1.75,  28: 18, 29: 1,  30: 0.22, 31: 16, 32: 6,
    33: 0.32, 34: 0.22, 35: 8,  36: 4,  37: 0.25, 38: 0.6, 39: 6,  40: 18,
    41: 7,  42: 6,  43: 1.2, 44: 20, 45: 6,  46: 7,  47: 9,  48: 7,
    49: 1.2, 50: 2,  51: 7,  52: 5,  53: 6,  54: 7,
]

/// Minimum scale for smaller dinosaur (e.g. 0.1 = 10% of full size). Below this, combination is "too small to see". Relaxed from 0.2 so small dinosaurs can compare with more options.
private let minVisibleScale: CGFloat = CGFloat(ComparisonGameLogic.minVisibleHeightRatio)
/// Reference height (m) for the standing paleontologist in the center slot.
/// Dinosaur mode keeps the legacy oversized reference for readability; pterosaur mode uses a realistic adult height.
private let paleontologistHeightMetersDino: Double = 4.5
private let paleontologistHeightMetersPtero: Double = 1.7
/// Which Ptero Is Taller: keep the *first selected* pterosaur visible before comparison.
/// Once both are selected, we use true relative scaling (no floor) so smaller-vs-smaller comparisons remain visually accurate.
private let minVisiblePterosaurScale: CGFloat = 0.22

// MARK: - Main View

struct WhoIsTallerGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: WhoIsTallerGameConfig

    @State private var speechManager = SpeechManager()
    @State private var roundsCompleted = 0
    private let maxRounds = 3
    @State private var currentRoundItems: [WhoIsTallerItem] = []
    @State private var selectedFirst: WhoIsTallerItem?
    @State private var selectedSecond: WhoIsTallerItem?
    @State private var canSelectSecond = false
    @State private var hasPlayedComparisonAudio = false
    @State private var introWalkStep: Int = -1
    /// True while "choose your first dinosaur" is playing; blocks taps until it finishes.
    @State private var isChooseFirstAudioPlaying = false
    /// Blocks grid taps while negative feedback (e.g. thats-too-small-to-see) is playing.
    @State private var gridTapsBlocked = false

    @State private var dinosaursCompared: [WhoIsTallerItem] = []
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0

    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    private var displayItems: [WhoIsTallerItem] { currentRoundItems.isEmpty ? gameConfig.items : currentRoundItems }
    private var isPterosaurPool: Bool { gameConfig.poolKind == .pterosaurs }
    private var isMarinePool: Bool { gameConfig.poolKind == .marineReptiles }
    private var usesRelativeFirstSelectionScale: Bool { isPterosaurPool || isMarinePool }
    private var introWalkComplete: Bool { displayItems.isEmpty || introWalkStep >= displayItems.count }
    private var canTapGrid: Bool { introWalkComplete && !isChooseFirstAudioPlaying && !gridTapsBlocked }

    /// Match Measure the Dinosaur layout: measure-dino-* are 140×340 px; paleontologist center 110×340 pt (larger display).
    private let measureSlotWidth: CGFloat = 140
    private let measureAreaHeight: CGFloat = 340
    private let measureCenterWidth: CGFloat = 110
    /// Minimal spacing so dinosaurs almost touch the paleontologist (tape measure).
    private let measureSpacing: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let safeHeight = max(geometry.size.height, 1)
            let safeWidth = max(geometry.size.width, 1)
            if isGameOver {
                // Full-screen victory (same as Weigh / Name That Dinosaur) so the game title stays pinned and visible.
                victoryView
                    .frame(width: safeWidth, height: safeHeight)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 8)

                        VStack(spacing: 8) {
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

                            if !displayItems.isEmpty {
                                let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
                                LazyVGrid(columns: columns, spacing: 6) {
                                    ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                                        WhoIsTallerItemCard(
                                            item: item,
                                            displayImageName: gridImageName(for: item),
                                            isSelected: selectedFirst?.id == item.id || selectedSecond?.id == item.id,
                                            isDisabled: (!canTapGrid) || (selectedFirst != nil && selectedSecond != nil) || (selectedFirst != nil && selectedSecond == nil && !canSelectSecond),
                                            isTooSmallToSee: selectedFirst != nil && selectedSecond == nil && wouldBeTooSmall(second: item),
                                            isIntroHighlighted: introWalkStep >= 0 && introWalkStep < displayItems.count && introWalkStep == index
                                        ) {
                                            handleItemTap(item)
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 330)

                                whoIsTallerMeasureArea
                                    .padding(.top, 8)
                            } else {
                                Text("Not enough creatures for this round.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                        .frame(width: safeWidth)

                        Spacer(minLength: 8)
                    }
                }
                .frame(minHeight: safeHeight)
            }
        }
        .navigationTitle(isGameOver ? "" : gameConfig.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isGameOver {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .onAppear {
            startRound()
        }
    }

    // MARK: - Measure area (left slot | paleontologist | right slot) — single layout; dinosaurs appear as chosen

    private var whoIsTallerMeasureArea: some View {
        let scales = whoIsTallerSlotScales()
        return HStack(alignment: .bottom, spacing: measureSpacing) {
            whoIsTallerSlotOptional(item: selectedFirst, scale: scales.left, alignTowardCenter: true)
                .id("left-\(selectedFirst?.id ?? 0)")
            whoIsTallerCenterImage(scale: scales.center)
            whoIsTallerSlotOptional(item: selectedSecond, scale: scales.right, alignTowardCenter: false)
                .id("right-\(selectedSecond?.id ?? 0)")
        }
        .frame(maxWidth: .infinity)
        .frame(height: measureAreaHeight + 20)
        .padding(.horizontal, 24)
    }

    /// Left creature, right creature, and paleontologist all scale from one reference height = max(left m, right m, human m).
    private func whoIsTallerSlotScales() -> (left: CGFloat, right: CGFloat, center: CGFloat) {
        let humanH = usesRelativeFirstSelectionScale ? paleontologistHeightMetersPtero : paleontologistHeightMetersDino
        guard let first = selectedFirst else { return (1.0, 1.0, 1.0) }
        let h1 = first.heightMeters
        if let second = selectedSecond {
            let h2 = second.heightMeters
            let ref = max(h1, h2, humanH)
            guard ref > 0 else { return (1.0, 1.0, 1.0) }
            let centerScale = CGFloat(humanH / ref)
            return (
                CGFloat(h1 / ref),
                CGFloat(h2 / ref),
                centerScale
            )
        }
        let ref = max(h1, humanH)
        guard ref > 0 else { return (1.0, 1.0, 1.0) }
        let centerScale = CGFloat(humanH / ref)
        let firstScale = usesRelativeFirstSelectionScale ? max(CGFloat(h1 / ref), minVisiblePterosaurScale) : CGFloat(h1 / ref)
        return (firstScale, 1.0, centerScale)
    }

    /// Slot with optional item: empty when nil, else measure-dino-* scaled. alignTowardCenter: true = left slot (trailing), false = right slot (leading).
    private func whoIsTallerSlotOptional(item: WhoIsTallerItem?, scale: CGFloat, alignTowardCenter: Bool) -> some View {
        Group {
            if let item = item, scale > 0 {
                whoIsTallerSlot(item: item, scale: scale, alignTowardCenter: alignTowardCenter)
            } else {
                Color.clear.frame(width: measureSlotWidth, height: measureAreaHeight)
            }
        }
    }

    /// Left slot: measure-dino-* aligned bottomTrailing (toward paleontologist). Right slot: bottomLeading.
    private func whoIsTallerSlot(item: WhoIsTallerItem, scale: CGFloat, alignTowardCenter: Bool) -> some View {
        let contentW = measureSlotWidth * scale
        let contentH = measureAreaHeight * scale
        let alignment: Alignment = alignTowardCenter ? .bottomTrailing : .bottomLeading
        return Group {
            if let name = measureDinoImageName(for: item), ImageAssetCache.imageExists(named: name) {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text(item.emoji)
                    .font(.system(size: 80))
            }
        }
        .frame(width: contentW, height: contentH, alignment: .bottom)
        .frame(width: measureSlotWidth, height: measureAreaHeight, alignment: alignment)
    }

    /// Paleontologist (tape pose): bottom-aligned with left/right creatures for height comparison. Scaled relative to max(creature heights, human).
    private func whoIsTallerCenterImage(scale: CGFloat) -> some View {
        let name = "measure-paleontologist-tape"
        let contentW = measureCenterWidth * scale
        let contentH = measureAreaHeight * scale
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
        .frame(width: contentW, height: contentH, alignment: .bottom)
        .frame(width: measureCenterWidth, height: measureAreaHeight, alignment: .bottom)
    }

    // MARK: - Logic

    /// Grid: use dino-* or ptero-* (square) images; comparison slots use measure-* (dinosaurs) or ptero-measure-* (pterosaurs) when present.
    private func gridImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? nameFallbackStem(item)
        return ImageAssetCache.imageExists(named: base) ? base : nil
    }

    /// Which Ptero Is Taller: bundled height poses use `ptero-measure-{clade}-{slug}` (same `{clade}-{slug}` tail as square `ptero-*` art under `Pterosaur-Height/`).
    private func pteroMeasureImageName(forSquareBase base: String) -> String? {
        let prefix = "ptero-"
        guard base.hasPrefix(prefix) else { return nil }
        let tail = String(base.dropFirst(prefix.count))
        guard !tail.isEmpty else { return nil }
        let measureName = "ptero-measure-\(tail)"
        return ImageAssetCache.imageExists(named: measureName) ? measureName : nil
    }

    /// Which Marine Reptile Is Longer: bundled length poses use `marine-measure-{group}-{slug}` when present.
    private func marineMeasureImageName(forSquareBase base: String) -> String? {
        let prefix = "marine-"
        guard base.hasPrefix(prefix) else { return nil }
        let tail = String(base.dropFirst(prefix.count))
        guard !tail.isEmpty else { return nil }
        let measureName = "marine-measure-\(tail)"
        return ImageAssetCache.imageExists(named: measureName) ? measureName : nil
    }

    private func measureDinoImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? nameFallbackStem(item)
        if isPterosaurPool {
            if let name = pteroMeasureImageName(forSquareBase: base) { return name }
            return ImageAssetCache.imageExists(named: base) ? base : nil
        }
        if isMarinePool {
            if let name = marineMeasureImageName(forSquareBase: base) { return name }
            return ImageAssetCache.imageExists(named: base) ? base : nil
        }
        let measureName = "measure-\(base)"
        return ImageAssetCache.imageExists(named: measureName) ? measureName : (ImageAssetCache.imageExists(named: base) ? base : nil)
    }

    private func nameFallbackStem(_ item: WhoIsTallerItem) -> String {
        let slug = item.name.lowercased().replacingOccurrences(of: " ", with: "-")
        if isPterosaurPool { return "ptero-\(slug)" }
        if isMarinePool { return "marine-\(slug)" }
        return "dino-\(slug)"
    }

    private func audioStem(for item: WhoIsTallerItem) -> String {
        item.imageName ?? nameFallbackStem(item)
    }

    private func playChooseFirstCreaturePrompt() {
        if isPterosaurPool {
            speechManager.speak(audioKey: "game-choose-your-first-pterosaur", fallbackText: "Choose your first pterosaur")
        } else if isMarinePool {
            speechManager.speak("game-choose-your-first-marine-reptile")
        } else {
            speechManager.speak("game-choose-your-first-dinosaur")
        }
    }

    private func playChooseSecondCreaturePrompt() {
        if isPterosaurPool {
            speechManager.speak(audioKey: "game-choose-your-second-pterosaur", fallbackText: "Choose your second pterosaur")
        } else if isMarinePool {
            speechManager.speak("game-choose-your-second-marine-reptile")
        } else {
            speechManager.speak("game-choose-your-second-dinosaur")
        }
    }

    /// True when the second dinosaur (the one being selected) would be the smaller one and scaled below minVisibleScale.
    private func wouldBeTooSmall(second: WhoIsTallerItem) -> Bool {
        guard let first = selectedFirst else { return false }
        return ComparisonGameLogic.rejectsSecondHeightPick(firstMeters: first.heightMeters, secondMeters: second.heightMeters)
    }

    private func handleItemTap(_ item: WhoIsTallerItem) {
        guard canTapGrid else { return }

        if selectedFirst == nil {
            selectedFirst = item
            canSelectSecond = false
            speechManager.speak(audioKey: audioStem(for: item), fallbackText: item.name)
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.onAudioFinished = {
                        DispatchQueue.main.async {
                            self.canSelectSecond = true
                            self.speechManager.onAudioFinished = nil
                        }
                    }
                    self.playChooseSecondCreaturePrompt()
                }
            }
        } else if selectedSecond == nil {
            guard canSelectSecond else { return }
            if wouldBeTooSmall(second: item) {
                gridTapsBlocked = true
                OrderedTouchFeedback.speak(ComparisonGameLogic.thatsTooSmallToSee, speechManager: speechManager) {
                    DispatchQueue.main.async {
                        self.speechManager.onAudioFinished = nil
                        self.gridTapsBlocked = false
                    }
                }
                return
            }
            selectedSecond = item
            hasPlayedComparisonAudio = false
            dinosaursCompared.append(selectedFirst!)
            dinosaursCompared.append(selectedSecond!)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                // Brief pause before declaring winner so the second dinosaur's name settles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let first = self.selectedFirst, let second = self.selectedSecond, !self.hasPlayedComparisonAudio {
                        let (taller, shorter) = first.heightMeters >= second.heightMeters ? (first, second) : (second, first)
                        self.playComparisonAudio(taller: taller, shorter: shorter)
                    }
                }
            }
            speechManager.speak(audioKey: audioStem(for: item), fallbackText: item.name)
        }
    }

    private let comparisonToNextRoundDelay: TimeInterval = 0.8

    private func playComparisonAudio(taller: WhoIsTallerItem, shorter: WhoIsTallerItem) {
        hasPlayedComparisonAudio = true
        let outcome = ComparisonGameLogic.heightComparisonOutcome(
            firstMeters: taller.heightMeters,
            secondMeters: shorter.heightMeters
        )
        let isSameHeight = outcome == .aboutTheSame

        let advanceAfterDelay = {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.comparisonToNextRoundDelay) {
                self.advanceRound()
            }
        }

        if isSameHeight {
            let key = ComparisonGameLogic.heightComparisonResultAudioKey(outcome: .aboutTheSame, isMarine: isMarinePool)
            speechManager.speak(audioKey: key, fallbackText: isMarinePool ? "about the same length" : "about the same height")
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                advanceAfterDelay()
            }
        } else {
            let audioKey = audioStem(for: taller)
            speechManager.speak(audioKey: audioKey, fallbackText: taller.name)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                let suffixKey = ComparisonGameLogic.heightComparisonResultAudioKey(
                    outcome: .firstTaller,
                    isMarine: self.isMarinePool
                )
                self.speechManager.speak(audioKey: suffixKey, fallbackText: self.isMarinePool ? "is longer" : "is taller", chainDelay: true)
                self.speechManager.onAudioFinished = {
                    self.speechManager.onAudioFinished = nil
                    advanceAfterDelay()
                }
            }
        }
    }

    private func advanceRound() {
        roundsCompleted += 1
        selectedFirst = nil
        selectedSecond = nil
        hasPlayedComparisonAudio = false

        if roundsCompleted < maxRounds {
            startRound()
        }
    }

    private func startRound() {
        let items = WhoIsTallerGameConfigs.makeRoundItems(
            excluding: Set(dinosaursCompared.map(\.id)),
            poolKind: gameConfig.poolKind
        )
        currentRoundItems = items
        selectedFirst = nil
        selectedSecond = nil
        canSelectSecond = false
        isChooseFirstAudioPlaying = false
        introWalkStep = items.isEmpty ? items.count : 0
        if !items.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.runIntroWalk()
            }
        }
    }

    private func runIntroWalk() {
        guard introWalkStep >= 0 && introWalkStep < displayItems.count else {
            introWalkStep = displayItems.count
            return
        }
        let item = displayItems[introWalkStep]
        let isLast = introWalkStep + 1 >= displayItems.count
        speechManager.speak(audioKey: audioStem(for: item), fallbackText: item.name)
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                self.introWalkStep += 1
                if isLast {
                    self.isChooseFirstAudioPlaying = true
                    self.speechManager.onAudioFinished = {
                        DispatchQueue.main.async {
                            self.isChooseFirstAudioPlaying = false
                            self.speechManager.onAudioFinished = nil
                        }
                    }
                    self.playChooseFirstCreaturePrompt()
                } else {
                    self.runIntroWalk()
                }
            }
        }
    }

    // MARK: - Victory

    /// Recap: height-comparison art shown during play (`measure-*` / `ptero-measure-*` when bundled).
    private var tallerVictoryRecapItems: [VictoryRecapDisplayItem] {
        dinosaursCompared.map { item in
            let imageName = measureDinoImageName(for: item) ?? gridImageName(for: item) ?? item.imageName
            let resolved = imageName.flatMap { ImageAssetCache.imageExists(named: $0) ? $0 : nil }
            return VictoryRecapDisplayItem(
                id: "\(item.id)",
                title: item.name,
                imageAssetName: resolved,
                fallbackEmoji: item.emoji
            )
        }
    }

    private var victoryListVisibleHeight: CGFloat {
        StandardVictoryLayout.recapListScrollHeight(itemCount: tallerVictoryRecapItems.count)
    }

    private var victorySuccessImageSide: CGFloat {
        GameCatalogImageMetrics.nameThatVictorySuccessImageSide
    }

    private var victoryView: some View {
        VictorySplitColumnView(
            listScrollHeight: victoryListVisibleHeight,
            showSuccessPhase: endSequenceStep == 2,
            endHighlightIndex: endHighlightIndex,
            gameTitle: gameConfig.title,
            scrollRows: {
                ForEach(Array(tallerVictoryRecapItems.enumerated()), id: \.element.id) { index, item in
                    StandardVictoryRecapRowView(
                        item: item,
                        isHighlighted: endSequenceStep >= 1 && index == endHighlightIndex
                    )
                    .id(index)
                }
            },
            successPhase: {
                LandGameVictorySuccessStingerThenContinue(
                    candidateSuccessImageNames: ["game-\(gameConfig.id)-success", "game-\(gameConfig.id)"],
                    catalogGameIdForStinger: gameConfig.id,
                    imageSide: victorySuccessImageSide,
                    speechManager: speechManager,
                    onContinue: playGoodJobAndCrowdThenDismiss
                )
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard endSequenceStep == -1 else { return }
            endSequenceStep = 1
            endHighlightIndex = 0
            if dinosaursCompared.isEmpty {
                endSequenceStep = 2
            } else {
                let item = dinosaursCompared[0]
                speechManager.speak(audioKey: audioStem(for: item), fallbackText: item.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < dinosaursCompared.count {
            let item = dinosaursCompared[endHighlightIndex]
            speechManager.speak(audioKey: audioStem(for: item), fallbackText: item.name)
            speechManager.onAudioFinished = { advanceVictoryHighlight() }
        } else {
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

    private func notifyCategoryCompletion() {
        switch gameConfig.poolKind {
        case .pterosaurs:
            PterosaurProgress.notifyCompletionIfPterosaurGame(configId: gameConfig.id)
        case .marineReptiles:
            MarineReptileProgress.notifyCompletionIfMarineGame(configId: gameConfig.id)
        case .dinosaurs:
            LandDinosaurProgress.notifyCompletionIfLandGame(configId: gameConfig.id)
        }
    }
}

// MARK: - Item Card

private struct WhoIsTallerItemCard: View {
    let item: WhoIsTallerItem
    let displayImageName: String?
    let isSelected: Bool
    let isDisabled: Bool
    /// True when this dinosaur would be "too small to see" with the current first selection; card is grayed but tappable so user gets "thats-too-small-to-see" feedback.
    let isTooSmallToSee: Bool
    let isIntroHighlighted: Bool
    let onTap: () -> Void

    /// Grid cell image size; compact to fit without overlapping Round/paleontologist.
    private let imageSize: CGFloat = 72

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Group {
                    if let name = displayImageName ?? item.imageName, ImageAssetCache.imageExists(named: name) {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageSize, height: imageSize)
                            .clipped()
                    } else {
                        Text(item.emoji)
                            .font(.system(size: 60))
                            .frame(width: imageSize, height: imageSize)
                    }
                }
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.3) : (isIntroHighlighted ? Color.accentColor.opacity(0.08) : Color.clear))
        )
        .overlay(
            Group {
                if isSelected || isIntroHighlighted {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.accentColor, lineWidth: isIntroHighlighted ? 4 : 3)
                }
            }
        )
        .opacity((isDisabled || isTooSmallToSee) && !isSelected && !isIntroHighlighted ? 0.5 : 1.0)
        .disabled(isDisabled && !isSelected)
    }
}

// MARK: - Configs

enum WhoIsTallerGameConfigs {
    static let whoIsTaller = WhoIsTallerGameConfig(
        id: "which-dino-is-taller",
        title: "Which Dino Is Taller",
        introAudio: "game-which-dino-is-taller",
        items: [],
        poolKind: .dinosaurs
    )

    static let whoIsTallerPterosaur = WhoIsTallerGameConfig(
        id: "which-ptero-is-taller",
        title: "Which Ptero Is Taller",
        introAudio: "game-which-ptero-is-taller",
        items: [],
        poolKind: .pterosaurs
    )

    static let whichMarineReptileIsLonger = WhoIsTallerGameConfig(
        id: "which-marine-reptile-is-longer",
        title: "Which Marine Reptile Is Longer",
        introAudio: "game-which-marine-reptile-is-longer",
        items: [],
        poolKind: .marineReptiles
    )

    /// Every dinosaur that can appear in Which Dino Is Taller (full pool for CI display-moment tests).
    static func allEligibleDinosaurItems() -> [WhoIsTallerItem] {
        MatchingGameConfigs.allDinosaurs.compactMap { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-"),
                  let height = whoIsTallerHeightMetersById[d.id] else { return nil }
            let measureName = "measure-\(imageName)"
            guard ImageAssetCache.imageExists(named: measureName) else { return nil }
            return WhoIsTallerItem(
                id: d.id,
                name: d.name,
                imageName: d.imageName,
                emoji: d.icon,
                heightMeters: height
            )
        }
    }

    /// Returns 9 creatures for the pool kind; dinosaurs require `measure-dino-*`; pterosaurs use standing heights from `AirPterosaurData`, square `ptero-*` on the grid, and `ptero-measure-{clade}-{slug}` in comparison slots when present; marine reptiles use `MarineReptileLengthCatalog` and `marine-measure-*` when bundled.
    static func makeRoundItems(excluding alreadyUsedIds: Set<Int> = [], poolKind: WhoIsTallerPoolKind) -> [WhoIsTallerItem] {
        switch poolKind {
        case .dinosaurs:
            let pool = allEligibleDinosaurItems().filter { !alreadyUsedIds.contains($0.id) }
            guard pool.count >= 9 else {
                return Array(pool.shuffled().prefix(9))
            }
            return Array(pool.shuffled().prefix(9))
        case .pterosaurs:
            let pool = MatchingGameConfigs.allPterosaurs.filter { d in
                guard let imageName = d.imageName, imageName.hasPrefix("ptero-"),
                      AirPterosaurData.pterosaurStandingHeightMetersById[d.id] != nil,
                      !alreadyUsedIds.contains(d.id),
                      ImageAssetCache.imageExists(named: imageName) else { return false }
                return true
            }
            guard pool.count >= 9 else {
                return pool.shuffled().prefix(9).map { d in
                    WhoIsTallerItem(
                        id: d.id,
                        name: d.name,
                        imageName: d.imageName,
                        emoji: d.icon,
                        heightMeters: AirPterosaurData.pterosaurStandingHeightMetersById[d.id] ?? 1
                    )
                }
            }
            return pool.shuffled().prefix(9).map { d in
                WhoIsTallerItem(
                    id: d.id,
                    name: d.name,
                    imageName: d.imageName,
                    emoji: d.icon,
                    heightMeters: AirPterosaurData.pterosaurStandingHeightMetersById[d.id] ?? 1
                )
            }
        case .marineReptiles:
            let pool = SeaMarineReptileData.allMarineReptiles.filter { d in
                guard let imageName = d.imageName, imageName.hasPrefix("marine-"),
                      MarineReptileLengthCatalog.totalLengthMeters(forImageName: imageName) != nil,
                      !alreadyUsedIds.contains(d.id),
                      ImageAssetCache.imageExists(named: imageName) else { return false }
                return true
            }
            guard pool.count >= 9 else {
                return pool.shuffled().prefix(9).map { d in
                    WhoIsTallerItem(
                        id: d.id,
                        name: d.name,
                        imageName: d.imageName,
                        emoji: d.icon,
                        heightMeters: MarineReptileLengthCatalog.totalLengthMeters(forImageName: d.imageName ?? "") ?? 1
                    )
                }
            }
            return pool.shuffled().prefix(9).map { d in
                WhoIsTallerItem(
                    id: d.id,
                    name: d.name,
                    imageName: d.imageName,
                    emoji: d.icon,
                    heightMeters: MarineReptileLengthCatalog.totalLengthMeters(forImageName: d.imageName ?? "") ?? 1
                )
            }
        }
    }

    static func randomized(from template: WhoIsTallerGameConfig) -> WhoIsTallerGameConfig {
        WhoIsTallerGameConfig(
            id: template.id,
            title: template.title,
            introAudio: template.introAudio,
            items: makeRoundItems(poolKind: template.poolKind),
            poolKind: template.poolKind
        )
    }

    static func whoIsTallerRandomized() -> WhoIsTallerGameConfig {
        randomized(from: whoIsTaller)
    }

    static func whoIsTallerPterosaurRandomized() -> WhoIsTallerGameConfig {
        randomized(from: whoIsTallerPterosaur)
    }

    static func whichMarineReptileIsLongerRandomized() -> WhoIsTallerGameConfig {
        randomized(from: whichMarineReptileIsLonger)
    }
}

#Preview {
    WhoIsTallerGameView(isPresented: .constant(true), gameConfig: WhoIsTallerGameConfigs.whoIsTallerRandomized())
}
