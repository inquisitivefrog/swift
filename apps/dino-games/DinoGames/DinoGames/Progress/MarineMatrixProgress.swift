//
//  MarineMatrixProgress.swift
//  DinoGames
//
//  Tracks which (material, marine reptile) fossil pairs have been featured in a completed Marine Matrix run.
//

import Foundation

enum MarineMatrixProgress {
    private static let playedPairKeysKey = "marineMatrixPlayedPairKeys"

    static func pairKey(materialSlug: String, marineReptileSlug: String) -> String {
        "\(materialSlug)|\(marineReptileSlug)"
    }

    static func loadPlayedPairKeys() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: playedPairKeysKey) ?? [])
    }

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
