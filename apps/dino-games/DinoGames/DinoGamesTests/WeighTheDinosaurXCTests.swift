//
//  WeighTheDinosaurXCTests.swift
//  DinoGamesTests
//
//  Game config, progress, round mechanics, and gameplay audio for Weigh the Dinosaur (land L1).
//  Catalog, display-moment, and mass contracts live in `LandDinosaurWeighCatalogXCTests`.
//

import XCTest
@testable import DinoGames

final class WeighTheDinosaurXCTests: XCTestCase {

    private var templateConfig: WeighGameConfig { WeighGameConfigs.weighDinosaur }

    // MARK: - Config / catalog

    func testWeighDinosaurConfigIdTitleAndIntro() {
        XCTAssertEqual(templateConfig.id, "weigh-dinosaur")
        XCTAssertEqual(templateConfig.title, "Weigh the Dinosaur!")
        XCTAssertEqual(templateConfig.introAudio, "game-intro-weigh")
    }

    func testWeighDinosaurAppearsOnLevel1() {
        let level1 = DinosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "weigh-dinosaur" },
            "Weigh the Dinosaur should appear on land level 1"
        )
    }

    func testWeighDinosaurProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("weigh-dinosaur"), .land)
    }

    func testWeighDinosaurIsPrerequisiteForBalance() {
        XCTAssertEqual(
            LandDinosaurGamePairing.prerequisites(before: "balance-the-dinosaur"),
            ["weigh-dinosaur"]
        )
    }

    func testWeighDinosaurPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-weigh-dinosaur"), "Missing picker art: game-weigh-dinosaur")
        XCTAssertTrue(
            known.contains("game-weigh-dinosaur-success") || known.contains("game-weigh-dinosaur"),
            "Missing victory art for weigh-dinosaur"
        )
    }

    // MARK: - Round mechanics

    func testWeighDinosaurRandomizedConfigHasNineItems() {
        let config = WeighGameConfigs.weighDinosaurRandomized()
        XCTAssertEqual(config.id, "weigh-dinosaur")
        XCTAssertEqual(config.items.count, 9)
    }

    func testWeighDinosaurRandomizedItemsAssignRanksOneThroughNine() {
        let items = WeighGameConfigs.makeRandomDinosaurItems()
        XCTAssertEqual(items.count, 9)
        XCTAssertEqual(Set(items.map(\.weight)), Set(1...9))
        let ids = Set(items.map(\.id))
        XCTAssertEqual(ids.count, 9, "Each grid cell should feature a distinct dinosaur")
    }

    func testWeighDinosaurExcludingUsedIdsProducesFreshCreatures() {
        let firstRound = WeighGameConfigs.makeRandomDinosaurItems()
        let usedIds = Set(firstRound.map(\.id))
        XCTAssertEqual(usedIds.count, 9)
        let secondRound = WeighGameConfigs.makeRandomDinosaurItems(excluding: usedIds)
        XCTAssertEqual(secondRound.count, 9)
        XCTAssertTrue(
            Set(secondRound.map(\.id)).isDisjoint(with: usedIds),
            "Second round should avoid dinosaurs already weighed when the pool is large enough"
        )
    }

    // MARK: - Audio

    func testWeighDinosaurGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-weigh-dinosaur",
            "game-choose-your-first-dinosaur",
            "game-choose-your-second-dinosaur",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Weigh the Dinosaur gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testWeighDinosaurIntroAudioResolvesInBundle() {
        let speech = SpeechManager()
        let candidates = [
            templateConfig.introAudio,
            "game-intro-weigh-dinosaur",
            "game-weigh-dinosaur",
        ]
        let resolved = candidates.contains { speech.urlForAudio(key: $0) != nil }
        XCTAssertTrue(resolved, "Intro audio not in bundle. Tried keys: \(candidates)")
    }

    @MainActor
    func testWeighDinosaurGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "weigh-dinosaur"),
            messagePrefix: "Weigh the Dinosaur"
        )
    }

    @MainActor
    func testWeighComparisonFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["they-both-weigh-about-the-same"],
            messagePrefix: "Weigh the Dinosaur comparison"
        )
    }
}
