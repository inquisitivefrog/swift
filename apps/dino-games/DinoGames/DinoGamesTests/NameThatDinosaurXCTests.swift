//
//  NameThatDinosaurXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Name That Dinosaur (land L2).
//

import XCTest
@testable import DinoGames

final class NameThatDinosaurXCTests: XCTestCase {

    private var config: GuessGameConfig { GuessGameConfigs.nameThatDinosaur }

    private var nameThatPool: [Dinosaur] {
        LandDinosaurData.allDinosaurs.filter { $0.imageName?.hasPrefix("dino-") == true }
    }

    private var nameThatMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "name-that-dinosaur" }
    }

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "nameThatDinosaurUsedCreatureIds")
        UserDefaults.standard.removeObject(forKey: "nameThatDinosaurUsedCladeRawValues")
    }

    // MARK: - Config / catalog

    func testNameThatDinosaurConfigIdAndIntro() {
        XCTAssertEqual(config.id, "name-that-dinosaur")
        XCTAssertEqual(config.title, "Name That Dinosaur!")
        XCTAssertEqual(config.introAudio, "can-you-name-the-dinosaur")
    }

    func testNameThatDinosaurAppearsOnLevel2() {
        let level2 = DinosaurGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "name-that-dinosaur" },
            "Name That Dinosaur should appear on land level 2"
        )
    }

    func testNameThatDinosaurPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-name-that-dinosaur"), "Missing picker art: game-name-that-dinosaur")
        XCTAssertTrue(
            known.contains("game-name-that-dinosaur-success") || known.contains("game-name-that-dinosaur"),
            "Missing victory art for name-that-dinosaur"
        )
    }

    func testNameThatDinosaurUsesFullLandCatalogAsOptionsPool() {
        XCTAssertEqual(config.availableDinosaurs.count, LandDinosaurData.allDinosaurs.count)
    }

    // MARK: - Playable pool

    func testNameThatDinosaurPoolHasEnoughCreatures() {
        XCTAssertGreaterThanOrEqual(nameThatPool.count, 3)
    }

    func testEveryCladeHasPlayableCreatureInNameThatPool() {
        for clade in DinoClade.allCases {
            let hasMember = nameThatPool.contains {
                LandDinosaurCladeCatalog.clade(forCreatureId: $0.id) == clade
            }
            XCTAssertTrue(
                hasMember,
                "Clade \(clade.rawValue) needs at least one dinosaur in the Name That pool"
            )
        }
    }

    func testNameThatPoolSilhouettesBundled() {
        let known = ImageAssetNames.knownAssets
        for dino in nameThatPool {
            guard let base = dino.imageName else {
                XCTFail("Dinosaur \(dino.name) missing imageName")
                continue
            }
            let slug = base.replacingOccurrences(of: "dino-", with: "")
            let silhouette = "dino-silhouette-\(slug)"
            XCTAssertTrue(
                known.contains(silhouette),
                "Missing silhouette imageset \(silhouette) for \(dino.name)"
            )
        }
    }

    // MARK: - Round structure

    func testNameThatDinosaurProductionConfigThreeRounds() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct dinosaur")
    }

    func testNameThatDinosaurRoundOptionsAndSilhouettes() {
        let known = ImageAssetNames.knownAssets
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertEqual(Set(round.options.map(\.id)).count, 3)
            XCTAssertTrue(round.options.contains { $0.id == round.correctAnswerId })

            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            let slug = correct.imageName?.replacingOccurrences(of: "dino-", with: "") ?? ""
            XCTAssertEqual(round.questionImageName, "dino-silhouette-\(slug)")
            XCTAssertEqual(round.questionImageFallback, correct.imageName)
            XCTAssertTrue(known.contains(round.questionImageName), "Missing silhouette: \(round.questionImageName)")
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Missing body art: \(fallback)")
            }
        }
    }

    func testNameThatDinosaurQuestionCladesAreDistinct() {
        let correctIds = config.rounds.map(\.correctAnswerId)
        let clades = Set(correctIds.map { LandDinosaurCladeCatalog.clade(forCreatureId: $0) })
        XCTAssertEqual(clades.count, 3, "Each round should question a dinosaur from a different clade")
    }

    func testNameThatDinosaurDecoysAreNotQuestionClade() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            let questionClade = LandDinosaurCladeCatalog.clade(forCreatureId: correct.id)
            let decoys = round.options.filter { $0.id != round.correctAnswerId }
            XCTAssertEqual(decoys.count, 2)
            for decoy in decoys {
                XCTAssertNotEqual(
                    LandDinosaurCladeCatalog.clade(forCreatureId: decoy.id),
                    questionClade,
                    "Decoy \(decoy.name) must not share clade with question \(correct.name)"
                )
            }
        }
    }

    // MARK: - Audio

    @MainActor
    func testNameThatDinosaurIntroAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [config.introAudio],
            messagePrefix: "Name That Dinosaur intro"
        )
    }

    @MainActor
    func testNameThatDinosaurGameplayFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["thats-right-you-guessed-it", "try-again"],
            messagePrefix: "Name That Dinosaur feedback"
        )
    }

    // MARK: - Display moments

    func testNameThatDinosaurDisplayMomentsCoverAllRoundOptions() {
        XCTAssertEqual(nameThatMoments.count, 9, "Expected three rounds × three options")
    }

    func testNameThatDinosaurDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = nameThatMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testNameThatDinosaurDisplayMomentsHaveResolvableAudio() {
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
