//
//  StandardVictorySequenceViews.swift
//  DinoGames
//
//  Shared layout metrics and success-card art for land games that end with:
//  “re-introduce” list (scroll + highlight + name audio) → success image (+ optional `game-{id}-victory` stinger) → good job + crowd → dismiss.
//  All Dinosaur (land) games use this pipeline; list shows up to `maxVisibleRecapRows` rows in a fixed viewport, then scrolls.
//  Dino Puzzle uses `PortraitJigsawPuzzleGameView`, which shares the same recap + stinger pattern via this file where wired.
//

import SwiftUI

// MARK: - List / row metrics (scroll region above success card)

enum StandardVictoryLayout {
    static let rowHeight: CGFloat = 92
    static let rowSpacing: CGFloat = 12
    /// Top + bottom padding inside the scroll’s inner `VStack` (matches existing games).
    static let listContentVerticalPadding: CGFloat = 16
    /// Fixed viewport: at most this many recap rows are visible; longer lists scroll inside the same height.
    static let maxVisibleRecapRows: Int = 3

    /// Standard recap list height for `itemCount` rows (caps visible slots at `maxVisibleRecapRows`).
    static func recapListScrollHeight(itemCount: Int) -> CGFloat {
        listScrollHeight(rowCount: itemCount, maxVisibleRows: maxVisibleRecapRows)
    }

    /// Height of the winner / recap scroll area when the number of rows can be less than `maxVisibleRows` (e.g. Guess games with 3 rounds).
    static func listScrollHeight(rowCount: Int, maxVisibleRows: Int = maxVisibleRecapRows) -> CGFloat {
        let visibleRows = max(1, min(maxVisibleRows, rowCount))
        let visibleGaps = max(0, visibleRows - 1)
        return listContentVerticalPadding
            + CGFloat(visibleRows) * rowHeight
            + CGFloat(visibleGaps) * rowSpacing
            + listContentVerticalPadding
    }

    /// Fixed number of row “slots” in the scroll (legacy helper when height must match an exact row count).
    static func listScrollHeightFixedRows(_ rowCount: Int) -> CGFloat {
        let rows = max(1, rowCount)
        let gaps = max(0, rows - 1)
        return listContentVerticalPadding
            + CGFloat(rows) * rowHeight
            + CGFloat(gaps) * rowSpacing
            + listContentVerticalPadding
    }

    /// Racing: same capped recap viewport as other land games (`maxVisibleRecapRows`); then cap so the success region still fits on small screens.
    static func listScrollHeightRacing(rowCount: Int, maxScreenHeight: CGFloat) -> CGFloat {
        let base = recapListScrollHeight(itemCount: rowCount)
        return min(base, max(260, maxScreenHeight * 0.58))
    }
}

// MARK: - Recap list row (one visual style for all land games)

/// One row in the victory recap (creature, plant, tool, tooth, material, etc.).
struct VictoryRecapDisplayItem: Identifiable, Equatable {
    let id: String
    let title: String
    /// Asset catalog / `UIImage` name for the thumbnail, if any.
    let imageAssetName: String?
    let fallbackEmoji: String

    init(id: String, title: String, imageAssetName: String?, fallbackEmoji: String = "🦕") {
        self.id = id
        self.title = title
        self.imageAssetName = imageAssetName
        self.fallbackEmoji = fallbackEmoji
    }
}

/// Shared HStack row: thumbnail + title, highlight ring, fixed `StandardVictoryLayout.rowHeight`.
struct StandardVictoryRecapRowView: View {
    let item: VictoryRecapDisplayItem
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let name = item.imageAssetName, ImageAssetCache.imageExists(named: name) {
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
                    Text(item.fallbackEmoji)
                        .font(.system(size: 40))
                        .frame(width: 72, height: 72)
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                }
            }
            Text(item.title)
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
        .frame(height: StandardVictoryLayout.rowHeight)
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

// MARK: - Success card + optional victory stinger (`game-{id}-victory` in Audio/Games, .mp3 / .m4a / .wav)

/// Audio key resolved by `SpeechManager` to `Games/game-{catalogGameId}-victory` (see `audioFilePath` `game-` rule).
enum LandVictoryAudio {
    static func stingerKey(catalogGameId: String) -> String { "game-\(catalogGameId)-victory" }
}

/// Shows `StandardVictorySuccessImageView`, then plays optional stinger clip, then invokes `onContinue` (typically good-job + crowd).
struct LandGameVictorySuccessStingerThenContinue: View {
    let candidateSuccessImageNames: [String]
    let catalogGameIdForStinger: String
    let imageSide: CGFloat
    let missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy
    let speechManager: SpeechManager
    let onContinue: () -> Void

    init(
        gameConfigId: String,
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy = .emojiCelebration,
        speechManager: SpeechManager,
        onContinue: @escaping () -> Void
    ) {
        self.candidateSuccessImageNames = ["game-\(gameConfigId)-success", "game-\(gameConfigId)"]
        self.catalogGameIdForStinger = gameConfigId
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onContinue = onContinue
    }

    init(
        candidateSuccessImageNames: [String],
        catalogGameIdForStinger: String,
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy = .emojiCelebration,
        speechManager: SpeechManager,
        onContinue: @escaping () -> Void
    ) {
        self.candidateSuccessImageNames = candidateSuccessImageNames
        self.catalogGameIdForStinger = catalogGameIdForStinger
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onContinue = onContinue
    }

    var body: some View {
        StandardVictorySuccessImageView(
            candidateAssetNames: candidateSuccessImageNames,
            imageSide: imageSide,
            missingPolicy: missingPolicy
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: playStingerThenContinue)
    }

