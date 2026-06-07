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

    func testWhichMarineReptileIsLongerConfig() {
        let config = WhoIsTallerGameConfigs.whichMarineReptileIsLonger
        XCTAssertEqual(config.id, "which-marine-reptile-is-longer")
        XCTAssertEqual(config.poolKind, .marineReptiles)
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .marineReptiles)
        XCTAssertGreaterThanOrEqual(round.count, 9, "Expected at least 9 marine reptiles for a round")
    }
}
