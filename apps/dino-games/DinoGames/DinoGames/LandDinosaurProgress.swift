//
//  LandDinosaurProgress.swift
//  DinoGames
//
//  Milestone unlock: level N+1 opens after every game in level N has been completed at least once.
//  Replays allowed anytime within an unlocked level. Concept prerequisites (possibly several) gate a game until all are completed once.
//
//  No extra prerequisites: Wacky Dinosaurs, Racing Dinosaurs, Dino Push!, Dino Footprints (and any catalog game not listed in `LandDinosaurGamePairing`).
//

import Foundation
import Combine

extension Notification.Name {
    static let landDinosaurGameCompleted = Notification.Name("landDinosaurGameCompleted")
}

/// Prerequisites for a dependent game (canonical catalog ids). Empty = playable when its level is unlocked (subject to milestone).
/// Future games: use the config `id` you assign when adding to `DinosaurGameCatalog` (e.g. `dino-trackways`, fossil-prep — must match `GameType.id`).
enum LandDinosaurGamePairing {
    static func prerequisites(before dependentCanonicalId: String) -> [String] {
        switch dependentCanonicalId {
        case "balance-the-dinosaur":
            return ["weigh-dinosaur"]
        case "measure-the-dinosaur":
            return ["which-dino-is-taller"]
        case "match-the-dinosaur":
            return ["name-that-dinosaur"]
        case "find-mama":
            return ["dino-eggs"]
        case "dino-toothache":
            return ["smiling-dinos"]
        case "dino-lunch":
            return ["match-the-diet"]
        case "dino-fossil-hunt":
            return ["dino-tools"]
        case "dino-flora", "dino-fauna":
            return ["dino-ages"]
        case "dino-habitats":
            return ["dino-flora", "dino-fauna"]
        case "dino-formations":
            return ["dino-matrix", "dino-habitats"]
        case "dino-bones":
            return ["whose-bones"]
        case "dino-trackways":
            return ["dino-footprints"]
        default:
            return []
        }
    }
}

final class LandDinosaurProgress: ObservableObject {
    static let shared = LandDinosaurProgress()

    private let defaultsKey = "landDinosaurPlayedCanonicalGameIds"

    /// Canonical ids that appear in `DinosaurGameCatalog` (one entry per logical game; racing/dino-push variants normalize here).
    static var allLandGameCanonicalIds: Set<String> {
        Set(
            DinosaurGameCatalog.games.compactMap { game in
                game.id.map { canonicalId(for: $0) }
            }
        )
    }

    /// Maps runtime config ids (e.g. racing-dinosaurs-jurassic) to catalog ids used for progress.
    static func canonicalId(for configId: String) -> String {
        if configId == "matrix-materials" { return "dino-matrix" }
        if configId.hasPrefix("dino-push-") { return "dino-push" }
        if configId.hasPrefix("racing-dinosaurs") { return "racing-dinosaurs" }
        return configId
    }

    @Published private(set) var playedCanonicalGameIds: Set<String>

    /// Keeps the notification subscription alive for the lifetime of the singleton.
    private let gameCompletedObserver: NSObjectProtocol

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        var ids = Set(stored)
        if ids.remove("matrix-materials") != nil {
            ids.insert("dino-matrix")
        }
        playedCanonicalGameIds = ids
        // Record here (not only from `GameSelectionView`) so completions still count when a game sheet
        // dismisses during navigation transitions or when that view is temporarily off-screen.
        gameCompletedObserver = NotificationCenter.default.addObserver(
            forName: .landDinosaurGameCompleted,
            object: nil,
            queue: .main
        ) { note in
            guard let id = note.userInfo?["gameId"] as? String else { return }
            // Use `shared` here (not `[weak self]`) so the closure is not built before `gameCompletedObserver` is stored.
            LandDinosaurProgress.shared.markPlayed(canonicalGameId: id)
        }
    }

    func markPlayed(canonicalGameId: String) {
        let id = Self.canonicalId(for: canonicalGameId)
        guard Self.allLandGameCanonicalIds.contains(id) else { return }
        guard !playedCanonicalGameIds.contains(id) else { return }
        playedCanonicalGameIds.insert(id)
        UserDefaults.standard.set(Array(playedCanonicalGameIds).sorted(), forKey: defaultsKey)
        objectWillChange.send()
    }

    /// Posted from game views after a successful run (not when the player taps Done early).
    static func notifyCompletionIfLandGame(configId: String) {
        let canonical = canonicalId(for: configId)
        guard allLandGameCanonicalIds.contains(canonical) else { return }
        NotificationCenter.default.post(
            name: .landDinosaurGameCompleted,
            object: nil,
            userInfo: ["gameId": canonical]
        )
    }

    func isLevelUnlocked(_ level: GameLevel) -> Bool {
        if DeveloperSessionFlags.unlockAllGameLevels { return true }
        let ord = level.zeroOrderedIndex
        if ord <= 0 { return true }
        let prev = GameLevel.allCases[ord - 1]
        return allGamesInLevelMarkedPlayed(prev)
    }

    private func allGamesInLevelMarkedPlayed(_ level: GameLevel) -> Bool {
        let games = DinosaurGameCatalog.games(level: level)
        if games.isEmpty { return true }
        return games.allSatisfy { game in
            guard let rawId = game.id else { return true }
            let c = Self.canonicalId(for: rawId)
            return playedCanonicalGameIds.contains(c)
        }
    }

    /// Every catalog game in `level` has been completed at least once (non-empty levels only). Used for level-up UX after the last first-time completion.
    func hasCompletedEveryGame(in level: GameLevel) -> Bool {
        let games = DinosaurGameCatalog.games(level: level)
        if games.isEmpty { return false }
        return games.allSatisfy { game in
            guard let rawId = game.id else { return true }
            let c = Self.canonicalId(for: rawId)
            return playedCanonicalGameIds.contains(c)
        }
    }

    /// Within an unlocked level: playable only when every concept prerequisite has been completed at least once.
    func canPlayLandGame(_ game: GameType, at level: GameLevel) -> Bool {
        if DeveloperSessionFlags.unlockAllGameLevels { return true }
        guard isLevelUnlocked(level) else { return false }
        guard let rawId = game.id else { return true }
        let canonical = Self.canonicalId(for: rawId)
        let prereqs = LandDinosaurGamePairing.prerequisites(before: canonical)
        return prereqs.allSatisfy { playedCanonicalGameIds.contains($0) }
    }
}

extension GameLevel {
    fileprivate var zeroOrderedIndex: Int {
        GameLevel.allCases.firstIndex(of: self) ?? 0
    }
}
