//
//  MarineReptileWeighCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Weigh the Marine Reptile (sea L1).
//

import XCTest
@testable import DinoGames

final class MarineReptileWeighCatalogXCTests: XCTestCase {

    private var templateConfig: WeighGameConfig { WeighGameConfigs.weighMarineReptile }

    private var weighMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingMarineMoments()
            .filter { $0.gameConfigId == "weigh-marine-reptile" }
    }

    // MARK: - Catalog

    func testWeighCatalogEntriesMatchBundledMarineAssets() {
        let bases = ImageAssetNames.knownAssets.filter { $0.hasPrefix("marine-") && !$0.contains("-silhouette-") }
        for e in MarineReptileWeighCatalog.allEntries {
            XCTAssertTrue(
                bases.contains(e.imageAssetName),
                "Weigh catalog references missing asset: \(e.imageAssetName)"
            )
            XCTAssertEqual(
                MarineReptileWeighCatalog.weightKgByStableId[e.stableId],
                e.weightKg,
                "Stable id \(e.stableId) kg map mismatch"
            )
        }
    }

    func testEveryWeighCladeHasPlayableCatalogEntry() {
        let cladesInCatalog = Set(MarineReptileWeighCatalog.allEntries.map(\.cladeRaw))
        XCTAssertGreaterThanOrEqual(cladesInCatalog.count, 9, "Need at least nine clades for a full weigh grid")
        for clade in cladesInCatalog {
            let hasMember = MarineReptileWeighCatalog.allEntries.contains { entry in
                entry.cladeRaw == clade
                    && ImageAssetNames.knownAssets.contains(entry.imageAssetName)
            }
            XCTAssertTrue(hasMember, "Weigh clade `\(clade)` needs at least one bundled catalog portrait")
        }
    }

    func testWeighCatalogPoolMatchesDisplayMomentsCount() {
        let expectedCount = MarineReptileWeighCatalog.allEntries.count
        XCTAssertGreaterThan(expectedCount, 9)
        XCTAssertEqual(weighMoments.count, expectedCount, "Each catalog creature should have a display moment")
    }

    // MARK: - Config / catalog

    func testWeighMarineReptileConfigIdTitleAndIntro() {
        XCTAssertEqual(templateConfig.id, "weigh-marine-reptile")
        XCTAssertEqual(templateConfig.title, "Weigh the Marine Reptile!")
        XCTAssertEqual(templateConfig.introAudio, "game-intro-weigh-marine-reptile")
    }

    func testWeighMarineReptileAppearsOnLevel1() {
        let level1 = MarineReptileGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "weigh-marine-reptile" },
            "Weigh the Marine Reptile should appear on marine level 1"
        )
    }

    func testWeighMarineReptileProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("weigh-marine-reptile"), .marineReptiles)
    }

    func testWeighMarineReptilePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-weigh-the-marine-reptile"), "Missing picker art: game-weigh-the-marine-reptile")
        XCTAssertTrue(
            known.contains("game-weigh-the-marine-reptile-success") || known.contains("game-weigh-the-marine-reptile"),
            "Missing victory art for weigh-marine-reptile"
        )
    }

    // MARK: - Round mechanics

    func testWeighRandomMarineItemsNineUniqueCladesWhenPoolFull() {
        let items = WeighGameConfigs.makeRandomMarineReptileItems()
        XCTAssertEqual(items.count, 9, "Expected nine grid creatures")
        let clades = Set(
            items.compactMap { item -> String? in
                guard let name = item.imageName else { return nil }
                let parts = name.split(separator: "-", omittingEmptySubsequences: false)
                guard parts.count >= 3, parts[0] == "marine" else { return nil }
                return String(parts[1])
            }
        )
        XCTAssertEqual(clades.count, 9, "Expected one creature per clade in the 3×3 grid; got clades: \(clades.sorted())")
    }

    func testWeighMarineReptileRandomizedConfigHasNineItems() {
        let config = WeighGameConfigs.weighMarineReptileRandomized()
        XCTAssertEqual(config.id, "weigh-marine-reptile")
        XCTAssertEqual(config.items.count, 9)
    }

    func testWeighMarineReptileRandomizedItemsAssignValidRanks() {
        let items = WeighGameConfigs.makeRandomMarineReptileItems()
        XCTAssertEqual(items.count, 9)
        for item in items {
            XCTAssertGreaterThanOrEqual(item.weight, 1)
            XCTAssertLessThanOrEqual(item.weight, 9)
        }
        let ids = Set(items.map(\.id))
        XCTAssertEqual(ids.count, 9, "Each grid cell should feature a distinct marine reptile")
    }

    func testWeighMarineReptileExcludingUsedIdsProducesFreshCreatures() {
        let firstRound = WeighGameConfigs.makeRandomMarineReptileItems()
        let usedIds = Set(firstRound.map(\.id))
        XCTAssertEqual(usedIds.count, 9)
        let secondRound = WeighGameConfigs.makeRandomMarineReptileItems(excluding: usedIds)
        XCTAssertEqual(secondRound.count, 9)
        XCTAssertTrue(
            Set(secondRound.map(\.id)).isDisjoint(with: usedIds),
            "Second round should avoid marine reptiles already weighed when the pool is large enough"
        )
    }

    func testWeighMarineReptileItemWeightsTrackCatalogMassOrder() {
        let items = WeighGameConfigs.makeRandomMarineReptileItems()
        let sortedByRank = items.sorted { $0.weight < $1.weight }
        for index in 0..<(sortedByRank.count - 1) {
            let lighter = sortedByRank[index]
            let heavier = sortedByRank[index + 1]
            let lighterKg = MarineReptileWeighCatalog.weightKgByStableId[lighter.id] ?? 0
            let heavierKg = MarineReptileWeighCatalog.weightKgByStableId[heavier.id] ?? 0
            XCTAssertLessThanOrEqual(
                lighterKg,
                heavierKg,
                "Rank \(lighter.weight) (\(lighter.name)) should not outweigh rank \(heavier.weight) (\(heavier.name))"
            )
        }
    }

    func testWeighMarineReptileRandomizedItemsForConfigId() {
        let items = WeighGameConfigs.randomizedItems(forId: "weigh-marine-reptile")
        XCTAssertEqual(items.count, 9)
    }

    // MARK: - Assets

    func testWeighDisplayImagesExistOrFallbackToPortrait() {
        let known = ImageAssetNames.knownAssets
        for entry in MarineReptileWeighCatalog.allEntries {
            let displayName = LandGameDisplayMomentCatalog.weighMarineDisplayImageName(for: entry.imageAssetName)
            let hasDisplayArt = known.contains(displayName)
            let hasPortrait = known.contains(entry.imageAssetName)
            XCTAssertTrue(
                hasDisplayArt || hasPortrait,
                "Missing weigh art and portrait for \(entry.displayName): tried `\(displayName)` and `\(entry.imageAssetName)`"
            )
        }
    }

    func testWeighDisplayImageNamingMatchesDisplayMomentCatalog() {
        for entry in MarineReptileWeighCatalog.allEntries {
            let expected = LandGameDisplayMomentCatalog.weighMarineDisplayImageName(for: entry.imageAssetName)
            XCTAssertFalse(expected.isEmpty)
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(expected),
                "Display moment image missing for \(entry.displayName): `\(expected)`"
            )
        }
    }

    // MARK: - Display moments

    func testWeighMarineReptileDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = weighMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testWeighMarineReptileDisplayMomentsHaveResolvableAudio() {
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

    func testWeighMarineReptileGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-weigh-marine-reptile",
            "game-intro-weigh-marine-reptile",
            "game-choose-your-first-marine-reptile",
            "game-choose-your-second-marine-reptile",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Weigh the Marine Reptile gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testWeighMarineReptileIntroAudioResolvesInBundle() {
        let speech = SpeechManager()
        let candidates = [
            templateConfig.introAudio,
            "game-intro-weigh-marine-reptile",
            "game-weigh-marine-reptile",
        ]
        let resolved = candidates.contains { speech.urlForAudio(key: $0) != nil }
        XCTAssertTrue(resolved, "Intro audio not in bundle. Tried keys: \(candidates)")
    }

    @MainActor
    func testWeighMarineReptileGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            [
                "game-choose-your-first-marine-reptile",
                "game-choose-your-second-marine-reptile",
            ],
            messagePrefix: "Weigh the Marine Reptile"
        )
    }

    @MainActor
    func testWeighMarineReptileComparisonFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["they-both-weigh-about-the-same"],
            messagePrefix: "Weigh the Marine Reptile comparison"
        )
    }
}
