//
//  PterosaurVictoryAssetsXCTests.swift
//  DinoGamesTests
//
//  Picker card + victory success imagesets for each shipping air game.
//

import XCTest
@testable import DinoGames

final class PterosaurVictoryAssetsXCTests: XCTestCase {

    private var shippingEntries: [(configId: String, picker: String, successCandidates: [String])] {
        PterosaurGameCatalog.games.compactMap { game in
            guard let configId = game.id else { return nil }
            return (configId, game.imageName, Self.successCandidates(for: configId))
        }
    }

    func testShippingAirGamesHavePickerAndSuccessArt() {
        XCTAssertFalse(shippingEntries.isEmpty, "Expected at least one air game in the catalog")
        let known = ImageAssetNames.knownAssets
        for entry in shippingEntries {
            XCTAssertTrue(known.contains(entry.picker), "Missing picker art for `\(entry.configId)`: \(entry.picker)")
            let hasSuccess = entry.successCandidates.contains { known.contains($0) }
            XCTAssertTrue(hasSuccess, "Missing victory art for `\(entry.configId)`. Tried: \(entry.successCandidates)")
        }
    }

    @MainActor
    func testCrowdCheeringResolvesForAirVictoryFinish() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "crowd-cheering"), "Victory finish expects crowd-cheering in bundle")
    }

    /// Mirrors picker + success candidate rules in gameplay views and `GameSelectionView`.
    private static func successCandidates(for configId: String) -> [String] {
        switch configId {
        case "ptero-diets":
            return ["game-ptero-diets-success", "game-ptero-diets", "game-ptero-diet-success", "game-ptero-diet"]
        case let id where id.hasPrefix("racing-pterosaurs"):
            return ["game-\(id)-success", "game-racing-pterosaurs-success", "game-racing-pterosaurs"]
        case "ptero-smile":
            return ["game-ptero-smile-success", "game-ptero-smile"]
        default:
            return StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: configId)
        }
    }
}
