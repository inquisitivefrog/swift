//
//  DinosaurGameCatalog.swift
//  DinoGames
//
//  Games for Land category (Dinosaurs). Ten levels; 0–5+ games per level. Visual: level image shows dinosaur size (small = level 1, bigger = level 2, etc.) so pre-readers can tell them apart. Audio: e.g. "Level One Really Easy Games"; files in Audio/Levels/level-*-.m4a.
//

import Foundation

/// Difficulty level for dinosaur games (1–10). Shown as a picker between Dinosaurs and the game list.
/// Use image with small dinosaur for level 1, bigger for level 2, etc. Audio: level-1-really-easy-games, … (map in SpeechManager to Levels/level-*-.m4a).
enum GameLevel: String, CaseIterable, Identifiable {
    case level1
    case level2
    case level3
    case level4
    case level5
    case level6
    case level7
    case level8
    case level9
    case level10

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
        case .level7: return 7
        case .level8: return 8
        case .level9: return 9
        case .level10: return 10
        }
    }

    var title: String { "Level \(number)" }

    /// Title spoken when showing the game list for this level (e.g. "Level 1 — Really Easy Games").
    var gameListTitle: String {
        let subtitle: String
        switch self {
        case .level1: subtitle = "Really Easy Games"
        case .level2: subtitle = "More Really Easy Games"
        case .level3: subtitle = "Easy Games"
        case .level4: subtitle = "More Easy Games"
        case .level5: subtitle = "Getting Harder"
        case .level6: subtitle = "And Harder"
        case .level7: subtitle = "Hard Games"
        case .level8: subtitle = "Are You Sure You're Ready?"
        case .level9: subtitle = "Impossible Games"
        case .level10: subtitle = "Good Luck You'll Need It"
        }
        return "\(title) — \(subtitle)"
    }

    /// Asset name for level card: dino-level-one (small dino), dino-level-two (bigger), … Pre-readers distinguish by size.
    var imageName: String {
        let names = [
            "dino-level-one", "dino-level-two", "dino-level-three", "dino-level-four", "dino-level-five",
            "dino-level-six", "dino-level-seven", "dino-level-eight", "dino-level-nine", "dino-level-ten",
        ]
        return names[number - 1]
    }

    /// Asset name for Air (pterosaur) level picker cards: `ptero-level-one` … `ptero-level-ten` in Assets.
    var pterosaurLevelImageName: String {
        let names = [
            "ptero-level-one", "ptero-level-two", "ptero-level-three", "ptero-level-four", "ptero-level-five",
            "ptero-level-six", "ptero-level-seven", "ptero-level-eight", "ptero-level-nine", "ptero-level-ten",
        ]
        return names[number - 1]
    }

    /// Badge image for land level intermission (`game-level-one` … `game-level-ten` in Assets).
    var gameLevelBadgeImageName: String {
        let names = [
            "game-level-one", "game-level-two", "game-level-three", "game-level-four", "game-level-five",
            "game-level-six", "game-level-seven", "game-level-eight", "game-level-nine", "game-level-ten",
        ]
        return names[number - 1]
    }

    /// Audio key for intro when this level is chosen (e.g. "Level One Really Easy Games"). Map in SpeechManager to Levels/level-*-.m4a.
    var introAudioKey: String {
        switch self {
        case .level1: return "level-1-really-easy-games"
        case .level2: return "level-2-more-really-easy-games"
        case .level3: return "level-3-easy-games"
        case .level4: return "level-4-more-easy-games"
        case .level5: return "level-5-getting-harder"
        case .level6: return "level-6-and-harder"
        case .level7: return "level-7-hard-games"
        case .level8: return "level-8-are-you-sure-youre-ready"
        case .level9: return "level-9-impossible-games"
        case .level10: return "level-10-good-luck-youll-need-it"
        }
    }

    var zeroOrderedIndex: Int {
        GameLevel.allCases.firstIndex(of: self) ?? 0
    }
}

extension GameLevel {
    /// Levels shown in each category’s level picker (land / air / marine). Levels 5+ remain on the enum for assets and future releases but are omitted from the picker and from catalog `games` aggregation until re-enabled.
    static let visibleInGamePicker: [GameLevel] = [.level1, .level2, .level3, .level4]
}

enum DinosaurGameCatalog {
    /// All dinosaur games in difficulty order (used when no level filter).
    static var games: [GameType] {
        GameLevel.visibleInGamePicker.flatMap { games(level: $0) }
    }

    /// Games for a specific level. Order = display order. Empty levels return [] (UI shows “coming soon”).
    static func games(level: GameLevel) -> [GameType] {
        switch level {
        case .level1:
            return [
                .weigh(WeighGameConfigs.weighDinosaur),        // Weigh the Dinosaur
                .whoIsTaller(WhoIsTallerGameConfigs.whoIsTaller), // Which Dino Is Taller
                .dinoPuzzle(DinoPuzzleGameConfigs.dinoPuzzle), // Dino Puzzle
            ]
        case .level2:
            return [
                .guess(GuessGameConfigs.nameThatDinosaur),      // Name That Dinosaur
                .racing(RacingGameConfigs.racingDinosaurs),     // Racing Dinosaurs
                .dinoAges(DinoAgesGameConfigs.dinoAges),           // Dino Ages
            ]
        case .level3:
            return [
                .guess(GuessGameConfigs.dinoFootprints),        // Dino Footprints
                .dinoFlora(DinoFloraGameConfigs.dinoFlora),    // Dino Flora!
                .dinoEggs(DinoEggsGameConfigs.dinoEggs),       // Dino Eggs!
            ]
        case .level4:
            return [
                .dinoMatrix(DinoMatrixGameConfigs.dinoMatrix), // Dino Matrix
                .matching(MatchingGameConfigs.dinoDietFeatures), // Dino Diets!
                .smilingDinos(SmilingDinosGameConfigs.smilingDinos), // Dino Smile!
            ]
        case .level5:
            return [
                .guess(GuessGameConfigs.whoseBones),            // Whose Bones? (before Dino Bones — concept pair)
                .dinoTools(DinoToolsGameConfigs.dinoTools),   // Dino Tools!
                .dinoFauna(DinoFaunaGameConfigs.dinoFauna),   // Dino Fauna!
            ]
        case .level6:
            return [
                .balance(BalanceGameConfigs.balanceDinosaur),   // Balance the Dinosaurs
                .measure(MeasureGameConfigs.measureDinosaur),   // Measure the Dinosaur!
                .dinoHabitats(DinoHabitatsGameConfigs.dinoHabitats), // Dino Habitats
            ]
        case .level7:
            return [
                .dinoPush(DinoPushGameConfigs.dinoPushNeedsPeriod),        // Dino Push!
                .matching(MatchingGameConfigs.dinoFeatures),   // Match the Dinosaur
                .guess(GuessGameConfigs.dinoBones),            // Dino Bones! (after Whose Bones — concept pair)
            ]
        case .level8:
            return [
                .dinoFossilHunt(DinoFossilHuntGameConfigs.dinoFossilHunt), // Dino Fossil Hunt!
                .toothache(ToothacheGameConfigs.toothache),    // Dino Toothache
                .findMama(FindMamaConfigs.findMama),           // Find Mama
            ]
        case .level9:
            return [
                .dinoLunch(DinoLunchConfigs.dinoLunch),        // Dino Lunch
                .wacky(WackyGameConfigs.wackyDinosaurs),       // Wacky Dinosaurs
            ]
        case .level10:
            return [
                .dinoFormations(DinoFormationsGameConfigs.dinoFormations), // Dino Formations
            ]
        }
    }
}
