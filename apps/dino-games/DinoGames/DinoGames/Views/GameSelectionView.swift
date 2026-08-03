//
//  GameSelectionView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
import AVFoundation
import Combine

// Import MatchingGameConfig from MatchingGameView
// (In Swift, types are accessible across files in the same module)

struct GameSelectionView: View {
    let category: GameCategory
    let guidedPlayMode: Bool
    let onReturnToCategoryMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("introducedGameListKeysCSV") private var introducedGameListKeysCSV = ""

    @State private var selectedGame: GameType?
    @State private var showGameName = false
    @State private var showMatchingGame = false
    @State private var showWeighGame = false
    @State private var showBalanceGame = false
    @State private var showGuessGame = false
    @State private var showWackyGame = false
    @State private var showToothacheGame = false
    @State private var showSmilingDinosGame = false
    @State private var showDinoEggsGame = false
    @State private var showDinoToolsGame = false
    @State private var showRacingGame = false
    @State private var showRacingPeriodSelection = false
    @State private var showFindMamaGame = false
    @State private var showDinoLunchGame = false
    @State private var showDinoMatrixGame = false
    @State private var showDinoAgesGame = false
    @State private var showDinoFormationsGame = false
    @State private var showDinoHabitatsGame = false
    @State private var showDinoFloraGame = false
    @State private var showPteroFloraGame = false
    @State private var showPteroEggsGame = false
    @State private var showDinoFaunaGame = false
    @State private var showDinoFossilHuntGame = false
    @State private var showMeasureGame = false
    @State private var showWhoIsTallerGame = false
    @State private var showDinoPushGame = false
    @State private var showDinoPuzzleGame = false
    @State private var showPteroPuzzleGame = false
    @State private var showMarinePuzzleGame = false
    @State private var showMarineFloraGame = false
    @State private var showMarineEggsGame = false
    @State private var currentGameConfig: MatchingGameConfig?
    @State private var currentWeighConfig: WeighGameConfig?
    @State private var currentBalanceConfig: BalanceGameConfig?
    @State private var currentGuessConfig: GuessGameConfig?
    @State private var currentWackyConfig: WackyGameConfig?
    @State private var currentToothacheConfig: ToothacheGameConfig?
    @State private var currentSmilingDinosConfig: SmilingDinosGameConfig?
    @State private var currentDinoEggsConfig: DinoEggsGameConfig?
    @State private var currentDinoToolsConfig: DinoToolsGameConfig?
    @State private var currentRacingConfig: RacingGameConfig?
    @State private var currentFindMamaConfig: FindMamaConfig?
    @State private var currentDinoLunchConfig: DinoLunchConfig?
    @State private var currentDinoMatrixConfig: DinoMatrixGameConfig?
    @State private var currentDinoAgesConfig: DinoAgesGameConfig?
    @State private var currentDinoFormationsConfig: DinoFormationsGameConfig?
    @State private var currentDinoHabitatsConfig: DinoHabitatsGameConfig?
    @State private var currentDinoFloraConfig: DinoFloraGameConfig?
    @State private var currentPteroFloraConfig: PteroFloraGameConfig?
    @State private var currentPteroEggsConfig: PteroEggsGameConfig?
    @State private var currentMarineFloraConfig: MarineFloraGameConfig?
    @State private var currentMarineEggsConfig: MarineEggsGameConfig?
    @State private var currentDinoFaunaConfig: DinoFaunaGameConfig?
    @State private var currentDinoFossilHuntConfig: DinoFossilHuntGameConfig?
    @State private var currentMeasureConfig: MeasureGameConfig?
    @State private var currentWhoIsTallerConfig: WhoIsTallerGameConfig?
    @State private var speechManager = SpeechManager()
    /// true from first frame when category intro will play, so the list is disabled until intro + game walk finish.
    @State private var isAudioPlaying = false
    @State private var hasPlayedWelcome = false
    @State private var showGameTransition = false
    /// When non-nil, we're walking the game list: highlight card at this index and play its intro audio; cards stay disabled until walk finishes.
    @State private var gameWalkIndex: Int? = nil
    @State private var transitionGameImage: String?
    @State private var transitionAudioFile: String?
    /// Selected difficulty rung (shared `GameLevel` across categories). nil = level picker; non-nil = game list for that level.
    @State private var selectedLevel: GameLevel? = nil
    /// Visual + crowd intermission after picking a level; blocks level intro until finished (land, air, marine).
    @State private var landLevelIntermissionActive = false
    @State private var guidedCategoryCompletionActive = false
    @ObservedObject private var landProgress = LandDinosaurProgress.shared
    @ObservedObject private var marineProgress = MarineReptileProgress.shared
    @ObservedObject private var pterosaurProgress = PterosaurProgress.shared
    /// Snapshot at game open: if the level was not yet fully played, the next dismiss may complete it and trigger auto-advance to the next unlocked level.
    @State private var levelWasFullyPlayedWhenGameOpened = false
    /// Triggers auto-launch of the next catalog game after the level intro (or game-name walk).
    @State private var pendingGuidedAutoLaunch = false
    /// Set when guided play advances to the next level; skips the game-name walk after level intro.
    @State private var guidedPendingLevelAdvance = false
    /// Game being auto-launched after the walk (used to resume an interrupted session).
    @State private var lastCompletedGameForGuidedAdvance: GameType?

    init(
        category: GameCategory,
        guidedPlayMode: Bool,
        onReturnToCategoryMenu: @escaping () -> Void
    ) {
        self.category = category
        self.guidedPlayMode = guidedPlayMode
        self.onReturnToCategoryMenu = onReturnToCategoryMenu
        let entryLevel = guidedPlayMode ? CategoryPlaySession.guidedEntryLevel(for: category) : nil
        let resumingGuided = guidedPlayMode && CategoryPlaySession.shouldSkipGuidedLevelIntro(for: category)
        _selectedLevel = State(initialValue: entryLevel)
        _landLevelIntermissionActive = State(initialValue: entryLevel != nil && !resumingGuided)
        _hasPlayedWelcome = State(initialValue: resumingGuided)
        if entryLevel != nil && !resumingGuided {
            _isAudioPlaying = State(initialValue: true)
        }
    }

    /// Games for the current category and level. When `selectedLevel == nil`, callers typically show the level picker instead of this list.
    private var gamesForCategory: [GameType] {
        GameCatalog.games(for: category, level: selectedLevel)
    }

    /// True when we show the game list (intro + game walk). False on the level picker.
    private var showingGameList: Bool {
        selectedLevel != nil
    }
    
    private var selectedGameId: String? {
        selectedGame?.id
    }

    private var currentGameListIntroductionKey: String? {
        guard let level = selectedLevel else { return nil }
        return "\(category.rawValue)-\(level.rawValue)"
    }

