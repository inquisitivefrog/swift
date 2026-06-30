//
//  WeighTheDinosaurXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Weigh the Dinosaur (land L1).
//

import XCTest
@testable import DinoGames

final class WeighTheDinosaurXCTests: XCTestCase {

    private var templateConfig: WeighGameConfig { WeighGameConfigs.weighDinosaur }

    private var weighMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments().filter { $0.gameConfigId == "weigh-dinosaur" }
    }

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

    // MARK: - Playable pool

    func testEveryCladeHasPlayableWeighEntry() {
        for clade in DinoClade.allCases {
            let hasMember = LandDinosaurWeighCatalog.allEntries.contains { $0.clade == clade }
            XCTAssertTrue(
                hasMember,
                "Clade \(clade.rawValue) needs at least one dinosaur in the weigh catalog"
            )
        }
    }

    func testWeighCatalogPoolMatchesDisplayMomentsCount() {
        let expectedCount = LandDinosaurWeighCatalog.allEntries.count
        XCTAssertGreaterThan(expectedCount, 9)
        XCTAssertEqual(weighMoments.count, expectedCount, "Each catalog creature should have a display moment")
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

    func testWeighDinosaurRandomizedItemsPreferOnePerClade() {
        let items = WeighGameConfigs.makeRandomDinosaurItems()
        let clades = Set(
            items.compactMap { LandDinosaurCladeCatalog.cladeByCreatureId[$0.id] }
        )
        XCTAssertEqual(
            clades.count,
            9,
            "Expected one creature per clade in the 3×3 grid; got clades: \(clades.map(\.rawValue).sorted())"
        )
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

    func testWeighDinosaurItemWeightsTrackCatalogMassOrder() {
        let items = WeighGameConfigs.makeRandomDinosaurItems()
        let sortedByRank = items.sorted { $0.weight < $1.weight }
        for index in 0..<(sortedByRank.count - 1) {
            let lighter = sortedByRank[index]
            let heavier = sortedByRank[index + 1]
            let lighterKg = LandDinosaurWeighCatalog.weightKgByStableId[lighter.id] ?? 0
            let heavierKg = LandDinosaurWeighCatalog.weightKgByStableId[heavier.id] ?? 0
            XCTAssertLessThanOrEqual(
                lighterKg,
                heavierKg,
                "Rank \(lighter.weight) (\(lighter.name)) should not outweigh rank \(heavier.weight) (\(heavier.name))"
            )
        }
    }

    // MARK: - Assets

    func testWeighDisplayImagesExistOrFallbackToPortrait() {
        let known = ImageAssetNames.knownAssets
        for entry in LandDinosaurWeighCatalog.allEntries {
            let weighName = "weigh-\(entry.imageAssetName)"
            let hasWeighArt = known.contains(weighName)
            let hasPortrait = known.contains(entry.imageAssetName)
            XCTAssertTrue(
                hasWeighArt || hasPortrait,
                "Missing weigh art and portrait for \(entry.displayName): tried `\(weighName)` and `\(entry.imageAssetName)`"
            )
        }
    }

    func testWeighDisplayImageNamingMatchesDisplayMomentCatalog() {
        for entry in LandDinosaurWeighCatalog.allEntries {
            let expected = LandGameDisplayMomentCatalog.weighDisplayImageName(for: entry.imageAssetName)
            XCTAssertFalse(expected.isEmpty)
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(expected),
                "Display moment image missing for \(entry.displayName): `\(expected)`"
            )
        }
    }

    // MARK: - Display moments

    func testWeighDinosaurDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = weighMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testWeighDinosaurDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = weighMoments.filter { moment in
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
