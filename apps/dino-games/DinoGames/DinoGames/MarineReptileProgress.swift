//
//  MarineReptileProgress.swift
//  DinoGames
//
//  Level unlocks for Marine Reptile games.
//  Level N+1 unlocks after all games in level N are completed at least once.
//

import Foundation
import Combine

extension Notification.Name {
    static let marineReptileGameCompleted = Notification.Name("marineReptileGameCompleted")
}

final class MarineReptileProgress: ObservableObject {
    static let shared = MarineReptileProgress()

    private let defaultsKey = "marineReptilePlayedCanonicalGameIds"

    static var allMarineGameCanonicalIds: Set<String> {
        Set(
            MarineReptileGameCatalog.games.compactMap { game in
                game.id.map { canonicalId(for: $0) }
            }
        )
    }

    static func canonicalId(for configId: String) -> String {
        configId
    }

    @Published private(set) var playedCanonicalGameIds: Set<String>

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        playedCanonicalGameIds = Set(stored)
    }

    func markPlayed(canonicalGameId: String) {
        let id = Self.canonicalId(for: canonicalGameId)
        guard Self.allMarineGameCanonicalIds.contains(id) else { return }
        guard !playedCanonicalGameIds.contains(id) else { return }
        playedCanonicalGameIds.insert(id)
        UserDefaults.standard.set(Array(playedCanonicalGameIds).sorted(), forKey: defaultsKey)
        objectWillChange.send()
    }

    static func notifyCompletionIfMarineGame(configId: String) {
        let canonical = canonicalId(for: configId)
        guard allMarineGameCanonicalIds.contains(canonical) else { return }
        NotificationCenter.default.post(
            name: .marineReptileGameCompleted,
            object: nil,
            userInfo: ["gameId": canonical]
        )
    }

    func isLevelUnlocked(_ level: GameLevel) -> Bool {
        guard let ord = GameLevel.allCases.firstIndex(of: level) else { return true }
        if ord <= 0 { return true }
        // Keep future marine levels locked until they actually have games configured.
        guard !MarineReptileGameCatalog.games(level: level).isEmpty else { return false }
        let prev = GameLevel.allCases[ord - 1]
        return allGamesInLevelMarkedPlayed(prev)
    }

    private func allGamesInLevelMarkedPlayed(_ level: GameLevel) -> Bool {
        let games = MarineReptileGameCatalog.games(level: level)
        if games.isEmpty { return false }
        return games.allSatisfy { game in
            guard let rawId = game.id else { return true }
            return playedCanonicalGameIds.contains(Self.canonicalId(for: rawId))
        }
    }

    func canPlayMarineGame(_ game: GameType, at level: GameLevel) -> Bool {
        guard isLevelUnlocked(level) else { return false }
        guard let rawId = game.id else { return true }
        return Self.allMarineGameCanonicalIds.contains(Self.canonicalId(for: rawId))
    }
}

