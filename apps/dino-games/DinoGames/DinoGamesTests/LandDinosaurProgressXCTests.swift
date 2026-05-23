//
//  LandDinosaurProgressXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurProgressXCTests: XCTestCase {

    func testCanonicalRuntimeIdsMapToCatalogIds() {
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "dino-push-jurassic"), "dino-push")
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "racing-dinosaurs-cretaceous"), "racing-dinosaurs")
        XCTAssertEqual(LandDinosaurProgress.canonicalId(for: "weigh-dinosaur"), "weigh-dinosaur")
    }

    func testConceptPrerequisiteLists() {
        XCTAssertEqual(LandDinosaurGamePairing.prerequisites(before: "balance-the-dinosaur"), ["weigh-dinosaur"])
        XCTAssertEqual(LandDinosaurGamePairing.prerequisites(before: "measure-the-dinosaur"), ["which-dino-is-taller"])
        XCTAssertEqual(LandDinosaurGamePairing.prerequisites(before: "dino-formations"), ["dino-matrix", "dino-habitats"])
        XCTAssertEqual(LandDinosaurGamePairing.prerequisites(before: "dino-habitats"), ["dino-flora", "dino-fauna"])
        XCTAssertTrue(LandDinosaurGamePairing.prerequisites(before: "wacky-dinosaurs").isEmpty)
        XCTAssertTrue(LandDinosaurGamePairing.prerequisites(before: "dino-footprints").isEmpty)
        XCTAssertEqual(LandDinosaurGamePairing.prerequisites(before: "dino-trackways"), ["dino-footprints"])
    }

    func testLandCatalogCanonicalIdSetCoversCatalog() {
        let fromCatalog = Set(DinosaurGameCatalog.games.compactMap { $0.id.map { LandDinosaurProgress.canonicalId(for: $0) } })
        XCTAssertEqual(fromCatalog, LandDinosaurProgress.allLandGameCanonicalIds)
    }
}
