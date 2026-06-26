//
//  MarineReptileLengthCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileLengthCatalogXCTests: XCTestCase {

    func testEveryPlayableMarineReptileHasLengthData() {
        let missing = SeaMarineReptileData.allMarineReptiles.compactMap { creature -> String? in
            guard let imageName = creature.imageName else { return creature.name }
            guard MarineReptileLengthCatalog.totalLengthMeters(forImageName: imageName) != nil else {
                return imageName
            }
            return nil
        }
        XCTAssertTrue(missing.isEmpty, "Missing length (m) for marine reptiles: \(missing)")
    }

    func testMarineImageNamesAtMostOneMeter() {
        XCTAssertEqual(MarineReptileLengthCatalog.marineImageNamesAtMostOneMeter, [
            "marine-teleo-gillicus",
            "marine-testu-proganochelys",
            "marine-basal-judeasaurus",
            "marine-basal-hupehsuchus",
            "marine-basal-mesosaurus",
            "marine-notho-henodus",
        ])
        let playable = MarineReptileLengthCatalog.marineImageNamesAtMostOneMeter(
            playableIn: SeaMarineReptileData.allMarineReptiles
        )
        XCTAssertEqual(playable.count, 6)
    }

    func testWhichMarineReptileIsLongerConfig() {
        let config = WhoIsTallerGameConfigs.whichMarineReptileIsLonger
        XCTAssertEqual(config.id, "which-marine-reptile-is-longer")
        XCTAssertEqual(config.poolKind, .marineReptiles)
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .marineReptiles)
        XCTAssertGreaterThanOrEqual(round.count, 9, "Expected at least 9 marine reptiles for a round")
    }

    func testMeasureMarineImageCandidateMapsPortraitToSpeciesSlug() {
        XCTAssertEqual(
            MarineReptileLengthCatalog.measureMarineImageCandidate(forImageName: "marine-plesio-elasmosaurus"),
            "measure-marine-elasmosaurus"
        )
        XCTAssertEqual(
            MarineReptileLengthCatalog.measureMarineImageCandidate(forImageName: "marine-tylo-tylosaurus"),
            "measure-marine-tylosaurus"
        )
        XCTAssertNil(MarineReptileLengthCatalog.measureMarineImageCandidate(forImageName: "dino-trex"))
    }

    func testBundledMeasureMarineAssetsResolveForPlayablePortraits() {
        let pairs: [(String, String)] = [
            ("marine-plesio-elasmosaurus", "measure-marine-elasmosaurus"),
            ("marine-mosa-mosasaurus", "measure-marine-mosasaurus"),
            ("marine-ichthyo-shastasaurus", "measure-marine-shastasaurus"),
        ]
        for (portrait, measure) in pairs {
            XCTAssertEqual(MarineReptileLengthCatalog.measureMarineImageCandidate(forImageName: portrait), measure)
            XCTAssertTrue(ImageAssetCache.imageExists(named: measure), "Missing bundled \(measure)")
            XCTAssertEqual(MarineReptileLengthCatalog.measureMarineImageName(forImageName: portrait), measure)
        }
    }

    func testMeasureMarineSnoutOnTrailingAssetsAreMirroredForTapeAlignment() {
        let mirrored: [(String, String)] = [
            ("marine-plesio-elasmosaurus", "elasmosaurus"),
            ("marine-mosa-hainosaurus", "hainosaurus"),
            ("marine-hali-pluridens", "pluridens"),
            ("marine-plesio-thalassomedon", "thalassomedon"),
            ("marine-tylo-tylosaurus", "tylosaurus"),
        ]
        for (portrait, slug) in mirrored {
            XCTAssertTrue(
                MarineReptileLengthCatalog.measureMarineImageMirroredForTapeAlignment(forImageName: portrait),
                "Expected mirror for \(slug)"
            )
        }
        XCTAssertFalse(
            MarineReptileLengthCatalog.measureMarineImageMirroredForTapeAlignment(forImageName: "marine-plio-liopleurodon")
        )
    }

    func testMeasureMarineTapeDisplayScaleUsesCatalogLengthOnFullBleedStrips() {
        let caypullisaurus = MarineReptileLengthCatalog.measureMarineTapeDisplayScale(
            forImageName: "marine-ichthyo-caypullisaurus",
            lengthMeters: 5.0
        )
        let platecarpus = MarineReptileLengthCatalog.measureMarineTapeDisplayScale(
            forImageName: "marine-pliop-platecarpus",
            lengthMeters: 6.0
        )
        let xenodens = MarineReptileLengthCatalog.measureMarineTapeDisplayScale(
            forImageName: "marine-mosa-xenodens",
            lengthMeters: 4.0
        )
        XCTAssertEqual(caypullisaurus, 5.0 / 22.0, accuracy: 0.001)
        XCTAssertEqual(platecarpus, 6.0 / 22.0, accuracy: 0.001)
        XCTAssertEqual(xenodens, 4.0 / 22.0, accuracy: 0.001)
        XCTAssertNotEqual(caypullisaurus, platecarpus)
    }

    func testTapeVisibilityMagnification_scalesToLongerReptileWithinTape() {
        // Xenodens 4 m + Plotosaurus 10 m — longer fits ~2× before hitting 22 m cap.
        let xenodensPlotosaurus = MarineReptileLengthCatalog.tapeVisibilityMagnification(
            firstMeters: 4.0,
            secondMeters: 10.0
        )
        XCTAssertEqual(xenodensPlotosaurus, 0.75 * 22.0 / 10.0, accuracy: 0.01)

        // Henodus 1 m + Enchodus 1.5 m — hits max zoom cap.
        let tinyPair = MarineReptileLengthCatalog.tapeVisibilityMagnification(
            firstMeters: 1.0,
            secondMeters: 1.5
        )
        XCTAssertEqual(tinyPair, MarineReptileLengthCatalog.marineLengthMaxTapeVisibilityMagnification, accuracy: 0.001)

        // Shonisaurus 21 m + Elasmosaurus 14 m — already fills tape; no zoom.
        XCTAssertEqual(
            MarineReptileLengthCatalog.tapeVisibilityMagnification(firstMeters: 21.0, secondMeters: 14.0),
            1.0,
            accuracy: 0.001
        )
    }

    func testTapeVisibilityMagnification_firstPickAloneUsesItsLength() {
        let mag = MarineReptileLengthCatalog.tapeVisibilityMagnification(firstMeters: 10.0, secondMeters: nil)
        XCTAssertEqual(mag, 0.75 * 22.0 / 10.0, accuracy: 0.01)
    }

    func testTapeVisibilityMagnification_largeReptileStaysAtOneX() {
        // Mosasaurus 17 m — already ~77% of tape; no marginal zoom or vector labels.
        XCTAssertEqual(
            MarineReptileLengthCatalog.tapeVisibilityMagnification(firstMeters: 17.0, secondMeters: nil),
            1.0,
            accuracy: 0.001
        )
    }

    func testTapeRulerLabelIntervalMeters_spreadsLabelsWhenCrowded() {
        XCTAssertEqual(
            MarineReptileLengthCatalog.tapeRulerLabelIntervalMeters(visibleMeters: 22, clipWidth: 280),
            3
        )
        XCTAssertEqual(
            MarineReptileLengthCatalog.tapeRulerLabelIntervalMeters(visibleMeters: 3, clipWidth: 280),
            1
        )
    }

    func testMarineRoundLengthsAreFullyComparable() {
        XCTAssertFalse(
            MarineReptileLengthCatalog.marineRoundLengthsAreFullyComparable([1.0, 11, 12, 10, 14, 15, 17, 6, 8])
        )
        XCTAssertTrue(
            MarineReptileLengthCatalog.marineRoundLengthsAreFullyComparable([1.0, 2.5, 3.0, 3.5, 4.0, 6, 8, 10, 12])
        )
    }

    func testMakeRoundItemsMarineReptiles_everyChoiceHasPartner() {
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .marineReptiles)
        XCTAssertGreaterThanOrEqual(round.count, 9)
        let lengths = round.map(\.heightMeters)
        XCTAssertTrue(MarineReptileLengthCatalog.marineRoundLengthsAreFullyComparable(lengths))
    }
}
