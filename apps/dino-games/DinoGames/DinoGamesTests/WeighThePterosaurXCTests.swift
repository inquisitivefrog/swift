//
//  WeighThePterosaurXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Weigh the Pterosaur (air L1).
//

import XCTest
@testable import DinoGames

final class WeighThePterosaurXCTests: XCTestCase {

    private var templateConfig: WeighGameConfig { WeighGameConfigs.weighPterosaur }

    // MARK: - Config / catalog

    func testWeighPterosaurConfigIdTitleAndIntro() {
        XCTAssertEqual(templateConfig.id, "weigh-pterosaur")
        XCTAssertEqual(templateConfig.title, "Weigh the Pterosaur!")
        XCTAssertEqual(templateConfig.introAudio, "game-intro-weigh-pterosaur")
    }

    func testWeighPterosaurAppearsOnLevel1() {
        let level1 = PterosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "weigh-pterosaur" },
            "Weigh the Pterosaur should appear on air level 1"
        )
    }

    func testWeighPterosaurProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("weigh-pterosaur"), .air)
    }

    func testWeighPterosaurPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-weigh-pterosaur"), "Missing picker art: game-weigh-pterosaur")
        XCTAssertTrue(
            known.contains("game-weigh-pterosaur-success") || known.contains("game-weigh-pterosaur"),
            "Missing victory art for weigh-pterosaur"
        )
    }

    // MARK: - Playable pool

    func testEveryGuessGroupHasPlayableWeighCandidate() {
        let pool = weighablePterosaurPool()
        XCTAssertFalse(pool.isEmpty)
        for group in PterosaurGuessGroup.allCases {
            let hasMember = pool.contains { entry in
                PterosaurGuessGroup.guessGroup(forImageName: entry.imageName) == group
            }
            XCTAssertTrue(
                hasMember,
                "Guess group \(group.rawValue) needs at least one pterosaur in the weigh pool"
            )
        }
    }

    func testWeighablePterosaurPoolHasEstimatedWeightForEveryEntry() {
        for entry in weighablePterosaurPool() {
            XCTAssertNotNil(
                AirPterosaurData.pterosaurEstimatedWeightKgById[entry.creatureId],
                "\(entry.name) needs estimated weight data"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(entry.imageName),
                "Missing portrait for \(entry.name): \(entry.imageName)"
            )
        }
    }

    // MARK: - Round mechanics

    func testWeighPterosaurRandomizedConfigHasNineItems() {
        let config = WeighGameConfigs.weighPterosaurRandomized()
        XCTAssertEqual(config.id, "weigh-pterosaur")
        XCTAssertEqual(config.items.count, 9)
    }

    func testWeighPterosaurRandomizedItemsAssignValidRanks() {
        let items = WeighGameConfigs.makeRandomPterosaurItems()
        XCTAssertEqual(items.count, 9)
        for item in items {
            XCTAssertGreaterThanOrEqual(item.weight, 1)
            XCTAssertLessThanOrEqual(item.weight, 9)
        }
        let ids = Set(items.map(\.id))
        XCTAssertEqual(ids.count, 9, "Each grid cell should feature a distinct pterosaur")
    }

    func testWeighPterosaurRandomizedItemsPreferOnePerGuessGroupWhenPoolAllows() {
        let items = WeighGameConfigs.makeRandomPterosaurItems()
        let groups = Set(
            items.compactMap { item -> PterosaurGuessGroup? in
                guard let imageName = item.imageName else { return nil }
                return PterosaurGuessGroup.guessGroup(forImageName: imageName)
            }
        )
        XCTAssertEqual(
            groups.count,
            PterosaurGuessGroup.allCases.count,
            "Expected one pterosaur per guess group in the 3×3 grid; got groups: \(groups.map(\.rawValue).sorted())"
        )
    }

    func testWeighPterosaurExcludingUsedIdsProducesFreshCreatures() {
        let firstRound = WeighGameConfigs.makeRandomPterosaurItems()
        let usedIds = Set(firstRound.map(\.id))
        XCTAssertEqual(usedIds.count, 9)
        let secondRound = WeighGameConfigs.makeRandomPterosaurItems(excluding: usedIds)
        XCTAssertEqual(secondRound.count, 9)
        XCTAssertTrue(
            Set(secondRound.map(\.id)).isDisjoint(with: usedIds),
            "Second round should avoid pterosaurs already weighed when the pool is large enough"
        )
    }

    func testWeighPterosaurItemWeightsTrackEstimatedMassOrder() {
        let items = WeighGameConfigs.makeRandomPterosaurItems()
        let sortedByRank = items.sorted { $0.weight < $1.weight }
        for index in 0..<(sortedByRank.count - 1) {
            let lighter = sortedByRank[index]
            let heavier = sortedByRank[index + 1]
            let lighterKg = AirPterosaurData.pterosaurEstimatedWeightKgById[lighter.id] ?? 0
            let heavierKg = AirPterosaurData.pterosaurEstimatedWeightKgById[heavier.id] ?? 0
            XCTAssertLessThanOrEqual(
                lighterKg,
                heavierKg,
                "Rank \(lighter.weight) (\(lighter.name)) should not outweigh rank \(heavier.weight) (\(heavier.name))"
            )
        }
    }

    func testWeighPterosaurRandomizedItemsForConfigId() {
        let items = WeighGameConfigs.randomizedItems(forId: "weigh-pterosaur")
        XCTAssertEqual(items.count, 9)
    }

    // MARK: - Audio

    func testWeighPterosaurGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-weigh-pterosaur",
            "game-choose-your-first-pterosaur",
            "game-choose-your-second-pterosaur",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Weigh the Pterosaur gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testWeighPterosaurIntroAudioResolvesInBundle() {
        let speech = SpeechManager()
        let candidates = [
            templateConfig.introAudio,
            "game-intro-weigh-pterosaur",
            "game-weigh-pterosaur",
        ]
        let resolved = candidates.contains { speech.urlForAudio(key: $0) != nil }
        XCTAssertTrue(resolved, "Intro audio not in bundle. Tried keys: \(candidates)")
    }

    @MainActor
    func testWeighPterosaurGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "weigh-pterosaur"),
            messagePrefix: "Weigh the Pterosaur"
        )
    }

    @MainActor
    func testWeighPterosaurComparisonFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["they-both-weigh-about-the-same"],
            messagePrefix: "Weigh the Pterosaur comparison"
        )
    }

    // MARK: - Helpers

    private struct WeighablePterosaurPoolEntry {
        let creatureId: Int
        let name: String
        let imageName: String
    }

    /// Mirrors private `allWeighablePterosaurs` in `WeighGameView`.
    private func weighablePterosaurPool() -> [WeighablePterosaurPoolEntry] {
        AirPterosaurData.allPterosaurs.compactMap { d in
            guard let img = d.imageName,
                  AirPterosaurData.pterosaurEstimatedWeightKgById[d.id] != nil else { return nil }
            return WeighablePterosaurPoolEntry(creatureId: d.id, name: d.name, imageName: img)
        }
    }
}
