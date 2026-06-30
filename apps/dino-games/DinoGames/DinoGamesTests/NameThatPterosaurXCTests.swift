//
//  NameThatPterosaurXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Name That Pterosaur (air L2).
//

import XCTest
@testable import DinoGames

final class NameThatPterosaurXCTests: XCTestCase {

    private var config: GuessGameConfig { GuessGameConfigs.nameThatPterosaur }

    private var nameThatPool: [Dinosaur] {
        AirPterosaurData.nameThatPterosaurPool
    }

    private var nameThatMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments().filter { $0.gameConfigId == "name-that-pterosaur" }
    }

    // MARK: - Config / catalog

    func testNameThatPterosaurConfigIdAndIntro() {
        XCTAssertEqual(config.id, "name-that-pterosaur")
        XCTAssertEqual(config.title, "Name That Pterosaur!")
        XCTAssertEqual(config.introAudio, "can-you-name-the-pterosaur")
    }

    func testNameThatPterosaurAppearsOnLevel2() {
        let level2 = PterosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "name-that-pterosaur" },
            "Name That Pterosaur should appear on air level 2"
        )
    }

    func testNameThatPterosaurPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-name-that-pterosaur"), "Missing picker art: game-name-that-pterosaur")
        XCTAssertTrue(
            known.contains("game-name-that-pterosaur-success") || known.contains("game-name-that-pterosaur"),
            "Missing victory art for name-that-pterosaur"
        )
    }

    func testNameThatPterosaurUsesFullPterosaurCatalogAsOptionsPool() {
        XCTAssertEqual(config.availableDinosaurs.count, MatchingGameConfigs.allPterosaurs.count)
    }

    // MARK: - Playable pool

    func testNameThatPterosaurPoolHasEnoughCreatures() {
        XCTAssertGreaterThanOrEqual(nameThatPool.count, 3)
    }

    func testEveryGuessGroupHasPlayableCreatureInNameThatPool() {
        for group in PterosaurGuessGroup.allCases {
            let hasMember = nameThatPool.contains {
                PterosaurGuessGroup.guessGroup(forImageName: $0.imageName ?? "") == group
            }
            XCTAssertTrue(
                hasMember,
                "Guess group \(group.rawValue) needs at least one pterosaur in the Name That pool"
            )
        }
    }

    func testNameThatPterosaurPoolSilhouettesBundled() {
        let known = ImageAssetNames.knownAssets
        for ptero in nameThatPool {
            guard let base = ptero.imageName else {
                XCTFail("Pterosaur \(ptero.name) missing imageName")
                continue
            }
            let silhouette = AirPterosaurData.silhouetteAssetName(forBodyImage: base)
            XCTAssertTrue(
                known.contains(silhouette),
                "Missing silhouette imageset \(silhouette) for \(ptero.name)"
            )
        }
    }

    // MARK: - Round structure

    func testNameThatPterosaurProductionConfigThreeRounds() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct pterosaur")
    }

    func testNameThatPterosaurRoundOptionsAndSilhouettes() {
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertEqual(Set(round.options.map(\.id)).count, 3)
            XCTAssertTrue(round.options.contains { $0.id == round.correctAnswerId })

            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            guard let base = correct.imageName else {
                XCTFail("Round \(round.id) correct option missing imageName")
                continue
            }
            let expectedSilhouette = AirPterosaurData.silhouetteAssetName(forBodyImage: base)
            XCTAssertEqual(round.questionImageName, expectedSilhouette)
            XCTAssertEqual(round.questionImageFallback, correct.imageName)
            XCTAssertTrue(known.contains(round.questionImageName), "Missing silhouette: \(round.questionImageName)")
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Missing body art: \(fallback)")
            }
        }
    }

    func testNameThatPterosaurDecoysAreNotQuestionGuessGroup() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            let questionGroup = PterosaurGuessGroup.guessGroup(forImageName: correct.imageName ?? "")
            let decoys = round.options.filter { $0.id != round.correctAnswerId }
            XCTAssertEqual(decoys.count, 2)
            for decoy in decoys {
                XCTAssertNotEqual(
                    PterosaurGuessGroup.guessGroup(forImageName: decoy.imageName ?? ""),
                    questionGroup,
                    "Decoy \(decoy.name) must not share guess group with question \(correct.name)"
                )
            }
        }
    }

    // MARK: - Audio

    @MainActor
    func testNameThatPterosaurIntroAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [config.introAudio],
            messagePrefix: "Name That Pterosaur intro"
        )
    }

    @MainActor
    func testNameThatPterosaurGameplayFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["thats-right-you-guessed-it", "try-again"],
            messagePrefix: "Name That Pterosaur feedback"
        )
    }

    // MARK: - Display moments

    func testNameThatPterosaurDisplayMomentsCoverSilhouettePool() {
        XCTAssertEqual(
            nameThatMoments.count,
            nameThatPool.count,
            "Expected one display moment per bundled silhouette in the Name That pool"
        )
    }

    func testNameThatPterosaurDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = nameThatMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testNameThatPterosaurDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = nameThatMoments.filter { moment in
            LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment)
                .compactMap { speech.urlForAudio(key: $0) }
                .isEmpty
        }
        let labels = missing.map { moment in
            let keys = LandGameDisplayMomentCatalog.audioCandidateKeys(for: moment).joined(separator: "|")
            return "\(moment.context) → audio `\(keys)`"
        }
        XCTAssertTrue(labels.isEmpty, "Missing bundle audio: \(labels.joined(separator: "; "))")
    }
}
