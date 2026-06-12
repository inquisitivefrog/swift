//
//  MarineRacingXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineRacingXCTests: XCTestCase {

    func testRacingMarineReptilesConfigUsesSlalomAndMarinePrefix() {
        let config = RacingGameConfigs.racingMarineReptiles
        XCTAssertEqual(config.id, "racing-marine-reptiles")
        XCTAssertEqual(config.assetPrefix, "marine")
        XCTAssertEqual(config.trackLayout, .marineBuoySlalom(buoyCount: 8)) // eight buoys; slalom wide/tight legs
        XCTAssertFalse(config.racers.isEmpty, "Expected featured marine reptiles with bundled body art")
    }

    func testMarineRacingAssetBaseDerivedFromCatalogImageName() {
        let base = SeaMarineReptileData.marineRacingAssetBase(fromCatalogImageName: "marine-mosa-mosasaurus")
        if let base {
            XCTAssertTrue(base.hasPrefix("marine-racer-") || base.hasPrefix("marine-racing-"))
        }
        XCTAssertNil(SeaMarineReptileData.marineRacingAssetBase(fromCatalogImageName: "invalid"))
    }

    func testMarineRacersForRacingFeaturedSpeciesWhenPresent() throws {
        let pool = SeaMarineReptileData.marineRacersForRacing()
        guard !pool.isEmpty else {
            throw XCTSkip("No featured marine reptiles with bundled body images in the test catalog yet.")
        }
        XCTAssertGreaterThanOrEqual(pool.count, 2)
        let names = Set(pool.map { $0.creature.name })
        XCTAssertTrue(names.contains("Mosasaurus") || names.contains("Ichthyosaurus"))
    }

    func testMarineReptileProgressCanonicalIdForRacing() {
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles"),
            "racing-marine-reptiles"
        )
    }

    @MainActor
    func testMarineRacingSelectionPromptsResolveToBundledClips() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-choose-your-first-marine-reptile"),
            "Racing Marine Reptiles should use Games/game-choose-your-first-marine-reptile.m4a, not TTS"
        )
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-choose-your-second-marine-reptile"),
            "Racing Marine Reptiles should use Games/game-choose-your-second-marine-reptile.m4a, not TTS"
        )
    }

    @MainActor
    func testMarineRacingReadySetGoResolveToBundledClips() {
        let speech = SpeechManager()
        for key in [
            "game-racing-marine-reptiles-ready",
            "game-racing-marine-reptiles-set",
            "game-racing-marine-reptiles-go",
        ] {
            XCTAssertNotNil(
                speech.urlForAudio(key: key),
                "Racing Marine Reptiles countdown should use bundled Games/\(key).m4a, not TTS"
            )
        }
    }
}
