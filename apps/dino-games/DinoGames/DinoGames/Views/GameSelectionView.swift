//
//  GameSelectionView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/23/26.
//

import SwiftUI

// Import MatchingGameConfig from MatchingGameView
// (In Swift, types are accessible across files in the same module)

struct GameSelectionView: View {
    @State private var selectedGame: GameType?
    @State private var showGameName = false
    @State private var showMatchingGame = false
    @State private var showWeighGame = false
    @State private var currentGameConfig: MatchingGameConfig?
    @State private var currentWeighConfig: WeighGameConfig?
    
    // List of all available matching games
    private let matchingGames: [GameType] = [
        .matching(MatchingGameConfigs.dinoFeatures)
        // Add more matching games here:
        // .matching(MatchingGameConfigs.dinoHabitat),
        // .matching(MatchingGameConfigs.dinoFood)
    ]
    
    // List of all available weigh games
    private let weighGames: [GameType] = [
        .weigh(WeighGameConfigs.weighDinosaur)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Cover image at top (larger than game cards)
                Image("CoverImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Text("Choose a Game!")
                    .font(.title2)
                    .padding(.top, 10)
                
                // Game cards
                VStack(spacing: 20) {
                    // Matching Game cards
                    ForEach(matchingGames, id: \.gameConfig?.id) { gameType in
                        GameCard(
                            gameType: gameType,
                            icon: "🔗",
                            imageName: gameType.imageName,
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id) == gameType.gameConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id) == gameType.gameConfig?.id,
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
                            isSelected: (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id) == gameType.weighConfig?.id,
                            showName: showGameName && (selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id) == gameType.weighConfig?.id,
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
                if let config = currentGameConfig {
                    MatchingGameView(isPresented: $showMatchingGame, gameConfig: config)
                }
            }
            .sheet(isPresented: $showWeighGame) {
                if let config = currentWeighConfig {
                    WeighGameView(isPresented: $showWeighGame, gameConfig: config)
                }
            }
            .onChange(of: showMatchingGame) { oldValue, newValue in
                // Reset selection state when game is dismissed to allow replay
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showWeighGame {
                            selectedGame = nil
                            showGameName = false
                        }
                    }
                }
            }
            .onChange(of: showWeighGame) { oldValue, newValue in
                // Reset selection state when game is dismissed to allow replay
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !showMatchingGame {
                            selectedGame = nil
                            showGameName = false
                        }
                    }
                }
            }
        }
    }
    
    private func handleGameTap(_ gameType: GameType) {
        let currentId = selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id
        let newId = gameType.gameConfig?.id ?? gameType.weighConfig?.id
        
        if currentId == newId && showGameName {
            // Already selected and name shown - do nothing (will auto-start)
        } else {
            // First tap - show game name for parents to read
            selectedGame = gameType
            showGameName = true
            currentGameConfig = gameType.gameConfig
            currentWeighConfig = gameType.weighConfig
            
            // Auto-start game after 2 seconds (for children, or if parents aren't present)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let stillSelectedId = selectedGame?.gameConfig?.id ?? selectedGame?.weighConfig?.id
                if stillSelectedId == newId && showGameName {
                    if gameType.gameConfig != nil {
                        showMatchingGame = true
                    } else if gameType.weighConfig != nil {
                        showWeighGame = true
                    }
                }
            }
        }
    }
}

enum GameType {
    case matching(MatchingGameConfig) // Matching game configuration
    case weigh(WeighGameConfig) // Weigh game configuration
    
    var name: String {
        switch self {
        case .matching(let config):
            return config.title
        case .weigh(let config):
            return config.title
        }
    }
    
    var description: String {
        switch self {
        case .matching:
            return "Match dinosaurs to their special features"
        case .weigh:
            return "Compare weights on a seesaw"
        }
    }
    
    var gameConfig: MatchingGameConfig? {
        switch self {
        case .matching(let config):
            return config
        case .weigh:
            return nil
        }
    }
    
    var weighConfig: WeighGameConfig? {
        switch self {
        case .matching:
            return nil
        case .weigh(let config):
            return config
        }
    }
    
    var imageName: String {
        switch self {
        case .matching(let config):
            return "game-\(config.id)"
        case .weigh(let config):
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
                if let imageName = imageName {
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

#Preview {
    GameSelectionView()
}
