//
//  NameThatMarineReptileXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Name That Marine Reptile (sea L2).
//

import XCTest
@testable import DinoGames

final class NameThatMarineReptileXCTests: XCTestCase {

    private var config: GuessGameConfig { GuessGameConfigs.nameThatMarineReptile }

    private var nameThatPool: [Dinosaur] {
        SeaMarineReptileData.allMarineReptiles
    }

    private var nameThatMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingMarineMoments()
            .filter { $0.gameConfigId == "name-that-marine-reptile" }
    }

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "nameThatMarineReptileUsedCreatureIds")
        UserDefaults.standard.removeObject(forKey: "nameThatMarineReptileUsedCladeRawValues")
    }

    // MARK: - Config / catalog

    func testNameThatMarineReptileConfigIdAndIntro() {
        XCTAssertEqual(config.id, "name-that-marine-reptile")
        XCTAssertEqual(config.title, "Name That Marine Reptile!")
        XCTAssertEqual(config.introAudio, "can-you-name-that-marine-reptile")
    }

    func testNameThatMarineReptileAppearsOnLevel2() {
        let level2 = MarineReptileGameCatalog.games(level: .level2)
        XCTAssertTrue(
            level2.contains { $0.id == "name-that-marine-reptile" },
            "Name That Marine Reptile should appear on marine level 2"
        )
    }

    func testNameThatMarineReptileProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("name-that-marine-reptile"), .marineReptiles)
    }

    func testNameThatMarineReptilePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-name-that-marine-reptile"), "Missing picker art: game-name-that-marine-reptile")
        XCTAssertTrue(
            known.contains("game-name-that-marine-reptile-success") || known.contains("game-name-that-marine-reptile"),
            "Missing victory art for name-that-marine-reptile"
        )
    }

    func testNameThatMarineReptileUsesFullMarineCatalogAsOptionsPool() {
        XCTAssertEqual(config.availableDinosaurs.count, SeaMarineReptileData.allMarineReptiles.count)
    }

    // MARK: - Playable pool

    func testNameThatMarineReptilePoolHasEnoughCreatures() {
        XCTAssertGreaterThanOrEqual(nameThatPool.count, 3)
    }

    func testEveryMarineGroupHasPlayableCreatureInNameThatPool() {
        let groupsInPool = Set(nameThatPool.map { SeaMarineReptileData.marineCladeRawValue(for: $0) })
        XCTAssertGreaterThanOrEqual(groupsInPool.count, 3, "Need at least three marine image groups for Name That rounds")
        for group in groupsInPool {
            let hasMember = nameThatPool.contains {
                SeaMarineReptileData.marineCladeRawValue(for: $0) == group
            }
            XCTAssertTrue(hasMember, "Marine group `\(group)` needs at least one creature in the Name That pool")
        }
    }

    func testNameThatMarineReptilePoolSilhouettesBundled() {
        let known = ImageAssetNames.knownAssets
        for marine in nameThatPool {
            guard let base = marine.imageName else {
                XCTFail("Marine reptile \(marine.name) missing imageName")
                continue
            }
            guard let silhouette = LandGameDisplayMomentCatalog.marineSilhouetteAssetName(forBodyImage: base) else {
                XCTFail("Missing silhouette mapping for \(marine.name) body `\(base)`")
                continue
            }
            XCTAssertTrue(
                known.contains(silhouette),
                "Missing silhouette imageset \(silhouette) for \(marine.name)"
            )
        }
    }

    // MARK: - Round structure

    func testNameThatMarineReptileProductionConfigThreeRounds() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctIds = config.rounds.map(\.correctAnswerId)
        XCTAssertEqual(Set(correctIds).count, 3, "Each round should feature a distinct correct marine reptile")
    }

    func testNameThatMarineReptileRoundOptionsAndSilhouettes() {
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
            let prefix = SeaMarineReptileData.marineBodyImagePrefix(for: correct)
            let slug = base.replacingOccurrences(of: prefix, with: "")
            let expectedSilhouette = "\(prefix.dropLast())-silhouette-\(slug)"
            XCTAssertEqual(round.questionImageName, expectedSilhouette)
            XCTAssertEqual(round.questionImageFallback, correct.imageName)
            XCTAssertTrue(known.contains(round.questionImageName), "Missing silhouette: \(round.questionImageName)")
            if let fallback = round.questionImageFallback {
                XCTAssertTrue(known.contains(fallback), "Missing body art: \(fallback)")
            }
        }
    }

    func testNameThatMarineReptileDecoysAreNotQuestionMarineGroup() {
        for round in config.rounds {
            guard let correct = round.options.first(where: { $0.id == round.correctAnswerId }) else {
                XCTFail("Round \(round.id) missing correct option")
                continue
            }
            let questionGroup = SeaMarineReptileData.marineCladeRawValue(for: correct)
            let decoys = round.options.filter { $0.id != round.correctAnswerId }
            XCTAssertEqual(decoys.count, 2)
            for decoy in decoys {
                XCTAssertNotEqual(
                    SeaMarineReptileData.marineCladeRawValue(for: decoy),
                    questionGroup,
                    "Decoy \(decoy.name) must not share marine group with question \(correct.name)"
                )
            }
        }
    }

    // MARK: - Audio

    @MainActor
    func testNameThatMarineReptileIntroAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [config.introAudio],
            messagePrefix: "Name That Marine Reptile intro"
        )
    }

    @MainActor
    func testNameThatMarineReptileGameplayFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [
                "game-name-that-marine-reptile-thats-right",
                "game-name-that-marine-reptile-try-again",
            ],
            messagePrefix: "Name That Marine Reptile feedback"
        )
    }

    // MARK: - Display moments

    func testNameThatMarineReptileDisplayMomentsCoverSilhouettePool() {
        XCTAssertEqual(
            nameThatMoments.count,
            nameThatPool.count,
            "Expected one display moment per bundled silhouette in the Name That pool"
        )
    }

    func testNameThatMarineReptileDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = nameThatMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testNameThatMarineReptileDisplayMomentsHaveResolvableAudio() {
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
