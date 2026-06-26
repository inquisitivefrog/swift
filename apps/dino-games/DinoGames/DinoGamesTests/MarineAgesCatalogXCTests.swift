//
//  MarineAgesCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineAgesCatalogXCTests: XCTestCase {

    func testMarineAgesAppearsOnLevel2() {
        let level2 = MarineReptileGameCatalog.games(level: .level2)
        XCTAssertTrue(level2.contains { $0.id == "marine-ages" }, "Marine Ages should appear on marine level 2")
    }

    func testMarineAgesPoolHasBothPeriods() {
        let jurassic = SeaMarineReptileData.allMarineReptiles.filter {
            SeaMarineReptileData.mesozoicSpanForAges(creature: $0) == .jurassic
        }
        let cretaceous = SeaMarineReptileData.allMarineReptiles.filter {
            SeaMarineReptileData.mesozoicSpanForAges(creature: $0) == .cretaceous
        }
        XCTAssertGreaterThanOrEqual(jurassic.count, 6, "Need enough Jurassic marine reptiles for three rounds")
        XCTAssertGreaterThanOrEqual(cretaceous.count, 6, "Need enough Cretaceous marine reptiles for three rounds")
    }

    func testMarineAgesProgressCategory() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-ages"), .marineReptiles)
    }

    func testMarineAgesBundledArtExists() {
        for name in [
            "marine-ages-jurassic",
            "marine-ages-cretaceous",
            "source-marine-ages-jurassic",
            "source-marine-ages-cretaceous",
            "game-marine-ages",
            "game-marine-ages-success",
        ] {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(name), "Missing bundled asset: \(name)")
        }
    }

    @MainActor
    func testMarineAgesHintAudioResolvesInBundle() {
        let speech = SpeechManager()
        XCTAssertNotNil(
            speech.urlForAudio(key: "game-marine-ages-tap-the-period-to-hear-description"),
            "Marine Ages hints button intro should resolve to bundled Games/ clip"
        )
    }
}
