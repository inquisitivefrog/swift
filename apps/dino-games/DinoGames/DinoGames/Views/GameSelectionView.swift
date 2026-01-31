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
    
    @State private var selectedGame: GameType?
    @State private var showGameName = false
    @State private var showMatchingGame = false
    @State private var showWeighGame = false
    @State private var showGuessGame = false
    @State private var showWackyGame = false
    @State private var currentGameConfig: MatchingGameConfig?
    @State private var currentWeighConfig: WeighGameConfig?
    @State private var currentGuessConfig: GuessGameConfig?
    @State private var currentWackyConfig: WackyGameConfig?
    @State private var speechManager = SpeechManager()
    @State private var isAudioPlaying = false
    @State private var hasPlayedWelcome = false
    @State private var showGameTransition = false
    @State private var transitionGameImage: String?
    @State private var transitionAudioFile: String?
    
    // Games shown depend on the selected category from the prior screen.
    private var matchingGames: [GameType] {
        switch category {
        case .land:
            return [
                .matching(MatchingGameConfigs.dinoFeatures)
            ]
        case .air:
            return [
                .matching(MatchingGameConfigs.pterosaurFeatures)
            ]
        case .sea:
            return []
        }
    }
    
    private var weighGames: [GameType] {
        switch category {
        case .land:
            return [.weigh(WeighGameConfigs.weighDinosaur)]
        case .air, .sea:
            return []
        }
    }
    
    private var guessGames: [GameType] {
        switch category {
        case .land:
            return [.guess(GuessGameConfigs.nameThatDinosaur)]
        case .air, .sea:
            return []
        }
    }
    
    private var wackyGames: [GameType] {
        switch category {
        case .land:
            return [.wacky(WackyGameConfigs.wackyDinosaurs)]
        case .air, .sea:
            return []
        }
    }
    
    private var gameSelectionTitle: String {
        switch category {
        case .land: return "Choose a Dinosaur Game!"
        case .air: return "Choose a Pterosaur Game!"
        case .sea: return "Choose a Marine Reptile Game!"
        }
    }
    
    var body: some View {
        Group {
            if showGameTransition, let imageName = transitionGameImage {
                // Transition screen: full-size game image with audio
                GameTransitionView(
                    imageName: imageName,
                    audioFile: transitionAudioFile ?? "",
                    onComplete: {
                        // Dismiss transition first so the list view (with .sheet) is on screen,
                        // then present the game sheet so it actually shows.
                        let gameType = selectedGame
                        DispatchQueue.main.async {
                            showGameTransition = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if let gameType = gameType {
                                    if gameType.gameConfig != nil {
                                        showMatchingGame = true
                                    } else if gameType.weighConfig != nil {
                                        showWeighGame = true
                                    } else if gameType.guessConfig != nil {
                                        showGuessGame = true
                                    } else if gameType.wackyConfig != nil {
                                        showWackyGame = true
                                    }
                                }
                            }
                        }
                    }
                )
            } else {
                NavigationView {
                    VStack(spacing: 20) {
                // Title
                Text(gameSelectionTitle)
                    .font(.title2)
                    .padding(.top, 10)
                
                // Cover image only for Land (Dinosaurs); Pterosaurs and Marine Reptiles show only title and game cards
                if category == .land {
                    Image("CoverImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
                
                // Game cards
                VStack(spacing: 20) {
                    if matchingGames.isEmpty && weighGames.isEmpty && guessGames.isEmpty && wackyGames.isEmpty {
                        Text("New games are coming soon")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    }
                    
                    // Matching Game cards
                    ForEach(matchingGames, id: \.gameConfig?.id) { gameType in
                        GameCard(
                            gameType: gameType,
                            icon: "🔗",
                            imageName: gameType.imageName,
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.gameConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.gameConfig?.id,
                            onTap: {
                                handleGameTap(gameType)
                            }
                        )
                    }
                    
                    // Weigh Game cards
                    ForEach(weighGames, id: \.weighConfig?.id) { gameType in
                        GameCard(
                            gameType: gameType,
                            icon: "⚖️",
                            imageName: gameType.imageName,
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.weighConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.weighConfig?.id,
                            onTap: {
                                handleGameTap(gameType)
                            }
                        )
                    }
                    
                    // Guess Game cards
                    ForEach(guessGames, id: \.guessConfig?.id) { gameType in
                        GameCard(
                            gameType: gameType,
                            icon: "🔍",
                            imageName: gameType.imageName,
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.guessConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.guessConfig?.id,
                            onTap: {
                                handleGameTap(gameType)
                            }
                        )
                    }
                    
                    // Wacky Game cards
                    ForEach(wackyGames, id: \.wackyConfig?.id) { gameType in
                        GameCard(
                            gameType: gameType,
                            icon: "🦕",
                            imageName: gameType.imageName,
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.wackyConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id ?? selectedGame?.guessConfig?.id ?? selectedGame?.wackyConfig?.id) == gameType.wackyConfig?.id,
                            onTap: {
                                handleGameTap(gameType)
                            }
                        )
                    }
                }
                .padding()
                
                // Countdown indicator (optional - shows game will start soon)
                if showGameName && selectedGame != nil {
                    Text("Starting game...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Scoreboard placeholder (for future multi-player tracking)
                VStack(spacing: 8) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Scoreboard")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Placeholder - will show player scores when multi-player is implemented
                    Text("Multi-player tracking coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.bottom, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Empty - title is in cover image
                }
            }
            .sheet(isPresented: $showMatchingGame) {
                // Create a new random game configuration each time the game opens
                // Use the selected game's config, or fallback to dinoFeatures
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
            .sheet(isPresented: $showGuessGame) {
                if let config = currentGuessConfig {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: config)
                } else {
                    GuessGameView(isPresented: $showGuessGame, gameConfig: GuessGameConfigs.nameThatDinosaur)
                }
            }
            .sheet(isPresented: $showWackyGame) {
                if let config = currentWackyConfig {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: config)
                } else {
                    WackyGameView(isPresented: $showWackyGame, gameConfig: WackyGameConfigs.wackyDinosaurs)
                }
            }
            .onChange(of: showMatchingGame) { oldValue, newValue in
                // Reset selection state when game is dismissed to allow replay
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showWeighGame && !showGuessGame && !showWackyGame {
                            selectedGame = nil
                            showGameName = false
                            currentGameConfig = nil // Clear config to force new random config next time
                        }
                    }
                } else {
                    // Game is opening - create new random config for matching games
                    if let gameType = selectedGame, let _ = gameType.gameConfig {
                        // Create a new random config based on which game type
                        if gameType.gameConfig?.id == "match-the-pterosaur" {
                            currentGameConfig = MatchingGameConfigs.pterosaurFeatures
                        } else {
                            currentGameConfig = MatchingGameConfigs.dinoFeatures
                        }
                    }
                }
            }
            .onChange(of: showWeighGame) { oldValue, newValue in
                // Reset selection state when game is dismissed to allow replay
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showMatchingGame && !showGuessGame && !showWackyGame {
                            selectedGame = nil
                            showGameName = false
                            currentWeighConfig = nil
                        }
                    }
                }
            }
            .onChange(of: showGuessGame) { oldValue, newValue in
                // Reset selection state when game is dismissed to allow replay
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showMatchingGame && !showWeighGame && !showWackyGame {
                            selectedGame = nil
                            showGameName = false
                            currentGuessConfig = nil // Clear config to force new random config next time
                        }
                    }
                } else {
                    // Game is opening - create new random config
                    currentGuessConfig = GuessGameConfigs.nameThatDinosaur
                }
            }
            .onChange(of: showWackyGame) { oldValue, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showMatchingGame && !showWeighGame && !showGuessGame {
                            selectedGame = nil
                            showGameName = false
                            currentWackyConfig = nil
                        }
                    }
                }
            }
            .onAppear {
                // Play category-appropriate game selection audio after a short gap (so it doesn't run into the category name just played)
                if !hasPlayedWelcome {
                    hasPlayedWelcome = true
                    speechManager.onAudioFinished = {
                        isAudioPlaying = false
                    }
                    let introKey: String
                    switch category {
                    case .land: introKey = "choose-a-dinosaur-game"
                    case .air: introKey = "choose-a-pterosaur-game"
                    case .sea: introKey = "choose-a-marine-reptile-game"
                    }
                    let delay: TimeInterval = 1.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        isAudioPlaying = true
                        speechManager.speak(introKey)
                    }
                }
            }
            .allowsHitTesting(!isAudioPlaying) // Disable interaction while welcome audio plays
            .opacity(isAudioPlaying ? 0.7 : 1.0) // Visual indicator that interaction is disabled
                }
            }
        }
    }
    
    private func handleGameTap(_ gameType: GameType) {
        guard !isAudioPlaying && !showGameTransition else { return }
        
        // Store the selected game
        selectedGame = gameType
        currentGameConfig = gameType.gameConfig
        // Weigh game: use a new random set of 9 dinosaurs each time
        currentWeighConfig = gameType.weighConfig != nil ? WeighGameConfigs.weighDinosaurRandomized() : nil
        currentGuessConfig = gameType.guessConfig
        currentWackyConfig = gameType.wackyConfig
        
        // Determine which audio file to play based on game type
        var audioFile: String?
        if gameType.wackyConfig != nil {
            // Optional: add intro audio key for Wacky Dinosaurs when you have a file
            audioFile = nil
        } else if let config = gameType.gameConfig {
            // Matching games
            if config.id == "match-the-dinosaur" {
                audioFile = "can-you-match-each-dinosaur"
            } else if config.id == "match-the-pterosaur" {
                audioFile = "can-you-match-each-pterosaur"
            }
        } else if gameType.weighConfig != nil {
            audioFile = "guess-which-dinosaur-is-heavier"
        } else if gameType.guessConfig != nil {
            audioFile = (gameType.guessConfig?.id == "name-that-dinosaur") ? "can-you-name-that-dinosaur" : "can-you-name-the-dinosaur"
        }
        
        // Show transition screen with full-size image
        transitionGameImage = gameType.imageName
        transitionAudioFile = audioFile
        
        // Fade out current screen, then show transition
        withAnimation(.easeOut(duration: 0.3)) {
            showGameTransition = true
        }
    }
}

