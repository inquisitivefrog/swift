//
//  WhichDinoIsTallerXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Which Dino Is Taller (land L1).
//

import XCTest
@testable import DinoGames

final class WhichDinoIsTallerXCTests: XCTestCase {

    private var templateConfig: WhoIsTallerGameConfig { WhoIsTallerGameConfigs.whoIsTaller }

    private var eligiblePool: [WhoIsTallerItem] { WhoIsTallerGameConfigs.allEligibleDinosaurItems() }

    private var tallerMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "which-dino-is-taller" }
    }

    // MARK: - Config / catalog

    func testWhichDinoIsTallerConfigIdTitleAndIntro() {
        XCTAssertEqual(templateConfig.id, "which-dino-is-taller")
        XCTAssertEqual(templateConfig.title, "Which Dino Is Taller")
        XCTAssertEqual(templateConfig.introAudio, "game-which-dino-is-taller")
        XCTAssertEqual(templateConfig.poolKind, .dinosaurs)
    }

    func testWhichDinoIsTallerAppearsOnLevel1() {
        let level1 = DinosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "which-dino-is-taller" },
            "Which Dino Is Taller should appear on land level 1"
        )
    }

    func testWhichDinoIsTallerProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("which-dino-is-taller"), .land)
    }

    func testWhichDinoIsTallerIsPrerequisiteForMeasure() {
        XCTAssertEqual(
            LandDinosaurGamePairing.prerequisites(before: "measure-the-dinosaur"),
            ["which-dino-is-taller"]
        )
    }

    func testWhichDinoIsTallerPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-which-dino-is-taller"), "Missing picker art: game-which-dino-is-taller")
        XCTAssertTrue(
            known.contains("game-which-dino-is-taller-success") || known.contains("game-which-dino-is-taller"),
            "Missing victory art for which-dino-is-taller"
        )
    }

    // MARK: - Playable pool

    func testEligibleDinosaurPoolIsLargeEnough() {
        XCTAssertGreaterThanOrEqual(eligiblePool.count, 9)
    }

    func testEligibleDinosaurPoolHasHeightAndMeasureArt() {
        let known = ImageAssetNames.knownAssets
        for item in eligiblePool {
            XCTAssertNotNil(
                LandDinosaurHeightCatalog.standingHeightMeters(forCreatureId: item.id),
                "\(item.name) needs standing height data"
            )
            guard let portrait = item.imageName else {
                XCTFail("\(item.name) missing portrait imageName")
                continue
            }
            XCTAssertTrue(portrait.hasPrefix("dino-"), "\(item.name) should use dino portrait")
            XCTAssertTrue(known.contains(portrait), "Missing grid portrait: \(portrait)")
            guard let measure = LandDinosaurHeightCatalog.measureDinoImageName(forImageName: portrait) else {
                XCTFail("\(item.name) missing bundled measure art for \(portrait)")
                continue
            }
            XCTAssertTrue(known.contains(measure), "Missing measure imageset: \(measure)")
        }
    }

    func testEligiblePoolDisplayImagesMatchDisplayMomentCatalog() {
        for item in eligiblePool {
            guard let portrait = item.imageName else { continue }
            let grid = LandGameDisplayMomentCatalog.tallerGridImageName(for: item)
            XCTAssertNotNil(grid, "Grid image missing for \(item.name)")
            XCTAssertEqual(grid, portrait)
            let measure = LandGameDisplayMomentCatalog.tallerMeasureImageName(for: item)
            XCTAssertEqual(measure, LandDinosaurHeightCatalog.measureDinoImageName(forImageName: portrait))
        }
    }

    // MARK: - Round mechanics

    func testWhichDinoIsTallerRandomizedConfigHasNineItems() {
        let config = WhoIsTallerGameConfigs.whoIsTallerRandomized()
        XCTAssertEqual(config.id, "which-dino-is-taller")
        XCTAssertEqual(config.items.count, 9)
    }

    func testWhichDinoIsTallerRoundHeightsAreFullyComparable() {
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .dinosaurs)
        XCTAssertEqual(round.count, 9)
        let ids = Set(round.map(\.id))
        XCTAssertEqual(ids.count, 9, "Each grid cell should feature a distinct dinosaur")
        XCTAssertTrue(
            LandDinosaurHeightCatalog.dinoRoundHeightsAreFullyComparable(round.map(\.heightMeters)),
            "Round heights must allow a valid second pick for every first pick"
        )
    }

    func testWhichDinoIsTallerExcludingUsedIdsProducesFreshCreatures() {
        let firstRound = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .dinosaurs)
        let usedIds = Set(firstRound.map(\.id))
        XCTAssertEqual(usedIds.count, 9)
        let secondRound = WhoIsTallerGameConfigs.makeRoundItems(excluding: usedIds, poolKind: .dinosaurs)
        XCTAssertEqual(secondRound.count, 9)
        XCTAssertTrue(
            Set(secondRound.map(\.id)).isDisjoint(with: usedIds),
            "Second round should avoid dinosaurs already compared when the pool is large enough"
        )
    }

    func testTinyDinosaurHeightListIncludesPlayableMicroRaptors() {
        let tiny = LandDinosaurHeightCatalog.dinosaurImageNamesAtMostOneMeter(
            playableIn: eligiblePool.map {
                Dinosaur(id: $0.id, name: $0.name, icon: $0.emoji, imageName: $0.imageName, characteristicIds: [])
            }
        )
        XCTAssertTrue(tiny.contains("dino-archaeopteryx"))
        XCTAssertTrue(tiny.contains("dino-compsognathus"))
    }

    // MARK: - Display moments

    func testWhichDinoIsTallerDisplayMomentsCoverEligiblePool() {
        let gridMoments = tallerMoments.filter { $0.context.hasPrefix("grid ") }
        let comparisonMoments = tallerMoments.filter { $0.context.hasPrefix("comparison ") }
        XCTAssertEqual(gridMoments.count, eligiblePool.count)
        XCTAssertEqual(comparisonMoments.count, eligiblePool.count)
    }

    func testWhichDinoIsTallerDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = tallerMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testWhichDinoIsTallerDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = tallerMoments.filter { moment in
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

    // MARK: - Audio

    func testWhichDinoIsTallerGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(
            stems.contains("game-which-dino-is-taller"),
            "Missing Which Dino Is Taller intro audio on disk"
        )
    }

    @MainActor
    func testWhichDinoIsTallerGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "which-dino-is-taller"),
            messagePrefix: "Which Dino Is Taller"
        )
    }

    @MainActor
    func testWhichDinoIsTallerComparisonFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["is-taller", "they-are-about-the-same-height", "thats-too-small-to-see"],
            messagePrefix: "Which Dino Is Taller comparison"
        )
    }
}
