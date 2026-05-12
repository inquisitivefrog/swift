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
    @State private var showMatrixMaterialsGame = false
    @State private var showDinoAgesGame = false
    @State private var showDinoFormationsGame = false
    @State private var showDinoHabitatsGame = false
    @State private var showDinoFloraGame = false
    @State private var showDinoFaunaGame = false
    @State private var showDinoFossilHuntGame = false
    @State private var showMeasureGame = false
    @State private var showWhoIsTallerGame = false
    @State private var showDinoPushGame = false
    @State private var showDinoPuzzleGame = false
    @State private var showPteroPuzzleGame = false
    @State private var showMarinePuzzleGame = false
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
    @State private var currentMatrixMaterialsConfig: MatrixMaterialsGameConfig?
    @State private var currentDinoAgesConfig: DinoAgesGameConfig?
    @State private var currentDinoFormationsConfig: DinoFormationsGameConfig?
    @State private var currentDinoHabitatsConfig: DinoHabitatsGameConfig?
    @State private var currentDinoFloraConfig: DinoFloraGameConfig?
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
    /// Land only: visual + crowd intermission after picking a level; blocks level intro until finished.
    @State private var landLevelIntermissionActive = false
    @ObservedObject private var landProgress = LandDinosaurProgress.shared
    @ObservedObject private var marineProgress = MarineReptileProgress.shared
    @ObservedObject private var pterosaurProgress = PterosaurProgress.shared

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
    
    /// Navigation bar title. Empty when showing a level's game list so the level header in the scroll is the only level heading.
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
            } else {
                // Racing Dinosaurs: embed period selection in RacingGameView to avoid sheet dismiss/present flash
                currentRacingConfig = RacingGameConfigs.racingDinosaursNeedsPeriod
                showRacingGame = true
            }
        } else if gameType.matrixMaterialsConfig != nil {
            showMatrixMaterialsGame = true
        } else if gameType.dinoAgesConfig != nil {
            showDinoAgesGame = true
        } else if gameType.dinoFormationsConfig != nil {
            showDinoFormationsGame = true
        } else if gameType.dinoHabitatsConfig != nil {
            showDinoHabitatsGame = true
        } else if gameType.dinoFloraConfig != nil {
            showDinoFloraGame = true
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
        }
    }

    private var hasNoGames: Bool {
        gamesForCategory.isEmpty
    }

    /// Level picker: ten levels in a grid. Shown when no level is selected yet.
    @ViewBuilder
    private var levelPickerContent: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                ForEach(GameLevel.allCases) { level in
                    LevelCard(
                        category: category,
                        level: level,
                        isLocked: isCategoryLevelLocked(level),
                        onTap: {
                            guard !isCategoryLevelLocked(level) else { return }
                            selectedLevel = level
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
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
            showMatrixMaterialsGame: $showMatrixMaterialsGame,
            showDinoAgesGame: $showDinoAgesGame,
            showDinoFormationsGame: $showDinoFormationsGame,
            showDinoHabitatsGame: $showDinoHabitatsGame,
            showDinoFloraGame: $showDinoFloraGame,
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
            selectedGame: $selectedGame,
            currentGameConfig: $currentGameConfig,
            currentWeighConfig: $currentWeighConfig,
            currentBalanceConfig: $currentBalanceConfig,
            currentGuessConfig: $currentGuessConfig,
            currentFindMamaConfig: $currentFindMamaConfig,
            currentDinoLunchConfig: $currentDinoLunchConfig,
            currentMatrixMaterialsConfig: $currentMatrixMaterialsConfig,
            currentDinoAgesConfig: $currentDinoAgesConfig,
            currentDinoFormationsConfig: $currentDinoFormationsConfig,
            currentDinoHabitatsConfig: $currentDinoHabitatsConfig,
            currentDinoFloraConfig: $currentDinoFloraConfig,
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
            content: AnyView(mainSelectionContent)
        )
    }

    /// Game cards list; single ForEach over catalog (shared UI). When category has no games for the selected level, show game-coming-soon image.
    /// For land + selected level, show a level header (title) at top so it stays visible when returning from a game (nav bar can be unreliable after sheet dismiss).
    @ViewBuilder
    private var gameCardsStack: some View {
        Group {
            if let level = selectedLevel {
                levelHeaderView(level: level)
                    .id("levelHeader")
            }
            if hasNoGames {
                if ImageAssetCache.imageExists(named: "game-coming-soon") {
                    Image("game-coming-soon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 320, maxHeight: 320)
                        .padding(.vertical, 24)
                } else {
                    Text("New games are coming soon")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
            }
            ForEach(Array(gamesForCategory.enumerated()), id: \.element.id) { index, gameType in
                GameCard(
                    gameType: gameType,
                    icon: gameType.icon,
                    imageName: gameType.imageName,
                    isSelected: selectedGameId == gameType.id || (gameWalkIndex != nil && gameWalkIndex == index),
                    isIntroduced: hasIntroducedCurrentGameList || (gameWalkIndex == nil && !isAudioPlaying) || (gameWalkIndex != nil && index <= gameWalkIndex!),
                    showName: showGameName && selectedGameId == gameType.id,
                    isDisabled: isAudioPlaying || !isCurrentCategoryGamePlayable(gameType),
                    onTap: { handleGameTap(gameType) }
                )
                .id(gameType.id)
            }
        }
    }

    /// Level header shown at top of game list (title only; image is in level picker).
    private func levelHeaderView(level: GameLevel) -> some View {
        Text(level.gameListTitle)
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
    
    var body: some View {
        ZStack {
            Group {
                if showGameTransition, let imageName = transitionGameImage {
                    GameTransitionView(
                        imageName: imageName,
                        audioFile: transitionAudioFile ?? "",
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
                LandLevelIntermissionView(category: category, level: level) {
                    landLevelIntermissionActive = false
                }
                .zIndex(10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if showGameTransition {
                        showGameTransition = false
                        selectedGame = nil
                    } else if selectedLevel != nil {
                        selectedLevel = nil
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedLevel) { _, newLevel in
            // So the game-name walk runs for each level when the list changes (non-readers memorize by hearing names).
            hasPlayedWelcome = false
            if newLevel != nil {
                landLevelIntermissionActive = true
            } else {
                landLevelIntermissionActive = false
            }
        }
        .onChange(of: landLevelIntermissionActive) { _, active in
            if active {
                speechManager.stopCurrentAudio()
            }
        }
        // Land / marine / pterosaur completion → `UserDefaults` is handled by `*Progress.shared` notification observers
        // so progress still updates if this view is off-screen during sheet dismiss or transition.
    }

    private func handleGameTap(_ gameType: GameType) {
        guard !isAudioPlaying && !showGameTransition else { return }
        guard isCurrentCategoryGamePlayable(gameType) else { return }
        
        // Store the selected game
        selectedGame = gameType
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
        currentMatrixMaterialsConfig = gameType.matrixMaterialsConfig
        currentDinoAgesConfig = gameType.dinoAgesConfig
        currentDinoFormationsConfig = gameType.dinoFormationsConfig
        currentDinoHabitatsConfig = gameType.dinoHabitatsConfig
        currentDinoFloraConfig = gameType.dinoFloraConfig
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
    @Binding var showFindMamaGame: Bool
    @Binding var showDinoLunchGame: Bool
    @Binding var showMatrixMaterialsGame: Bool
    @Binding var showDinoAgesGame: Bool
    @Binding var showDinoFormationsGame: Bool
    @Binding var showDinoHabitatsGame: Bool
    @Binding var showDinoFloraGame: Bool
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
    @Binding var selectedGame: GameType?
    @Binding var currentGameConfig: MatchingGameConfig?
    @Binding var currentWeighConfig: WeighGameConfig?
    @Binding var currentBalanceConfig: BalanceGameConfig?
    @Binding var currentGuessConfig: GuessGameConfig?
    @Binding var currentFindMamaConfig: FindMamaConfig?
    @Binding var currentDinoLunchConfig: DinoLunchConfig?
    @Binding var currentMatrixMaterialsConfig: MatrixMaterialsGameConfig?
    @Binding var currentDinoAgesConfig: DinoAgesGameConfig?
    @Binding var currentDinoFormationsConfig: DinoFormationsGameConfig?
    @Binding var currentDinoHabitatsConfig: DinoHabitatsGameConfig?
    @Binding var currentDinoFloraConfig: DinoFloraGameConfig?
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
    let content: AnyView
    @AppStorage("introducedGameListKeysCSV") private var introducedGameListKeysCSV = ""

    /// Bumped to scroll the game list to the level header (fixes stuck offset after game walk or when replaying level intro).
    @State private var gameListScrollToTopToken: Int = 0

    private var noOtherGameShowing: Bool {
        !showMatchingGame && !showWeighGame && !showBalanceGame && !showGuessGame &&
        !showFindMamaGame && !showDinoLunchGame && !showMatrixMaterialsGame && !showDinoAgesGame && !showDinoFormationsGame && !showDinoHabitatsGame && !showDinoFloraGame && !showDinoFaunaGame && !showMeasureGame && !showWhoIsTallerGame && !showWackyGame && !showToothacheGame && !showSmilingDinosGame && !showDinoEggsGame &&
        !showRacingGame && !showRacingPeriodSelection && !showDinoPushGame && !showDinoPuzzleGame && !showPteroPuzzleGame && !showMarinePuzzleGame && !showDinoToolsGame && !showDinoFossilHuntGame
    }

    private func scrollGameListToTop(proxy: ScrollViewProxy) {
        guard selectedLevel != nil else { return }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("levelHeader", anchor: .top)
            }
        }
    }

    /// Called from sheet-dismiss handlers (after the same delay as state reset). Scrolls the list to the level header; avoids relying on `onChange` of the derived `noOtherGameShowing` flag, which can miss updates.
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
            ScrollView {
                VStack(spacing: 20) {
                    content
                }
                .padding()
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
        .navigationTitle(gameSelectionTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentWithSheets: some View {
        navigationContent
            .sheet(isPresented: $showMatchingGame) {
                // Dino Diets!: always pass a fresh diet config so right side shows diets (diet- images + Diets audio), not dinosaur characteristics
                if selectedGameId == "match-the-diet" {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.dinoDietFeatures)
                } else if let config = currentGameConfig {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: config)
                } else {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: MatchingGameConfigs.dinoFeatures)
                }
            }
            .sheet(isPresented: $showWeighGame) {
                if let config = currentWeighConfig {
                    WeighGameView(isPresented: $showWeighGame, gameConfig: config)
                }
            }
            .sheet(isPresented: $showBalanceGame) {
                if let config = currentBalanceConfig {
                    BalanceGameView(isPresented: $showBalanceGame, gameConfig: config)
                }
            }
            .sheet(isPresented: $showGuessGame) {
                if let config = currentGuessConfig {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: config)
                } else {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: GuessGameConfigs.nameThatDinosaur)
                }
            }
            .sheet(isPresented: $showFindMamaGame) {
                if let config = currentFindMamaConfig {
                    FindMamaGameView(isPresented: $showFindMamaGame, gameConfig: config)
                } else {
                    FindMamaGameView(isPresented: $showFindMamaGame, gameConfig: FindMamaConfigs.findMama)
                }
            }
            .sheet(isPresented: $showDinoLunchGame) {
                if let config = currentDinoLunchConfig {
                    DinoLunchGameView(isPresented: $showDinoLunchGame, gameConfig: config)
                } else {
                    DinoLunchGameView(isPresented: $showDinoLunchGame, gameConfig: DinoLunchConfigs.dinoLunch)
                }
            }
            .sheet(isPresented: $showWackyGame) {
                if let config = currentWackyConfig {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: config)
                } else {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: WackyGameConfigs.wackyDinosaurs)
                }
            }
            .sheet(isPresented: $showToothacheGame) {
                if let config = currentToothacheConfig {
                    ToothacheGameView(isPresented: $showToothacheGame, gameConfig: config)
                } else {
                    ToothacheGameView(isPresented: $showToothacheGame, gameConfig: ToothacheGameConfigs.toothache)
                }
            }
            .sheet(isPresented: $showSmilingDinosGame) {
                if let config = currentSmilingDinosConfig {
                    SmilingDinosGameView(isPresented: $showSmilingDinosGame, gameConfig: config)
                } else {
                    SmilingDinosGameView(isPresented: $showSmilingDinosGame, gameConfig: SmilingDinosGameConfigs.smilingDinos)
                }
            }
            .sheet(isPresented: $showDinoEggsGame) {
                if let config = currentDinoEggsConfig {
                    DinoEggsGameView(isPresented: $showDinoEggsGame, gameConfig: config)
                } else {
                    DinoEggsGameView(isPresented: $showDinoEggsGame, gameConfig: DinoEggsGameConfigs.dinoEggs)
                }
            }
            .sheet(isPresented: $showDinoToolsGame) {
                if let config = currentDinoToolsConfig {
                    DinoToolsGameView(isPresented: $showDinoToolsGame, gameConfig: config)
                } else {
                    DinoToolsGameView(isPresented: $showDinoToolsGame, gameConfig: DinoToolsGameConfigs.dinoTools)
                }
            }
            .sheet(isPresented: $showRacingPeriodSelection) {
                RacingPeriodSelectionView(isPresented: $showRacingPeriodSelection, onSelectPeriod: { config in
                    currentRacingConfig = config
                    showRacingPeriodSelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRacingGame = true
                    }
                })
            }
            .sheet(isPresented: $showRacingGame) {
                if let config = currentRacingConfig {
                    RacingGameView(isPresented: $showRacingGame, gameConfig: config)
                }
            }
            .sheet(isPresented: $showMatrixMaterialsGame) {
                if let config = currentMatrixMaterialsConfig {
                    MatrixMaterialsGameView(isPresented: $showMatrixMaterialsGame, gameConfig: config)
                } else {
                    MatrixMaterialsGameView(isPresented: $showMatrixMaterialsGame, gameConfig: MatrixMaterialsGameConfigs.matrixMaterials)
                }
            }
            .sheet(isPresented: $showDinoAgesGame) {
                if let config = currentDinoAgesConfig {
                    DinoAgesGameView(isPresented: $showDinoAgesGame, gameConfig: config)
                } else {
                    DinoAgesGameView(
                        isPresented: $showDinoAgesGame,
                        gameConfig: category == .air ? DinoAgesGameConfigs.pteroAges : DinoAgesGameConfigs.dinoAges
                    )
                }
            }
            .sheet(isPresented: $showDinoFormationsGame) {
                if let config = currentDinoFormationsConfig {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: config)
                } else {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: DinoFormationsGameConfigs.dinoFormations)
                }
            }
            .sheet(isPresented: $showDinoHabitatsGame) {
                if let config = currentDinoHabitatsConfig {
                    DinoHabitatsGameView(isPresented: $showDinoHabitatsGame, gameConfig: config)
                } else {
                    DinoHabitatsGameView(isPresented: $showDinoHabitatsGame, gameConfig: DinoHabitatsGameConfigs.dinoHabitats)
                }
            }
            .sheet(isPresented: $showDinoFloraGame) {
                if let config = currentDinoFloraConfig {
                    DinoFloraGameView(isPresented: $showDinoFloraGame, gameConfig: config)
                } else {
                    DinoFloraGameView(isPresented: $showDinoFloraGame, gameConfig: DinoFloraGameConfigs.dinoFlora)
                }
            }
            .sheet(isPresented: $showDinoFaunaGame) {
                if let config = currentDinoFaunaConfig {
                    DinoFaunaGameView(isPresented: $showDinoFaunaGame, gameConfig: config)
                } else {
                    DinoFaunaGameView(isPresented: $showDinoFaunaGame, gameConfig: DinoFaunaGameConfigs.dinoFauna)
                }
            }
            .sheet(isPresented: $showDinoFossilHuntGame) {
                if let config = currentDinoFossilHuntConfig {
                    DinoFossilHuntGameView(isPresented: $showDinoFossilHuntGame, gameConfig: config)
                } else {
                    DinoFossilHuntGameView(isPresented: $showDinoFossilHuntGame, gameConfig: DinoFossilHuntGameConfigs.dinoFossilHunt)
                }
            }
            .sheet(isPresented: $showMeasureGame) {
                if let config = currentMeasureConfig {
                    MeasureGameView(isPresented: $showMeasureGame, gameConfig: config)
                } else {
                    MeasureGameView(isPresented: $showMeasureGame, gameConfig: MeasureGameConfigs.measureDinosaur)
                }
            }
            .sheet(isPresented: $showWhoIsTallerGame) {
                if let config = currentWhoIsTallerConfig {
                    WhoIsTallerGameView(isPresented: $showWhoIsTallerGame, gameConfig: config)
                } else {
                    WhoIsTallerGameView(isPresented: $showWhoIsTallerGame, gameConfig: WhoIsTallerGameConfigs.whoIsTallerRandomized())
                }
            }
            .sheet(isPresented: $showDinoPushGame) {
                DinoPushGameView(isPresented: $showDinoPushGame, gameConfig: DinoPushGameConfigs.dinoPushNeedsPeriod)
            }
            .sheet(isPresented: $showDinoPuzzleGame) {
                DinoPuzzleGameView(isPresented: $showDinoPuzzleGame, gameConfig: DinoPuzzleGameConfigs.dinoPuzzle)
            }
            .sheet(isPresented: $showPteroPuzzleGame) {
                PteroPuzzleGameView(isPresented: $showPteroPuzzleGame, gameConfig: PteroPuzzleGameConfigs.pteroPuzzle)
            }
            .sheet(isPresented: $showMarinePuzzleGame) {
                MarineReptilePuzzleGameView(isPresented: $showMarinePuzzleGame, gameConfig: MarineReptilePuzzleGameConfigs.marinePuzzle)
            }
    }

    private var contentWithOnChangeStep1: some View {
        contentWithSheets
            .onChange(of: showMatchingGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentGameConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    if let gameType = selectedGame, gameType.gameConfig != nil {
                        currentGameConfig = gameType.gameConfig?.id == "match-the-pterosaur"
                            ? MatchingGameConfigs.pterosaurFeatures
                            : MatchingGameConfigs.dinoFeatures
                    }
                }
            }
            .onChange(of: showWeighGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWeighConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showBalanceGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentBalanceConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
    }

    private var contentWithOnChangeStep2: some View {
        contentWithOnChangeStep1
            .onChange(of: showGuessGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentGuessConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentFindMamaConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentFindMamaConfig = FindMamaConfigs.findMama
                }
            }
            .onChange(of: showDinoLunchGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoLunchConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWackyConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showToothacheGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentToothacheConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentToothacheConfig = ToothacheGameConfigs.toothache
                }
            }
            .onChange(of: showSmilingDinosGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentSmilingDinosConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentSmilingDinosConfig = SmilingDinosGameConfigs.smilingDinos
                }
            }
            .onChange(of: showDinoEggsGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoEggsConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentDinoEggsConfig = DinoEggsGameConfigs.dinoEggs
                }
            }
            .onChange(of: showDinoToolsGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoToolsConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedGame = nil
                        showGameName = false
                        currentRacingConfig = nil
                        hasPlayedWelcome = false
                        bumpGameListScrollToHeaderAfterSheetDismissed()
                    }
                }
            }
            .onChange(of: showDinoPushGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showDinoPuzzleGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showPteroPuzzleGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showMarinePuzzleGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                }
            }
            .onChange(of: showMatrixMaterialsGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentMatrixMaterialsConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentMatrixMaterialsConfig = MatrixMaterialsGameConfigs.matrixMaterials
                }
            }
            .onChange(of: showDinoAgesGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoAgesConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentDinoAgesConfig = category == .air ? DinoAgesGameConfigs.pteroAges : DinoAgesGameConfigs.dinoAges
                }
            }
            .onChange(of: showDinoFormationsGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFormationsConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFloraConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentDinoFloraConfig = DinoFloraGameConfigs.dinoFlora
                }
            }
            .onChange(of: showDinoFaunaGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFaunaConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentDinoFaunaConfig = DinoFaunaGameConfigs.dinoFauna
                }
            }
            .onChange(of: showDinoFossilHuntGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFossilHuntConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoHabitatsConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentDinoHabitatsConfig = DinoHabitatsGameConfigs.dinoHabitats
                }
            }
            .onChange(of: showMeasureGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentMeasureConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
                        }
                    }
                } else {
                    currentMeasureConfig = MeasureGameConfigs.measureDinosaur
                }
            }
            .onChange(of: showWhoIsTallerGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentWhoIsTallerConfig = nil
                            hasPlayedWelcome = false
                            bumpGameListScrollToHeaderAfterSheetDismissed()
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
            // Brief delay after overlay removal so layout/audio session settle; avoids level intro being skipped and the card walk stopping early.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                runWelcomeAndWalkIfNeeded()
            }
        }
        .allowsHitTesting(!isAudioPlaying)
    }

    private func runWelcomeAndWalkIfNeeded() {
        guard showingGameList, !hasPlayedWelcome else { return }
        if landLevelIntermissionActive { return }
        if selectedLevel != nil {
            gameListScrollToTopToken &+= 1
        }
        hasPlayedWelcome = true
        isAudioPlaying = true
        speechManager.onAudioFinished = nil
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                if self.hasIntroducedCurrentGameList {
                    self.isAudioPlaying = false
                    self.speechManager.onAudioFinished = nil
                } else {
                    self.startGameWalk()
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
            markCurrentGameListIntroduced()
            gameWalkIndex = nil
            isAudioPlaying = false
            speechManager.onAudioFinished = nil
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
    case matrixMaterials(MatrixMaterialsGameConfig) // Matrix Materials: identify matrix encasing fossil
    case dinoAges(DinoAgesGameConfig) // Dino Ages: when dinosaurs lived
    case dinoFormations(DinoFormationsGameConfig) // Dino Formations: dinosaurs found in named formation
    case dinoHabitats(DinoHabitatsGameConfig) // Dino Habitats: which dinosaur prefers this habitat
    case dinoFlora(DinoFloraGameConfig) // Dino Flora: which dinosaurs ate this plant
    case dinoFauna(DinoFaunaGameConfig) // Dino Fauna: which dinosaurs fit this animal
    case measure(MeasureGameConfig) // Measure the Dinosaur!: stack to match height
    case whoIsTaller(WhoIsTallerGameConfig) // Which Dino Is Taller: compare two dinosaurs by height
    case smilingDinos(SmilingDinosGameConfig) // Dino Smile!: match dinosaur smiles to teeth
    case dinoEggs(DinoEggsGameConfig) // Dino Eggs!: match dinosaurs to their eggs
    case dinoTools(DinoToolsGameConfig) // Dino Tools!: magnify, SEM, scanner, pick dinosaur
    case dinoFossilHunt(DinoFossilHuntGameConfig) // Dino Fossil Hunt: story beats + pick 2 of 5 tools
    case dinoPuzzle(DinoPuzzleGameConfig) // Dino Puzzle: drag jigsaw pieces for three dinosaurs
    case pteroPuzzle(PteroPuzzleGameConfig) // Ptero Puzzle: drag jigsaw pieces for three pterosaurs
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
        case .matrixMaterials(let config):
            return config.title
        case .dinoAges(let config):
            return config.title
        case .dinoFormations(let config):
            return config.title
        case .dinoHabitats(let config):
            return config.title
        case .dinoFlora(let config):
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
            return config.id == "match-the-diet" ? "Match each dinosaur to its diet" : "Match dinosaurs to their special features"
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
        case .racing:
            return "Race two dinosaurs!"
        case .dinoPush:
            return "Sumo-style push face-off!"
        case .matrixMaterials:
            return "Identify the matrix material encasing the fossil"
        case .dinoAges(let config):
            return config.id == "ptero-ages" ? "Discover when pterosaurs lived" : "Discover when dinosaurs lived"
        case .dinoFormations:
            return "Pick dinosaurs found in the formation shown"
        case .dinoHabitats:
            return "Which dinosaur prefers this habitat?"
        case .dinoFlora:
            return "Which dinosaurs ate this plant?"
        case .dinoFauna:
            return "Which three dinosaurs fit this animal?"
        case .measure:
            return "Stack dinosaurs to match the reference height"
        case .whoIsTaller(let config):
            return config.id == "which-ptero-is-taller"
                ? "Compare two pterosaurs to see which one is taller"
                : "Compare two dinosaurs to see which dino is taller"
        case .smilingDinos:
            return "Match dinosaur smiles to their teeth"
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
        case .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var weighConfig: WeighGameConfig? {
        switch self {
        case .weigh(let config): return config
        case .matching, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var balanceConfig: BalanceGameConfig? {
        switch self {
        case .balance(let config): return config
        case .matching, .weigh, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var guessConfig: GuessGameConfig? {
        switch self {
        case .guess(let config): return config
        case .matching, .weigh, .balance, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var findMamaConfig: FindMamaConfig? {
        switch self {
        case .findMama(let config): return config
        case .matching, .weigh, .balance, .guess, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoLunchConfig: DinoLunchConfig? {
        switch self {
        case .dinoLunch(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var wackyConfig: WackyGameConfig? {
        switch self {
        case .wacky(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var toothacheConfig: ToothacheGameConfig? {
        switch self {
        case .toothache(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var racingConfig: RacingGameConfig? {
        switch self {
        case .racing(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoPushConfig: DinoPushGameConfig? {
        switch self {
        case .dinoPush(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var matrixMaterialsConfig: MatrixMaterialsGameConfig? {
        switch self {
        case .matrixMaterials(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoAgesConfig: DinoAgesGameConfig? {
        switch self {
        case .dinoAges(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoFormationsConfig: DinoFormationsGameConfig? {
        switch self {
        case .dinoFormations(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoHabitatsConfig: DinoHabitatsGameConfig? {
        switch self {
        case .dinoHabitats(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoFloraConfig: DinoFloraGameConfig? {
        switch self {
        case .dinoFlora(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoFaunaConfig: DinoFaunaGameConfig? {
        switch self {
        case .dinoFauna(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var measureConfig: MeasureGameConfig? {
        switch self {
        case .measure(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var whoIsTallerConfig: WhoIsTallerGameConfig? {
        switch self {
        case .whoIsTaller(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var smilingDinosConfig: SmilingDinosGameConfig? {
        switch self {
        case .smilingDinos(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoEggsConfig: DinoEggsGameConfig? {
        switch self {
        case .dinoEggs(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoToolsConfig: DinoToolsGameConfig? {
        switch self {
        case .dinoTools(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoFossilHuntConfig: DinoFossilHuntGameConfig? {
        switch self {
        case .dinoFossilHunt(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoPuzzle, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var dinoPuzzleConfig: DinoPuzzleGameConfig? {
        switch self {
        case .dinoPuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .pteroPuzzle, .marinePuzzle: return nil
        }
    }

    var pteroPuzzleConfig: PteroPuzzleGameConfig? {
        switch self {
        case .pteroPuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .marinePuzzle: return nil
        }
    }

    var marinePuzzleConfig: MarineReptilePuzzleGameConfig? {
        switch self {
        case .marinePuzzle(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoPush, .matrixMaterials, .dinoAges, .dinoFormations, .dinoHabitats, .dinoFlora, .dinoFauna, .measure, .whoIsTaller, .smilingDinos, .dinoEggs, .dinoTools, .dinoFossilHunt, .dinoPuzzle, .pteroPuzzle: return nil
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
        case .matrixMaterials(let config): return config.id
        case .dinoAges(let config): return config.id
        case .dinoFormations(let config): return config.id
        case .dinoHabitats(let config): return config.id
        case .dinoFlora(let config): return config.id
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
            return config.id == "match-the-diet" ? "game-dino-diets" : "game-\(config.id)"
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
            return config.id.hasPrefix("racing-pterosaur") ? "game-racing-pterosaurs" : "game-racing-dinosaurs"
        case .dinoPush(let config):
            return "game-\(config.id)"
        case .matrixMaterials(let config):
            return "game-\(config.id)"
        case .dinoAges(let config):
            return "game-\(config.id)"
        case .dinoFormations(let config):
            return "game-\(config.id)"
        case .dinoHabitats(let config):
            return "game-\(config.id)"
        case .dinoFlora(let config):
            return "game-\(config.id)"
        case .dinoFauna(let config):
            return "game-\(config.id)"
        case .measure(let config):
            return "game-\(config.id)"
        case .whoIsTaller(let config):
            return "game-\(config.id)"
        case .smilingDinos:
            return "game-dino-smile"
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
        case .matrixMaterials: return "🪨"
        case .dinoAges: return "🕐"
        case .dinoFormations: return "🪨"
        case .dinoHabitats: return "🌿"
        case .dinoFlora: return "🌿"
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
        case .matching(let config): return config.id == "match-the-diet" ? "game-dino-diets" : "game-\(config.id)"
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
        case .racing(let config): return config.id.hasPrefix("racing-pterosaur") ? "game-racing-pterosaurs" : "game-racing-dinosaurs"
        case .dinoPush(let config): return "game-\(config.id)"
        case .matrixMaterials(let config): return "game-\(config.id)"
        case .dinoAges(let config): return config.introAudio
        case .dinoFormations(let config): return config.introAudio
        case .dinoHabitats(let config): return config.introAudio
        case .dinoFlora(let config): return config.introAudio
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

// MARK: - Level card (4×2 grid: image above, text below)

private struct LevelCard: View {
    let category: GameCategory
    let level: GameLevel
    var isLocked: Bool = false
    let onTap: () -> Void

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
                VStack(spacing: 8) {
                    if ImageAssetCache.imageExists(named: levelImageName) {
                        Image(levelImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 60, maxHeight: 80)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(minHeight: 60, maxHeight: 80)
                            .overlay(
                                Text(level.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            )
                    }
                    Text(level.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .opacity(isLocked ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

/// Sizes for catalog game art vs name-that guess victory (list stays compact; end-sequence success reads larger).
enum GameCatalogImageMetrics {
    static let levelTwoListGameImageSide: CGFloat = 180
    /// Name That Dinosaur / Pterosaur / Marine Reptile / Racing victory `game-*-success` (matches Match the Dinosaur / Weigh success treatment).
    static let nameThatVictorySuccessImageSide: CGFloat = 280
}

struct GameCard: View {
    let gameType: GameType
    let icon: String
    let imageName: String? // Optional image name from Assets.xcassets
    let isSelected: Bool
    /// True when this card has been introduced during the walk (or walk is done). Like category cards: all start dim, brighten when introduced, stay bright.
    let isIntroduced: Bool
    let showName: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                // Large icon/image - use image if available, otherwise emoji
                if let imageName = imageName, ImageAssetCache.imageExists(named: imageName) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: GameCatalogImageMetrics.levelTwoListGameImageSide, height: GameCatalogImageMetrics.levelTwoListGameImageSide)
                        .brightness(imageName == "game-name-that-dinosaur" ? 0.2 : 0)
                } else {
                    Text(icon)
                        .font(.system(size: 100))
                }
                
                // Show name when selected (for parents) - removed description to prevent truncation
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
            .frame(width: 260, height: showName ? 240 : 210)
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
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Game Transition View

struct GameTransitionView: View {
    let imageName: String
    let audioFile: String
    let onComplete: () -> Void
    
    @State private var speechManager = SpeechManager()
    @State private var hasPlayedAudio = false
    /// Safety: if intro audio never finishes (missing file, TTS glitch), still dismiss after this delay so the game never freezes.
    private let maxTransitionDuration: TimeInterval = 15

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
        .onAppear {
            var didComplete = false
            let completeOnce: () -> Void = {
                guard !didComplete else { return }
                didComplete = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onComplete() }
            }

            // Safety timeout: ensure we never stay stuck on transition
            DispatchQueue.main.asyncAfter(deadline: .now() + maxTransitionDuration) { completeOnce() }

            if !hasPlayedAudio && !audioFile.isEmpty {
                hasPlayedAudio = true
                speechManager.onAudioFinished = { completeOnce() }
                speechManager.speak(audioFile)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completeOnce() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GameSelectionView(category: .land)
    }
}