    private func playStingerThenContinue() {
        let key = LandVictoryAudio.stingerKey(catalogGameId: catalogGameIdForStinger)
        if let url = speechManager.urlForAudio(key: key) {
            speechManager.onAudioFinished = {
                speechManager.onAudioFinished = nil
                onContinue()
            }
            speechManager.playAudioFile(url: url)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                onContinue()
            }
        }
    }
}

// MARK: - Success image (game card art, optional fallbacks)

/// Centered success / fallback game art for the bottom half of the standard victory column.
struct StandardVictorySuccessImageView: View {
    /// First existing name wins (e.g. `game-dino-footprints-success`, then `game-dino-footprints`).
    let candidateAssetNames: [String]
    let imageSide: CGFloat
    let missingPolicy: MissingAssetPolicy

    enum MissingAssetPolicy {
        case empty
        case emojiCelebration
    }

    init(
        candidateAssetNames: [String],
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: MissingAssetPolicy = .empty
    ) {
        self.candidateAssetNames = candidateAssetNames
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
    }

    /// Convenience: primary `game-{id}-success` then `game-{id}`.
    init(gameConfigId: String, imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide, missingPolicy: MissingAssetPolicy = .emojiCelebration) {
        self.init(
            candidateAssetNames: ["game-\(gameConfigId)-success", "game-\(gameConfigId)"],
            imageSide: imageSide,
            missingPolicy: missingPolicy
        )
    }

    var body: some View {
        ZStack {
            resolvedContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var resolvedContent: some View {
        if let name = candidateAssetNames.first(where: { ImageAssetCache.imageExists(named: $0) }) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSide, height: imageSide)
                .layoutPriority(1)
        } else {
            switch missingPolicy {
            case .empty:
                EmptyView()
            case .emojiCelebration:
                Text("🎉")
                    .font(.system(size: 100))
            }
        }
    }
}

// MARK: - Split column (scroll list + success phase)

/// Owns the standard victory column shell: optional game title → `ScrollViewReader` / `ScrollView` / fixed-height list → bottom `Group` with success or `Spacer`.
struct VictorySplitColumnView<ScrollRows: View, SuccessPhase: View>: View {
    let listScrollHeight: CGFloat
    let showSuccessPhase: Bool
    let endHighlightIndex: Int
    /// Shown above the recap list when non-nil and non-empty (game name / marketing title).
    let gameTitle: String?

    var rowSpacing: CGFloat = StandardVictoryLayout.rowSpacing
    /// When `nil`, uses SwiftUI’s default horizontal inset (same as `.padding(.horizontal)` with no argument).
    var listHorizontalPadding: CGFloat? = nil
    var listVerticalPadding: CGFloat = StandardVictoryLayout.listContentVerticalPadding
    var vStackHorizontalAlignment: HorizontalAlignment = .center
    /// When true, the inner list `VStack` gets `frame(maxWidth: .infinity, alignment: .leading)` (Dino Eggs / Dino Tools victory lists).
    var extendScrollListToMaxWidth: Bool = false
    var scrollIndicators: ScrollIndicatorVisibility = .visible
    /// Return `false` to skip `scrollTo` (e.g. index out of range for a dynamic list).
    var highlightScrollValidator: ((Int) -> Bool)? = nil

    @ViewBuilder private let scrollRows: () -> ScrollRows
    @ViewBuilder private let successPhase: () -> SuccessPhase

    init(
        listScrollHeight: CGFloat,
        showSuccessPhase: Bool,
        endHighlightIndex: Int,
        gameTitle: String? = nil,
        rowSpacing: CGFloat = StandardVictoryLayout.rowSpacing,
        listHorizontalPadding: CGFloat? = nil,
        listVerticalPadding: CGFloat = StandardVictoryLayout.listContentVerticalPadding,
        vStackHorizontalAlignment: HorizontalAlignment = .center,
        extendScrollListToMaxWidth: Bool = false,
        scrollIndicators: ScrollIndicatorVisibility = .visible,
        highlightScrollValidator: ((Int) -> Bool)? = nil,
        @ViewBuilder scrollRows: @escaping () -> ScrollRows,
        @ViewBuilder successPhase: @escaping () -> SuccessPhase
    ) {
        self.listScrollHeight = listScrollHeight
        self.showSuccessPhase = showSuccessPhase
        self.endHighlightIndex = endHighlightIndex
        self.gameTitle = gameTitle
        self.rowSpacing = rowSpacing
        self.listHorizontalPadding = listHorizontalPadding
        self.listVerticalPadding = listVerticalPadding
        self.vStackHorizontalAlignment = vStackHorizontalAlignment
        self.extendScrollListToMaxWidth = extendScrollListToMaxWidth
        self.scrollIndicators = scrollIndicators
        self.highlightScrollValidator = highlightScrollValidator
        self.scrollRows = scrollRows
        self.successPhase = successPhase
    }

    var body: some View {
        VStack(spacing: 0) {
            if let gameTitle, !gameTitle.isEmpty {
                Text(gameTitle)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }
            scrollSection
            bottomSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scrollSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if let h = listHorizontalPadding {
                        listStack
                            .padding(.horizontal, h)
                            .padding(.vertical, listVerticalPadding)
                    } else {
                        listStack
                            .padding(.horizontal)
                            .padding(.vertical, listVerticalPadding)
                    }
                }
            }
            .scrollIndicators(scrollIndicators)
            .frame(height: listScrollHeight)
            .onChange(of: endHighlightIndex) { _, newIndex in
                if let validator = highlightScrollValidator, !validator(newIndex) { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var listStack: some View {
        let core = VStack(alignment: vStackHorizontalAlignment, spacing: rowSpacing) {
            scrollRows()
        }
        if extendScrollListToMaxWidth {
            core.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            core
        }
    }

    private var bottomSection: some View {
        Group {
            if showSuccessPhase {
                successPhase()
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
