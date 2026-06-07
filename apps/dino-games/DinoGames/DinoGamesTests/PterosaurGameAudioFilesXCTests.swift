//
//  PterosaurGameAudioFilesXCTests.swift
//  DinoGamesTests
//
//  Per-game audio contracts for air (pterosaur) catalog games. Creature-name coverage
//  remains in `PterosaurAudioFilesXCTests`; this file asserts bundle resolution the same
//  way gameplay loads clips (`SpeechManager.urlForAudio`).
//

import XCTest
@testable import DinoGames

final class PterosaurGameAudioFilesXCTests: XCTestCase {

    func testAirGameCatalogHasAudioContractForEveryPlacedGame() {
        let placed = GameCatalog.allPlacedGames().filter { $0.category == .air }
        XCTAssertFalse(placed.isEmpty, "Expected air games in the visible catalog.")

        let contractedIds = Set(PterosaurGameAudioContracts.all.map(\.configId))
        for slot in placed {
            guard let configId = slot.game.id else {
                XCTFail("Air game at level \(slot.level.number) has no config id.")
                continue
            }
            XCTAssertTrue(
                contractedIds.contains(configId),
                "Missing `PterosaurGameAudioContracts` entry for `\(configId)` (\(slot.game.name)). Add required audio keys."
            )
        }
    }

    func testPterosaurGameAudioContractsHaveNoDuplicateConfigIds() {
        let ids = PterosaurGameAudioContracts.all.map(\.configId)
        let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $1.count > 1 }.map(\.key)
        XCTAssertTrue(duplicates.isEmpty, "Duplicate pterosaur audio contract config ids: \(duplicates)")
    }

    @MainActor
    func testPlacedAirGameAudioKeysResolveInBundle() {
        let placed = GameCatalog.allPlacedGames().filter { $0.category == .air }
        for slot in placed {
            guard let configId = slot.game.id else { continue }
            let keys = PterosaurGameAudioContracts.allRequiredKeys(forConfigId: configId)
            XCTAssertFalse(
                keys.isEmpty,
                "No audio keys listed for air game `\(configId)`."
            )
            TestBundleHelpers.assertBundleResolvesAudioKeys(
                keys,
                messagePrefix: "\(slot.game.name) (`\(configId)`)"
            )
        }
    }

    @MainActor
    func testPterosaurGameIntroAudioKeysFromConfigsResolveInBundle() {
        let speech = SpeechManager()
        let introChecks: [(configId: String, introKey: String, fallbacks: [String])] = [
            (configId: "weigh-pterosaur", introKey: WeighGameConfigs.weighPterosaur.introAudio, fallbacks: ["game-weigh-pterosaur"]),
            (configId: "which-ptero-is-taller", introKey: WhoIsTallerGameConfigs.whoIsTallerPterosaur.introAudio, fallbacks: []),
            (configId: "ptero-puzzle", introKey: PteroPuzzleGameConfigs.pteroPuzzle.introAudio, fallbacks: []),
            (configId: "name-that-pterosaur", introKey: GuessGameConfigs.nameThatPterosaur.introAudio, fallbacks: ["game-can-you-name-that-pterosaur"]),
            (configId: "racing-pterosaurs", introKey: RacingGameConfigs.racingPterosaursCardConfig.introAudio, fallbacks: ["game-racing-pterosaurs"]),
            (configId: "ptero-ages", introKey: DinoAgesGameConfigs.pteroAges.introAudio ?? "", fallbacks: []),
            (configId: "ptero-footprints", introKey: GuessGameConfigs.pteroFootprints.introAudio, fallbacks: []),
            (configId: "ptero-flora", introKey: PteroFloraGameConfigs.pteroFloraKarabastau.introAudio ?? "", fallbacks: []),
            (configId: "ptero-eggs", introKey: PteroEggsGameConfigs.pteroEggs.introAudio, fallbacks: []),
            (configId: "ptero-diets", introKey: MatchingGameConfigs.pteroDietFeatures.introAudio, fallbacks: ["game-ptero-diet"]),
            (configId: "ptero-smile", introKey: SmilingDinosGameConfigs.pteroSmile.introAudio, fallbacks: []),
            (configId: "balance-the-pterosaur", introKey: BalanceGameConfigs.balancePterosaur.introAudio, fallbacks: []),
            (configId: "match-the-pterosaur", introKey: MatchingGameConfigs.pterosaurFeatures.introAudio, fallbacks: ["game-match-the-pterosaur", "game-can-you-match-each-pterosaur"]),
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

    @MainActor
    func testPteroMatrixIntroResolvesWhenGameIsPlaced() {
        guard PteroMatrixGameConfigs.makePteroMatrix() != nil else { return }
        let placed = GameCatalog.allPlacedGames().filter { $0.category == .air }
        guard placed.contains(where: { $0.game.id == "ptero-matrix" }) else { return }

        let speech = SpeechManager()
        let intro = PteroMatrixGameConfigs.makePteroMatrix()!.introAudio
        XCTAssertTrue(
            speech.urlForAudio(key: intro) != nil,
            "Ptero Matrix intro `\(intro)` should resolve when the game is in the catalog."
        )
    }

    @MainActor
    func testPteroEggsMorphotypeAudioResolvesInBundleWhenPresent() {
        let keys = PterosaurGameAudioContracts.pteroEggsMorphotypeAudioKeysOnDisk()
        let speech = SpeechManager()
        let missing = keys.filter { speech.urlForAudio(key: $0) == nil }.sorted()
        XCTAssertTrue(
            missing.isEmpty,
            """
            Missing Ptero Eggs morphotype narration (expected under Assets/Audio/Eggs/Pterosaurs/ as \
            ptero-eggs-{clade}.m4a and ptero-nests-{clade}.m4a): \(missing)
            """
        )
    }
}
