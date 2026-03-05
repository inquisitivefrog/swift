//
//  WhoIsTallerGameView.swift
//  DinoGames
//
//  Who Is Taller?: Compare two dinosaurs by height. Three rounds; each round 9 dinosaurs (dino-* images) in a 3×3 grid; measure-dino-* only in comparison slots.
//  Player selects two; smaller is scaled down with paleontologist as official. "Too small" combinations are rejected.
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

struct WhoIsTallerGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [WhoIsTallerItem]
}

// MARK: - Height Data (shared with Measure)

private let whoIsTallerHeightMetersById: [Int: Double] = [
    1: 12,  2: 9,   3: 9,   4: 0.6,  5: 12,  6: 15,  7: 22,  8: 8,
    9: 9,   10: 8,  11: 9,  12: 1.5, 13: 9,  14: 18, 15: 2,  16: 5,
    17: 4,  18: 6,  19: 0.2, 20: 0.2, 21: 26, 22: 6,  23: 20, 24: 5,
    25: 7,  26: 0.5, 27: 3,  28: 18, 29: 1,  30: 0.2, 31: 16, 32: 6,
    33: 0.4, 34: 0.2, 35: 8,  36: 4,  37: 0.2, 38: 0.6, 39: 6,  40: 18,
    41: 7,  42: 6,  43: 1.2, 44: 20, 45: 6,  46: 7,  47: 9,  48: 7,
    49: 1.2, 50: 2,  51: 7,  52: 5,  53: 6,  54: 7,
]

