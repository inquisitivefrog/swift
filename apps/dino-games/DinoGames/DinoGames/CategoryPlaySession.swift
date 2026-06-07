//
//  CategoryPlaySession.swift
//  DinoGames
//
//  Persists the player's place in guided category play (land / air / marine) so the app can resume
//  after interruption. Replay mode (category fully completed) does not use guided auto-navigation.
//

import Foundation

enum CategoryPlaySession {
    private static let categoryKey = "categoryPlaySessionCategory"
    private static let levelKey = "categoryPlaySessionLevel"
    private static let gameIdKey = "categoryPlaySessionGameId"
    private static let guidedKey = "categoryPlaySessionGuided"

    struct Snapshot: Equatable {
        var category: GameCategory?
        var level: GameLevel?
        var gameCanonicalId: String?
        var guidedPlayMode: Bool
    }

    static func load() -> Snapshot {
        let category = UserDefaults.standard.string(forKey: categoryKey).flatMap(GameCategory.init(rawValue:))
        let level = UserDefaults.standard.string(forKey: levelKey).flatMap(GameLevel.init(rawValue:))
        let gameId = UserDefaults.standard.string(forKey: gameIdKey)
        let guided = UserDefaults.standard.bool(forKey: guidedKey)
        return Snapshot(category: category, level: level, gameCanonicalId: gameId, guidedPlayMode: guided)
    }

    static func save(
        category: GameCategory?,
        level: GameLevel?,
        gameCanonicalId: String?,
        guidedPlayMode: Bool
    ) {
        let defaults = UserDefaults.standard
        if let category {
            defaults.set(category.rawValue, forKey: categoryKey)
        } else {
            defaults.removeObject(forKey: categoryKey)
        }
        if let level {
            defaults.set(level.rawValue, forKey: levelKey)
        } else {
            defaults.removeObject(forKey: levelKey)
        }
        if let gameCanonicalId, !gameCanonicalId.isEmpty {
            defaults.set(gameCanonicalId, forKey: gameIdKey)
        } else {
            defaults.removeObject(forKey: gameIdKey)
        }
        defaults.set(guidedPlayMode, forKey: guidedKey)
    }

    static func clearGameSlot() {
        UserDefaults.standard.removeObject(forKey: gameIdKey)
    }

    static func clearLevelAndGame() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: levelKey)
        defaults.removeObject(forKey: gameIdKey)
    }

    static func clearAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: categoryKey)
        defaults.removeObject(forKey: levelKey)
        defaults.removeObject(forKey: gameIdKey)
        defaults.removeObject(forKey: guidedKey)
    }

    /// Guided auto-play until every game in every non-empty visible level has been completed once.
    static func shouldUseGuidedMode(for category: GameCategory) -> Bool {
        !GameCatalog.isCategoryFullyPlayed(category)
    }

    /// True when we should restore into an in-progress guided run on cold start.
    static var hasResumableGuidedSession: Bool {
        let snap = load()
        guard let category = snap.category, snap.guidedPlayMode else { return false }
        return shouldUseGuidedMode(for: category)
    }

    private static let landPlayedKey = "landDinosaurPlayedCanonicalGameIds"
    private static let pteroPlayedKey = "pterosaurPlayedCanonicalGameIds"
    private static let marinePlayedKey = "marineReptilePlayedCanonicalGameIds"

    /// True when any land / air / marine game has been played at least once.
    static var hasAnyRecordedPlayProgress: Bool {
        let defaults = UserDefaults.standard
        func hasPlayedGames(_ key: String) -> Bool {
            !(defaults.stringArray(forKey: key) ?? []).isEmpty
        }
        return hasPlayedGames(landPlayedKey)
            || hasPlayedGames(pteroPlayedKey)
            || hasPlayedGames(marinePlayedKey)
    }

    /// Skip splash welcome and category cover intros for returning players.
    static var shouldSkipLaunchIntros: Bool {
        hasResumableGuidedSession || hasAnyRecordedPlayProgress
    }

    /// Skip level intro + game-name walk when auto-resuming an interrupted guided run (saved level still on disk).
    static func shouldSkipGuidedLevelIntro(for category: GameCategory) -> Bool {
        let snap = load()
        guard snap.guidedPlayMode, snap.category == category, snap.level != nil else { return false }
        return shouldUseGuidedMode(for: category)
    }

    /// Level to open when entering guided play (saved session or first incomplete unlocked level).
    static func guidedEntryLevel(for category: GameCategory) -> GameLevel? {
        let snap = load()
        if snap.category == category, let level = snap.level, GameCatalog.isLevelUnlocked(level, category: category) {
            return level
        }
        if let level = GameCatalog.firstIncompleteUnlockedLevel(for: category) {
            return level
        }
        return GameCatalog.levelsWithGames(for: category).first
    }
}
