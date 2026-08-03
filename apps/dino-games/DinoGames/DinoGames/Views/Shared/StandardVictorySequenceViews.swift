//
//  StandardVictorySequenceViews.swift
//  DinoGames
//
//  Shared layout metrics and success-card art for land games that end with:
//  “re-introduce” list (scroll + highlight + name audio) → crowd cheering + success game card → dismiss.
//  Orchestration helpers live in `StandardVictorySequence.swift`.
//  Land, air, and marine games use this pipeline; list shows up to `maxVisibleRecapRows` rows in a fixed viewport, then scrolls.
//  Victory is one continuous screen: title + recap list stay visible above the success card.
//  Dino Puzzle uses `PortraitJigsawPuzzleGameView`, which shares the same recap + finish pattern via this file where wired.
//

import SwiftUI

// MARK: - iPad layout scale (set by `VictorySplitColumnView`)

private struct VictoryLayoutScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    /// Canvas scale for victory recap rows / success art (1.0 on phone).
    var victoryLayoutScale: CGFloat {
        get { self[VictoryLayoutScaleKey.self] }
        set { self[VictoryLayoutScaleKey.self] = newValue }
    }
}

// MARK: - List / row metrics (scroll region above success card)

enum StandardVictoryLayout {
    /// Phone-tuned recap row height (thumbnail + padding).
    static let rowHeight: CGFloat = 92
    static let rowSpacing: CGFloat = 12
    /// Phone-tuned recap thumbnail side.
    static let recapThumbnailSide: CGFloat = 72
    /// Top + bottom padding inside the scroll’s inner `VStack`.
    /// Keep at 0 so a bottom-aligned `scrollTo` shows exactly `maxVisibleRecapRows` full rows (no partial peek).
    static let listContentVerticalPadding: CGFloat = 0
    /// Fixed viewport: at most this many recap rows are visible; longer lists scroll inside the same height.
    static let maxVisibleRecapRows: Int = 3
    /// Cap for victory art growth on wide canvases (phone stays 1.0).
    static let iPadMaxScale: CGFloat = 1.85

    static func layoutScale(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.canvasScale(safeWidth: safeWidth, maxScale: iPadMaxScale)
    }

    static func scaledRowHeight(_ scale: CGFloat) -> CGFloat {
        (rowHeight * scale).rounded()
    }

    static func scaledRecapThumbnailSide(_ scale: CGFloat) -> CGFloat {
        (recapThumbnailSide * scale).rounded()
    }

    /// Standard recap list height for `itemCount` rows (caps visible slots at `maxVisibleRecapRows`).
    static func recapListScrollHeight(itemCount: Int, scale: CGFloat = 1) -> CGFloat {
        listScrollHeight(rowCount: itemCount, maxVisibleRows: maxVisibleRecapRows, scale: scale)
    }

    /// Height of the winner / recap scroll area when the number of rows can be less than `maxVisibleRows` (e.g. Guess games with 3 rounds).
    static func listScrollHeight(rowCount: Int, maxVisibleRows: Int = maxVisibleRecapRows, scale: CGFloat = 1) -> CGFloat {
        let visibleRows = max(1, min(maxVisibleRows, rowCount))
        let visibleGaps = max(0, visibleRows - 1)
        let rh = scaledRowHeight(scale)
        // Exactly N full rows + gaps — no internal vertical insets (those caused a partial row when scrolling).
        return CGFloat(visibleRows) * rh + CGFloat(visibleGaps) * rowSpacing
    }

    /// Fixed number of row “slots” in the scroll (legacy helper when height must match an exact row count).
    static func listScrollHeightFixedRows(_ rowCount: Int, scale: CGFloat = 1) -> CGFloat {
        let rows = max(1, rowCount)
        let gaps = max(0, rows - 1)
        let rh = scaledRowHeight(scale)
        return CGFloat(rows) * rh + CGFloat(gaps) * rowSpacing
    }

    /// Titles longer than this use `.title2` instead of `.largeTitle` in victory (e.g. Which Marine Reptile Is Longer).
    static let compactVictoryGameTitleCharacterThreshold: Int = 24

