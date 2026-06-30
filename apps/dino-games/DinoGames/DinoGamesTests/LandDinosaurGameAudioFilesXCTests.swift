//
//  LandDinosaurGameAudioFilesXCTests.swift
//  DinoGamesTests
//
//  Per-game audio contracts for land (dinosaur) catalog games. Footprint tier narration
//  is also covered in `DinoFootprintsAssetsXCTests`; this file asserts bundle resolution
//  the same way gameplay loads clips (`SpeechManager.urlForAudio`).
//

import XCTest
@testable import DinoGames

final class LandDinosaurGameAudioFilesXCTests: XCTestCase {

    func testLandGameCatalogHasAudioContractForEveryPlacedGame() {
        let placed = GameCatalog.allPlacedGames().filter { $0.category == .land }
        XCTAssertFalse(placed.isEmpty, "Expected land games in the visible catalog.")

        let contractedIds = Set(LandDinosaurGameAudioContracts.all.map(\.configId))
        for slot in placed {
            guard let configId = slot.game.id else {
                XCTFail("Land game at level \(slot.level.number) has no config id.")
                continue
            }
            XCTAssertTrue(
                contractedIds.contains(configId),
                "Missing `LandDinosaurGameAudioContracts` entry for `\(configId)` (\(slot.game.name)). Add required audio keys."
            )
        }
    }

    func testLandGameAudioContractsHaveNoDuplicateConfigIds() {
        let ids = LandDinosaurGameAudioContracts.all.map(\.configId)
        let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $1.count > 1 }.map(\.key)
        XCTAssertTrue(duplicates.isEmpty, "Duplicate land audio contract config ids: \(duplicates)")
    }

    @MainActor
    func testPlacedLandGameAudioKeysResolveInBundle() {
        let placed = GameCatalog.allPlacedGames().filter { $0.category == .land }
        for slot in placed {
            guard let configId = slot.game.id else { continue }
            let keys = LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: configId)
            XCTAssertFalse(
                keys.isEmpty,
                "No audio keys listed for land game `\(configId)`."
            )
            TestBundleHelpers.assertBundleResolvesAudioKeys(
                keys,
                messagePrefix: "\(slot.game.name) (`\(configId)`)"
            )
        }
    }

    @MainActor
    func testLandGameIntroAudioKeysFromConfigsResolveInBundle() {
        let speech = SpeechManager()
        let introChecks: [(configId: String, introKey: String, fallbacks: [String])] = [
            (configId: "weigh-dinosaur", introKey: WeighGameConfigs.weighDinosaur.introAudio, fallbacks: ["game-intro-weigh-dinosaur"]),
            (configId: "which-dino-is-taller", introKey: WhoIsTallerGameConfigs.whoIsTaller.introAudio, fallbacks: []),
            (configId: "dino-puzzle", introKey: DinoPuzzleGameConfigs.dinoPuzzle.introAudio, fallbacks: []),
            (configId: "name-that-dinosaur", introKey: GuessGameConfigs.nameThatDinosaur.introAudio, fallbacks: []),
            (configId: "racing-dinosaurs", introKey: RacingGameConfigs.racingDinosaurs.introAudio, fallbacks: []),
            (configId: "dino-ages", introKey: DinoAgesGameConfigs.dinoAges.introAudio ?? "", fallbacks: []),
            (configId: "dino-footprints", introKey: GuessGameConfigs.dinoFootprints.introAudio, fallbacks: []),
            (configId: "dino-flora", introKey: DinoFloraGameConfigs.dinoFlora.introAudio ?? "", fallbacks: []),
            (configId: "dino-eggs", introKey: DinoEggsGameConfigs.dinoEggs.introAudio, fallbacks: []),
            (configId: "dino-matrix", introKey: DinoMatrixGameConfigs.dinoMatrix.introAudio, fallbacks: []),
            (configId: "match-the-diet", introKey: MatchingGameConfigs.dinoDietFeatures.introAudio, fallbacks: ["game-dino-diets"]),
            (configId: "smiling-dinos", introKey: SmilingDinosGameConfigs.smilingDinos.introAudio, fallbacks: []),
        ]
        for check in introChecks {
            XCTAssertFalse(check.introKey.isEmpty, "Empty intro audio key for `\(check.configId)`.")
            let candidates = [check.introKey] + check.fallbacks
            let resolved = candidates.contains { speech.urlForAudio(key: $0) != nil }
            XCTAssertTrue(
                resolved,
                "Intro audio for `\(check.configId)` not in bundle. Tried keys: \(candidates)"
            )
        }
    }

    func testVisibleLandLevelIntroAudioFilesExist() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Levels")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let stems = try TestBundleHelpers.audioStems(in: directory)
        let expected = Set(GameLevel.visibleInGamePicker.map { $0.introAudioKey.lowercased() })
        let missing = expected.subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing level-picker intro audio under Levels/: \(missing)")
    }

    func testDinoEggsMorphotypeAudioExistsOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Eggs")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        let clades = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-eggs")
            .filter { $0.hasPrefix("dino-eggs-") && !$0.contains("scans") && !$0.hasPrefix("game-") }
        let missing = Set(clades).subtracting(stems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing Dino Eggs clade narration under Dino-Eggs/: \(missing)")
    }
}