private let sameHeightRelativeThreshold = 0.08
/// Minimum scale for smaller dinosaur (e.g. 0.2 = 20% of full size). Below this, combination is "too small to see".
private let minVisibleScale: CGFloat = 0.2
/// Paleontologist on ladder: total height in meters (ladder + person reaching up) for scaling. ~4.5m so the ladder setup stays visible next to large dinosaurs.
private let paleontologistHeightMeters: Double = 4.5

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

    @State private var dinosaursCompared: [WhoIsTallerItem] = []
    @State private var endSequenceStep: Int = -1
    @State private var endHighlightIndex: Int = 0

    private var isGameOver: Bool { roundsCompleted >= maxRounds }
    private var displayItems: [WhoIsTallerItem] { currentRoundItems.isEmpty ? gameConfig.items : currentRoundItems }
    private var introWalkComplete: Bool { displayItems.isEmpty || introWalkStep >= displayItems.count }
    private var canTapGrid: Bool { introWalkComplete && !isChooseFirstAudioPlaying }

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
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    if isGameOver {
                        victoryView
                    } else {
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
                                    ForEach(0..<displayItems.count, id: \.self) { index in
                                        let item = displayItems[index]
                                        WhoIsTallerItemCard(
                                            item: item,
                                            displayImageName: gridImageName(for: item),
                                            isSelected: selectedFirst?.id == item.id || selectedSecond?.id == item.id,
                                            isDisabled: (!canTapGrid) || (selectedFirst != nil && selectedSecond != nil) || (selectedFirst != nil && selectedSecond == nil && !canSelectSecond),
                                            isTooSmallToSee: wouldBeTooSmall(second: item),
                                            isIntroHighlighted: introWalkStep >= 0 && introWalkStep < displayItems.count && introWalkStep == index
                                        ) {
                                            handleItemTap(item)
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 330)

                                // Bottom: left slot | paleontologist-ladder | right slot (dinosaurs appear here as chosen; same layout throughout)
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
                    }

                    Spacer(minLength: 8)
                }
            }
            .frame(minHeight: safeHeight)
        }
        .navigationTitle(gameConfig.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { isPresented = false }
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
            whoIsTallerCenterImage(scale: scales.center)
            whoIsTallerSlotOptional(item: selectedSecond, scale: scales.right, alignTowardCenter: false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: measureAreaHeight + 20)
        .padding(.horizontal, 24)
    }

    /// Scale for left, right, and paleontologist: all relative to max(dino heights, human). Small dinos appear smaller than paleontologist.
    private func whoIsTallerSlotScales() -> (left: CGFloat, right: CGFloat, center: CGFloat) {
        let humanH = paleontologistHeightMeters
        guard let first = selectedFirst else { return (1.0, 1.0, 1.0) }
        let h1 = first.heightMeters
        if let second = selectedSecond {
            let h2 = second.heightMeters
            let ref = max(h1, h2, humanH)
            guard ref > 0 else { return (1.0, 1.0, 1.0) }
            let leftS = CGFloat(h1 / ref)
            let rightS = CGFloat(h2 / ref)
            let centerS = CGFloat(humanH / ref)
            return (leftS, rightS, centerS)
        }
        // Only first selected: scale relative to human so small dinos appear smaller than paleontologist
        let ref = max(h1, humanH)
        guard ref > 0 else { return (1.0, 1.0, 1.0) }
        return (CGFloat(h1 / ref), 1.0, CGFloat(humanH / ref))
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

    /// Paleontologist ladder: bottom-aligned so it lines up with left/right dinosaurs for height comparison. Scaled relative to max(dino heights, human).
    private func whoIsTallerCenterImage(scale: CGFloat) -> some View {
        let name = "measure-paleontologist-ladder"
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

    /// Grid: use dino-* (square) images with names below; measure-dino-* only in comparison slots.
    private func gridImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        return ImageAssetCache.imageExists(named: base) ? base : nil
    }

    private func measureDinoImageName(for item: WhoIsTallerItem) -> String? {
        let base = item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let measureName = "measure-\(base)"
        return ImageAssetCache.imageExists(named: measureName) ? measureName : (ImageAssetCache.imageExists(named: base) ? base : nil)
    }

    /// True when the second dinosaur (the one being selected) would be the smaller one and scaled below minVisibleScale.
    private func wouldBeTooSmall(second: WhoIsTallerItem) -> Bool {
        guard let first = selectedFirst else { return false }
        let h1 = first.heightMeters
        let h2 = second.heightMeters
        guard h2 < h1 else { return false } // Second is larger or same → full size, never block
        let larger = h1
        guard larger > 0 else { return false }
        let ratio = h2 / larger
        return CGFloat(ratio) < minVisibleScale
    }

    private func handleItemTap(_ item: WhoIsTallerItem) {
        guard canTapGrid else { return }

        if selectedFirst == nil {
            selectedFirst = item
            canSelectSecond = false
            speechManager.speak(audioKey: item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))", fallbackText: item.name)
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {
                    self.speechManager.onAudioFinished = nil
                    self.speechManager.onAudioFinished = {
                        DispatchQueue.main.async {
                            self.canSelectSecond = true
                            self.speechManager.onAudioFinished = nil
                        }
                    }
                    self.speechManager.speak("game-choose-your-second-dinosaur")
                }
            }
        } else if selectedSecond == nil {
            if wouldBeTooSmall(second: item) {
                speechManager.speak("thats-too-small-to-see")
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
            speechManager.speak(audioKey: item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))", fallbackText: item.name)
        }
    }

    private let comparisonToNextRoundDelay: TimeInterval = 0.8

    private func playComparisonAudio(taller: WhoIsTallerItem, shorter: WhoIsTallerItem) {
        hasPlayedComparisonAudio = true
        let tallerH = taller.heightMeters
        let shorterH = shorter.heightMeters
        let diff = abs(tallerH - shorterH)
        let isSameHeight = diff < sameHeightRelativeThreshold * max(tallerH, shorterH)

        let advanceAfterDelay = {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.comparisonToNextRoundDelay) {
                self.advanceRound()
            }
        }

        if isSameHeight {
            speechManager.speak("they-are-about-the-same-height")
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                advanceAfterDelay()
            }
        } else {
            let audioKey = taller.imageName ?? "dino-\(taller.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
            speechManager.speak(audioKey: audioKey, fallbackText: taller.name)
            speechManager.onAudioFinished = {
                self.speechManager.onAudioFinished = nil
                self.speechManager.speak("is-taller", chainDelay: true)
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
        let items = WhoIsTallerGameConfigs.makeRoundItems(excluding: Set(dinosaursCompared.map(\.id)))
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
        speechManager.speak(audioKey: item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))", fallbackText: item.name)
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
                    self.speechManager.speak("game-choose-your-first-dinosaur")
                } else {
                    self.runIntroWalk()
                }
            }
        }
    }

    // MARK: - Victory

    private let victoryRowHeight: CGFloat = 92
    private var victoryListVisibleHeight: CGFloat { 16 + 4 * victoryRowHeight + 3 * 12 + 16 }

    private var victoryView: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(dinosaursCompared.enumerated()), id: \.offset) { index, item in
                                let isHighlighted = endSequenceStep >= 1 && index == endHighlightIndex
                                HStack(spacing: 16) {
                                    Group {
                                        if let name = gridImageName(for: item) ?? item.imageName, ImageAssetCache.imageExists(named: name) {
                                            Image(name)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 72, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            Text(item.emoji)
                                                .font(.system(size: 40))
                                                .frame(width: 72, height: 72)
                                        }
                                    }
                                    .opacity(isHighlighted ? 1.0 : 0.4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                                    )

                                    Text(item.name)
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
                    .onChange(of: endHighlightIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                Group {
                    if endSequenceStep == 2 {
                        whoIsTallerSuccessImageView
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
            if dinosaursCompared.isEmpty {
                endSequenceStep = 2
            } else {
                let item = dinosaursCompared[0]
                speechManager.speak(audioKey: item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))", fallbackText: item.name)
                speechManager.onAudioFinished = { advanceVictoryHighlight() }
            }
        }
    }

    private var whoIsTallerSuccessImageView: some View {
        Group {
            let successName = "game-\(gameConfig.id)-success"
            let fallbackName = "game-\(gameConfig.id)"
            if ImageAssetCache.imageExists(named: successName) {
                Image(successName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else if ImageAssetCache.imageExists(named: fallbackName) {
                Image(fallbackName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280, height: 280)
            } else {
                Text("🎉")
                    .font(.system(size: 100))
            }
        }
    }

    private func advanceVictoryHighlight() {
        speechManager.onAudioFinished = nil
        endHighlightIndex += 1
        if endHighlightIndex < dinosaursCompared.count {
            let item = dinosaursCompared[endHighlightIndex]
            speechManager.speak(audioKey: item.imageName ?? "dino-\(item.name.lowercased().replacingOccurrences(of: " ", with: "-"))", fallbackText: item.name)
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
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
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
        id: "who-is-taller",
        title: "Who Is Taller?",
        introAudio: "game-who-is-taller",
        items: []
    )

    /// Returns 9 dinosaurs with measure-dino-* imageset, random selection, excluding already used this game.
    static func makeRoundItems(excluding alreadyUsedIds: Set<Int> = []) -> [WhoIsTallerItem] {
        let pool = MatchingGameConfigs.allDinosaurs.filter { d in
            guard let imageName = d.imageName, imageName.hasPrefix("dino-"),
                  whoIsTallerHeightMetersById[d.id] != nil,
                  !alreadyUsedIds.contains(d.id) else { return false }
            let measureName = "measure-\(imageName)"
            return ImageAssetCache.imageExists(named: measureName)
        }
        guard pool.count >= 9 else {
            return pool.shuffled().prefix(9).map { d in
                WhoIsTallerItem(
                    id: d.id,
                    name: d.name,
                    imageName: d.imageName,
                    emoji: d.icon,
                    heightMeters: whoIsTallerHeightMetersById[d.id] ?? 1
                )
            }
        }
        return pool.shuffled().prefix(9).map { d in
            WhoIsTallerItem(
                id: d.id,
                name: d.name,
                imageName: d.imageName,
                emoji: d.icon,
                heightMeters: whoIsTallerHeightMetersById[d.id] ?? 1
            )
        }
    }

    static func whoIsTallerRandomized() -> WhoIsTallerGameConfig {
        WhoIsTallerGameConfig(
            id: "who-is-taller",
            title: "Who Is Taller?",
            introAudio: "game-who-is-taller",
            items: makeRoundItems()
        )
    }
}

#Preview {
    WhoIsTallerGameView(isPresented: .constant(true), gameConfig: WhoIsTallerGameConfigs.whoIsTallerRandomized())
}
