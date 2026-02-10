//
//  PterosaurGameCatalog.swift
//  DinoGames
//
//  Games for Air category (Pterosaurs). Order determines display order in game selection.
//

import Foundation

enum PterosaurGameCatalog {
    static var games: [GameType] {
        [
            .matching(MatchingGameConfigs.pterosaurFeatures),
            .weigh(WeighGameConfigs.weighPterosaur),       // Weigh the Pterosaur
            .balance(BalanceGameConfigs.balancePterosaur),  // Balance the Pterosaurs
            .guess(GuessGameConfigs.nameThatPterosaur),     // Name That Pterosaur
            .racing(RacingGameConfigs.racingPterosaursCardConfig), // Racing Pterosaurs!
        ]
    }
}
