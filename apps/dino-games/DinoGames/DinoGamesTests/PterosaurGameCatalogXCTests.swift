//
//  PterosaurGameCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurGameCatalogXCTests: XCTestCase {

    func testPteroMatrixFossilSlugMatchesBundledComposites() {
        let dimorphodon = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-basal-dimorphodon" }
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: dimorphodon!), "dimorphodon")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-shale-dimorphodon"))

        let quetz = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-azhd-quetzalcoatlus" }
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: quetz!), "quetzalcoatlus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-lignite-quetzalcoatlus"))
    }

    func testPteroMatrixConfigBuildsAndAppearsInLevel4() {
        XCTAssertNotNil(
            PteroMatrixGameConfigs.makePteroMatrix(),
            "Ptero Matrix needs at least three bundled fossil-in-matrix image sets."
        )
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-matrix" },
            "Expected Ptero Matrix in air level 4 when matrix config builds."
        )
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-diets" },
            "Expected Ptero Diets in air level 4."
        )
    }

    func testPteroMatrixGameCardImageExists() {
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-matrix"),
            "Missing picker/transition art: game-ptero-matrix.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-matrix-success"),
            "Missing victory art: game-ptero-matrix-success.imageset"
        )
    }

    func testPteroSmileIsInCatalogWhenAssetsShip() {
        XCTAssertTrue(
            SmilingDinosGameConfigs.isPteroSmilePlayable,
            "Expected enough bundled pterosaur smile portraits and matching tooth art for 3×3 rounds."
        )
        let allIds = Set(PterosaurGameCatalog.games.compactMap(\.id))
        XCTAssertTrue(
            allIds.contains("ptero-smile"),
            "Ptero Smile should appear in the air catalog when smile/tooth assets are bundled."
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-smile"),
            "Missing game card art: game-ptero-smile.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-ptero-smile-success"),
            "Missing victory art: game-ptero-smile-success.imageset"
        )
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-smile" },
            "Expected Ptero Smile in air level 4."
        )
    }

    func testPteroSmileConfigBuildsThreeRounds() {
        guard let config = SmilingDinosGameConfigs.makePteroSmile() else {
            XCTFail("makePteroSmile() returned nil — check pool size and round builder.")
            return
        }
        XCTAssertEqual(config.rounds.count, 3)
        XCTAssertEqual(config.id, "ptero-smile")
        for round in config.rounds {
            XCTAssertEqual(round.pairs.count, SmilingDinosRound.creaturesPerRound)
            XCTAssertEqual(round.distractorToothTypes.count, SmilingDinosRound.distractorTeethPerRound)
        }
    }

    func testPteroSmileBundledPortraitAndToothArt() {
        let expected: [(portrait: String, tooth: String)] = [
            ("ptero-smile-quetzalcoatlus", "ptero-smile-tooth-beak-spear"),
            ("ptero-smile-hatzegopteryx", "ptero-smile-tooth-beak-spear"),
            ("ptero-smile-anuanguera", "ptero-smile-tooth-needle-spike"),
            ("ptero-smile-ornithocheirus", "ptero-smile-tooth-needle-spike"),
            ("ptero-smile-dimorphodon", "ptero-smile-tooth-peg-slicer"),
            ("ptero-smile-rhamphorhynchus", "ptero-smile-tooth-peg-slicer"),
            ("ptero-smile-tupandactylus", "ptero-smile-tooth-nutcracker"),
            ("ptero-smile-anurognathus", "ptero-smile-tooth-micro-peg"),
            ("ptero-smile-pterodaustro", "ptero-smile-tooth-comb-filter"),
        ]
        for pair in expected {
            XCTAssertTrue(
                ImageAssetCache.imageExists(named: pair.portrait),
                "Missing portrait art: \(pair.portrait)"
            )
            XCTAssertTrue(
                ImageAssetCache.imageExists(named: pair.tooth),
                "Missing tooth art: \(pair.tooth)"
            )
        }
    }

    func testPteroEggsVictoryRecapEggDisplayTitlesAreNonEmpty() {
        let morphology = PteroEggMorphology.morphology
        for round in PteroEggsGameConfigs.pteroEggs.rounds {
            let title = morphology.eggDisplayTitle(for: round.eggType)
            XCTAssertFalse(title.isEmpty, "Victory recap needs a label for egg clade `\(round.eggType)`")
        }
    }
}
