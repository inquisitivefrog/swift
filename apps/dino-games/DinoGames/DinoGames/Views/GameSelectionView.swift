//
//  GameSelectionView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI
import AVFoundation

// Import MatchingGameConfig from MatchingGameView
// (In Swift, types are accessible across files in the same module)

struct GameSelectionView: View {
    let category: GameCategory
    /// When false, pops back to the cover (Choose A Game Type) so back button can return to game list when transition is showing.
    @Binding var navigateToCategories: Bool

    @State private var selectedGame: GameType?
    @State private var showGameName = false
    @State private var showMatchingGame = false
    @State private var showWeighGame = false
    @State private var showBalanceGame = false
    @State private var showGuessGame = false
    @State private var showWackyGame = false
    @State private var showToothacheGame = false
    @State private var showRacingGame = false
    @State private var showRacingPeriodSelection = false
    @State private var showFindMamaGame = false
    @State private var showDinoLunchGame = false
    @State private var showMatrixMaterialsGame = false
    @State private var showDinoAgesGame = false
    @State private var showDinoFormationsGame = false
    @State private var currentGameConfig: MatchingGameConfig?
    @State private var currentWeighConfig: WeighGameConfig?
    @State private var currentBalanceConfig: BalanceGameConfig?
    @State private var currentGuessConfig: GuessGameConfig?
    @State private var currentWackyConfig: WackyGameConfig?
    @State private var currentToothacheConfig: ToothacheGameConfig?
    @State private var currentRacingConfig: RacingGameConfig?
    @State private var currentFindMamaConfig: FindMamaConfig?
    @State private var currentDinoLunchConfig: DinoLunchConfig?
    @State private var currentMatrixMaterialsConfig: MatrixMaterialsGameConfig?
    @State private var currentDinoAgesConfig: DinoAgesGameConfig?
    @State private var currentDinoFormationsConfig: DinoFormationsGameConfig?
    @State private var speechManager = SpeechManager()
    /// true from first frame when category intro will play, so the list is disabled until intro + game walk finish.
    @State private var isAudioPlaying = false
    @State private var hasPlayedWelcome = false
    @State private var showGameTransition = false
    /// When non-nil, we're walking the game list: highlight card at this index and play its intro audio; cards stay disabled until walk finishes.
    @State private var gameWalkIndex: Int? = nil
    @State private var transitionGameImage: String?
    @State private var transitionAudioFile: String?
    /// For Dinosaurs only: selected level (Easy/Mid/Hard). nil = showing level picker; non-nil = showing game list for that level.
    @State private var selectedLevel: GameLevel? = nil

    /// Games for the current category (and level when category is land). When land + selectedLevel == nil we show level picker, not this list.
    private var gamesForCategory: [GameType] {
        GameCatalog.games(for: category, level: category == .land ? selectedLevel : nil)
    }

    /// True when we show the game list (so intro + game walk run). False when we show the level picker (land, no level yet).
    private var showingGameList: Bool {
        category != .land || selectedLevel != nil
    }
    
    private var selectedGameId: String? {
        selectedGame?.id
    }
    
    private var gameSelectionTitle: String {
        switch category {
        case .land:
            if let level = selectedLevel { return "\(level.title) — Choose a Dinosaur Game!" }
            return "Choose a level"
        case .air: return "Choose a Pterosaur Game!"
        case .sea: return "Choose a Marine Reptile Game!"
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
        } else if gameType.racingConfig != nil {
            showRacingPeriodSelection = true
        } else if gameType.matrixMaterialsConfig != nil {
            showMatrixMaterialsGame = true
        } else if gameType.dinoAgesConfig != nil {
            showDinoAgesGame = true
        } else if gameType.dinoFormationsConfig != nil {
            showDinoFormationsGame = true
        }
    }

    private var hasNoGames: Bool {
        gamesForCategory.isEmpty
    }

