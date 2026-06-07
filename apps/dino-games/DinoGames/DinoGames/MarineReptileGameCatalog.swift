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
                .whoIsTaller(WhoIsTallerGameConfigs.whichMarineReptileIsLonger),
                .marinePuzzle(MarineReptilePuzzleGameConfigs.marinePuzzle),
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatMarineReptile),
                .racing(RacingGameConfigs.racingMarineReptiles),
                .dinoAges(DinoAgesGameConfigs.marineAges),
            ]
        case .level3:
            if let eggs = MarineEggsGameConfigs.makeMarineEggs() {
                return [.marineEggs(eggs)] // Marine Eggs!
            }
            return []
        case .level4:
            var level4: [GameType] = [
                .matching(MatchingGameConfigs.marineDietFeatures), // Marine Diets
            ]
            if let matrix = MarineMatrixGameConfigs.makeMarineMatrix() {
                level4.insert(.marineMatrix(matrix), at: 0) // Marine Matrix (when fossil image sets are bundled)
            }
            return level4
        default:
            return []
        }
    }
}
