//
//  UnifiedGameMediaContractXCTests.swift
//  DinoGamesTests
//
//  PR 3: Single cross-category contract driven by `GameCatalog.allPlacedGames()`.
//  Slice 1 — game picker card imagesets must exist in `ImageAssetNames` for every catalog slot.
//  Expand later: success cards, bundled audio stems, victory art, etc.
//

import XCTest
@testable import DinoGames

final class UnifiedGameMediaContractXCTests: XCTestCase {

    func testLandPlacedGamesHaveGameCardImagesets() {
        assertEveryPlacedGameCardExists(in: .land)
    }

    func testAirPlacedGamesHaveGameCardImagesets() {
        assertEveryPlacedGameCardExists(in: .air)
    }

    func testMarinePlacedGamesHaveGameCardImagesets() {
        assertEveryPlacedGameCardExists(in: .marineReptiles)
    }

    private func assertEveryPlacedGameCardExists(in category: GameCategory) {
        let known = ImageAssetNames.knownAssets
        let slots = GameCatalog.allPlacedGames().filter { $0.category == category }
        XCTAssertFalse(slots.isEmpty, "Expected at least one catalog row for \(category.title).")

        for slot in slots {
            let card = slot.game.imageName
            XCTAssertTrue(
                known.contains(card),
                "\(category.title) — Level \(slot.level.number) — config `\(slot.game.id ?? "?")` — missing game card imageset `\(card)` (run Scripts/regenerate-asset-names.sh after adding assets)."
            )
        }
    }
}
