//
//  PterosaurGameCatalog.swift
//  DinoGames
//
//  Games for Air category (Pterosaurs). Same level structure as the dinosaur catalog; pool size comes from `AirPterosaurData`.
//

import Foundation

enum PterosaurGameCatalog {
    static var games: [GameType] {
        GameLevel.visibleInGamePicker.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [
                .weigh(WeighGameConfigs.weighPterosaur),
                .whoIsTaller(WhoIsTallerGameConfigs.whoIsTallerPterosaur),
                .pteroPuzzle(PteroPuzzleGameConfigs.pteroPuzzle),
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatPterosaur),
                .racing(RacingGameConfigs.racingPterosaursCardConfig),
                .dinoAges(DinoAgesGameConfigs.pteroAges),
            ]
        case .level3:
            return [
                .guess(GuessGameConfigs.pteroFootprints),        // Ptero Footprints
                .pteroFlora(PteroFloraGameConfigs.pteroFloraKarabastau),
                .pteroEggs(PteroEggsGameConfigs.pteroEggs),       // Ptero Eggs!
            ]
        case .level6:
            return [
                .balance(BalanceGameConfigs.balancePterosaur),
            ]
        case .level7:
            return [
                .matching(MatchingGameConfigs.pterosaurFeatures),
            ]
        default:
            return []
        }
    }
}
