//
//  LandDinosaurGameCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurGameCatalogXCTests: XCTestCase {

    /// Canonical progress ids (runtime config ids may differ, e.g. `racing-dinosaurs-cretaceous`).
    private let shippingCanonicalByLevel: [GameLevel: [String]] = [
        .level1: ["weigh-dinosaur", "which-dino-is-taller", "dino-puzzle"],
        .level2: ["name-that-dinosaur", "racing-dinosaurs", "dino-ages"],
        .level3: ["dino-footprints", "dino-flora", "dino-eggs"],
        .level4: ["dino-matrix", "match-the-diet", "smiling-dinos"],
    ]

    func testVisibleLandLevelsAreOneThroughFour() {
        XCTAssertEqual(GameLevel.visibleInGamePicker, [.level1, .level2, .level3, .level4])
    }

    func testEachShippingLevelHasThreeGamesInCatalogOrder() {
        for level in GameLevel.visibleInGamePicker {
            let expected = shippingCanonicalByLevel[level] ?? []
            let games = DinosaurGameCatalog.games(level: level)
            XCTAssertEqual(games.count, 3, "Land level \(level.number) should list three games")
            let actual = games.compactMap { $0.id.map { LandDinosaurProgress.canonicalId(for: $0) } }
            XCTAssertEqual(actual, expected, "Land level \(level.number) canonical catalog order")
        }
    }

    func testShippingLandGamesMapToLandProgressCategory() {
        let ids = GameLevel.visibleInGamePicker.flatMap { DinosaurGameCatalog.games(level: $0).compactMap(\.id) }
        for id in ids {
            XCTAssertEqual(GameCategory.forCatalogConfigId(id), .land, "Config `\(id)` should map to land")
        }
    }

    func testLandCatalogBuildsWithoutFatalError() {
        XCTAssertNoThrow({
            _ = DinosaurGameCatalog.games
            _ = LandDinosaurProgress.allLandGameCanonicalIds
        }())
    }
}
