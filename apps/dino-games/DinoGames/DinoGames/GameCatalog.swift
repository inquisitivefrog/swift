//
//  GameCatalog.swift
//  DinoGames
//
//  Single entry point for game lists by category. Shared by GameSelectionView.
//

import Foundation

enum GameCatalog {
    /// Returns the ordered list of games for the given category. For .land, pass a level to get games for that level; otherwise level is ignored.
    static func games(for category: GameCategory, level: GameLevel? = nil) -> [GameType] {
        switch category {
        case .land:
            if let level = level {
                return DinosaurGameCatalog.games(level: level)
            }
            return DinosaurGameCatalog.games
        case .air:
            return PterosaurGameCatalog.games
        case .sea:
            return MarineReptileGameCatalog.games
        }
    }
}
