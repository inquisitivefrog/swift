//
//  MarineReptileMechanicCatalogXCTests.swift
//  DinoGamesTests
//
//  Cross-game smoke: every shipping marine config builds without fatal errors.
//  Per-game contracts (config, assets, audio, display moments, rounds) live in
//  dedicated *XCTests.swift files.
//

import XCTest
@testable import DinoGames

final class MarineReptileMechanicCatalogXCTests: XCTestCase {

    func testAllShippingMarineGameConfigsBuildWithoutFatalError() {
        XCTAssertNoThrow {
            _ = WeighGameConfigs.weighMarineReptile
            _ = WhoIsTallerGameConfigs.whichMarineReptileIsLonger
            _ = MarineReptilePuzzleGameConfigs.marinePuzzle
            _ = GuessGameConfigs.nameThatMarineReptile
            _ = RacingGameConfigs.racingMarineReptiles
            _ = DinoAgesGameConfigs.marineAges
            if let footprints = GuessGameConfigs.makeMarineFootprints() {
                _ = footprints
            }
            if MarineFloraGameConfigs.isPlayable {
                _ = MarineFloraGameConfigs.marineFlora
            }
            if let eggs = MarineEggsGameConfigs.makeMarineEggs() {
                _ = eggs
            }
            if let matrix = MarineMatrixGameConfigs.makeMarineMatrix() {
                _ = matrix
            }
            _ = MatchingGameConfigs.marineDietFeatures
            if let smile = GuessGameConfigs.makeMarineSmile() {
                _ = smile
            }
        }
    }
}
