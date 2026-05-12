//
//  GameCatalog.swift
//  DinoGames
//
//  Single entry point for game lists by category. Shared by GameSelectionView.
//

import Foundation

/// One catalog slot: a concrete `GameType` at its category and difficulty rung (PR 2: cross-category test iterator).
struct GameCatalogPlacedGame {
    let category: GameCategory
    let level: GameLevel
    let game: GameType

    /// Stable string for deduping / assertions: `category|level|configId` (empty id segment if missing).
    var placementKey: String {
        let id = game.id ?? ""
        return "\(category.rawValue)|\(level.rawValue)|\(id)"
    }
}

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

    /// Every non-empty `(category, level, game)` slot in display order: `GameCategory.allCases` × `GameLevel.visibleInGamePicker` × catalog row order.
    /// Empty levels (no games configured) are skipped — the slice has no rows for that level.
    static func allPlacedGames() -> [GameCatalogPlacedGame] {
        var out: [GameCatalogPlacedGame] = []
        out.reserveCapacity(64)
        for category in GameCategory.allCases {
            for level in GameLevel.visibleInGamePicker {
                for game in games(for: category, level: level) {
                    out.append(GameCatalogPlacedGame(category: category, level: level, game: game))
                }
            }
        }
        return out
    }
}
