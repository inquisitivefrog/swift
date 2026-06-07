//
//  GameCatalogFlattenXCTests.swift
//  DinoGamesTests
//
//  PR 2: `GameCatalog.allPlacedGames()` — single cross-category iterator for catalog contracts.
//

import XCTest
@testable import DinoGames

final class GameCatalogFlattenXCTests: XCTestCase {

    func testAllPlacedGamesMatchesPerCategoryConcatenation() {
        let placed = GameCatalog.allPlacedGames()
        XCTAssertFalse(placed.isEmpty, "Expected at least one placed game across all categories.")

        for category in GameCategory.allCases {
            let fromIterator = placed.filter { $0.category == category }.map(\.game)
            let fromCatalog = GameCatalog.games(for: category, level: nil)
            XCTAssertEqual(
                fromIterator.count,
                fromCatalog.count,
                "Placed-game count for \(category) should match flatMap catalog order."
            )
            XCTAssertEqual(
                fromIterator.map { $0.id },
                fromCatalog.map { $0.id },
                "Placed-game id order for \(category) should match catalog concatenation."
            )
        }
    }

    func testAllPlacedGamesHaveUniquePlacementKeys() {
        let placed = GameCatalog.allPlacedGames()
        let keys = placed.map(\.placementKey)
        XCTAssertEqual(
            Set(keys).count,
            keys.count,
            "Duplicate placementKey — same category+level+configId listed twice: \(Dictionary(grouping: keys, by: { $0 }).filter { $0.value.count > 1 }.keys.sorted())"
        )
    }

    func testEveryPlacedGameHasConfigId() {
        let placed = GameCatalog.allPlacedGames()
        let missing = placed.filter { $0.game.id == nil || ($0.game.id?.isEmpty == true) }
        XCTAssertTrue(
            missing.isEmpty,
            "Every catalog game should expose a config id for progress / selection; missing: \(missing.map { "\($0.category)/\($0.level)/\($0.game.name)" })"
        )
    }

    func testForCatalogConfigIdMatchesPlacedGameCategory() {
        for placed in GameCatalog.allPlacedGames() {
            guard let id = placed.game.id else { continue }
            XCTAssertEqual(
                GameCategory.forCatalogConfigId(id),
                placed.category,
                "Config id \(id) should map to \(placed.category), not another category or nil."
            )
        }
    }
}
