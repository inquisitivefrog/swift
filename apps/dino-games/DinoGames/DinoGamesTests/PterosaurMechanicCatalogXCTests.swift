//
//  PterosaurMechanicCatalogXCTests.swift
//  DinoGamesTests
//
//  Cross-game smoke: every shipping air config builds without fatal errors.
//  Per-game contracts (config, assets, audio, display moments, rounds) live in
//  dedicated *XCTests.swift files.
//

import XCTest
@testable import DinoGames

final class PterosaurMechanicCatalogXCTests: XCTestCase {

    func testAllShippingAirGameConfigsBuildWithoutFatalError() {
        XCTAssertNoThrow {
            _ = WeighGameConfigs.weighPterosaur
            _ = WhoIsTallerGameConfigs.whoIsTallerPterosaur
            _ = PteroPuzzleGameConfigs.pteroPuzzle
            _ = GuessGameConfigs.nameThatPterosaur
            _ = RacingGameConfigs.racingPterosaursCardConfig
            _ = DinoAgesGameConfigs.pteroAges
            _ = GuessGameConfigs.pteroFootprints
            _ = PteroFloraGameConfigs.pteroFloraKarabastau
            _ = PteroEggsGameConfigs.pteroEggs
            if let matrix = PteroMatrixGameConfigs.makePteroMatrix() {
                _ = matrix
            }
            _ = MatchingGameConfigs.pteroDietFeatures
            if SmilingDinosGameConfigs.isPteroSmilePlayable {
                _ = SmilingDinosGameConfigs.pteroSmile
            }
        }
    }
}
