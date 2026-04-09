//
//  MarineReptileGameCatalog.swift
//  DinoGames
//
//  Per-lineage marine game lists with the same level ladder as land dinosaurs.
//

import Foundation

enum MosasaurGameCatalog {
    static var games: [GameType] {
        GameLevel.allCases.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [.guess(GuessGameConfigs.nameThatMosasaur)]
        default:
            return []
        }
    }
}

enum PlesiosaurGameCatalog {
    static var games: [GameType] {
        GameLevel.allCases.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [.guess(GuessGameConfigs.nameThatPlesiosaur)]
        default:
            return []
        }
    }
}

enum IchthyosaurGameCatalog {
    static var games: [GameType] {
        GameLevel.allCases.flatMap { games(level: $0) }
    }

    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [.guess(GuessGameConfigs.nameThatIchthyosaur)]
        default:
            return []
        }
    }
}
