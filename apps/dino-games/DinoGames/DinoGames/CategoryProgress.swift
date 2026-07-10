//
//  CategoryProgress.swift
//  DinoGames
//
//  Completed N of M catalog progress (first-time wins only; replays do not increment).
//

import Foundation

struct CategoryProgressSnapshot: Equatable {
    let category: GameCategory
    let completed: Int
    let total: Int

    var displayText: String {
        CategoryProgressCopy.displayText(completed: completed, total: total)
    }

    var audioKey: String {
        CategoryProgressCopy.audioKey(completed: completed, total: total)
    }
}

enum CategoryProgressCopy {
    static func displayText(completed: Int, total: Int) -> String {
        "Completed \(completed) of \(total) games"
    }

    /// Bundled narration when present: `games-completed-{n}-of-{m}` under `Audio/Games/`.
    static func audioKey(completed: Int, total: Int) -> String {
        "games-completed-\(completed)-of-\(total)"
    }
}

extension GameCatalog {
    /// Every playable catalog slot in visible levels for this category.
    static func playableGames(for category: GameCategory) -> [GameType] {
        games(for: category, level: nil)
    }

    static func totalGameCount(for category: GameCategory) -> Int {
        playableGames(for: category).count
    }

    static func completedCount(in category: GameCategory) -> Int {
        playableGames(for: category).filter { hasPlayed($0, category: category) }.count
    }

    static func totalGameCount(in level: GameLevel, category: GameCategory) -> Int {
        games(for: category, level: level).count
    }

    static func completedCount(in level: GameLevel, category: GameCategory) -> Int {
        games(for: category, level: level).filter { hasPlayed($0, category: category) }.count
    }

    static func levelProgressLabel(for level: GameLevel, category: GameCategory) -> String? {
        let total = totalGameCount(in: level, category: category)
        guard total > 0 else { return nil }
        let completed = completedCount(in: level, category: category)
        return "\(completed)/\(total)"
    }

    static func categoryProgressSnapshot(for category: GameCategory) -> CategoryProgressSnapshot? {
        let total = totalGameCount(for: category)
        guard total > 0 else { return nil }
        return CategoryProgressSnapshot(
            category: category,
            completed: completedCount(in: category),
            total: total
        )
    }

    /// Count includes the game whose victory screen is showing (before `markPlayed` on dismiss).
    static func victoryProgressSnapshot(forConfigId configId: String) -> CategoryProgressSnapshot? {
        guard let category = GameCategory.forCatalogConfigId(configId) else { return nil }
        let total = totalGameCount(for: category)
        guard total > 0 else { return nil }
        var completed = completedCount(in: category)
        if let canonical = canonicalId(forConfigId: configId, category: category),
           !hasPlayedCanonicalId(canonical, category: category) {
            completed += 1
        }
        return CategoryProgressSnapshot(
            category: category,
            completed: min(completed, total),
            total: total
        )
    }

    static func victoryProgressDisplayText(forConfigId configId: String) -> String? {
        victoryProgressSnapshot(forConfigId: configId)?.displayText
    }

    static func canonicalId(forConfigId configId: String, category: GameCategory) -> String? {
        switch category {
        case .land:
            let canonical = LandDinosaurProgress.canonicalId(for: configId)
            return LandDinosaurProgress.allLandGameCanonicalIds.contains(canonical) ? canonical : nil
        case .air:
            let canonical = PterosaurProgress.canonicalId(for: configId)
            return PterosaurProgress.allPterosaurGameCanonicalIds.contains(canonical) ? canonical : nil
        case .marineReptiles:
            let canonical = MarineReptileProgress.canonicalId(for: configId)
            return MarineReptileProgress.allMarineGameCanonicalIds.contains(canonical) ? canonical : nil
        }
    }

    private static func hasPlayedCanonicalId(_ canonical: String, category: GameCategory) -> Bool {
        switch category {
        case .land:
            return LandDinosaurProgress.shared.playedCanonicalGameIds.contains(canonical)
        case .air:
            return PterosaurProgress.shared.playedCanonicalGameIds.contains(canonical)
        case .marineReptiles:
            return MarineReptileProgress.shared.playedCanonicalGameIds.contains(canonical)
        }
    }
}

extension GameCategory {
    var categoryProgressMenuTitle: String {
        switch self {
        case .land: return "Dinosaur games"
        case .air: return "Pterosaur games"
        case .marineReptiles: return "Marine Reptile games"
        }
    }
}

enum CategoryGuidedCompletion {
    static let congratulationsAudioKey = "congratulations-you-completed-all-games"
    static let crowdAudioKey = "crowd-cheering"

    static func imageName(for category: GameCategory) -> String {
        switch category {
        case .land: return "dino-level-congrats"
        case .air: return "ptero-level-congrats"
        case .marineReptiles: return "marine-level-congrats"
        }
    }

    static func celebrationEmojis(for category: GameCategory) -> [String] {
        switch category {
        case .land: return ["🎉", "🦕", "🌟", "🎊", "✨", "🦖"]
        case .air: return ["🎉", "🦅", "🌟", "🎊", "✨", "🪶"]
        case .marineReptiles: return ["🎉", "🐢", "🌟", "🎊", "✨", "🌊"]
        }
    }
}
