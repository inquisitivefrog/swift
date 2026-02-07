//
//  DinosaurGameCatalog.swift
//  DinoGames
//
//  Games for Land category (Dinosaurs). Six levels; each level has 2 games (level 6 has 1). Visual: level image shows dinosaur size (small = level 1, bigger = level 2, etc.) so pre-readers can tell them apart. Audio: e.g. "Level One Really Easy Games".
//

import Foundation

/// Difficulty level for dinosaur games (1–6). Shown as a picker between Dinosaurs and the game list.
/// Use image with small dinosaur for level 1, bigger for level 2, etc. Audio: level-1-really-easy-games, level-2-easy-games, etc.
enum GameLevel: String, CaseIterable, Identifiable {
    case level1
    case level2
    case level3
    case level4
    case level5
    case level6

    var id: String { rawValue }

    /// Display and accessibility: "Level 1", "Level 2", …
    var number: Int {
        switch self {
        case .level1: return 1
        case .level2: return 2
        case .level3: return 3
        case .level4: return 4
        case .level5: return 5
        case .level6: return 6
        }
    }

    var title: String { "Level \(number)" }

    /// Asset name for level card: dino-level-one (small dino), dino-level-two (bigger), … dino-level-six (largest). Pre-readers distinguish by size. Prefix separates from future Pterosaur level images.
    var imageName: String {
        let names = ["dino-level-one", "dino-level-two", "dino-level-three", "dino-level-four", "dino-level-five", "dino-level-six"]
        return names[number - 1]
    }

    /// Audio key for intro when this level is chosen (e.g. "Level One Really Easy Games"). Map in SpeechManager to Games/level-1-really-easy-games.m4a etc.
    var introAudioKey: String {
        switch self {
        case .level1: return "level-1-really-easy-games"
        case .level2: return "level-2-easy-games"
        case .level3: return "level-3-getting-harder"
        case .level4: return "level-4-hard-games"
        case .level5: return "level-5-really-hard-games"
        case .level6: return "level-6-really-hard-games"
        }
    }
}

enum DinosaurGameCatalog {
    /// All dinosaur games in difficulty order (used when no level filter).
    static var games: [GameType] {
        GameLevel.allCases.flatMap { games(level: $0) }
    }

    /// Games for a specific level. Order = display order. Empty levels return [] (UI shows “coming soon”).
    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [
                .matching(MatchingGameConfigs.dinoFeatures),   // Match the Dinosaur
                .weigh(WeighGameConfigs.weighDinosaur),        // Weigh the Dinosaur
                .wacky(WackyGameConfigs.wackyDinosaurs),       // Wack Dinosaurs
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatDinosaur),      // Name That Dinosaur
                .balance(BalanceGameConfigs.balanceDinosaur),   // Balance the Dinosaurs
                .matrixMaterials(MatrixMaterialsGameConfigs.matrixMaterials), // Matrix Materials
            ]
        case .level3:
            return [
                .racing(RacingGameConfigs.racingDinosaurs),     // Racing Dinosaurs
            ]
        case .level4:
            return [
                .dinoAges(DinoAgesGameConfigs.dinoAges),           // Dino Ages
                .dinoFormations(DinoFormationsGameConfigs.dinoFormations), // Dino Formations
            ]
        case .level5:
            return [
                .toothache(ToothacheGameConfigs.toothache),    // Toothache
                .findMama(FindMamaConfigs.findMama),           // Find Mama
                .dinoLunch(DinoLunchConfigs.dinoLunch),        // Dino Lunch
            ]
        case .level6:
            return []  // empty
        }
    }
}
