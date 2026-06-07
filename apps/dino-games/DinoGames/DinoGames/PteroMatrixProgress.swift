//
//  PteroMatrixProgress.swift
//  DinoGames
//
//  Tracks which (material, pterosaur) fossil pairs have been featured in a completed Ptero Matrix run.
//

import Foundation

enum PteroMatrixProgress {
    private static let playedPairKeysKey = "pteroMatrixPlayedPairKeys"

    static func pairKey(materialSlug: String, pterosaurSlug: String) -> String {
        "\(materialSlug)|\(pterosaurSlug)"
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
