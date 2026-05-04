//
//  MarineReptileWeighCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileWeighCatalogXCTests: XCTestCase {

    func testWeighCatalogEntriesMatchBundledMarineAssets() {
        let bases = ImageAssetNames.knownAssets.filter { $0.hasPrefix("marine-") && !$0.contains("-silhouette-") }
        for e in MarineReptileWeighCatalog.allEntries {
            XCTAssertTrue(
                bases.contains(e.imageAssetName),
                "Weigh catalog references missing asset: \(e.imageAssetName)"
            )
            XCTAssertEqual(
                MarineReptileWeighCatalog.weightKgByStableId[e.stableId],
                e.weightKg,
                "Stable id \(e.stableId) kg map mismatch"
            )
        }
    }

    func testWeighRandomMarineItemsNineUniqueCladesWhenPoolFull() {
        let items = WeighGameConfigs.makeRandomMarineReptileItems()
        XCTAssertEqual(items.count, 9, "Expected nine grid creatures")
        let clades = Set(
            items.compactMap { item -> String? in
                guard let name = item.imageName else { return nil }
                let parts = name.split(separator: "-", omittingEmptySubsequences: false)
                guard parts.count >= 3, parts[0] == "marine" else { return nil }
                return String(parts[1])
            }
        )
        XCTAssertEqual(clades.count, 9, "Expected one creature per clade in the 3×3 grid; got clades: \(clades.sorted())")
    }
}
