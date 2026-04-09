//
//  DinoGamesTests.swift
//  DinoGamesTests
//
//  Additional coverage: LandDinosaurCladeCatalogXCTests, GuessSilhouetteGameXCTests,
//  LandDinosaurCladeCatalogSwiftTests, GuessSilhouetteGameSwiftTests.

import XCTest
@testable import DinoGames

final class DinoGamesTests: XCTestCase {

    func testTestableImportLinksMainTarget() {
        XCTAssertFalse(MatchingGameLandDinosaurData.allDinosaurs.isEmpty)
        XCTAssertFalse(DinoClade.allCases.isEmpty)
    }
}
