//
//  PterosaurGameCatalog.swift
//  DinoGames
//
//  Games for Air category (Pterosaurs). Ten levels; same structure as dinosaur catalog.
//

import Foundation

enum PterosaurGameCatalog {
    static var games: [GameType] {
        GameLevel.allCases.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [
                .matching(MatchingGameConfigs.pterosaurFeatures),
                .weigh(WeighGameConfigs.weighPterosaur),
                .balance(BalanceGameConfigs.balancePterosaur),
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatPterosaur),
                .racing(RacingGameConfigs.racingPterosaursCardConfig),
            ]
        default:
            return []
        }
    }
}
