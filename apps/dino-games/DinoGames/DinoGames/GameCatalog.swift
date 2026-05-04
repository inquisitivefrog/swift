//
//  GameCatalog.swift
//  DinoGames
//
//  Single entry point for game lists by category. Shared by GameSelectionView.
//

import Foundation

enum GameCatalog {
    /// Returns the ordered list of games for the given category.
    /// Pass a `GameLevel` to get games for that rung; when `level` is nil, returns all games in level order (concatenated).
    static func games(for category: GameCategory, level: GameLevel? = nil) -> [GameType] {
        switch category {
        case .land:
            if let level = level {
                return DinosaurGameCatalog.games(level: level)
            }
            return DinosaurGameCatalog.games
        case .air:
            if let level = level {
                return PterosaurGameCatalog.games(level: level)
            }
            return PterosaurGameCatalog.games
        case .marineReptiles:
            if let level = level {
                return MarineReptileGameCatalog.games(level: level)
            }
            return MarineReptileGameCatalog.games
        }
    }
}
