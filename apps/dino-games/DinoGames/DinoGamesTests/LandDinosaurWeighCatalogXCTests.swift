//
//  LandDinosaurWeighCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, display-moment, and mass-order contracts for Weigh the Dinosaur.
//  Game config, progress, and gameplay audio live in `WeighTheDinosaurXCTests`.
//

import XCTest
@testable import DinoGames

final class LandDinosaurWeighCatalogXCTests: XCTestCase {

    private var weighMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingLandMoments()
            .filter { $0.gameConfigId == "weigh-dinosaur" }
    }

    // MARK: - Catalog

    func testWeighCatalogEntriesMatchBundledDinoAssets() {
        let bases = ImageAssetNames.knownAssets.filter { $0.hasPrefix("dino-") && !$0.contains("-silhouette-") }
        for e in LandDinosaurWeighCatalog.allEntries {
            XCTAssertTrue(
                bases.contains(e.imageAssetName),
                "Weigh catalog references missing asset: \(e.imageAssetName)"
            )
            XCTAssertEqual(
                LandDinosaurWeighCatalog.weightKgByStableId[e.stableId],
                e.weightKg,
                "Stable id \(e.stableId) kg map mismatch"
            )
            XCTAssertEqual(
                LandDinosaurData.dinosaurEstimatedWeightKgById[e.stableId],
                e.weightKg,
                "Catalog kg should match LandDinosaurData for id \(e.stableId)"
            )
        }
    }

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

    func testWeightKgLookupMapsStayConsistent() {
        for entry in LandDinosaurWeighCatalog.allEntries {
            XCTAssertEqual(
                LandDinosaurWeighCatalog.weightKgByStableId[entry.stableId],
                entry.weightKg,
                "Stable-id lookup mismatch for \(entry.displayName)"
            )
            XCTAssertEqual(
                LandDinosaurWeighCatalog.weightKgByImageAsset[entry.imageAssetName],
                entry.weightKg,
                "Image lookup mismatch for \(entry.imageAssetName)"
            )
        }
    }

    // MARK: - Round mechanics (catalog-driven)

    func testWeighRandomDinosaurItemsNineUniqueCladesWhenPoolFull() {
        let items = WeighGameConfigs.makeRandomDinosaurItems()
        XCTAssertEqual(items.count, 9, "Expected nine grid creatures")
        let clades = Set(
            items.compactMap { item -> DinoClade? in
                LandDinosaurCladeCatalog.cladeByCreatureId[item.id]
            }
        )
        XCTAssertEqual(
            clades.count,
            9,
            "Expected one creature per clade in the 3×3 grid; got clades: \(clades.map(\.rawValue).sorted())"
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

    func testWeighDinosaurRandomizedItemsForConfigId() {
        let items = WeighGameConfigs.randomizedItems(forId: "weigh-dinosaur")
        XCTAssertEqual(items.count, 9)
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
}
