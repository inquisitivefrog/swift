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
        ]
    }
}