    /// Stable for the whole victory screen — changing size when the success card appears reads as a blink.
    static func victoryGameTitleFont(for title: String, showSuccessPhase _: Bool) -> Font {
        let useCompact = title.count > compactVictoryGameTitleCharacterThreshold
        return useCompact ? .title2 : .largeTitle
    }

    /// Racing: same capped recap viewport as other land games (`maxVisibleRecapRows`); then cap so the success region still fits on small screens.
    static func listScrollHeightRacing(rowCount: Int, maxScreenHeight: CGFloat, scale: CGFloat = 1) -> CGFloat {
        let base = recapListScrollHeight(itemCount: rowCount, scale: scale)
        return min(base, max(260 * scale, maxScreenHeight * 0.58))
    }

    /// Scroll only after the highlight leaves the first viewport page (e.g. Dino Ages: 9 rows, 3 visible).
    static func recapScrollTargetId(
        highlightIndex: Int,
        itemCount: Int,
        maxVisibleRows: Int = maxVisibleRecapRows
    ) -> Int? {
        guard itemCount > 0, highlightIndex >= 0, highlightIndex < itemCount else { return nil }
        guard highlightIndex >= maxVisibleRows else { return nil }
        return highlightIndex
    }

    /// Bottom-align the highlighted row in the capped viewport so the list advances steadily (avoids center-scroll blanking).
    static func recapScrollAnchor(maxVisibleRows: Int = maxVisibleRecapRows) -> UnitPoint {
        .bottom
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

/// Shared HStack row: thumbnail + title, highlight ring, scaled `StandardVictoryLayout.rowHeight` on iPad.
struct StandardVictoryRecapRowView: View {
    let item: VictoryRecapDisplayItem
    let isHighlighted: Bool
    @Environment(\.victoryLayoutScale) private var layoutScale

    var body: some View {
        let thumb = StandardVictoryLayout.scaledRecapThumbnailSide(layoutScale)
        let rowH = StandardVictoryLayout.scaledRowHeight(layoutScale)
        HStack(spacing: 16) {
            Group {
                if let name = item.imageAssetName, ImageAssetCache.imageExists(named: name) {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: thumb, height: thumb)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .opacity(isHighlighted ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                } else {
                    Text(item.fallbackEmoji)
                        .font(.system(size: (40 * layoutScale).rounded()))
                        .frame(width: thumb, height: thumb)
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
                        .font(layoutScale > 1.15 ? .title : .title2)
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                }
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(layoutScale > 1.15 ? .title2 : .headline)
                        .fontWeight(isHighlighted ? .semibold : .medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(isHighlighted ? 1.0 : 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: rowH)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .animation(.none, value: isHighlighted)
    }
}

// MARK: - Category progress (victory success card)

/// Quiet caption under the success game card: `Completed N of M games`.
struct StandardVictoryCategoryProgressLabel: View {
    let catalogGameConfigId: String

    var body: some View {
        if let text = GameCatalog.victoryProgressDisplayText(forConfigId: catalogGameConfigId) {
            Text(text)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .accessibilityIdentifier("victory-category-progress")
        }
    }
}

// MARK: - Success card + crowd (standard finish)

/// Shows the success game card (`game-{id}-success`) and plays crowd cheering once; then `onComplete` (dismiss).
struct StandardVictoryCrowdThenSuccessView: View {
    let candidateSuccessImageNames: [String]
    let catalogGameConfigId: String?
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
        self.catalogGameConfigId = gameConfigId
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onComplete = onComplete
    }

    init(
        candidateSuccessImageNames: [String],
        catalogGameConfigId: String? = nil,
        imageSide: CGFloat = GameCatalogImageMetrics.nameThatVictorySuccessImageSide,
        missingPolicy: StandardVictorySuccessImageView.MissingAssetPolicy = .emojiCelebration,
        speechManager: SpeechManager,
        onComplete: @escaping () -> Void
    ) {
        self.candidateSuccessImageNames = candidateSuccessImageNames
        self.catalogGameConfigId = catalogGameConfigId
        self.imageSide = imageSide
        self.missingPolicy = missingPolicy
        self.speechManager = speechManager
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            StandardVictorySuccessImageView(
                candidateAssetNames: candidateSuccessImageNames,
                imageSide: imageSide,
                missingPolicy: missingPolicy
            )
            if let catalogGameConfigId {
                StandardVictoryCategoryProgressLabel(catalogGameConfigId: catalogGameConfigId)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: startCrowdThenComplete)
    }

    private func startCrowdThenComplete() {
        guard !didStartFinish else { return }
        didStartFinish = true
        if let catalogGameConfigId {
            StandardVictorySequence.playCrowdCheeringThenCategoryProgress(
                catalogGameConfigId: catalogGameConfigId,
                speechManager: speechManager,
                onComplete: onComplete
            )
        } else {
            StandardVictorySequence.playCrowdCheeringThen(speechManager: speechManager, onComplete: onComplete)
        }
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
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let safeHeight = max(geometry.size.height, 1)
            // Grow toward available space on iPad; never exceed the success-phase frame.
            let widthScaled = GameCatalogImageMetrics.scaled(
                imageSide,
                safeWidth: safeWidth,
                maxScale: StandardVictoryLayout.iPadMaxScale
            )
            let side = min(widthScaled, safeWidth * 0.88, safeHeight * 0.92)
            ZStack {
                resolvedContent(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("victory-success-image")
    }

    @ViewBuilder
    private func resolvedContent(side: CGFloat) -> some View {
        if let name = candidateAssetNames.first(where: { ImageAssetCache.imageExists(named: $0) }) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: side, height: side)
                .layoutPriority(1)
        } else {
            switch missingPolicy {
            case .empty:
                EmptyView()
            case .emojiCelebration:
                Text("🎉")
                    .font(.system(size: min(100, side * 0.35)))
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
    /// Shown above the recap list when non-nil and non-empty. Hidden during the success phase only when `hideGameTitleDuringSuccessPhase` is true.
    let gameTitle: String?
    /// When true, the text title is removed during the success card (legacy two-screen layout).
    var hideGameTitleDuringSuccessPhase: Bool = false
    /// When true, the recap list collapses during the success card (legacy two-screen layout).
    var collapseRecapListDuringSuccessPhase: Bool = false

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
    /// Total recap rows; when set, scroll policy skips the first `maxVisibleRecapRows` highlights (no jump on rows 1–3).
    var recapItemCount: Int? = nil

    @ViewBuilder private let scrollRows: () -> ScrollRows
    @ViewBuilder private let successPhase: () -> SuccessPhase

    init(
        listScrollHeight: CGFloat,
        showSuccessPhase: Bool,
        endHighlightIndex: Int,
        gameTitle: String? = nil,
        hideGameTitleDuringSuccessPhase: Bool = false,
        collapseRecapListDuringSuccessPhase: Bool = false,
        rowSpacing: CGFloat = StandardVictoryLayout.rowSpacing,
        listHorizontalPadding: CGFloat? = nil,
        listVerticalPadding: CGFloat = StandardVictoryLayout.listContentVerticalPadding,
        vStackHorizontalAlignment: HorizontalAlignment = .center,
        extendScrollListToMaxWidth: Bool = false,
        scrollIndicators: ScrollIndicatorVisibility = .visible,
        highlightScrollValidator: ((Int) -> Bool)? = nil,
        recapItemCount: Int? = nil,
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
        self.recapItemCount = recapItemCount
        self.scrollRows = scrollRows
        self.successPhase = successPhase
    }

    /// Recap list is hidden during the success card when collapsed so the title and success art fit on screen (e.g. Weigh the Marine Reptile in landscape).
    private func activeListScrollHeight(scale: CGFloat) -> CGFloat {
        if showSuccessPhase && collapseRecapListDuringSuccessPhase { return 0 }
        // Prefer recomputing from item count so row height and viewport stay in sync on iPad.
        if let count = recapItemCount {
            return StandardVictoryLayout.recapListScrollHeight(itemCount: count, scale: scale)
        }
        return (listScrollHeight * scale).rounded()
    }

    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 1)
            let topInset = geometry.safeAreaInsets.top
            let scale = StandardVictoryLayout.layoutScale(safeWidth: safeWidth)
            columnContent(scale: scale, topInset: topInset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .environment(\.victoryLayoutScale, scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("victory-split-column")
    }

    private func columnContent(scale: CGFloat, topInset: CGFloat) -> some View {
        let listH = activeListScrollHeight(scale: scale)
        return VStack(spacing: 0) {
            if let gameTitle, !gameTitle.isEmpty, !(hideGameTitleDuringSuccessPhase && showSuccessPhase) {
                Text(gameTitle)
                    .font(StandardVictoryLayout.victoryGameTitleFont(for: gameTitle, showSuccessPhase: showSuccessPhase))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 8 + topInset)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .layoutPriority(2)
                    .accessibilityIdentifier("victory-game-title")
            }
            if listH > 0 {
                scrollSection(listHeight: listH)
            }
            bottomSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scrollSection(listHeight: CGFloat) -> some View {
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
            .frame(height: listHeight)
            .clipped()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("victory-recap-list")
            .onChange(of: endHighlightIndex) { _, newIndex in
                scrollRecapToHighlight(newIndex, proxy: proxy)
            }
        }
        .id("victory-recap-scroll-reader")
        .frame(maxWidth: .infinity)
    }

    private func scrollRecapToHighlight(_ newIndex: Int, proxy: ScrollViewProxy) {
        if let validator = highlightScrollValidator, !validator(newIndex) { return }
        let itemCount = recapItemCount ?? Int.max
        guard let target = StandardVictoryLayout.recapScrollTargetId(
            highlightIndex: newIndex,
            itemCount: itemCount
        ) else { return }
        // Defer and disable animation: animated scrollTo + highlight changes caused the recap list to blank briefly (e.g. Dino Ages item 5).
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                proxy.scrollTo(
                    target,
                    anchor: StandardVictoryLayout.recapScrollAnchor()
                )
            }
        }
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
                    .accessibilityIdentifier("victory-success-phase")
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Source hints overlay title (Ages, Eggs, Footprints, Plants)

/// Shared iPad-friendly metrics for full-screen source-hints grids.
enum SourceHintsLayout {
    static let maxScale: CGFloat = 1.85
    /// Phone-tuned grid tile height; grows on wider canvases.
    static let phoneGridCardHeight: CGFloat = 160
    static let phoneDetailImageSide: CGFloat = 360
    static let phoneTitleFont: CGFloat = 28
    static let phoneDetailLabelFont: CGFloat = 26
    static let phoneFallbackLabelFont: CGFloat = 18
    static let phoneGridSpacing: CGFloat = 20
    static let phoneHorizontalPadding: CGFloat = 20

    static func gridCardHeight(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneGridCardHeight, safeWidth: safeWidth, maxScale: maxScale)
    }

    static func detailImageSide(safeWidth: CGFloat) -> CGFloat {
        min(
            GameCatalogImageMetrics.scaled(phoneDetailImageSide, safeWidth: safeWidth, maxScale: maxScale),
            safeWidth * 0.86
        )
    }

    static func titleFont(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneTitleFont, safeWidth: safeWidth, maxScale: maxScale)
    }

    static func detailLabelFont(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneDetailLabelFont, safeWidth: safeWidth, maxScale: maxScale)
    }

    static func fallbackLabelFont(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneFallbackLabelFont, safeWidth: safeWidth, maxScale: maxScale)
    }

    static func gridSpacing(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneGridSpacing, safeWidth: safeWidth, maxScale: maxScale)
    }

    static func horizontalPadding(safeWidth: CGFloat) -> CGFloat {
        GameCatalogImageMetrics.scaled(phoneHorizontalPadding, safeWidth: safeWidth, maxScale: maxScale)
    }
}

/// Shared header for full-screen source-hints grids (`Source Ages`, `Source Eggs`, …).
struct SourceHintsScreenTitle: View {
    let title: String
    var fontSize: CGFloat = 28

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 44)
            .padding(.horizontal, 52)
            .accessibilityIdentifier("source-hints-title")
    }
}

enum SourceHintsTitles {
    static let ages = "Source Ages"
    static let eggs = "Source Eggs"
    static let footprints = "Source Footprints"
    static let plants = "Source Plants"
}

enum SourceHintsIntroAudioKeys {
    /// Shared “tap to hear a description” intro for Source hints grids (Footprints, Matrix, …).
    static let tapToHearDescription = "game-footprints-tap-the-footprint-to-hear-description"
}
