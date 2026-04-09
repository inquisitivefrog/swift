//
//  LandDinosaurCladeCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurCladeCatalogXCTests: XCTestCase {

    func testEveryLandPoolDinosaurHasExplicitClade() {
        let ids = Set(MatchingGameLandDinosaurData.allDinosaurs.map(\.id))
        for id in ids {
            XCTAssertNotNil(
                LandDinosaurCladeCatalog.cladeByCreatureId[id],
                "Missing clade for land dinosaur id \(id)"
            )
        }
    }

    func testCladeLookupMatchesDictionary() {
        for id in MatchingGameLandDinosaurData.allDinosaurs.map(\.id) {
            let fromMap = LandDinosaurCladeCatalog.cladeByCreatureId[id]!
            XCTAssertEqual(LandDinosaurCladeCatalog.clade(forCreatureId: id), fromMap)
        }
    }

    func testUnknownIdFallsBackToTheropod() {
        XCTAssertEqual(LandDinosaurCladeCatalog.clade(forCreatureId: -1), .theropod)
        XCTAssertNil(LandDinosaurCladeCatalog.cladeByCreatureId[-1])
    }

    func testCladeBucketCountMatchesNameThatDinosaurVariety() {
        XCTAssertEqual(DinoClade.allCases.count, 9)
    }
}
