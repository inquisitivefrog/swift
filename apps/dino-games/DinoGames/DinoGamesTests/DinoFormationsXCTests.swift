//
//  DinoFormationsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinoFormationsXCTests: XCTestCase {

    func testDinoFormationsJSONFoldersExist() {
        let root = TestBundleHelpers.projectRootURL()
        XCTAssertTrue(
            TestBundleHelpers.directoryExists(root.appendingPathComponent("json/dino-formations")),
            "Missing json/dino-formations"
        )
        XCTAssertTrue(
            TestBundleHelpers.directoryExists(root.appendingPathComponent("json/dinosaurs")),
            "Missing json/dinosaurs"
        )
    }

    func testLoadFormationsFromJSONProducesPlayableSet() {
        let root = TestBundleHelpers.projectRootURL()
        let formations = DinoFormationsCatalog.loadFormations(resourceRoot: root)
        XCTAssertGreaterThanOrEqual(
            formations.count,
            3,
            "Expected at least three playable formations from json/dino-formations + char JSON"
        )
        for formation in formations {
            XCTAssertGreaterThanOrEqual(
                formation.dinoImageNames.count,
                3,
                "Formation \(formation.id) needs ≥3 species"
            )
            XCTAssertFalse(formation.name.isEmpty)
            XCTAssertEqual(formation.imageName, "formation-\(formation.id)")
        }
    }

    func testHellCreekFormationIncludesTRex() {
        let root = TestBundleHelpers.projectRootURL()
        let formations = DinoFormationsCatalog.loadFormations(resourceRoot: root)
        let hellCreek = formations.first { $0.id == "hell-creek" }
        XCTAssertNotNil(hellCreek, "Expected hell-creek formation from hell_creek_formation.json")
        XCTAssertTrue(
            hellCreek?.dinoImageNames.contains("dino-trex") == true,
            "Hell Creek should include T-Rex from char_trex.json"
        )
    }

    func testMorrisonFormationAggregatesMORRISONCharIDs() {
        let root = TestBundleHelpers.projectRootURL()
        let formations = DinoFormationsCatalog.loadFormations(resourceRoot: root)
        let morrison = formations.first { $0.id == "morrison" }
        XCTAssertNotNil(morrison, "Expected morrison formation from morrison_formation.json")
        XCTAssertTrue(
            morrison?.dinoImageNames.contains("dino-brachiosaurus") == true,
            "MORRISON char slugs should match morrison_formation.json (MORRISON_LJ)"
        )
        XCTAssertTrue(
            morrison?.dinoImageNames.contains("dino-stegosaurus") == true,
            "Expected Morrison sauropods/ornithischians from char JSON"
        )
    }

    func testCatalogPlayableFormationsIsNonEmpty() {
        XCTAssertGreaterThanOrEqual(DinoFormationsCatalog.playableFormations.count, 3)
    }

    func testFormationsPoolMatchesNameThatDinosaurPortraitPool() {
        let expected = LandDinosaurData.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        let names = Set(expected.compactMap(\.imageName))
        XCTAssertGreaterThanOrEqual(names.count, 3)
        XCTAssertTrue(names.contains("dino-trex"))
        XCTAssertTrue(names.contains("dino-triceratops"))
    }
}
