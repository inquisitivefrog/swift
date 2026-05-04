//
//  LandDinosaurCladeCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurCladeCatalogXCTests: XCTestCase {

    func testEveryLandPoolDinosaurHasExplicitClade() {
        let ids = Set(LandDinosaurData.allDinosaurs.map(\.id))
        for id in ids {
            XCTAssertNotNil(
                LandDinosaurCladeCatalog.cladeByCreatureId[id],
                "Missing clade for land dinosaur id \(id)"
            )
        }
    }

    func testCladeLookupMatchesDictionary() {
        for id in LandDinosaurData.allDinosaurs.map(\.id) {
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

    func testPickTwoDecoysPreferDistinctNonQuestionClades() {
        let pool = LandDinosaurData.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
        guard let question = pool.first(where: { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) == .theropod }) else {
            XCTFail("Expected a theropod in land pool")
            return
        }
        let qClade = LandDinosaurCladeCatalog.clade(forCreatureId: question.id)
        let decoys = LandDinosaurCladeCatalog.pickTwoDecoysDifferentClades(question: question, questionClade: qClade, pool: pool)
        XCTAssertEqual(decoys.count, 2)
        XCTAssertFalse(decoys.contains { $0.id == question.id })
        for d in decoys {
            XCTAssertNotEqual(LandDinosaurCladeCatalog.clade(forCreatureId: d.id), qClade)
        }
        let distinctCladesInPool = Set(pool.map { LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) })
        if distinctCladesInPool.count >= 3 {
            let c0 = LandDinosaurCladeCatalog.clade(forCreatureId: decoys[0].id)
            let c1 = LandDinosaurCladeCatalog.clade(forCreatureId: decoys[1].id)
            XCTAssertNotEqual(c0, c1, "With 3+ clades in pool, decoys should use two different clades when possible")
        }
    }
}
