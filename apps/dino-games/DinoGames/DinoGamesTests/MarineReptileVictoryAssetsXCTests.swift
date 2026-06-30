//
//  MarineReptileVictoryAssetsXCTests.swift
//  DinoGamesTests
//
//  Picker card + victory success imagesets for each shipping marine game.
//

import XCTest
@testable import DinoGames

final class MarineReptileVictoryAssetsXCTests: XCTestCase {

    private var shippingEntries: [(configId: String, picker: String, successCandidates: [String])] {
        MarineReptileGameCatalog.games.compactMap { game in
            guard let configId = game.id else { return nil }
            let entry = Self.victoryAssetEntry(for: configId)
            return (configId, entry.picker, entry.successCandidates)
        }
    }

    func testShippingMarineGamesHavePickerAndSuccessArt() {
        XCTAssertFalse(shippingEntries.isEmpty, "Expected at least one marine game in the catalog")
        let known = ImageAssetNames.knownAssets
        for entry in shippingEntries {
            XCTAssertTrue(known.contains(entry.picker), "Missing picker art for `\(entry.configId)`: \(entry.picker)")
            let hasSuccess = entry.successCandidates.contains { known.contains($0) }
            XCTAssertTrue(hasSuccess, "Missing victory art for `\(entry.configId)`. Tried: \(entry.successCandidates)")
        }
    }

    @MainActor
    func testCrowdCheeringResolvesForMarineVictoryFinish() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "crowd-cheering"), "Victory finish expects crowd-cheering in bundle")
    }

    /// Mirrors picker + success candidate rules in gameplay views and `GameSelectionView`.
    private static func victoryAssetEntry(for configId: String) -> (picker: String, successCandidates: [String]) {
        switch configId {
        case "weigh-marine-reptile":
            return (
                "game-weigh-the-marine-reptile",
                ["game-weigh-the-marine-reptile-success", "game-weigh-the-marine-reptile"]
            )
        case "marine-diets":
            return (
                "game-marine-diets",
                ["game-marine-diets-success", "game-marine-diets"]
            )
        case let id where id.hasPrefix("racing-marine-reptiles"):
            return (
                "game-racing-marine-reptiles",
                ["game-\(id)-success", "game-racing-marine-reptiles-success", "game-racing-marine-reptiles"]
            )
        default:
            return (
                "game-\(configId)",
                ["game-\(configId)-success", "game-\(configId)"]
            )
        }
    }
}