enum GameType {
    case matching(MatchingGameConfig) // Matching game configuration
    case weigh(WeighGameConfig) // Weigh game configuration
    case guess(GuessGameConfig) // Guess game configuration
    case wacky(WackyGameConfig) // Wacky Dinosaurs! etc.
    
    var name: String {
        switch self {
        case .matching(let config):
            return config.title
        case .weigh(let config):
            return config.title
        case .guess(let config):
            return config.title
        case .wacky(let config):
            return config.title
        }
    }
    
    var description: String {
        switch self {
        case .matching:
            return "Match dinosaurs to their special features"
        case .weigh:
            return "Compare weights on a seesaw"
        case .guess:
            return "Match silhouettes to dinosaurs"
        case .wacky:
            return "Wacky dinosaur fun!"
        }
    }
    
    var gameConfig: MatchingGameConfig? {
        switch self {
        case .matching(let config):
            return config
        case .weigh, .guess, .wacky:
            return nil
        }
    }
    
    var weighConfig: WeighGameConfig? {
        switch self {
        case .weigh(let config):
            return config
        case .matching, .guess, .wacky:
            return nil
        }
    }
    
    var guessConfig: GuessGameConfig? {
        switch self {
        case .guess(let config):
            return config
        case .matching, .weigh, .wacky:
            return nil
        }
    }
    
    var wackyConfig: WackyGameConfig? {
        switch self {
        case .wacky(let config):
            return config
        case .matching, .weigh, .guess:
            return nil
        }
    }
    
    var imageName: String {
        switch self {
        case .matching(let config):
            return "game-\(config.id)"
        case .weigh(let config):
            return "game-\(config.id)"
        case .guess(let config):
            return "game-\(config.id)"
        case .wacky(let config):
            return "game-\(config.id)"
        }
    }
}

struct GameCard: View {
    let gameType: GameType
    let icon: String
    let imageName: String? // Optional image name from Assets.xcassets
    let isSelected: Bool
    let showName: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                // Large icon/image - use image if available, otherwise emoji
                if let imageName = imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                } else {
                    Text(icon)
                        .font(.system(size: 80))
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
            .frame(width: 200, height: showName ? 180 : 150)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: showName)
        }
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
    GameSelectionView(category: .land)
}
