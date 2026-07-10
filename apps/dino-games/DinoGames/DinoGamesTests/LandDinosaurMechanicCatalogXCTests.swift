//
//  LandDinosaurMechanicCatalogXCTests.swift
//  DinoGamesTests
//
//  Cross-game smoke: every shipping land config builds without fatal errors.
//  Per-game contracts (config, assets, audio, display moments, rounds) live in
//  dedicated *XCTests.swift files.
//

import XCTest
@testable import DinoGames

final class LandDinosaurMechanicCatalogXCTests: XCTestCase {

    func testAllShippingLandGameConfigsBuildWithoutFatalError() {
        XCTAssertNoThrow {
            _ = WeighGameConfigs.weighDinosaur
            _ = WhoIsTallerGameConfigs.whoIsTallerRandomized()
            _ = DinoPuzzleGameConfigs.dinoPuzzle
            _ = GuessGameConfigs.nameThatDinosaur
            _ = RacingGameConfigs.racingDinosaursNeedsPeriod
            _ = RacingGameConfigs.makeConfig(for: .both)
            _ = DinoAgesGameConfigs.dinoAges
            _ = GuessGameConfigs.dinoFootprints
            _ = DinoFloraGameConfigs.dinoFlora
            _ = DinoEggsGameConfigs.dinoEggs
            _ = DinoMatrixGameConfigs.dinoMatrix
            _ = MatchingGameConfigs.dinoDietFeatures
            _ = SmilingDinosGameConfigs.smilingDinos
        }
    }
}
