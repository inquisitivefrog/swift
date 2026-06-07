//
//  StandardVictorySequenceViews.swift
//  DinoGames
//
//  Shared layout metrics and success-card art for land games that end with:
//  “re-introduce” list (scroll + highlight + name audio) → crowd cheering + success game card → dismiss.
//  Orchestration helpers live in `StandardVictorySequence.swift`.
//  All Dinosaur (land) games use this pipeline; list shows up to `maxVisibleRecapRows` rows in a fixed viewport, then scrolls.
//  Dino Puzzle uses `PortraitJigsawPuzzleGameView`, which shares the same recap + finish pattern via this file where wired.
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

    /// Titles longer than this use `.title2` / `.title3` instead of `.largeTitle` / `.title` in victory (e.g. Which Marine Reptile Is Longer).
    static let compactVictoryGameTitleCharacterThreshold: Int = 24

    static func victoryGameTitleFont(for title: String, showSuccessPhase: Bool) -> Font {
        let useCompact = title.count > compactVictoryGameTitleCharacterThreshold
        if showSuccessPhase {
            return useCompact ? .title3 : .title
        }
        return useCompact ? .title2 : .largeTitle
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
    /// Optional second line (e.g. racing speed).
    let subtitle: String?
    /// Asset catalog / `UIImage` name for the thumbnail, if any.
    let imageAssetName: String?
    let fallbackEmoji: String

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        imageAssetName: String?,
        fallbackEmoji: String = "🦕"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
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
            VStack(alignment: .leading, spacing: 2) {
                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                }
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
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

// MARK: - Success card + crowd (standard finish)

/// Shows the success game card (`game-{id}-success`) and plays crowd cheering once; then `onComplete` (dismiss).
struct StandardVictoryCrowdThenSuccessView: View {
    let candidateSuccessImageNames: [String]
    let imageSide: CGFloat
    let missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy
    let speechManager: SpeechManager
    let onComplete: () -> Void

    @State private var didStartFinish = false

    init(
        gameConfigId: String,
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy = .emojiCelebration,
        speechManager: SpeechManager,
        onComplete: @escaping () -> Void
    ) {
        self.candidateSuccessImageNames = StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: gameConfigId)
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onComplete = onComplete
    }

    init(
        candidateSuccessImageNames: [String],
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy = .emojiCelebration,
        speechManager: SpeechManager,
        onComplete: @escaping () -> Void
    ) {
        self.candidateSuccessImageNames = candidateSuccessImageNames
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onComplete = onComplete
    }

    var body: some View {
        StandardVictorySuccessImageView(
            candidateAssetNames: candidateSuccessImageNames,
            imageSide: imageSide,
            missingPolicy: missingPolicy
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: startCrowdThenComplete)
    }

    private func startCrowdThenComplete() {
        guard !didStartFinish else { return }
        didStartFinish = true
        StandardVictorySequence.playCrowdCheeringThen(speechManager: speechManager, onComplete: onComplete)
    }
}

// MARK: - Legacy alias (all call sites use crowd + success card; victory stinger removed)

/// Shows `StandardVictorySuccessImageView`, plays crowd cheering, then invokes `onContinue` (dismiss).
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
        self.candidateSuccessImageNames = StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: gameConfigId)
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
        StandardVictoryCrowdThenSuccessView(
            candidateSuccessImageNames: candidateSuccessImageNames,
            imageSide: imageSide,
            missingPolicy: missingPolicy,
            speechManager: speechManager,
            onComplete: onContinue
        )
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
    /// Shown above the recap list when non-nil and non-empty. Hidden during the success phase when `hideGameTitleDuringSuccessPhase` is true (success card art may already include the title, e.g. Ptero Footprints).
    let gameTitle: String?
    /// When false, the title stays pinned above the list through the success stinger (e.g. Dino Matrix success art has no title).
    var hideGameTitleDuringSuccessPhase: Bool = true
    /// When false, the recap list stays visible above the success card so the two phases read as one screen (Name That Dinosaur / Pterosaur).
    var collapseRecapListDuringSuccessPhase: Bool = true

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
        hideGameTitleDuringSuccessPhase: Bool = true,
        collapseRecapListDuringSuccessPhase: Bool = true,
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
        self.hideGameTitleDuringSuccessPhase = hideGameTitleDuringSuccessPhase
        self.collapseRecapListDuringSuccessPhase = collapseRecapListDuringSuccessPhase
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

    /// Recap list is hidden during the success card when collapsed so the title and success art fit on screen (e.g. Weigh the Marine Reptile in landscape).
    private var activeListScrollHeight: CGFloat {
        showSuccessPhase && collapseRecapListDuringSuccessPhase ? 0 : listScrollHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            if let gameTitle, !gameTitle.isEmpty, !(hideGameTitleDuringSuccessPhase && showSuccessPhase) {
                Text(gameTitle)
                    .font(StandardVictoryLayout.victoryGameTitleFont(for: gameTitle, showSuccessPhase: showSuccessPhase))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .layoutPriority(2)
            }
            if activeListScrollHeight > 0 {
                scrollSection
            }
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
            .frame(height: activeListScrollHeight)
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
