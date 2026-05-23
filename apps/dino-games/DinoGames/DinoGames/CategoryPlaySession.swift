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
}
