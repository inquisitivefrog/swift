//
//  LandDinosaurHeightCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurHeightCatalogXCTests: XCTestCase {

    func testEveryPlayableDinosaurHasHeightData() {
        let missing = WhoIsTallerGameConfigs.allEligibleDinosaurItems().compactMap { item -> String? in
            guard let imageName = item.imageName else { return item.name }
            guard LandDinosaurHeightCatalog.standingHeightMeters(forCreatureId: item.id) != nil else {
                return imageName
            }
            return nil
        }
        XCTAssertTrue(missing.isEmpty, "Missing height (m) for playable dinosaurs: \(missing)")
    }

    func testDinosaurImageNamesAtMostOneMeter() {
        XCTAssertEqual(LandDinosaurHeightCatalog.dinosaurImageNamesAtMostOneMeter, [
            "dino-archaeopteryx",
            "dino-eosinopteryx",
            "dino-pedopenna",
            "dino-anchiornis",
            "dino-xiaotingia",
            "dino-microraptor",
            "dino-compsognathus",
            "dino-velociraptor",
            "dino-masiakasaurus",
            "dino-dromaeosaurus",
        ])
        let playable = LandDinosaurHeightCatalog.dinosaurImageNamesAtMostOneMeter(
            playableIn: WhoIsTallerGameConfigs.allEligibleDinosaurItems().map {
                Dinosaur(id: $0.id, name: $0.name, icon: $0.emoji, imageName: $0.imageName, characteristicIds: [])
            }
        )
        XCTAssertFalse(playable.isEmpty)
    }

    func testWhichDinoIsTallerConfig() {
        let config = WhoIsTallerGameConfigs.whoIsTaller
        XCTAssertEqual(config.id, "which-dino-is-taller")
        XCTAssertEqual(config.poolKind, .dinosaurs)
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .dinosaurs)
        XCTAssertGreaterThanOrEqual(round.count, 9, "Expected at least 9 dinosaurs for a round")
        let level1 = DinosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(level1.contains { $0.id == "which-dino-is-taller" })
    }

    func testMeasureDinoImageCandidateMapsPortraitToMeasureAsset() {
        XCTAssertEqual(
            LandDinosaurHeightCatalog.measureDinoImageCandidate(forImageName: "dino-trex"),
            "measure-dino-trex"
        )
        XCTAssertEqual(
            LandDinosaurHeightCatalog.measureDinoImageCandidate(forImageName: "dino-triceratops"),
            "measure-dino-triceratops"
        )
        XCTAssertNil(LandDinosaurHeightCatalog.measureDinoImageCandidate(forImageName: "marine-mosasaurus"))
    }

    func testBundledMeasureDinoAssetsResolveForPlayablePortraits() {
        let pairs: [(String, String)] = [
            ("dino-trex", "measure-dino-trex"),
            ("dino-triceratops", "measure-dino-triceratops"),
            ("dino-stegosaurus", "measure-dino-stegosaurus"),
        ]
        for (portrait, measure) in pairs {
            XCTAssertEqual(LandDinosaurHeightCatalog.measureDinoImageCandidate(forImageName: portrait), measure)
            XCTAssertTrue(ImageAssetCache.imageExists(named: measure), "Missing bundled \(measure)")
            XCTAssertEqual(LandDinosaurHeightCatalog.measureDinoImageName(forImageName: portrait), measure)
        }
    }

    func testDinoRoundHeightsAreFullyComparable() {
        XCTAssertFalse(
            LandDinosaurHeightCatalog.dinoRoundHeightsAreFullyComparable([20, 0.22, 0.25, 0.35, 1.0, 1.2, 1.5])
        )
        XCTAssertTrue(
            LandDinosaurHeightCatalog.dinoRoundHeightsAreFullyComparable([0.22, 0.25, 0.35, 0.55, 0.6, 1.0, 1.2, 1.5, 2.0])
        )
    }

    func testMakeRoundItemsDinosaurs_everyChoiceHasPartner() {
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .dinosaurs)
        XCTAssertGreaterThanOrEqual(round.count, 9)
        let heights = round.map(\.heightMeters)
        XCTAssertTrue(LandDinosaurHeightCatalog.dinoRoundHeightsAreFullyComparable(heights))
    }

    func testHeightCatalogMatchesMeasureGameSource() {
        for (id, meters) in LandDinosaurHeightCatalog.standingHeightMetersById {
            XCTAssertEqual(
                LandDinosaurHeightCatalog.standingHeightMeters(forCreatureId: id),
                meters,
                "Lookup mismatch for creature id \(id)"
            )
        }
    }
}