    /// Level picker: Level 1–6 cards (Dinosaurs only). Shown when category == .land && selectedLevel == nil.
    @ViewBuilder
    private var levelPickerContent: some View {
        VStack(spacing: 10) {
            ForEach(GameLevel.allCases) { level in
                LevelCard(level: level, onTap: { selectedLevel = level })
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onAppear {
            // Level picker should be tappable after the prompt finishes.
            // While the prompt is playing, we temporarily disable hit testing via `isAudioPlaying`.
            guard let url = speechManager.urlForAudio(key: "choose-a-level") else {
                isAudioPlaying = false
                return
            }
            isAudioPlaying = true
            speechManager.onAudioFinished = {
                DispatchQueue.main.async {
                    isAudioPlaying = false
                    speechManager.onAudioFinished = nil
                }
            }
            speechManager.playAudioFile(url: url)
        }
    }

    /// Main content: level picker for Dinosaurs (no level chosen) or game cards.
    @ViewBuilder
    private var mainSelectionContent: some View {
        if category == .land && selectedLevel == nil {
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
            showWackyGame: $showWackyGame,
            showToothacheGame: $showToothacheGame,
            showRacingPeriodSelection: $showRacingPeriodSelection,
            showRacingGame: $showRacingGame,
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
            currentWackyConfig: $currentWackyConfig,
            currentToothacheConfig: $currentToothacheConfig,
            currentRacingConfig: $currentRacingConfig,
            hasPlayedWelcome: $hasPlayedWelcome,
            speechManager: speechManager,
            isAudioPlaying: $isAudioPlaying,
            gameWalkIndex: $gameWalkIndex,
            content: AnyView(mainSelectionContent)
        )
    }

    /// Game cards list; single ForEach over catalog (shared UI). When category has no games (e.g. Marine Reptiles), show game-coming-soon image.
    @ViewBuilder
    private var gameCardsStack: some View {
        Group {
            if hasNoGames {
                if UIImage(named: "game-coming-soon") != nil {
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
                    showName: showGameName && selectedGameId == gameType.id,
                    isDisabled: isAudioPlaying,
                    onTap: { handleGameTap(gameType) }
                )
                .id(gameType.id)
            }
        }
    }
    
    var body: some View {
        Group {
            if showGameTransition, let imageName = transitionGameImage {
                GameTransitionView(
                    imageName: imageName,
                    audioFile: transitionAudioFile ?? "",
                    onComplete: {
                        DispatchQueue.main.async {
                            showGameTransition = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                presentSheetForSelectedGame()
                            }
                        }
                    }
                )
            } else {
                gameSelectionNavigationContent
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if showGameTransition {
                        showGameTransition = false
                        selectedGame = nil
                    } else if category == .land && selectedLevel != nil {
                        selectedLevel = nil
                    } else {
                        navigateToCategories = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedLevel) { _, _ in
            // So the game-name walk runs for each level when the list changes (non-readers memorize by hearing names).
            hasPlayedWelcome = false
        }
    }

    private func handleGameTap(_ gameType: GameType) {
        guard !isAudioPlaying && !showGameTransition else { return }
        
        // Store the selected game
        selectedGame = gameType
        currentGameConfig = gameType.gameConfig
        // Weigh game: use a new random set of 9 dinosaurs each time
        currentWeighConfig = gameType.weighConfig != nil ? WeighGameConfigs.weighDinosaurRandomized() : nil
        currentBalanceConfig = gameType.balanceConfig != nil ? BalanceGameConfigs.balanceDinosaurRandomized() : nil
        currentGuessConfig = gameType.guessConfig
        currentFindMamaConfig = gameType.findMamaConfig != nil ? FindMamaConfigs.findMama : nil
        currentDinoLunchConfig = gameType.dinoLunchConfig != nil ? DinoLunchConfigs.dinoLunch : nil
        currentWackyConfig = gameType.wackyConfig
        currentToothacheConfig = gameType.toothacheConfig
        currentMatrixMaterialsConfig = gameType.matrixMaterialsConfig
        currentDinoAgesConfig = gameType.dinoAgesConfig
        currentDinoFormationsConfig = gameType.dinoFormationsConfig

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
    @Binding var showWackyGame: Bool
    @Binding var showToothacheGame: Bool
    @Binding var showRacingPeriodSelection: Bool
    @Binding var showRacingGame: Bool
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
    @Binding var currentWackyConfig: WackyGameConfig?
    @Binding var currentToothacheConfig: ToothacheGameConfig?
    @Binding var currentRacingConfig: RacingGameConfig?
    @Binding var hasPlayedWelcome: Bool
    let speechManager: SpeechManager
    @Binding var isAudioPlaying: Bool
    @Binding var gameWalkIndex: Int?
    let content: AnyView

    private var noOtherGameShowing: Bool {
        !showMatchingGame && !showWeighGame && !showBalanceGame && !showGuessGame &&
        !showFindMamaGame && !showDinoLunchGame && !showMatrixMaterialsGame && !showDinoAgesGame && !showDinoFormationsGame && !showWackyGame && !showToothacheGame &&
        !showRacingGame && !showRacingPeriodSelection
    }

    private var navigationContent: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        content
                    }
                    .padding()
                }
                .onChange(of: gameWalkIndex) { _, newValue in
                    guard let idx = newValue else { return }
                    let games = GameCatalog.games(for: category, level: category == .land ? selectedLevel : nil)
                    guard idx < games.count, let id = games[idx].id else { return }
                    // Defer scroll so the list has updated (highlight state); ensures off-screen cards become visible.
                    func doScroll() {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                    DispatchQueue.main.async { doScroll() }
                    // Second attempt after layout pass; improves reliability when list is long.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { doScroll() }
                }
            }
            .navigationTitle(gameSelectionTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var contentWithSheets: some View {
        navigationContent
            .sheet(isPresented: $showMatchingGame) {
                if let config = currentGameConfig {
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
            .sheet(isPresented: $showRacingPeriodSelection) {
                RacingPeriodSelectionView(isPresented: $showRacingPeriodSelection) { config in
                    currentRacingConfig = config
                    showRacingPeriodSelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRacingGame = true
                    }
                }
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
                    DinoAgesGameView(isPresented: $showDinoAgesGame, gameConfig: DinoAgesGameConfigs.dinoAges)
                }
            }
            .sheet(isPresented: $showDinoFormationsGame) {
                if let config = currentDinoFormationsConfig {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: config)
                } else {
                    DinoFormationsGameView(isPresented: $showDinoFormationsGame, gameConfig: DinoFormationsGameConfigs.dinoFormations)
                }
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
                        }
                    }
                } else {
                    currentGuessConfig = GuessGameConfigs.nameThatDinosaur
                }
            }
            .onChange(of: showFindMamaGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentFindMamaConfig = nil
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
                        }
                    }
                } else {
                    currentToothacheConfig = ToothacheGameConfigs.toothache
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
                        }
                    }
                } else {
                    currentDinoAgesConfig = DinoAgesGameConfigs.dinoAges
                }
            }
            .onChange(of: showDinoFormationsGame) { _, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if noOtherGameShowing {
                            selectedGame = nil
                            showGameName = false
                            currentDinoFormationsConfig = nil
                        }
                    }
                } else {
                    currentDinoFormationsConfig = DinoFormationsGameConfigs.dinoFormations
                }
            }
    }

    private var contentWithOnChange: some View {
        contentWithOnChangeStep4
    }

    var body: some View {
        contentWithOnChange
        .onAppear {
            runWelcomeAndWalkIfNeeded()
        }
        .onChange(of: showingGameList) { _, newValue in
            if newValue { runWelcomeAndWalkIfNeeded() }
        }
        .allowsHitTesting(!isAudioPlaying)
    }

    private func runWelcomeAndWalkIfNeeded() {
        guard showingGameList, !hasPlayedWelcome else { return }
        hasPlayedWelcome = true
        isAudioPlaying = true
        speechManager.onAudioFinished = {
            DispatchQueue.main.async {
                startGameWalk()
            }
        }
        let introKey: String
        switch category {
        case .land:
            introKey = selectedLevel.map { $0.introAudioKey } ?? "choose-a-dinosaur-game"
        case .air: introKey = "choose-a-pterosaur-game"
        case .sea: introKey = "choose-a-marine-reptile-game"
        }
        let delay: TimeInterval = 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            speechManager.speak(introKey)
        }
    }

    /// After category intro finishes, walk the game list: highlight each card and play its intro audio so children learn image ↔ name.
    private func startGameWalk() {
        let games = GameCatalog.games(for: category, level: category == .land ? selectedLevel : nil)
        if games.isEmpty {
            isAudioPlaying = false
            speechManager.onAudioFinished = nil
            return
        }
        isAudioPlaying = true
        gameWalkIndex = 0
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
    case toothache(ToothacheGameConfig) // Toothache: match tooth to grumpy dinosaur
    case racing(RacingGameConfig) // Racing Dinosaurs!
    case matrixMaterials(MatrixMaterialsGameConfig) // Matrix Materials: identify matrix encasing fossil
    case dinoAges(DinoAgesGameConfig) // Dino Ages: when dinosaurs lived
    case dinoFormations(DinoFormationsGameConfig) // Dino Formations: dinosaurs found in named formation

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
        case .matrixMaterials(let config):
            return config.title
        case .dinoAges(let config):
            return config.title
        case .dinoFormations(let config):
            return config.title
        }
    }

    var description: String {
        switch self {
        case .matching:
            return "Match dinosaurs to their special features"
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
        case .matrixMaterials:
            return "Identify the matrix material encasing the fossil"
        case .dinoAges:
            return "Discover when dinosaurs lived"
        case .dinoFormations:
            return "Pick dinosaurs found in the formation shown"
        }
    }

    var gameConfig: MatchingGameConfig? {
        switch self {
        case .matching(let config): return config
        case .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var weighConfig: WeighGameConfig? {
        switch self {
        case .weigh(let config): return config
        case .matching, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var balanceConfig: BalanceGameConfig? {
        switch self {
        case .balance(let config): return config
        case .matching, .weigh, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var guessConfig: GuessGameConfig? {
        switch self {
        case .guess(let config): return config
        case .matching, .weigh, .balance, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var findMamaConfig: FindMamaConfig? {
        switch self {
        case .findMama(let config): return config
        case .matching, .weigh, .balance, .guess, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var dinoLunchConfig: DinoLunchConfig? {
        switch self {
        case .dinoLunch(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var wackyConfig: WackyGameConfig? {
        switch self {
        case .wacky(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .toothache, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var toothacheConfig: ToothacheGameConfig? {
        switch self {
        case .toothache(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .racing, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var racingConfig: RacingGameConfig? {
        switch self {
        case .racing(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .matrixMaterials, .dinoAges, .dinoFormations: return nil
        }
    }

    var matrixMaterialsConfig: MatrixMaterialsGameConfig? {
        switch self {
        case .matrixMaterials(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .dinoAges, .dinoFormations: return nil
        }
    }

    var dinoAgesConfig: DinoAgesGameConfig? {
        switch self {
        case .dinoAges(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoFormations: return nil
        }
    }

    var dinoFormationsConfig: DinoFormationsGameConfig? {
        switch self {
        case .dinoFormations(let config): return config
        case .matching, .weigh, .balance, .guess, .findMama, .dinoLunch, .wacky, .toothache, .racing, .matrixMaterials, .dinoAges: return nil
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
        case .matrixMaterials(let config): return config.id
        case .dinoAges(let config): return config.id
        case .dinoFormations(let config): return config.id
        }
    }

    var imageName: String {
        switch self {
        case .matching(let config):
            return "game-\(config.id)"
        case .weigh(let config):
            return "game-\(config.id)"
        case .balance:
            return "game-balance-the-dinosaurs"
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
        case .racing:
            return "game-racing-dinosaurs"
        case .matrixMaterials(let config):
            return "game-\(config.id)"
        case .dinoAges(let config):
            return "game-\(config.id)"
        case .dinoFormations(let config):
            return "game-\(config.id)"
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
        case .matrixMaterials: return "🪨"
        case .dinoAges: return "🕐"
        case .dinoFormations: return "🪨"
        }
    }

    /// Audio key played when this game is highlighted during the "walk" (and on transition when tapping). File should be game-{slug}.m4a in Games/.
    var introAudioKey: String? {
        switch self {
        case .matching(let config): return "game-\(config.id)"
        case .weigh(let config): return "game-\(config.id)"
        case .balance(let config): return "game-\(config.id)"
        case .guess(let config): return "game-\(config.id)"
        case .findMama(let config): return "game-\(config.id)"
        case .dinoLunch(let config): return "game-\(config.id)"
        case .wacky(let config): return "game-\(config.id)"
        case .toothache(let config): return "game-\(config.id)"
        case .racing: return "game-racing-dinosaurs"
        case .matrixMaterials(let config): return "game-\(config.id)"
        case .dinoAges(let config): return config.introAudio
        case .dinoFormations(let config): return config.introAudio
        }
    }
}

// MARK: - Level card (Easy / Mid / Hard)

private struct LevelCard: View {
    let level: GameLevel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Label-style image: wide and short so all six levels fit on screen; size progression (small→big dino) still reads.
                if UIImage(named: level.imageName) != nil {
                    Image(level.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 48)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 72, height: 48)
                        .overlay(
                            Text(level.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        )
                }
                Text(level.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GameCard: View {
    let gameType: GameType
    let icon: String
    let imageName: String? // Optional image name from Assets.xcassets
    let isSelected: Bool
    let showName: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                // Large icon/image - use image if available, otherwise emoji
                if let imageName = imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
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
            .opacity(isDisabled ? 0.7 : 1.0)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: showName)
        }
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
    
    var body: some View {
        ZStack {
            // Background flush (white/clear)
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Full-size game image
                if UIImage(named: imageName) != nil {
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
            // Play audio file when transition screen appears
            if !hasPlayedAudio && !audioFile.isEmpty {
                hasPlayedAudio = true
                speechManager.onAudioFinished = {
                    // Wait a brief moment after audio finishes, then complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
                speechManager.speak(audioFile)
            } else {
                // If no audio file, complete immediately
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    GameSelectionView(category: .land, navigateToCategories: .constant(true))
}
