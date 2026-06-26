//
//  MarineEggsCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineEggsCatalogXCTests: XCTestCase {

    func testMarineCatalogBuildsWithoutFatalErrorWhenEggsUnavailable() {
        XCTAssertNoThrow({
            _ = MarineReptileGameCatalog.games
            _ = MarineReptileProgress.allMarineGameCanonicalIds
        }())
    }

    func testLandVictoryConfigIdDoesNotTargetMarineCategory() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("weigh-dinosaur"), .land)
        XCTAssertNotEqual(GameCategory.forCatalogConfigId("weigh-dinosaur"), .marineReptiles)
    }

    func testMarineEggAssetsEnablePlayableGame() {
        XCTAssertFalse(MarineEggMorphology.playableNestEggSlugs.isEmpty, "Expected marine-eggs-egg + nest pairs in the catalog")
        XCTAssertTrue(MarineEggsGameConfigs.isPlayable, "Marine Eggs should register on level 3 when egg/nest art is bundled")
        XCTAssertTrue(
            MarineReptileGameCatalog.games(level: .level3).contains { $0.id == "marine-eggs" },
            "Marine Eggs should appear in the marine level-3 picker"
        )
    }

    func testMesoleptosHasMatchingEggAndNest() {
        XCTAssertTrue(MarineEggMorphology.playableNestEggSlugs.contains("mesoleptos"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-eggs-egg-mesoleptos"))
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-eggs-nest-mesoleptos"))
    }

    func testMarineEggsVictoryUsesCreatureNameRecap() {
        XCTAssertTrue(MarineEggMorphology.settings.victoryRecapUsesCreatureName)
        XCTAssertFalse(MarineEggMorphology.settings.victoryRecapLabelUsesCreatureName)
        XCTAssertEqual(
            MarineEggMorphology.morphology.eggAudioKey(eggType: "archelon"),
            "marine-eggs-archelon"
        )
    }

    func testMarineEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let morphology = MarineEggMorphology.morphology
        for round in config.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg slug `\(round.eggType)`")
        }
    }

    func testNestEggScanRevealUsesDedicatedScanArtWhenBundled() {
        for slug in MarineEggMorphology.playableNestEggSlugs {
            let dedicated = "marine-eggs-scan-\(slug)"
            let scan = MarineEggMorphology.scanAssetName(forCatalogSlug: slug)
            if ImageAssetNames.knownAssets.contains(dedicated) {
                XCTAssertEqual(scan, dedicated, "Scan for \(slug) should prefer bundled CT scan art")
            } else {
                XCTAssertTrue(
                    ImageAssetCache.imageExists(named: scan),
                    "Missing scan asset for \(slug): \(scan)"
                )
            }
            let egg = MarineEggMorphology.eggAssetName(forCatalogSlug: slug)
            XCTAssertNotEqual(
                scan,
                egg,
                "Scan should not fall back to the same egg image for \(slug) when dedicated scan art is expected"
            )
        }
    }

    func testMarineScanEmptyAssetIsBundledAndResolved() {
        XCTAssertTrue(
            ImageAssetNames.knownAssets.contains("marine-eggs-scan-empty"),
            "Expected marine-eggs-scan-empty imageset in the catalog"
        )
        XCTAssertEqual(
            MarineEggMorphology.morphology.scansEmptyName(),
            "marine-eggs-scan-empty"
        )
    }

    func testSpecimenOnlyFishSlugsJoinPool() {
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("enchodus"))
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("gillicus"))
        XCTAssertTrue(MarineEggMorphology.playableSpecimenOnlySlugs.contains("xiphactinus"))
    }

    func testMakeMarineEggsCanIncludeSpecimenOnlyRound() {
        guard let config = MarineEggsGameConfigs.makeMarineEggs() else {
            XCTFail("Expected Marine Eggs config")
            return
        }
        let specimenRounds = config.rounds.filter { !$0.alternatesNestAndEgg }
        XCTAssertFalse(specimenRounds.isEmpty, "Expected at least one live/spawn-only round when fish spawn art is bundled")
        for round in specimenRounds {
            XCTAssertNotNil(round.fixedMainImageAssetName)
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(round.fixedMainImageAssetName!))
        }
    }
}
