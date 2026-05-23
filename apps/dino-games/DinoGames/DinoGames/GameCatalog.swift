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

    /// Visible picker levels that have at least one configured game (empty levels are ignored for “category complete”).
    static func levelsWithGames(for category: GameCategory) -> [GameLevel] {
        GameLevel.visibleInGamePicker.filter { !games(for: category, level: $0).isEmpty }
    }

    static func isCategoryFullyPlayed(_ category: GameCategory) -> Bool {
        let levels = levelsWithGames(for: category)
        guard !levels.isEmpty else { return false }
        switch category {
        case .land:
            return levels.allSatisfy { LandDinosaurProgress.shared.hasCompletedEveryGame(in: $0) }
        case .air:
            return levels.allSatisfy { PterosaurProgress.shared.hasCompletedEveryGame(in: $0) }
        case .marineReptiles:
            return levels.allSatisfy { MarineReptileProgress.shared.hasCompletedEveryGame(in: $0) }
        }
    }

    static func isLevelUnlocked(_ level: GameLevel, category: GameCategory) -> Bool {
        switch category {
        case .land: return LandDinosaurProgress.shared.isLevelUnlocked(level)
        case .air: return PterosaurProgress.shared.isLevelUnlocked(level)
        case .marineReptiles: return MarineReptileProgress.shared.isLevelUnlocked(level)
        }
    }

    static func isLevelFullyPlayed(_ level: GameLevel, category: GameCategory) -> Bool {
        switch category {
        case .land: return LandDinosaurProgress.shared.hasCompletedEveryGame(in: level)
        case .air: return PterosaurProgress.shared.hasCompletedEveryGame(in: level)
        case .marineReptiles: return MarineReptileProgress.shared.hasCompletedEveryGame(in: level)
        }
    }

    static func canonicalId(for game: GameType, category: GameCategory) -> String? {
        guard let raw = game.id else { return nil }
        switch category {
        case .land: return LandDinosaurProgress.canonicalId(for: raw)
        case .air: return PterosaurProgress.canonicalId(for: raw)
        case .marineReptiles: return MarineReptileProgress.canonicalId(for: raw)
        }
    }

    static func hasPlayed(_ game: GameType, category: GameCategory) -> Bool {
        guard let canonical = canonicalId(for: game, category: category) else { return false }
        switch category {
        case .land: return LandDinosaurProgress.shared.playedCanonicalGameIds.contains(canonical)
        case .air: return PterosaurProgress.shared.playedCanonicalGameIds.contains(canonical)
        case .marineReptiles: return MarineReptileProgress.shared.playedCanonicalGameIds.contains(canonical)
        }
    }

    static func canPlay(_ game: GameType, at level: GameLevel, category: GameCategory) -> Bool {
        switch category {
        case .land: return LandDinosaurProgress.shared.canPlayLandGame(game, at: level)
        case .air: return PterosaurProgress.shared.canPlayPterosaurGame(game, at: level)
        case .marineReptiles: return MarineReptileProgress.shared.canPlayMarineGame(game, at: level)
        }
    }

    /// First visible level (in order) that has games, is unlocked, and still has an unplayed slot.
    static func firstIncompleteUnlockedLevel(for category: GameCategory) -> GameLevel? {
        levelsWithGames(for: category).first { level in
            isLevelUnlocked(level, category: category) && !isLevelFullyPlayed(level, category: category)
        }
    }

    /// Next level after `level` that has games and is unlocked (used after finishing a level in guided play).
    static func nextPlayableUnlockedLevel(after level: GameLevel, category: GameCategory) -> GameLevel? {
        guard let idx = levelsWithGames(for: category).firstIndex(of: level) else { return nil }
        let tail = levelsWithGames(for: category)[levelsWithGames(for: category).index(after: idx)...]
        return tail.first { isLevelUnlocked($0, category: category) }
    }

    /// Catalog order: first playable game in `level` not yet marked played.
    static func firstUnplayedGame(in level: GameLevel, category: GameCategory) -> GameType? {
        games(for: category, level: level).first { game in
            canPlay(game, at: level, category: category) && !hasPlayed(game, category: category)
        }
    }

    /// After `completedGame`, the next game in the same level (by catalog order), or nil if the level has no more unplayed games.
    static func nextUnplayedGame(
        in level: GameLevel,
        category: GameCategory,
        after completedGame: GameType
    ) -> GameType? {
        let games = games(for: category, level: level)
        guard let idx = games.firstIndex(where: { $0.id == completedGame.id }) else {
            return firstUnplayedGame(in: level, category: category)
        }
        let tail = games[games.index(after: idx)...]
        return tail.first { game in
            canPlay(game, at: level, category: category) && !hasPlayed(game, category: category)
        }
    }
}