    private var introducedGameListKeys: Set<String> {
        Set(
            introducedGameListKeysCSV
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    private var hasIntroducedCurrentGameList: Bool {
        guard let key = currentGameListIntroductionKey else { return false }
        return introducedGameListKeys.contains(key)
    }
    
    /// Navigation bar title. Empty on the game list — level title lives in the scroll header (nav bar hidden there to avoid a blank strip after sheet dismiss).
    private var gameSelectionTitle: String {
        if selectedLevel != nil { return "" }
        return "Choose a level"
    }

    private func isLandLevelLocked(_ level: GameLevel) -> Bool {
        category == .land && !landProgress.isLevelUnlocked(level)
    }

    private func isMarineLevelLocked(_ level: GameLevel) -> Bool {
        category == .marineReptiles && !marineProgress.isLevelUnlocked(level)
    }

    private func isPterosaurLevelLocked(_ level: GameLevel) -> Bool {
        category == .air && !pterosaurProgress.isLevelUnlocked(level)
    }

    private func isCategoryLevelLocked(_ level: GameLevel) -> Bool {
        isLandLevelLocked(level) || isMarineLevelLocked(level) || isPterosaurLevelLocked(level)
    }

    private func isLandGamePlayable(_ game: GameType) -> Bool {
        guard category == .land, let level = selectedLevel else { return true }
        return landProgress.canPlayLandGame(game, at: level)
    }

    private func isMarineGamePlayable(_ game: GameType) -> Bool {
        guard category == .marineReptiles, let level = selectedLevel else { return true }
        return marineProgress.canPlayMarineGame(game, at: level)
    }

    private func isCurrentCategoryGamePlayable(_ game: GameType) -> Bool {
        switch category {
        case .land:
            return isLandGamePlayable(game)
        case .marineReptiles:
            return isMarineGamePlayable(game)
        case .air:
            guard let level = selectedLevel else { return true }
            return pterosaurProgress.canPlayPterosaurGame(game, at: level)
        }
    }

    private func isCatalogLevelFullyPlayed(_ level: GameLevel) -> Bool {
        switch category {
        case .land:
            return landProgress.hasCompletedEveryGame(in: level)
        case .marineReptiles:
            return marineProgress.hasCompletedEveryGame(in: level)
        case .air:
            return pterosaurProgress.hasCompletedEveryGame(in: level)
        }
    }

    /// After returning from a game sheet: if this run completed the final never-played slot in the current level, jump to the next level so intermission + level intro + game walk play there.
    private func maybeAutoAdvanceToNextLevelAfterGameDismissed() {
        defer { levelWasFullyPlayedWhenGameOpened = false }
        guard let current = selectedLevel else { return }
        guard !levelWasFullyPlayedWhenGameOpened else { return }
        guard isCatalogLevelFullyPlayed(current) else { return }
        guard let next = GameCatalog.nextPlayableUnlockedLevel(after: current, category: category) else { return }
        if guidedPlayMode {
            guidedPendingLevelAdvance = true
        }
        // Swap level + cover in one update so the completed level's game list never paints
        // under the sheet dismiss before hopping/cheering starts.
        selectedLevel = next
        landLevelIntermissionActive = true
        isAudioPlaying = true
        persistPlaySession(gameCanonicalId: nil)
    }

    private func persistPlaySession(gameCanonicalId: String?) {
        CategoryPlaySession.save(
            category: category,
            level: selectedLevel,
            gameCanonicalId: gameCanonicalId,
            guidedPlayMode: guidedPlayMode
        )
    }

    /// Guided play: ensure session is persisted (level is chosen in `init` so the level picker never flashes).
    private func applyGuidedEntryIfNeeded() {
        guard guidedPlayMode else { return }
        if selectedLevel == nil, let level = CategoryPlaySession.guidedEntryLevel(for: category) {
            landLevelIntermissionActive = true
            isAudioPlaying = true
            selectedLevel = level
        }
        let snap = CategoryPlaySession.load()
        persistPlaySession(gameCanonicalId: snap.gameCanonicalId)
    }

    private func gameForGuidedAutoLaunch() -> GameType? {
        guard let level = selectedLevel else { return nil }
        let snap = CategoryPlaySession.load()
        if let savedId = snap.gameCanonicalId,
           let saved = gamesForCategory.first(where: { GameCatalog.canonicalId(for: $0, category: category) == savedId }),
           GameCatalog.canPlay(saved, at: level, category: category),
           !GameCatalog.hasPlayed(saved, category: category) {
            return saved
        }
        if let completed = lastCompletedGameForGuidedAdvance,
           let next = GameCatalog.nextUnplayedGame(in: level, category: category, after: completed) {
            return next
        }
        return GameCatalog.firstUnplayedGame(in: level, category: category)
    }

    private func autoLaunchNextGuidedGame() {
        guard guidedPlayMode, !showGameTransition else { return }
        if GameCatalog.isCategoryFullyPlayed(category) {
            scheduleGuidedCategoryCelebrationIfNeeded()
            return
        }
        guard let game = gameForGuidedAutoLaunch() else { return }
        guard isCurrentCategoryGamePlayable(game) else { return }
        if let canonical = GameCatalog.canonicalId(for: game, category: category) {
            persistPlaySession(gameCanonicalId: canonical)
        }
        handleGameTap(game)
    }

    /// Guided run finished every game in every visible level — celebrate, then return to the game-type menu.
    private func finishGuidedCategoryAndReturnToMenu() {
        guard !guidedCategoryCompletionActive else { return }
        CategoryPlaySession.save(category: category, level: nil, gameCanonicalId: nil, guidedPlayMode: false)
        showGameTransition = false
        speechManager.onAudioFinished = nil
        gameWalkIndex = nil
        hasPlayedWelcome = true
        landLevelIntermissionActive = false
        guidedPendingLevelAdvance = false
        pendingGuidedAutoLaunch = false
        selectedLevel = nil
        guidedCategoryCompletionActive = true
        isAudioPlaying = true
    }

    /// Defer category celebration until the game sheet has dismissed so victory audio and layout settle.
    private func scheduleGuidedCategoryCelebrationIfNeeded() {
        guard guidedPlayMode, GameCatalog.isCategoryFullyPlayed(category) else { return }
        guard !guidedCategoryCompletionActive else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            guard guidedPlayMode, GameCatalog.isCategoryFullyPlayed(category) else { return }
            finishGuidedCategoryAndReturnToMenu()
        }
    }

    private func completeGuidedCategoryCelebrationAndReturnToMenu() {
        guidedCategoryCompletionActive = false
        isAudioPlaying = false
        onReturnToCategoryMenu()
    }

    /// Guided post-game: level-up, category completion → top menu, or re-walk + next game.
    private func runGuidedPostGameDismissal() {
        if let game = selectedGame {
            lastCompletedGameForGuidedAdvance = game
        }
        maybeAutoAdvanceToNextLevelAfterGameDismissed()
        if GameCatalog.isCategoryFullyPlayed(category) {
            scheduleGuidedCategoryCelebrationIfNeeded()
            return
        }
        CategoryPlaySession.clearGameSlot()
        persistPlaySession(gameCanonicalId: nil)
    }

    private func runPostGameDismissalSideEffects() {
        if guidedPlayMode {
            runGuidedPostGameDismissal()
        } else {
            maybeAutoAdvanceToNextLevelAfterGameDismissed()
        }
    }

    private var gameSelectionBackDisabled: Bool {
        isAudioPlaying || landLevelIntermissionActive || guidedCategoryCompletionActive || showGameTransition
    }

    private func handleGameSelectionBack() {
        if showGameTransition {
            showGameTransition = false
            selectedGame = nil
        } else if selectedLevel != nil {
            if guidedPlayMode {
                persistPlaySession(gameCanonicalId: nil)
                onReturnToCategoryMenu()
            } else {
                selectedLevel = nil
            }
        } else {
            dismiss()
        }
    }

    /// Call after transition dismisses to present the correct game sheet.
    private func presentSheetForSelectedGame() {
        guard let gameType = selectedGame else { return }
        if gameType.gameConfig != nil {
            showMatchingGame = true
        } else if gameType.weighConfig != nil {
            showWeighGame = true
        } else if gameType.balanceConfig != nil {
            showBalanceGame = true
        } else if gameType.guessConfig != nil {
            showGuessGame = true
        } else if gameType.findMamaConfig != nil {
            showFindMamaGame = true
        } else if gameType.dinoLunchConfig != nil {
            showDinoLunchGame = true
        } else if gameType.wackyConfig != nil {
            showWackyGame = true
        } else if gameType.toothacheConfig != nil {
            showToothacheGame = true
        } else if gameType.smilingDinosConfig != nil {
            showSmilingDinosGame = true
        } else if gameType.dinoEggsConfig != nil {
            showDinoEggsGame = true
        } else if gameType.dinoToolsConfig != nil {
            showDinoToolsGame = true
        } else if let racingConfig = gameType.racingConfig {
            if racingConfig.id.hasPrefix("racing-pterosaurs") {
                currentRacingConfig = RacingGameConfigs.racingPterosaursNeedsPeriod
                showRacingGame = true
            } else if racingConfig.id.hasPrefix("racing-marine") {
                currentRacingConfig = RacingGameConfigs.racingMarineReptilesNeedsPeriod
                showRacingGame = true
            } else {
                // Racing Dinosaurs: embed period selection in RacingGameView to avoid sheet dismiss/present flash
                currentRacingConfig = RacingGameConfigs.racingDinosaursNeedsPeriod
                showRacingGame = true
            }
        } else if let matrixConfig = gameType.matrixGameConfig {
            currentDinoMatrixConfig = matrixConfig
            showDinoMatrixGame = true
        } else if gameType.dinoAgesConfig != nil {
            showDinoAgesGame = true
        } else if gameType.dinoFormationsConfig != nil {
            showDinoFormationsGame = true
        } else if gameType.dinoHabitatsConfig != nil {
            showDinoHabitatsGame = true
        } else if gameType.dinoFloraConfig != nil {
            showDinoFloraGame = true
        } else if gameType.pteroFloraConfig != nil {
            showPteroFloraGame = true
        } else if gameType.pteroEggsConfig != nil {
            showPteroEggsGame = true
        } else if gameType.dinoFaunaConfig != nil {
            showDinoFaunaGame = true
        } else if gameType.dinoFossilHuntConfig != nil {
            showDinoFossilHuntGame = true
        } else if gameType.measureConfig != nil {
            showMeasureGame = true
        } else if gameType.whoIsTallerConfig != nil {
            showWhoIsTallerGame = true
        } else if gameType.dinoPushConfig != nil {
            showDinoPushGame = true
        } else if gameType.dinoPuzzleConfig != nil {
            showDinoPuzzleGame = true
        } else if gameType.pteroPuzzleConfig != nil {
            showPteroPuzzleGame = true
        } else if gameType.marinePuzzleConfig != nil {
            showMarinePuzzleGame = true
        } else if gameType.marineFloraConfig != nil {
            showMarineFloraGame = true
        } else if gameType.marineEggsConfig != nil {
            showMarineEggsGame = true
        }
    }

    private var hasNoGames: Bool {
        gamesForCategory.isEmpty
    }

    /// Level picker: shipping levels in a grid. Shown when no level is selected yet.
    /// iPad (regular width): 2×2 so four level tiles read large; compact phones keep 2 columns too
    /// now that only four levels ship (was a dense 4-column strip for up to ~20 levels).
    @ViewBuilder
    private var levelPickerContent: some View {
        GeometryReader { geo in
            let columnCount = 2
            let rowSpacing: CGFloat = 16
            let columnSpacing: CGFloat = 16
            let horizontalPadding: CGFloat = 20
            let headerReserve: CGFloat = guidedPlayMode ? 8 : 88
            let levelCount = CGFloat(GameLevel.visibleInGamePicker.count)
            let rowCount = max(1, ceil(levelCount / CGFloat(columnCount)))
            let verticalBudget = max(0, geo.size.height - headerReserve - 24)
            let tileHeight = max(
                140,
                (verticalBudget - rowSpacing * (rowCount - 1)) / rowCount
            )
            let imageMaxHeight = max(72, tileHeight - 64)

            ScrollView {
                VStack(spacing: 12) {
                    if !guidedPlayMode, let snapshot = GameCatalog.categoryProgressSnapshot(for: category) {
                        CategoryProgressLevelPickerHeader(snapshot: snapshot)
                    }
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: columnSpacing),
                            count: columnCount
                        ),
                        spacing: rowSpacing
                    ) {
                        ForEach(GameLevel.visibleInGamePicker) { level in
                            LevelCard(
                                category: category,
                                level: level,
                                isLocked: isCategoryLevelLocked(level),
                                progressLabel: guidedPlayMode ? nil : GameCatalog.levelProgressLabel(for: level, category: category),
                                imageMaxHeight: imageMaxHeight,
                                onTap: {
                                    guard !isCategoryLevelLocked(level) else { return }
                                    // Activate intermission before `selectedLevel` so `onChange(of: showingGameList)` cannot
                                    // run level intro audio ahead of the level image + crowd sequence.
                                    selectedLevel = level
                                }
                            )
                            .frame(minHeight: tileHeight)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("level-picker")
        .onAppear {
            // Manual replay only: guided auto-play skips the level picker (and this prompt).
            guard !guidedPlayMode else { return }
            if UITestConfiguration.skipGameSelectionIntros {
                isAudioPlaying = false
                return
            }
            // Level picker should be tappable after the prompt finishes.
            // While the prompt is playing, we temporarily disable hit testing via `isAudioPlaying`.
            // Use speak() so we get the same fade-out as other intros and avoid a post-audio click.
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                // Short delay before re-enabling so UI update isn't tied to audio end (reduces perceived click).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isAudioPlaying = false
                    speechManager.onAudioFinished = nil
                }
            }
            speechManager.speak("choose-a-level")
        }
    }

    /// Main content: level picker or game cards.
    @ViewBuilder
    private var mainSelectionContent: some View {
        if selectedLevel == nil {
            levelPickerContent
        } else {
            gameCardsStack
        }
    }

    /// Extracted to reduce type-checker load on body.
    private var gameSelectionNavigationContent: some View {
        GameSelectionNavigationContent(
            category: category,
            selectedLevel: selectedLevel,
            gameSelectionTitle: gameSelectionTitle,
            hasNoGames: hasNoGames,
            selectedGameId: selectedGameId,
            showingGameList: showingGameList,
            showGameName: $showGameName,
            showMatchingGame: $showMatchingGame,
            showWeighGame: $showWeighGame,
            showBalanceGame: $showBalanceGame,
            showGuessGame: $showGuessGame,
            showFindMamaGame: $showFindMamaGame,
            showDinoLunchGame: $showDinoLunchGame,
            showDinoMatrixGame: $showDinoMatrixGame,
            showDinoAgesGame: $showDinoAgesGame,
            showDinoFormationsGame: $showDinoFormationsGame,
            showDinoHabitatsGame: $showDinoHabitatsGame,
            showDinoFloraGame: $showDinoFloraGame,
            showPteroFloraGame: $showPteroFloraGame,
            showPteroEggsGame: $showPteroEggsGame,
            showDinoFaunaGame: $showDinoFaunaGame,
            showDinoFossilHuntGame: $showDinoFossilHuntGame,
            showMeasureGame: $showMeasureGame,
            showWhoIsTallerGame: $showWhoIsTallerGame,
            showWackyGame: $showWackyGame,
            showToothacheGame: $showToothacheGame,
            showSmilingDinosGame: $showSmilingDinosGame,
            showDinoEggsGame: $showDinoEggsGame,
            showDinoToolsGame: $showDinoToolsGame,
            showRacingPeriodSelection: $showRacingPeriodSelection,
            showRacingGame: $showRacingGame,
            showDinoPushGame: $showDinoPushGame,
            showDinoPuzzleGame: $showDinoPuzzleGame,
            showPteroPuzzleGame: $showPteroPuzzleGame,
            showMarinePuzzleGame: $showMarinePuzzleGame,
            showMarineFloraGame: $showMarineFloraGame,
            showMarineEggsGame: $showMarineEggsGame,
            selectedGame: $selectedGame,
            currentGameConfig: $currentGameConfig,
            currentWeighConfig: $currentWeighConfig,
            currentBalanceConfig: $currentBalanceConfig,
            currentGuessConfig: $currentGuessConfig,
            currentFindMamaConfig: $currentFindMamaConfig,
            currentDinoLunchConfig: $currentDinoLunchConfig,
            currentDinoMatrixConfig: $currentDinoMatrixConfig,
            currentDinoAgesConfig: $currentDinoAgesConfig,
            currentDinoFormationsConfig: $currentDinoFormationsConfig,
            currentDinoHabitatsConfig: $currentDinoHabitatsConfig,
            currentDinoFloraConfig: $currentDinoFloraConfig,
            currentPteroFloraConfig: $currentPteroFloraConfig,
            currentPteroEggsConfig: $currentPteroEggsConfig,
            currentMarineFloraConfig: $currentMarineFloraConfig,
            currentMarineEggsConfig: $currentMarineEggsConfig,
            currentDinoFaunaConfig: $currentDinoFaunaConfig,
            currentDinoFossilHuntConfig: $currentDinoFossilHuntConfig,
            currentMeasureConfig: $currentMeasureConfig,
            currentWhoIsTallerConfig: $currentWhoIsTallerConfig,
            currentWackyConfig: $currentWackyConfig,
            currentToothacheConfig: $currentToothacheConfig,
            currentSmilingDinosConfig: $currentSmilingDinosConfig,
            currentDinoEggsConfig: $currentDinoEggsConfig,
            currentDinoToolsConfig: $currentDinoToolsConfig,
            currentRacingConfig: $currentRacingConfig,
            hasPlayedWelcome: $hasPlayedWelcome,
            speechManager: speechManager,
            isAudioPlaying: $isAudioPlaying,
            gameWalkIndex: $gameWalkIndex,
            landLevelIntermissionActive: $landLevelIntermissionActive,
            guidedPendingLevelAdvance: $guidedPendingLevelAdvance,
            guidedPlayMode: guidedPlayMode,
            onImmediatePostGameSheetDismissed: { maybeAutoAdvanceToNextLevelAfterGameDismissed() },
            onPostGameSheetDismissalCleanup: { runPostGameDismissalSideEffects() },
            onGuidedWalkFinished: { pendingGuidedAutoLaunch = true },
            content: AnyView(mainSelectionContent)
        )
    }

    /// Game cards list; single ForEach over catalog (shared UI). When category has no games for the selected level, show game-coming-soon image.
    /// Level header (back + title) stays with the list so layout is stable when returning from a game sheet.
    /// Sizes from available canvas so all games fit on one screen (same idea as category landing).
    @ViewBuilder
    private var gameCardsStack: some View {
        GeometryReader { geo in
            let games = gamesForCategory
            let cardCount = CGFloat(max(games.count, 1))
            let rowSpacing: CGFloat = 12
            let horizontalPadding: CGFloat = 20
            let headerHeight: CGFloat = 52
            let contentWidth = max(0, geo.size.width - horizontalPadding * 2)
            let verticalBudget = max(0, geo.size.height - headerHeight - 8)
            let cardHeight = max(
                GameCatalogImageMetrics.levelTwoListCardHeight,
                (verticalBudget - rowSpacing * max(cardCount - 1, 0)) / cardCount
            )
            let nameReserve: CGFloat = 8
            let imageSide = min(
                contentWidth * GameCatalogImageMetrics.listWidthFraction,
                max(
                    GameCatalogImageMetrics.levelTwoListGameImageSide,
                    cardHeight - nameReserve - 16
                )
            )
            let cardWidth = min(contentWidth, max(imageSide + 32, contentWidth * 0.92))

            VStack(spacing: rowSpacing) {
                if let level = selectedLevel {
                    levelHeaderView(level: level)
                        .id("levelHeader")
                        .frame(height: headerHeight)
                }
                if hasNoGames {
                    if ImageAssetCache.imageExists(named: "game-coming-soon") {
                        Image("game-coming-soon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: min(320, contentWidth), maxHeight: min(320, verticalBudget))
                            .padding(.vertical, 24)
                    } else {
                        Text("New games are coming soon")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    }
                    Spacer(minLength: 0)
                } else {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, gameType in
                        GameCard(
                            gameType: gameType,
                            icon: gameType.icon,
                            imageName: gameType.imageName,
                            isSelected: selectedGameId == gameType.id || (gameWalkIndex != nil && gameWalkIndex == index),
                            isIntroduced: hasIntroducedCurrentGameList || (gameWalkIndex == nil && !isAudioPlaying) || (gameWalkIndex != nil && index <= gameWalkIndex!),
                            showCompletionCheckmark: guidedPlayMode && GameCatalog.hasPlayed(gameType, category: category),
                            showName: showGameName && selectedGameId == gameType.id,
                            isDisabled: isAudioPlaying || !isCurrentCategoryGamePlayable(gameType),
                            imageSide: imageSide,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            onTap: { handleGameTap(gameType) }
                        )
                        .id(gameType.id)
                        .frame(height: cardHeight)
                        .accessibilityIdentifier(gameType.id.map { "game-\($0)" } ?? "game-unknown")
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Level header at top of game list (title + back). Nav bar is hidden on this screen so sheet dismiss does not leave an empty bar that steals list height.
    private func levelHeaderView(level: GameLevel) -> some View {
        LevelGameListHeader(
            title: level.gameListTitle,
            backDisabled: gameSelectionBackDisabled,
            onBack: handleGameSelectionBack
        )
    }
    
    var body: some View {
        ZStack {
            Group {
                if showGameTransition, let imageName = transitionGameImage {
                    GameTransitionView(
                        imageName: imageName,
                        audioFile: transitionAudioFile ?? "",
                        compact: guidedPlayMode,
                        onComplete: {
                            DispatchQueue.main.async {
                                presentSheetForSelectedGame()
                                showGameTransition = false
                            }
                        }
                    )
                } else {
                    gameSelectionNavigationContent
                }
            }

            if landLevelIntermissionActive, let level = selectedLevel, !showGameTransition {
                LandLevelIntermissionView(category: category, level: level, compact: guidedPlayMode) {
                    isAudioPlaying = true
                    landLevelIntermissionActive = false
                }
                .zIndex(10)
            }

            if guidedCategoryCompletionActive, !showGameTransition {
                CategoryGuidedCompletionView(category: category) {
                    completeGuidedCategoryCelebrationAndReturnToMenu()
                }
                .zIndex(11)
            }
        }
        .toolbar {
            if selectedLevel == nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleGameSelectionBack) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(gameSelectionBackDisabled)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedLevel) { _, newLevel in
            // So the game-name walk runs for each level when the list changes (non-readers memorize by hearing names).
            lastCompletedGameForGuidedAdvance = nil
            if newLevel != nil {
                if UITestConfiguration.skipGameSelectionIntros {
                    hasPlayedWelcome = true
                    isAudioPlaying = false
                    landLevelIntermissionActive = false
                } else {
                    hasPlayedWelcome = false
                    isAudioPlaying = true
                    landLevelIntermissionActive = true
                }
                if guidedPlayMode {
                    persistPlaySession(gameCanonicalId: nil)
                }
            } else {
                hasPlayedWelcome = false
                landLevelIntermissionActive = false
            }
        }
        .onChange(of: landLevelIntermissionActive) { _, active in
            if active {
                isAudioPlaying = true
                speechManager.stopCurrentAudio()
            }
        }
        // Land / marine / pterosaur completion → `UserDefaults` is handled by `*Progress.shared` notification observers
        // so progress still updates if this view is off-screen during sheet dismiss or transition.
        .onAppear {
            applyGuidedEntryIfNeeded()
            if CategoryPlaySession.shouldSkipGuidedLevelIntro(for: category) {
                pendingGuidedAutoLaunch = true
            }
        }
        .onChange(of: pendingGuidedAutoLaunch) { _, shouldLaunch in
            guard shouldLaunch else { return }
            pendingGuidedAutoLaunch = false
            DispatchQueue.main.asyncAfter(deadline: .now() + (guidedPlayMode ? 0.35 : 0.15)) {
                autoLaunchNextGuidedGame()
            }
        }
    }

    private func handleGameTap(_ gameType: GameType) {
        guard !isAudioPlaying && !showGameTransition else { return }
        guard isCurrentCategoryGamePlayable(gameType) else { return }
        if let level = selectedLevel {
            levelWasFullyPlayedWhenGameOpened = isCatalogLevelFullyPlayed(level)
        } else {
            levelWasFullyPlayedWhenGameOpened = false
        }

        if guidedPlayMode {
            lastCompletedGameForGuidedAdvance = nil
        }
        // Store the selected game
        selectedGame = gameType
        if guidedPlayMode, let canonical = GameCatalog.canonicalId(for: gameType, category: category) {
            persistPlaySession(gameCanonicalId: canonical)
        }
        currentGameConfig = gameType.gameConfig
        // Weigh game: use random set of 9 (dinosaurs or pterosaurs) based on which game was tapped
        if let weighConfig = gameType.weighConfig {
            switch weighConfig.id {
            case "weigh-pterosaur":
                currentWeighConfig = WeighGameConfigs.weighPterosaurRandomized()
            case "weigh-marine-reptile":
                currentWeighConfig = WeighGameConfigs.weighMarineReptileRandomized()
            default:
                currentWeighConfig = WeighGameConfigs.weighDinosaurRandomized()
            }
        } else {
            currentWeighConfig = nil
        }
        if let balanceConfig = gameType.balanceConfig {
            currentBalanceConfig = balanceConfig.id == "balance-the-pterosaur"
                ? BalanceGameConfigs.balancePterosaurRandomized()
                : BalanceGameConfigs.balanceDinosaurRandomized()
        } else {
            currentBalanceConfig = nil
        }
        currentGuessConfig = gameType.guessConfig
        currentFindMamaConfig = gameType.findMamaConfig != nil ? FindMamaConfigs.findMama : nil
        currentDinoLunchConfig = gameType.dinoLunchConfig != nil ? DinoLunchConfigs.dinoLunch : nil
        currentWackyConfig = gameType.wackyConfig
        currentToothacheConfig = gameType.toothacheConfig
        currentSmilingDinosConfig = gameType.smilingDinosConfig
        currentDinoEggsConfig = gameType.dinoEggsConfig
        currentDinoToolsConfig = gameType.dinoToolsConfig
        currentDinoMatrixConfig = gameType.matrixGameConfig
        currentDinoAgesConfig = gameType.dinoAgesConfig
        currentDinoFormationsConfig = gameType.dinoFormationsConfig
        currentDinoHabitatsConfig = gameType.dinoHabitatsConfig
        currentDinoFloraConfig = gameType.dinoFloraConfig
        currentPteroFloraConfig = gameType.pteroFloraConfig
        currentPteroEggsConfig = gameType.pteroEggsConfig
        currentMarineFloraConfig = gameType.marineFloraConfig
        currentMarineEggsConfig = gameType.marineEggsConfig
        currentDinoFaunaConfig = gameType.dinoFaunaConfig
        currentDinoFossilHuntConfig = gameType.dinoFossilHuntConfig
        currentMeasureConfig = gameType.measureConfig
        currentWhoIsTallerConfig = gameType.whoIsTallerConfig.map { WhoIsTallerGameConfigs.randomized(from: $0) }

        // Use game-{slug} for transition intro (same as walk)
        transitionGameImage = gameType.imageName
        transitionAudioFile = gameType.introAudioKey
        
        // Fade out current screen, then show transition
        withAnimation(.easeOut(duration: 0.3)) {
            showGameTransition = true
        }
    }
}

// MARK: - GameSelectionNavigationContent (extracted to reduce type-checker load)

private struct GameSelectionNavigationContent: View {
    let category: GameCategory
    let selectedLevel: GameLevel?
    let gameSelectionTitle: String
    let hasNoGames: Bool
    let selectedGameId: String?
    let showingGameList: Bool
    @Binding var showGameName: Bool
    @Binding var showMatchingGame: Bool
    @Binding var showWeighGame: Bool
    @Binding var showBalanceGame: Bool
    @Binding var showGuessGame: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var showFindMamaGame: Bool
    @Binding var showDinoLunchGame: Bool
    @Binding var showDinoMatrixGame: Bool
    @Binding var showDinoAgesGame: Bool
    @Binding var showDinoFormationsGame: Bool
    @Binding var showDinoHabitatsGame: Bool
    @Binding var showDinoFloraGame: Bool
    @Binding var showPteroFloraGame: Bool
    @Binding var showPteroEggsGame: Bool
    @Binding var showDinoFaunaGame: Bool
    @Binding var showDinoFossilHuntGame: Bool
    @Binding var showMeasureGame: Bool
    @Binding var showWhoIsTallerGame: Bool
    @Binding var showWackyGame: Bool
    @Binding var showToothacheGame: Bool
    @Binding var showSmilingDinosGame: Bool
    @Binding var showDinoEggsGame: Bool
    @Binding var showDinoToolsGame: Bool
    @Binding var showRacingPeriodSelection: Bool
    @Binding var showRacingGame: Bool
    @Binding var showDinoPushGame: Bool
    @Binding var showDinoPuzzleGame: Bool
    @Binding var showPteroPuzzleGame: Bool
    @Binding var showMarinePuzzleGame: Bool
    @Binding var showMarineFloraGame: Bool
    @Binding var showMarineEggsGame: Bool
    @Binding var selectedGame: GameType?
    @Binding var currentGameConfig: MatchingGameConfig?
    @Binding var currentWeighConfig: WeighGameConfig?
    @Binding var currentBalanceConfig: BalanceGameConfig?
    @Binding var currentGuessConfig: GuessGameConfig?
    @Binding var currentFindMamaConfig: FindMamaConfig?
    @Binding var currentDinoLunchConfig: DinoLunchConfig?
    @Binding var currentDinoMatrixConfig: DinoMatrixGameConfig?
    @Binding var currentDinoAgesConfig: DinoAgesGameConfig?
    @Binding var currentDinoFormationsConfig: DinoFormationsGameConfig?
    @Binding var currentDinoHabitatsConfig: DinoHabitatsGameConfig?
    @Binding var currentDinoFloraConfig: DinoFloraGameConfig?
    @Binding var currentPteroFloraConfig: PteroFloraGameConfig?
    @Binding var currentPteroEggsConfig: PteroEggsGameConfig?
    @Binding var currentMarineFloraConfig: MarineFloraGameConfig?
    @Binding var currentMarineEggsConfig: MarineEggsGameConfig?
    @Binding var currentDinoFaunaConfig: DinoFaunaGameConfig?
    @Binding var currentDinoFossilHuntConfig: DinoFossilHuntGameConfig?
    @Binding var currentMeasureConfig: MeasureGameConfig?
    @Binding var currentWhoIsTallerConfig: WhoIsTallerGameConfig?
    @Binding var currentWackyConfig: WackyGameConfig?
    @Binding var currentToothacheConfig: ToothacheGameConfig?
    @Binding var currentSmilingDinosConfig: SmilingDinosGameConfig?
    @Binding var currentDinoEggsConfig: DinoEggsGameConfig?
    @Binding var currentDinoToolsConfig: DinoToolsGameConfig?
    @Binding var currentRacingConfig: RacingGameConfig?
    @Binding var hasPlayedWelcome: Bool
    let speechManager: SpeechManager
    @Binding var isAudioPlaying: Bool
    @Binding var gameWalkIndex: Int?
    @Binding var landLevelIntermissionActive: Bool
    @Binding var guidedPendingLevelAdvance: Bool
    let guidedPlayMode: Bool
    /// Runs as soon as a game sheet flag clears (before settle delay) so level-up intermission can cover the list.
    let onImmediatePostGameSheetDismissed: () -> Void
    let onPostGameSheetDismissalCleanup: () -> Void
    let onGuidedWalkFinished: () -> Void
    let content: AnyView
    @AppStorage("introducedGameListKeysCSV") private var introducedGameListKeysCSV = ""

    /// Bumped to scroll the game list to the level header (fixes stuck offset after game walk or when replaying level intro).
    @State private var gameListScrollToTopToken: Int = 0

    private var noOtherGameShowing: Bool {
        !showMatchingGame && !showWeighGame && !showBalanceGame && !showGuessGame &&
        !showFindMamaGame && !showDinoLunchGame && !showDinoMatrixGame && !showDinoAgesGame && !showDinoFormationsGame && !showDinoHabitatsGame && !showDinoFloraGame && !showPteroFloraGame && !showPteroEggsGame && !showDinoFaunaGame && !showMeasureGame && !showWhoIsTallerGame && !showWackyGame && !showToothacheGame && !showSmilingDinosGame && !showDinoEggsGame &&
        !showRacingGame && !showRacingPeriodSelection && !showDinoPushGame && !showDinoPuzzleGame && !showPteroPuzzleGame && !showMarinePuzzleGame && !showMarineFloraGame && !showMarineEggsGame && !showDinoToolsGame && !showDinoFossilHuntGame
    }

    /// Delay before handling game sheet dismiss (guided auto-play uses a shorter settle across land, air, and marine).
    private var gameSheetDismissSettleDelay: TimeInterval { guidedPlayMode ? 0.04 : 0.1 }

    private func scheduleAfterGameSheetDismissed(_ action: @escaping () -> Void) {
        // Level-up intermission must start on this turn — waiting for settle delay flashes the completed level list.
        onImmediatePostGameSheetDismissed()
        DispatchQueue.main.asyncAfter(deadline: .now() + gameSheetDismissSettleDelay, execute: action)
    }

    private func scrollGameListToTop(proxy: ScrollViewProxy) {
        guard selectedLevel != nil else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("levelHeader", anchor: .top)
            }
        }
    }

    /// Called from sheet-dismiss handlers (after the same delay as state reset). Runs level-up advance if applicable, then scrolls the list to the level header; avoids relying on `onChange` of the derived `noOtherGameShowing` flag, which can miss updates.
    /// Skip level intro replay when guided auto-play finished the whole category (Dinosaurs, Pterosaurs, or Marine Reptiles).
    private func shouldReplayLevelIntroAfterGameDismissed() -> Bool {
        CategoryGuidedCompletion.shouldReplayLevelIntroAfterGameDismissed(
            guidedPlayMode: guidedPlayMode,
            categoryFullyPlayed: GameCatalog.isCategoryFullyPlayed(category)
        )
    }

    private func runPostGameSheetDismissalSideEffects() {
        onPostGameSheetDismissalCleanup()
        if CategoryGuidedCompletion.shouldSkipPostGameSheetAudioReset(
            guidedPlayMode: guidedPlayMode,
            categoryFullyPlayed: GameCatalog.isCategoryFullyPlayed(category)
        ) {
            gameWalkIndex = nil
            return
        }
        if shouldReplayLevelIntroAfterGameDismissed() {
            // Guided: same-level → next game directly; level-up → intermission + level intro + game walk.
            if guidedPlayMode && !guidedPendingLevelAdvance {
                onGuidedWalkFinished()
            } else {
                hasPlayedWelcome = false
            }
        } else {
            speechManager.stopCurrentAudio()
            speechManager.onAudioFinished = nil
            isAudioPlaying = false
            gameWalkIndex = nil
        }
        bumpGameListScrollToHeaderAfterSheetDismissed()
    }

    private func bumpGameListScrollToHeaderAfterSheetDismissed() {
        guard selectedLevel != nil else { return }
        gameListScrollToTopToken &+= 1
    }

    private var currentGameListIntroductionKey: String? {
        guard let level = selectedLevel else { return nil }
        return "\(category.rawValue)-\(level.rawValue)"
    }

    private var introducedGameListKeys: Set<String> {
        Set(
            introducedGameListKeysCSV
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    private var hasIntroducedCurrentGameList: Bool {
        guard let key = currentGameListIntroductionKey else { return false }
        return introducedGameListKeys.contains(key)
    }

    private func markCurrentGameListIntroduced() {
        guard let key = currentGameListIntroductionKey else { return }
        var updated = introducedGameListKeys
        guard !updated.contains(key) else { return }
        updated.insert(key)
        introducedGameListKeysCSV = updated.sorted().joined(separator: ",")
    }

    /// No nested `NavigationView` here: `GameSelectionView` is already inside `CategorySelectionView`’s `NavigationStack`.
    /// An inner navigation container caused two UIKit nav controllers to observe the same `HostingScrollView` (console:
    /// “UIScrollView does not support multiple observers implementing _observeScrollView:willEndDragging…”).
    private var navigationContent: some View {
        ScrollViewReader { proxy in
            Group {
                if selectedLevel != nil {
                    // Level game list fills the canvas (GeometryReader inside gameCardsStack).
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Level picker also fills the canvas (2×2 GeometryReader inside levelPickerContent).
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: gameListScrollToTopToken) { _, _ in
                scrollGameListToTop(proxy: proxy)
            }
            .onChange(of: gameWalkIndex) { oldIndex, newValue in
                if let idx = newValue {
                    let games = GameCatalog.games(for: category, level: selectedLevel)
                    let targetId: String
                    if idx == 0, selectedLevel != nil {
                        targetId = "levelHeader"
                    } else if idx < games.count, let id = games[idx].id {
                        targetId = id
                    } else {
                        return
                    }
                    func doScroll() {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(targetId, anchor: idx == 0 && selectedLevel != nil ? .top : .center)
                        }
                    }
                    DispatchQueue.main.async { doScroll() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { doScroll() }
                } else if oldIndex != nil, selectedLevel != nil {
                    scrollGameListToTop(proxy: proxy)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(selectedLevel == nil ? .automatic : .hidden, for: .navigationBar)
        .toolbar {
            if selectedLevel == nil {
                ToolbarItem(placement: .principal) {
                    Text(gameSelectionTitle)
                        .font(horizontalSizeClass == .regular ? .title2.weight(.semibold) : .headline)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }

    /// Gameplay uses fullScreenCover so iPad does not float a page sheet over the level list.
    private var contentWithSheets: some View {
        navigationContent
            .fullScreenCover(isPresented: $showMatchingGame) {
                NavigationStack {
                // Dino Diets!: always pass a fresh diet config so right side shows diets (dino-diets- images + Diets audio), not dinosaur characteristics
                if selectedGameId == "match-the-diet" {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.dinoDietFeatures)
                } else if selectedGameId == "ptero-diets" {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.pteroDietFeatures)
                } else if selectedGameId == "marine-diets" {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.marineDietFeatures)
                } else if let config = currentGameConfig {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: config)
                } else {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.dinoFeatures)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showWeighGame) {
                NavigationStack {
                if let config = currentWeighConfig {
                    WeighGameView(isPresented: $showWeighGame, gameConfig: config)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showBalanceGame) {
                NavigationStack {
                if let config = currentBalanceConfig {
                    BalanceGameView(isPresented: $showBalanceGame, gameConfig: config)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showGuessGame) {
                NavigationStack {
                if let config = currentGuessConfig {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: config)
                } else {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: GuessGameConfigs.nameThatDinosaur)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showFindMamaGame) {
                NavigationStack {
                if let config = currentFindMamaConfig {
                    FindMamaGameView(isPresented: $showFindMamaGame, gameConfig: config)
                } else {
                    FindMamaGameView(isPresented: $showFindMamaGame, gameConfig: FindMamaConfigs.findMama)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoLunchGame) {
                NavigationStack {
                if let config = currentDinoLunchConfig {
                    DinoLunchGameView(isPresented: $showDinoLunchGame, gameConfig: config)
                } else {
                    DinoLunchGameView(isPresented: $showDinoLunchGame, gameConfig: DinoLunchConfigs.dinoLunch)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showWackyGame) {
                NavigationStack {
                if let config = currentWackyConfig {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: config)
                } else {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: WackyGameConfigs.wackyDinosaurs)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showToothacheGame) {
                NavigationStack {
                if let config = currentToothacheConfig {
                    ToothacheGameView(isPresented: $showToothacheGame, gameConfig: config)
                } else {
                    ToothacheGameView(isPresented: $showToothacheGame, gameConfig: ToothacheGameConfigs.toothache)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showSmilingDinosGame) {
                NavigationStack {
                if let config = currentSmilingDinosConfig {
                    SmilingDinosGameView(isPresented: $showSmilingDinosGame, gameConfig: config)
                } else {
                    SmilingDinosGameView(isPresented: $showSmilingDinosGame, gameConfig: SmilingDinosGameConfigs.config(for: category))
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoEggsGame) {
                NavigationStack {
                if let config = currentDinoEggsConfig {
                    DinoEggsGameView(isPresented: $showDinoEggsGame, gameConfig: config)
                } else {
                    DinoEggsGameView(isPresented: $showDinoEggsGame, gameConfig: DinoEggsGameConfigs.dinoEggs)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoToolsGame) {
                NavigationStack {
                if let config = currentDinoToolsConfig {
                    DinoToolsGameView(isPresented: $showDinoToolsGame, gameConfig: config)
                } else {
                    DinoToolsGameView(isPresented: $showDinoToolsGame, gameConfig: DinoToolsGameConfigs.dinoTools)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showRacingPeriodSelection) {
                NavigationStack {
                RacingPeriodSelectionView(isPresented: $showRacingPeriodSelection, onSelectPeriod: { config in
                    currentRacingConfig = config
                    showRacingPeriodSelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRacingGame = true
                    }
                })
            
                }
            }
            .fullScreenCover(isPresented: $showRacingGame) {
                NavigationStack {
                if let config = currentRacingConfig {
                    RacingGameView(isPresented: $showRacingGame, gameConfig: config)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoMatrixGame) {
                NavigationStack {
                if let config = currentDinoMatrixConfig {
                    DinoMatrixGameView(isPresented: $showDinoMatrixGame, gameConfig: config)
                } else {
                    DinoMatrixGameView(isPresented: $showDinoMatrixGame, gameConfig: DinoMatrixGameConfigs.dinoMatrix)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoAgesGame) {
                NavigationStack {
                if let config = currentDinoAgesConfig {
                    DinoAgesGameView(isPresented: $showDinoAgesGame, gameConfig: config)
                } else {
                    DinoAgesGameView(
                        isPresented: $showDinoAgesGame,
                        gameConfig: DinoAgesGameConfigs.config(for: category)
                    )
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoFormationsGame) {
                NavigationStack {
                if let config = currentDinoFormationsConfig {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: config)
                } else {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: DinoFormationsGameConfigs.dinoFormations)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoHabitatsGame) {
                NavigationStack {
                if let config = currentDinoHabitatsConfig {
                    DinoHabitatsGameView(isPresented: $showDinoHabitatsGame, gameConfig: config)
                } else {
                    DinoHabitatsGameView(isPresented: $showDinoHabitatsGame, gameConfig: DinoHabitatsGameConfigs.dinoHabitats)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoFloraGame) {
                NavigationStack {
                if let config = currentDinoFloraConfig {
                    DinoFloraGameView(isPresented: $showDinoFloraGame, gameConfig: config)
                } else {
                    DinoFloraGameView(isPresented: $showDinoFloraGame, gameConfig: DinoFloraGameConfigs.dinoFlora)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showPteroFloraGame) {
                NavigationStack {
                if let config = currentPteroFloraConfig {
                    PteroFloraGameView(isPresented: $showPteroFloraGame, gameConfig: config)
                } else {
                    PteroFloraGameView(isPresented: $showPteroFloraGame, gameConfig: PteroFloraGameConfigs.pteroFloraKarabastau)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showPteroEggsGame) {
                NavigationStack {
                if let config = currentPteroEggsConfig {
                    PteroEggsGameView(isPresented: $showPteroEggsGame, gameConfig: config)
                } else {
                    PteroEggsGameView(isPresented: $showPteroEggsGame, gameConfig: PteroEggsGameConfigs.pteroEggs)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoFaunaGame) {
                NavigationStack {
                if let config = currentDinoFaunaConfig {
                    DinoFaunaGameView(isPresented: $showDinoFaunaGame, gameConfig: config)
                } else {
                    DinoFaunaGameView(isPresented: $showDinoFaunaGame, gameConfig: DinoFaunaGameConfigs.dinoFauna)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoFossilHuntGame) {
                NavigationStack {
                if let config = currentDinoFossilHuntConfig {
                    DinoFossilHuntGameView(isPresented: $showDinoFossilHuntGame, gameConfig: config)
                } else {
                    DinoFossilHuntGameView(isPresented: $showDinoFossilHuntGame, gameConfig: DinoFossilHuntGameConfigs.dinoFossilHunt)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showMeasureGame) {
                NavigationStack {
                if let config = currentMeasureConfig {
                    MeasureGameView(isPresented: $showMeasureGame, gameConfig: config)
                } else {
                    MeasureGameView(isPresented: $showMeasureGame, gameConfig: MeasureGameConfigs.measureDinosaur)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showWhoIsTallerGame) {
                NavigationStack {
                if let config = currentWhoIsTallerConfig {
                    WhoIsTallerGameView(isPresented: $showWhoIsTallerGame, gameConfig: config)
                } else {
                    WhoIsTallerGameView(isPresented: $showWhoIsTallerGame, gameConfig: WhoIsTallerGameConfigs.whoIsTallerRandomized())
                }
            
                }
            }
            .fullScreenCover(isPresented: $showDinoPushGame) {
                NavigationStack {
                DinoPushGameView(isPresented: $showDinoPushGame, gameConfig: DinoPushGameConfigs.dinoPushNeedsPeriod)
            
                }
            }
            .fullScreenCover(isPresented: $showDinoPuzzleGame) {
                NavigationStack {
                DinoPuzzleGameView(isPresented: $showDinoPuzzleGame, gameConfig: DinoPuzzleGameConfigs.dinoPuzzle)
            
                }
            }
            .fullScreenCover(isPresented: $showPteroPuzzleGame) {
                NavigationStack {
                PteroPuzzleGameView(isPresented: $showPteroPuzzleGame, gameConfig: PteroPuzzleGameConfigs.pteroPuzzle)
            
                }
            }
            .fullScreenCover(isPresented: $showMarinePuzzleGame) {
                NavigationStack {
                MarineReptilePuzzleGameView(isPresented: $showMarinePuzzleGame, gameConfig: MarineReptilePuzzleGameConfigs.marinePuzzle)
            
                }
            }
            .fullScreenCover(isPresented: $showMarineFloraGame) {
                NavigationStack {
                if let config = currentMarineFloraConfig {
                    MarineFloraGameView(isPresented: $showMarineFloraGame, gameConfig: config)
                } else {
                    MarineFloraGameView(isPresented: $showMarineFloraGame, gameConfig: MarineFloraGameConfigs.marineFlora)
                }
            
                }
            }
            .fullScreenCover(isPresented: $showMarineEggsGame) {
                NavigationStack {
                if let config = currentMarineEggsConfig {
                    MarineEggsGameView(isPresented: $showMarineEggsGame, gameConfig: config)
                } else {
                    if let config = MarineEggsGameConfigs.makeMarineEggs() {
                        MarineEggsGameView(isPresented: $showMarineEggsGame, gameConfig: config)
                    } else {
                        Text("Marine Eggs is not available yet.")
                            .padding()
                    }
                }
            
                }
            }
    }

    private var contentWithOnChangeStep1: some View {
        contentWithSheets
            .onChange(of: showMatchingGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentGameConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    if let gameType = selectedGame, gameType.gameConfig != nil {
                        switch gameType.gameConfig?.id {
                        case "match-the-pterosaur":
                            currentGameConfig = MatchingGameConfigs.pterosaurFeatures
                        case "ptero-diets":
                            currentGameConfig = MatchingGameConfigs.pteroDietFeatures
                        case "marine-diets":
                            currentGameConfig = MatchingGameConfigs.marineDietFeatures
                        case "match-the-diet":
                            currentGameConfig = MatchingGameConfigs.dinoDietFeatures
                        default:
                            currentGameConfig = MatchingGameConfigs.dinoFeatures
                        }
                    }
                }
            }
            .onChange(of: showWeighGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWeighConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showBalanceGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentBalanceConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
    }

    private var contentWithOnChangeStep2: some View {
        contentWithOnChangeStep1
            .onChange(of: showGuessGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentGuessConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    // Use config already set by handleGameTap (Name That Dinosaur vs Name That Pterosaur)
                    if currentGuessConfig == nil {
                        currentGuessConfig = GuessGameConfigs.nameThatDinosaur
                    }
                }
            }
            .onChange(of: showFindMamaGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentFindMamaConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentFindMamaConfig = FindMamaConfigs.findMama
                }
            }
            .onChange(of: showDinoLunchGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoLunchConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoLunchConfig = DinoLunchConfigs.dinoLunch
                }
            }
    }

    private var contentWithOnChangeStep3: some View {
        contentWithOnChangeStep2
            .onChange(of: showWackyGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWackyConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showToothacheGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentToothacheConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentToothacheConfig = ToothacheGameConfigs.toothache
                }
            }
            .onChange(of: showSmilingDinosGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentSmilingDinosConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentSmilingDinosConfig = SmilingDinosGameConfigs.config(for: category)
                }
            }
            .onChange(of: showDinoEggsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoEggsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoEggsConfig = DinoEggsGameConfigs.dinoEggs
                }
            }
            .onChange(of: showDinoToolsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoToolsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoToolsConfig = DinoToolsGameConfigs.dinoTools
                }
            }
            .onChange(of: showRacingPeriodSelection) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !showRacingGame && !showRacingPeriodSelection {
                            selectedGame = nil
                            showGameName = false
                            currentRacingConfig = nil
                        }
                    }
                }
            }
    }

    private var contentWithOnChangeStep4: some View {
        contentWithOnChangeStep3
            .onChange(of: showRacingGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        selectedGame = nil
                        showGameName = false
                        currentRacingConfig = nil
                        runPostGameSheetDismissalSideEffects()
                    }
                }
            }
            .onChange(of: showDinoPushGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showDinoPuzzleGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showPteroPuzzleGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showMarinePuzzleGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showMarineFloraGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentMarineFloraConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if currentMarineFloraConfig == nil {
                    if let game = selectedGame, let c = game.marineFloraConfig {
                        currentMarineFloraConfig = c
                    } else {
                        currentMarineFloraConfig = MarineFloraGameConfigs.marineFlora
                    }
                }
            }
            .onChange(of: showMarineEggsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentMarineEggsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if currentMarineEggsConfig == nil {
                    if let game = selectedGame, let c = game.marineEggsConfig {
                        currentMarineEggsConfig = c
                    } else {
                        currentMarineEggsConfig = MarineEggsGameConfigs.makeMarineEggs()
                    }
                }
            }
            .onChange(of: showDinoMatrixGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoMatrixConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                }
            }
            .onChange(of: showDinoAgesGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoAgesConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoAgesConfig = DinoAgesGameConfigs.config(for: category)
                }
            }
            .onChange(of: showDinoFormationsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFormationsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoFormationsConfig = DinoFormationsGameConfigs.dinoFormations
                }
            }
    }

    /// Flora / fauna / fossil hunt / habitats / measure / taller — split from step 4 so the type checker stays fast.
    private var contentWithOnChangeStep5: some View {
        contentWithOnChangeStep4
            .onChange(of: showDinoFloraGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFloraConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoFloraConfig = DinoFloraGameConfigs.dinoFlora
                }
            }
            .onChange(of: showPteroFloraGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentPteroFloraConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if currentPteroFloraConfig == nil {
                    if let game = selectedGame, let c = game.pteroFloraConfig {
                        currentPteroFloraConfig = c
                    } else {
                        currentPteroFloraConfig = PteroFloraGameConfigs.pteroFloraKarabastau
                    }
                }
            }
            .onChange(of: showPteroEggsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentPteroEggsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if currentPteroEggsConfig == nil {
                    if let game = selectedGame, let c = game.pteroEggsConfig {
                        currentPteroEggsConfig = c
                    } else {
                        currentPteroEggsConfig = PteroEggsGameConfigs.pteroEggs
                    }
                }
            }
            .onChange(of: showDinoFaunaGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFaunaConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoFaunaConfig = DinoFaunaGameConfigs.dinoFauna
                }
            }
            .onChange(of: showDinoFossilHuntGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFossilHuntConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if currentDinoFossilHuntConfig == nil {
                    if let game = selectedGame, let c = game.dinoFossilHuntConfig {
                        currentDinoFossilHuntConfig = c
                    } else {
                        currentDinoFossilHuntConfig = DinoFossilHuntGameConfigs.dinoFossilHunt
                    }
                }
            }
            .onChange(of: showDinoHabitatsGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoHabitatsConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentDinoHabitatsConfig = DinoHabitatsGameConfigs.dinoHabitats
                }
            }
            .onChange(of: showMeasureGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentMeasureConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else {
                    currentMeasureConfig = MeasureGameConfigs.measureDinosaur
                }
            }
            .onChange(of: showWhoIsTallerGame) { _, newValue in
                if !newValue {
                    scheduleAfterGameSheetDismissed {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWhoIsTallerConfig = nil
                            runPostGameSheetDismissalSideEffects()
                        }
                    }
                } else if let w = selectedGame?.whoIsTallerConfig {
                    currentWhoIsTallerConfig = WhoIsTallerGameConfigs.randomized(from: w)
                }
            }
    }

    private var contentWithOnChange: some View {
        contentWithOnChangeStep5
    }

    var body: some View {
        contentWithOnChange
        .onAppear {
            runWelcomeAndWalkIfNeeded()
        }
        .onChange(of: showingGameList) { _, newValue in
            if newValue { runWelcomeAndWalkIfNeeded() }
        }
        .onChange(of: hasPlayedWelcome) { _, newValue in
            if !newValue, showingGameList { runWelcomeAndWalkIfNeeded() }
        }
        .onChange(of: landLevelIntermissionActive) { _, active in
            guard !active, showingGameList, !hasPlayedWelcome else { return }
            guard !(guidedPlayMode && GameCatalog.isCategoryFullyPlayed(category)) else { return }
            // Brief delay after overlay removal so layout/audio session settle; avoids level intro being skipped and the card walk stopping early.
            let settleDelay: TimeInterval = guidedPlayMode ? 0.08 : 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
                runWelcomeAndWalkIfNeeded()
            }
        }
        .allowsHitTesting(!isAudioPlaying)
    }

    private func runWelcomeAndWalkIfNeeded() {
        guard showingGameList, !hasPlayedWelcome else { return }
        if UITestConfiguration.skipGameSelectionIntros {
            hasPlayedWelcome = true
            isAudioPlaying = false
            speechManager.onAudioFinished = nil
            gameWalkIndex = nil
            return
        }
        if landLevelIntermissionActive { return }
        if guidedPlayMode && GameCatalog.isCategoryFullyPlayed(category) { return }
        if selectedLevel != nil {
            gameListScrollToTopToken &+= 1
        }
        hasPlayedWelcome = true
        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                if self.guidedPendingLevelAdvance {
                    self.guidedPendingLevelAdvance = false
                }
                if self.guidedPlayMode || !self.hasIntroducedCurrentGameList {
                    self.startGameWalk()
                } else {
                    self.isAudioPlaying = false
                    self.speechManager.onAudioFinished = nil
                }
            }
        }
        let introKey: String = {
            if let level = selectedLevel {
                return level.introAudioKey
            }
            switch category {
            case .land: return "choose-a-dinosaur-game"
            case .air: return "choose-a-pterosaur-game"
            case .marineReptiles: return "choose-a-marine-reptile-game"
            }
        }()
        speechManager.speak(introKey)
    }

    /// After category intro finishes, walk the game list: highlight each card and play its intro audio so children learn image ↔ name.
    private func startGameWalk() {
        let games = GameCatalog.games(for: category, level: selectedLevel)
        if games.isEmpty {
            isAudioPlaying = false
            speechManager.onAudioFinished = nil
            return
        }
        isAudioPlaying = true
        gameWalkIndex = 0
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                advanceGameWalk(index: 1, games: games)
            }
        }
        if let key = games[0].introAudioKey {
            speechManager.speak(key)
        } else {
            advanceGameWalk(index: 1, games: games)
        }
    }

    private func advanceGameWalk(index: Int, games: [GameType]) {
        if index >= games.count {
            if !guidedPlayMode {
                markCurrentGameListIntroduced()
            }
            gameWalkIndex = nil
            isAudioPlaying = false
            speechManager.onAudioFinished = nil
            if guidedPlayMode {
                onGuidedWalkFinished()
            }
            return
        }
        gameWalkIndex = index
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                advanceGameWalk(index: index + 1, games: games)
            }
        }
        if let key = games[index].introAudioKey {
            speechManager.speak(key)
        } else {
            advanceGameWalk(index: index + 1, games: games)
        }
    }
}

enum GameType {
    case matching(MatchingGameConfig) // Matching game configuration
    case weigh(WeighGameConfig) // Weigh game configuration
    case balance(BalanceGameConfig) // Balance the Dinosaurs
    case guess(GuessGameConfig) // Guess game configuration
    case findMama(FindMamaConfig) // Find Mama: return the egg to its mother
    case dinoLunch(DinoLunchConfig) // Dino Lunch!: match diet with dinosaur
    case wacky(WackyGameConfig) // Wacky Dinosaurs! etc.
    case toothache(ToothacheGameConfig) // Dino Toothache: match tooth to grumpy dinosaur
    case racing(RacingGameConfig) // Racing Dinosaurs!
    case dinoPush(DinoPushGameConfig) // Dino Push!: sumo-style face-off
    case dinoMatrix(DinoMatrixGameConfig) // Dino Matrix: identify matrix encasing fossil
    case pteroMatrix(DinoMatrixGameConfig) // Ptero Matrix: identify matrix encasing pterosaur fossil
    case marineMatrix(DinoMatrixGameConfig) // Marine Matrix: identify matrix encasing marine reptile fossil
    case dinoAges(DinoAgesGameConfig) // Dino Ages: when dinosaurs lived
    case dinoFormations(DinoFormationsGameConfig) // Dino Formations: dinosaurs found in named formation
    case dinoHabitats(DinoHabitatsGameConfig) // Dino Habitats: which dinosaur prefers this habitat
    case dinoFlora(DinoFloraGameConfig) // Dino Flora: which dinosaurs ate this plant
    case pteroFlora(PteroFloraGameConfig) // Ptero Flora!: which pterosaurs fit this plant
    case pteroEggs(PteroEggsGameConfig) // Ptero Eggs!: match pterosaurs to their eggs
    case dinoFauna(DinoFaunaGameConfig) // Dino Fauna: which dinosaurs fit this animal
    case measure(MeasureGameConfig) // Measure the Dinosaur!: stack to match height
    case whoIsTaller(WhoIsTallerGameConfig) // Which Dino Is Taller: compare two dinosaurs by height
    case smilingDinos(SmilingDinosGameConfig) // Dino Smile!: match dinosaur smiles to teeth
    case dinoEggs(DinoEggsGameConfig) // Dino Eggs!: match dinosaurs to their eggs
    case dinoTools(DinoToolsGameConfig) // Dino Tools!: magnify, SEM, scanner, pick dinosaur
    case dinoFossilHunt(DinoFossilHuntGameConfig) // Dino Fossil Hunt: story beats + pick 2 of 5 tools
    case dinoPuzzle(DinoPuzzleGameConfig) // Dino Puzzle: drag jigsaw pieces for three dinosaurs
    case pteroPuzzle(PteroPuzzleGameConfig) // Ptero Puzzle: drag jigsaw pieces for three pterosaurs
    case marineFlora(MarineFloraGameConfig) // Marine Flora!: which marine reptiles fit this plant
    case marineEggs(MarineEggsGameConfig) // Marine Eggs!: match marine reptiles to their eggs
    case marinePuzzle(MarineReptilePuzzleGameConfig) // Marine Reptile Puzzle: portrait jigsaw for three marine clades

    var name: String {
        switch self {
        case .matching(let config):
            return config.title
        case .weigh(let config):
            return config.title
        case .balance(let config):
            return config.title
        case .guess(let config):
            return config.title
        case .findMama(let config):
            return config.title
        case .dinoLunch(let config):
            return config.title
        case .wacky(let config):
            return config.title
        case .toothache(let config):
            return config.title
        case .racing(let config):
            return config.title
        case .dinoPush(let config):
            return config.title
        case .dinoMatrix(let config):
            return config.title
        case .pteroMatrix(let config):
            return config.title
        case .marineMatrix(let config):
            return config.title
        case .dinoAges(let config):
            return config.title
        case .dinoFormations(let config):
            return config.title
        case .dinoHabitats(let config):
            return config.title
        case .dinoFlora(let config):
            return config.title
        case .pteroFlora(let config):
            return config.title
        case .pteroEggs(let config):
            return config.title
        case .marineFlora(let config):
            return config.title
        case .marineEggs(let config):
            return config.title
        case .dinoFauna(let config):
            return config.title
        case .measure(let config):
            return config.title
        case .whoIsTaller(let config):
            return config.title
        case .smilingDinos(let config):
            return config.title
        case .dinoEggs(let config):
            return config.title
        case .dinoTools(let config):
            return config.title
        case .dinoFossilHunt(let config):
            return config.title
        case .dinoPuzzle(let config):
            return config.title
        case .pteroPuzzle(let config):
            return config.title
        case .marinePuzzle(let config):
            return config.title
        }
    }

    var description: String {
        switch self {
        case .matching(let config):
            switch config.id {
            case "match-the-diet": return "Match each dinosaur to its diet"
            case "ptero-diets": return "Match each pterosaur to its diet"
            case "marine-diets": return "Match each marine reptile to its diet"
            default: return "Match dinosaurs to their special features"
            }
        case .weigh:
            return "Compare weights on a seesaw"
        case .balance:
            return "Add dinosaurs to balance the seesaw"
        case .guess:
            return "Match silhouettes to dinosaurs"
        case .findMama:
            return "Return the lost egg to its worried mother"
        case .dinoLunch:
            return "Match the diet with the dinosaur"
        case .wacky:
            return "Wacky dinosaur fun!"
        case .toothache:
            return "Match the tooth to the grumpy dinosaur"
        case .racing(let config):
            if config.id.hasPrefix("racing-marine") { return "Race two marine reptiles around the buoys!" }
            if config.id.hasPrefix("racing-pterosaur") { return "Race two pterosaurs!" }
            return "Race two dinosaurs!"
        case .dinoPush:
            return "Sumo-style push face-off!"
        case .dinoMatrix:
            return "Identify the matrix material encasing the fossil"
        case .pteroMatrix:
            return "Identify the matrix material encasing the pterosaur fossil"
        case .marineMatrix:
            return "Identify the matrix material encasing the marine reptile fossil"
        case .dinoAges(let config):
            switch config.id {
            case "ptero-ages": return "Discover when pterosaurs lived"
            case "marine-ages": return "Discover when marine reptiles lived"
            default: return "Discover when dinosaurs lived"
            }
        case .dinoFormations:
            return "Pick dinosaurs found in the formation shown"
        case .dinoHabitats:
            return "Which dinosaur prefers this habitat?"
        case .dinoFlora:
            return "Which dinosaurs ate this plant?"
        case .pteroFlora:
            return "Which three pterosaurs fit this plant?"
        case .pteroEggs:
            return "Match pterosaurs to their eggs"
        case .marineFlora:
            return "Which three marine reptiles fit this plant?"
        case .marineEggs:
            return "Match marine reptiles to their eggs"
        case .dinoFauna:
            return "Which three dinosaurs fit this animal?"
        case .measure:
            return "Stack dinosaurs to match the reference height"
        case .whoIsTaller(let config):
            switch config.id {
            case "which-ptero-is-taller":
                return "Compare two pterosaurs to see which one is taller"
            case "which-marine-reptile-is-longer":
                return "Compare two marine reptiles to see which one is longer"
            default:
                return "Compare two dinosaurs to see which dino is taller"
            }
        case .smilingDinos(let config):
            return config.id == "ptero-smile"
                ? "Match pterosaur smiles to their beak shapes"
                : "Match dinosaur smiles to their teeth"
        case .dinoEggs:
            return "Match dinosaurs to their eggs"
        case .dinoTools:
            return "Use the tools, then pick the dinosaur that laid the egg"
        case .dinoFossilHunt:
            return "Follow the fossil quest—pick two tools for each step"
        case .dinoPuzzle:
            return "Drag pieces to rebuild each dinosaur picture"
        case .pteroPuzzle:
            return "Drag pieces to rebuild each pterosaur picture"
        case .marinePuzzle:
            return "Drag pieces to rebuild each marine reptile picture"
        }
    }

    var gameConfig: MatchingGameConfig? {
        switch self {
        case .matching(let config): return config
        case .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var weighConfig: WeighGameConfig? {
        switch self {
        case .weigh(let config): return config
        case .matching, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var balanceConfig: BalanceGameConfig? {
        switch self {
        case .balance(let config): return config
        case .matching, .weigh, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var guessConfig: GuessGameConfig? {
        switch self {
        case .guess(let config): return config
        case .matching, .weigh, .balance, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var findMamaConfig: FindMamaConfig? {
        switch self {
        case .findMama(let config): return config
        case .matching, .weigh, .balance, .guess, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoLunchConfig: DinoLunchConfig? {
        switch self {
        case .dinoLunch(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var wackyConfig: WackyGameConfig? {
        switch self {
        case .wacky(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var toothacheConfig: ToothacheGameConfig? {
        switch self {
        case .toothache(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var racingConfig: RacingGameConfig? {
        switch self {
        case .racing(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoPushConfig: DinoPushGameConfig? {
        switch self {
        case .dinoPush(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoMatrixConfig: DinoMatrixGameConfig? {
        switch self {
        case .dinoMatrix(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var pteroMatrixConfig: DinoMatrixGameConfig? {
        switch self {
        case .pteroMatrix(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var marineMatrixConfig: DinoMatrixGameConfig? {
        switch self {
        case .marineMatrix(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var matrixGameConfig: DinoMatrixGameConfig? {
        dinoMatrixConfig ?? pteroMatrixConfig ?? marineMatrixConfig
    }

    var dinoAgesConfig: DinoAgesGameConfig? {
        switch self {
        case .dinoAges(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoFormationsConfig: DinoFormationsGameConfig? {
        switch self {
        case .dinoFormations(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoHabitatsConfig: DinoHabitatsGameConfig? {
        switch self {
        case .dinoHabitats(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoFloraConfig: DinoFloraGameConfig? {
        switch self {
        case .dinoFlora(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var pteroFloraConfig: PteroFloraGameConfig? {
        switch self {
        case .pteroFlora(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var pteroEggsConfig: PteroEggsGameConfig? {
        switch self {
        case .pteroEggs(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoFaunaConfig: DinoFaunaGameConfig? {
        switch self {
        case .dinoFauna(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var measureConfig: MeasureGameConfig? {
        switch self {
        case .measure(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var whoIsTallerConfig: WhoIsTallerGameConfig? {
        switch self {
        case .whoIsTaller(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var smilingDinosConfig: SmilingDinosGameConfig? {
        switch self {
        case .smilingDinos(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoEggsConfig: DinoEggsGameConfig? {
        switch self {
        case .dinoEggs(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoToolsConfig: DinoToolsGameConfig? {
        switch self {
        case .dinoTools(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoFossilHuntConfig: DinoFossilHuntGameConfig? {
        switch self {
        case .dinoFossilHunt(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var dinoPuzzleConfig: DinoPuzzleGameConfig? {
        switch self {
        case .dinoPuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var pteroPuzzleConfig: PteroPuzzleGameConfig? {
        switch self {
        case .pteroPuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .marineFlora, .marineEggs, .marinePuzzle: return nil
        }
    }

    var marineFloraConfig: MarineFloraGameConfig? {
        switch self {
        case .marineFlora(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineEggs, .marinePuzzle: return nil
        }
    }

    var marineEggsConfig: MarineEggsGameConfig? {
        switch self {
        case .marineEggs(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marinePuzzle: return nil
        }
    }

    var marinePuzzleConfig: MarineReptilePuzzleGameConfig? {
        switch self {
        case .marinePuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoMatrix, .pteroMatrix, .marineMatrix, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroFlora, .pteroEggs, .pteroPuzzle, .marineFlora, .marineEggs: return nil
        }
    }

    /// Config id for this game type; used for selection state and ForEach identity.
    var id: String? {
        switch self {
        case .matching(let config): return config.id
        case .weigh(let config): return config.id
        case .balance(let config): return config.id
        case .guess(let config): return config.id
        case .findMama(let config): return config.id
        case .dinoLunch(let config): return config.id
        case .wacky(let config): return config.id
        case .toothache(let config): return config.id
        case .racing(let config): return config.id
        case .dinoPush(let config): return config.id
        case .dinoMatrix(let config): return config.id
        case .pteroMatrix(let config): return config.id
        case .marineMatrix(let config): return config.id
        case .dinoAges(let config): return config.id
        case .dinoFormations(let config): return config.id
        case .dinoHabitats(let config): return config.id
        case .dinoFlora(let config): return config.id
        case .pteroFlora(let config): return config.id
        case .pteroEggs(let config): return config.id
        case .marineFlora(let config): return config.id
        case .marineEggs(let config): return config.id
        case .dinoFauna(let config): return config.id
        case .measure(let config): return config.id
        case .whoIsTaller(let config): return config.id
        case .smilingDinos(let config): return config.id
        case .dinoEggs(let config): return config.id
        case .dinoTools(let config): return config.id
        case .dinoFossilHunt(let config): return config.id
        case .dinoPuzzle(let config): return config.id
        case .pteroPuzzle(let config): return config.id
        case .marinePuzzle(let config): return config.id
        }
    }

    var imageName: String {
        switch self {
        case .matching(let config):
            switch config.id {
            case "match-the-diet": return "game-dino-diets"
            case "ptero-diets": return "game-ptero-diets"
            case "marine-diets": return "game-marine-diets"
            default: return "game-\(config.id)"
            }
        case .weigh(let config):
            return config.id == "weigh-marine-reptile"
                ? "game-weigh-the-marine-reptile"
                : "game-\(config.id)"
        case .balance(let config):
            // Asset names use plural: game-balance-the-dinosaurs, game-balance-the-pterosaurs
            return config.id == "balance-the-pterosaur" ? "game-balance-the-pterosaurs" : "game-balance-the-dinosaurs"
        case .guess(let config):
            return "game-\(config.id)"
        case .findMama(let config):
            return "game-\(config.id)"
        case .dinoLunch(let config):
            return "game-\(config.id)"
        case .wacky(let config):
            return "game-\(config.id)"
        case .toothache(let config):
            return "game-\(config.id)"
        case .racing(let config):
            if config.id.hasPrefix("racing-marine") { return "game-racing-marine-reptiles" }
            if config.id.hasPrefix("racing-pterosaur") { return "game-racing-pterosaurs" }
            return "game-racing-dinosaurs"
        case .dinoPush(let config):
            return "game-\(config.id)"
        case .dinoMatrix(let config):
            return "game-\(config.id)"
        case .pteroMatrix(let config):
            return "game-\(config.id)"
        case .marineMatrix(let config):
            return "game-\(config.id)"
        case .dinoAges(let config):
            return "game-\(config.id)"
        case .dinoFormations(let config):
            return "game-\(config.id)"
        case .dinoHabitats(let config):
            return "game-\(config.id)"
        case .dinoFlora(let config):
            return "game-\(config.id)"
        case .pteroFlora(let config):
            return "game-\(config.id)"
        case .pteroEggs(let config):
            return "game-\(config.id)"
        case .marineFlora(let config):
            return "game-\(config.id)"
        case .marineEggs:
            return "game-marine-eggs"
        case .dinoFauna(let config):
            return "game-\(config.id)"
        case .measure(let config):
            return "game-\(config.id)"
        case .whoIsTaller(let config):
            return "game-\(config.id)"
        case .smilingDinos(let config):
            return config.introAudio
        case .dinoEggs:
            return "game-dino-eggs"
        case .dinoTools:
            return "game-dino-tools"
        case .dinoFossilHunt:
            return "game-dino-fossil-hunt"
        case .dinoPuzzle(let config):
            return "game-\(config.id)"
        case .pteroPuzzle(let config):
            return "game-\(config.id)"
        case .marinePuzzle:
            return "game-marine-reptile-puzzle"
        }
    }

    /// Emoji icon for the game card when no image asset is available; also used for accessibility.
    var icon: String {
        switch self {
        case .matching: return "🔗"
        case .weigh: return "⚖️"
        case .balance: return "⚖️"
        case .guess: return "🔍"
        case .findMama: return "🥚"
        case .dinoLunch: return "🍽️"
        case .wacky: return "🦕"
        case .toothache: return "🦷"
        case .racing: return "🏃"
        case .dinoPush: return "🤼"
        case .dinoMatrix: return "🪨"
        case .pteroMatrix: return "🪨"
        case .marineMatrix: return "🪨"
        case .dinoAges: return "🕐"
        case .dinoFormations: return "🪨"
        case .dinoHabitats: return "🌿"
        case .dinoFlora: return "🌿"
        case .pteroFlora: return "🌿"
        case .pteroEggs: return "🥚"
        case .marineFlora: return "🌿"
        case .marineEggs: return "🥚"
        case .dinoFauna: return "🦎"
        case .measure: return "📏"
        case .whoIsTaller: return "📏"
        case .smilingDinos: return "😁"
        case .dinoEggs: return "🥚"
        case .dinoTools: return "🔬"
        case .dinoFossilHunt: return "🦴"
        case .dinoPuzzle: return "🧩"
        case .pteroPuzzle: return "🧩"
        case .marinePuzzle: return "🧩"
        }
    }

    /// Audio key played when this game is highlighted during the "walk" (and on transition when tapping). File should be game-{slug}.m4a in Games/.
    var introAudioKey: String? {
        switch self {
        case .matching(let config):
            switch config.id {
            case "match-the-diet": return "game-dino-diets"
            case "ptero-diets": return "game-ptero-diets"
            case "marine-diets": return "game-marine-diets"
            default: return "game-\(config.id)"
            }
        case .weigh(let config):
            // Match card image / asset stem `game-weigh-the-marine-reptile` so the walk plays the same clip name users bundle with art.
            if config.id == "weigh-marine-reptile" { return "game-weigh-the-marine-reptile" }
            return "game-\(config.id)"
        case .balance(let config): return "game-\(config.id)"
        case .guess(let config): return "game-\(config.id)"
        case .findMama(let config): return "game-\(config.id)"
        case .dinoLunch(let config): return "game-\(config.id)"
        case .wacky(let config): return "game-\(config.id)"
        case .toothache(let config): return "game-\(config.id)"
        case .racing(let config):
            if config.id.hasPrefix("racing-marine") { return "game-racing-marine-reptiles" }
            if config.id.hasPrefix("racing-pterosaur") { return "game-racing-pterosaurs" }
            return "game-racing-dinosaurs"
        case .dinoPush(let config): return "game-\(config.id)"
        case .dinoMatrix(let config): return "game-\(config.id)"
        case .pteroMatrix(let config): return config.introAudio
        case .marineMatrix(let config): return config.introAudio
        case .dinoAges(let config): return config.introAudio
        case .dinoFormations(let config): return config.introAudio
        case .dinoHabitats(let config): return config.introAudio
        case .dinoFlora(let config): return config.introAudio
        case .pteroFlora(let config): return config.introAudio
        case .pteroEggs(let config): return config.introAudio
        case .marineFlora(let config): return config.introAudio
        case .marineEggs(let config): return config.introAudio
        case .dinoFauna(let config): return config.introAudio
        case .measure(let config): return config.introAudio
        case .whoIsTaller(let config): return config.introAudio
        case .smilingDinos(let config): return config.introAudio
        case .dinoEggs(let config): return config.introAudio
        case .dinoTools(let config): return config.introAudio
        case .dinoFossilHunt(let config): return config.introAudio
        case .dinoPuzzle(let config): return config.introAudio
        case .pteroPuzzle(let config): return config.introAudio
        case .marinePuzzle(let config): return config.introAudio
        }
    }
}

private struct LevelGameListHeader: View {
    let title: String
    let backDisabled: Bool
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font((horizontalSizeClass == .regular ? Font.title3 : Font.body).weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(backDisabled)

            Text(title)
                .font(horizontalSizeClass == .regular ? .title2.weight(.semibold) : .headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)

            // Balance chevron width so title stays centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }
}

private struct CategoryProgressLevelPickerHeader: View {
    let snapshot: CategoryProgressSnapshot
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesRegularTypography: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: usesRegularTypography ? 8 : 4) {
            Text(snapshot.category.categoryProgressMenuTitle)
                .font(usesRegularTypography ? .title.weight(.semibold) : .title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(snapshot.displayText)
                .font(usesRegularTypography ? .title2.weight(.semibold) : .title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("category-progress-header")
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }
}

// MARK: - Level card (2×2 when four levels ship; image above, text below)

private struct LevelCard: View {
    let category: GameCategory
    let level: GameLevel
    var isLocked: Bool = false
    var progressLabel: String? = nil
    /// Max height for level art; set by the picker so tiles fill available canvas.
    var imageMaxHeight: CGFloat = 80
    let onTap: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesRegularTypography: Bool {
        horizontalSizeClass == .regular
    }

    private var levelImageName: String {
        switch category {
        case .land:
            return level.imageName
        case .marineReptiles:
            let names = [
                "marine-level-one", "marine-level-two", "marine-level-three", "marine-level-four", "marine-level-five",
                "marine-level-six", "marine-level-seven", "marine-level-eight", "marine-level-nine", "marine-level-ten",
            ]
            return names[level.number - 1]
        case .air:
            return level.pterosaurLevelImageName
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: usesRegularTypography ? 12 : 8) {
                    if ImageAssetCache.imageExists(named: levelImageName) {
                        Image(levelImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: min(80, imageMaxHeight * 0.7), maxHeight: imageMaxHeight)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(minHeight: min(80, imageMaxHeight * 0.7), maxHeight: imageMaxHeight)
                            .overlay(
                                Text(level.title)
                                    .font(usesRegularTypography ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                            )
                    }
                    Text(level.title)
                        .font(usesRegularTypography ? .title3.weight(.semibold) : .subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let progressLabel {
                        Text(progressLabel)
                            .font(usesRegularTypography ? .body.weight(.semibold) : .caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("level-progress-\(level.rawValue)")
                    }
                }
                .padding(usesRegularTypography ? 16 : 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(isLocked ? 0.15 : 0.4), lineWidth: 2)
                )
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(usesRegularTypography ? .title3 : .caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .opacity(isLocked ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityIdentifier("level-\(level.rawValue)")
    }
}

/// Sizes for catalog game art vs name-that guess victory (list stays compact; end-sequence success reads larger).
enum GameCatalogImageMetrics {
    /// Phone-first catalog thumbnail floor when space is tight.
    static let levelTwoListGameImageSide: CGFloat = 180
    static let levelTwoListCardHeight: CGFloat = 210
    /// Cap relative to content width so squares stay proportional without forcing scroll.
    static let listWidthFraction: CGFloat = 0.55
    /// Name That Dinosaur / Pterosaur / Marine Reptile / Racing victory `game-*-success` (matches Match the Dinosaur / Weigh success treatment).
    /// Phone baseline; `StandardVictorySuccessImageView` grows this further on iPad within the success-phase frame.
    static let nameThatVictorySuccessImageSide: CGFloat = 360

    /// Phone reference width used by Weigh / Balance / play-area iPad scale.
    static let phoneReferenceWidth: CGFloat = 430

    /// Modest bump on wider canvases; keep phone at 1.0. Same formula as `WeighPlayAreaMetrics` grid scale.
    static func canvasScale(safeWidth: CGFloat, maxScale: CGFloat = 1.38) -> CGFloat {
        max(1, min(maxScale, safeWidth / phoneReferenceWidth))
    }

    /// Scale a phone-tuned point size for iPad without overgrowing.
    static func scaled(_ phoneSize: CGFloat, safeWidth: CGFloat, maxScale: CGFloat = 1.38) -> CGFloat {
        (phoneSize * canvasScale(safeWidth: safeWidth, maxScale: maxScale)).rounded()
    }
}

/// Shared 3×3 creature-portrait grid for gameplay pickers.
/// Used by Weigh / Which taller-longer / Measure / Balance select-heavy so land-air-sea stay aligned.
struct CreatureThreeByThreeGridMetrics {
    static let phoneImageSize: CGFloat = 96
    static let phoneLabelFontSize: CGFloat = 15
    /// Room for 2-line game title + "Round N of M" (56pt forced single-line ellipsis on long sea titles).
    static let phoneTitleBlockHeight: CGFloat = 80
    static let maxScale: CGFloat = 1.85

    let imageSize: CGFloat
    let labelFontSize: CGFloat
    let contentWidth: CGFloat
    let blockHeight: CGFloat
    let titleBlockHeight: CGFloat

    /// `reservedStageHeight` is the play area below the grid (seesaw, measure stage, etc).
    static func make(
        safeWidth: CGFloat,
        safeHeight: CGFloat,
        reservedStageHeight: CGFloat,
        chrome: CGFloat = 40,
        minimumGridBudget: CGFloat = 280
    ) -> CreatureThreeByThreeGridMetrics {
        let titleBlockHeight = phoneTitleBlockHeight
        let maxGridBudget = max(minimumGridBudget, safeHeight - reservedStageHeight - chrome)
        let widthScale = max(1, min(maxScale, safeWidth / GameCatalogImageMetrics.phoneReferenceWidth))
        var imageSize = (phoneImageSize * widthScale).rounded()
        var labelFontSize = (phoneLabelFontSize * min(widthScale, 1.35)).rounded()

        func rowHeight(image: CGFloat, label: CGFloat) -> CGFloat {
            image + 6 + max(18, label * 1.25) + 10
        }

        func blockHeight(image: CGFloat, label: CGFloat) -> CGFloat {
            titleBlockHeight + 6 + rowHeight(image: image, label: label) * 3 + 12
        }

        var computed = blockHeight(image: imageSize, label: labelFontSize)
        if computed > maxGridBudget {
            let rows: CGFloat = 3
            let fixed = titleBlockHeight + 6 + 12 + rows * (6 + 10)
            let perRowLabel = max(18, phoneLabelFontSize * min(widthScale, 1.35) * 1.25)
            let availableForImages = max(phoneImageSize * rows, maxGridBudget - fixed - rows * perRowLabel)
            imageSize = max(phoneImageSize, (availableForImages / rows).rounded())
            labelFontSize = (phoneLabelFontSize * min(imageSize / phoneImageSize, 1.35)).rounded()
            computed = blockHeight(image: imageSize, label: labelFontSize)
        }

        let contentWidth = min(
            safeWidth - 24,
            imageSize * 3 + 10 * 2 + 6 * 2 + 24
        )

        return CreatureThreeByThreeGridMetrics(
            imageSize: imageSize,
            labelFontSize: labelFontSize,
            contentWidth: contentWidth,
            blockHeight: min(computed, maxGridBudget),
            titleBlockHeight: titleBlockHeight
        )
    }
}


struct GameCard: View {
    let gameType: GameType
    let icon: String
    let imageName: String? // Optional image name from Assets.xcassets
    let isSelected: Bool
    /// True when this card has been introduced during the walk (or walk is done). Like category cards: all start dim, brighten when introduced, stay bright.
    let isIntroduced: Bool
    /// Guided first-play only: show a checkmark when this catalog game was completed earlier in the run.
    var showCompletionCheckmark: Bool = false
    let showName: Bool
    let isDisabled: Bool
    /// Explicit layout from the level list GeometryReader (fills iPad without exceeding three-up fit).
    var imageSide: CGFloat = GameCatalogImageMetrics.levelTwoListGameImageSide
    var cardWidth: CGFloat = 260
    var cardHeight: CGFloat = GameCatalogImageMetrics.levelTwoListCardHeight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    if let imageName = imageName, ImageAssetCache.imageExists(named: imageName) {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSide, height: imageSide)
                            .brightness(imageName == "game-name-that-dinosaur" ? 0.2 : 0)
                    } else {
                        Text(icon)
                            .font(.system(size: max(56, imageSide * 0.45)))
                    }

                    if showName {
                        Text(gameType.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 5)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: cardWidth, height: cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .opacity(isIntroduced ? 1.0 : 0.7)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
                .animation(.spring(response: 0.28), value: isIntroduced)
                .animation(.spring(response: 0.3), value: showName)

                if showCompletionCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.green)
                        .padding(10)
                        .accessibilityLabel("Completed")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Game Transition View

struct GameTransitionView: View {
    let imageName: String
    let audioFile: String
    /// Shorter tail delay after intro audio in guided auto-play (land, air, marine).
    var compact: Bool = false
    let onComplete: () -> Void
    
    @State private var speechManager = SpeechManager()
    @State private var hasPlayedAudio = false
    /// Safety: if intro audio never finishes (missing file, TTS glitch), still dismiss after this delay so the game never freezes.
    private let maxTransitionDuration: TimeInterval = 15

    private var postAudioDelay: TimeInterval { compact ? 0.12 : 0.5 }

    var body: some View {
        ZStack {
            // Background flush (white/clear)
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Full-size game image
                if ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    // Fallback if image not found
                    Text("Loading game...")
                        .font(.title)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if UITestConfiguration.skipGameSelectionIntros {
                onComplete()
                return
            }
            var didComplete = false
            let completeOnce: () -> Void = {
                guard !didComplete else { return }
                didComplete = true
                DispatchQueue.main.asyncAfter(deadline: .now() + postAudioDelay) { onComplete() }
            }

            // Safety timeout: ensure we never stay stuck on transition
            DispatchQueue.main.asyncAfter(deadline: .now() + maxTransitionDuration) { completeOnce() }

            if !hasPlayedAudio && !audioFile.isEmpty {
                hasPlayedAudio = true
                speechManager.onAudioFinished = { completeOnce() }
                speechManager.speak(audioFile)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + postAudioDelay) { completeOnce() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GameSelectionView(category: .land, guidedPlayMode: false, onReturnToCategoryMenu: {})
    }
}
