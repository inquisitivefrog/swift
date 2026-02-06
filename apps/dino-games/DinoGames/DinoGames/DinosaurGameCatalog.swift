//
//  DinosaurGameCatalog.swift
//  DinoGames
//
//  Games for Land category (Dinosaurs). Order determines display order in game selection.
//

import Foundation

enum DinosaurGameCatalog {
    static var games: [GameType] {
        [
            .matching(MatchingGameConfigs.dinoFeatures),
            .weigh(WeighGameConfigs.weighDinosaur),
            .balance(BalanceGameConfigs.balanceDinosaur),
            .guess(GuessGameConfigs.nameThatDinosaur),
            .findMama(FindMamaConfigs.findMama),
            .dinoLunch(DinoLunchConfigs.dinoLunch),
            .toothache(ToothacheGameConfigs.toothache),
            .racing(RacingGameConfigs.racingDinosaurs),
            .matrixMaterials(MatrixMaterialsGameConfigs.matrixMaterials),
            .dinoAges(DinoAgesGameConfigs.dinoAges),
            .wacky(WackyGameConfigs.wackyDinosaurs),
        ]
    }
}
