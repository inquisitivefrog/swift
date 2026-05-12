//
//  MarineReptileGameCatalog.swift
//  DinoGames
//
//  Marine reptile games (Name That Marine Reptile!, Weigh the Marine Reptile!, …) with the same level ladder as land dinosaurs.
//

import Foundation

enum MarineReptileGameCatalog {
    static var games: [GameType] {
        GameLevel.visibleInGamePicker.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [
                .weigh(WeighGameConfigs.weighMarineReptile),
                .marinePuzzle(MarineReptilePuzzleGameConfigs.marinePuzzle),
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatMarineReptile),
            ]
        default:
            return []
        }
    }
}
