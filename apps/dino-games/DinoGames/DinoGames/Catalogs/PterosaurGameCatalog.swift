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
        case .level4:
            var level4: [GameType] = [
                .matching(MatchingGameConfigs.pteroDietFeatures), // Ptero Diets
            ]
            if let matrix = PteroMatrixGameConfigs.makePteroMatrix() {
                level4.insert(.pteroMatrix(matrix), at: 0) // Ptero Matrix (when fossil image sets are bundled)
            }
            if SmilingDinosGameConfigs.isPteroSmilePlayable {
                level4.append(.smilingDinos(SmilingDinosGameConfigs.pteroSmile))
            }
            return level4
        case .level5:
            return [
                .balance(BalanceGameConfigs.balancePterosaur),   // Balance the Pterosaurs!
                .matching(MatchingGameConfigs.pterosaurFeatures), // Match the Pterosaur
            ]
        default:
            return []
        }
    }
}
