//
//  LandDinosaurWeighCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurWeighCatalogXCTests: XCTestCase {

    func testWeighCatalogEntriesMatchBundledDinoAssets() {
        let bases = ImageAssetNames.knownAssets.filter { $0.hasPrefix("dino-") && !$0.contains("-silhouette-") }
        for e in LandDinosaurWeighCatalog.allEntries {
            XCTAssertTrue(
                bases.contains(e.imageAssetName),
                "Weigh catalog references missing asset: \(e.imageAssetName)"
            )
            XCTAssertEqual(
                LandDinosaurWeighCatalog.weightKgByStableId[e.stableId],
                e.weightKg,
                "Stable id \(e.stableId) kg map mismatch"
            )
            XCTAssertEqual(
                LandDinosaurData.dinosaurEstimatedWeightKgById[e.stableId],
                e.weightKg,
                "Catalog kg should match LandDinosaurData for id \(e.stableId)"
            )
        }
    }

    func testWeighRandomDinosaurItemsNineUniqueCladesWhenPoolFull() {
        let items = WeighGameConfigs.makeRandomDinosaurItems()
        XCTAssertEqual(items.count, 9, "Expected nine grid creatures")
        let clades = Set(
            items.compactMap { item -> DinoClade? in
                LandDinosaurCladeCatalog.cladeByCreatureId[item.id]
            }
        )
        XCTAssertEqual(clades.count, 9, "Expected one creature per clade in the 3×3 grid; got clades: \(clades.map(\.rawValue).sorted())")
    }

    func testWeighDinosaurConfigIdAndIntro() {
        let config = WeighGameConfigs.weighDinosaur
        XCTAssertEqual(config.id, "weigh-dinosaur")
        XCTAssertEqual(config.introAudio, "game-intro-weigh")
        let level1 = DinosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(level1.contains { $0.id == "weigh-dinosaur" })
    }
}
