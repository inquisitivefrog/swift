//
//  DinoMatrixProgress.swift
//  DinoGames
//
//  Tracks which (material, dinosaur) fossil pairs have been featured in a completed Dino Matrix run
//  so cross-playthrough variety favors unseen pairs until the pool cycles.
//

import Foundation

enum DinoMatrixProgress {
    private static let playedPairKeysKey = "dinoMatrixPlayedPairKeys"

    static func pairKey(materialSlug: String, dinosaurSlug: String) -> String {
        "\(materialSlug)|\(dinosaurSlug)"
    }

    static func loadPlayedPairKeys() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: playedPairKeysKey) ?? [])
    }

    /// Called after a successful run (victory dismiss). Union of the three featured round pairs.
    static func markPairsPlayed(_ keys: Set<String>) {
        guard !keys.isEmpty else { return }
        var played = loadPlayedPairKeys()
        played.formUnion(keys)
        UserDefaults.standard.set(Array(played).sorted(), forKey: playedPairKeysKey)
    }

    static func clearPlayedPairKeys() {
        UserDefaults.standard.removeObject(forKey: playedPairKeysKey)
    }
}
