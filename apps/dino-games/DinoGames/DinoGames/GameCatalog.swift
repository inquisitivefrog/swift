//
//  GameCatalog.swift
//  DinoGames
//
//  Single entry point for game lists by category. Shared by GameSelectionView.
//

import Foundation

enum GameCatalog {
    /// Returns the ordered list of games for the given category (Land / Air / Sea).
    static func games(for category: GameCategory) -> [GameType] {
        switch category {
        case .land:
            return DinosaurGameCatalog.games
        case .air:
            return PterosaurGameCatalog.games
        case .sea:
            return MarineReptileGameCatalog.games
        }
    }
}
