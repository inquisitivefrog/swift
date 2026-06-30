//
//  WhichPteroIsTallerXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Which Ptero Is Taller (air L1).
//

import XCTest
@testable import DinoGames

final class WhichPteroIsTallerXCTests: XCTestCase {

    private var templateConfig: WhoIsTallerGameConfig { WhoIsTallerGameConfigs.whoIsTallerPterosaur }

    private var eligiblePool: [WhoIsTallerItem] { allEligiblePterosaurItems() }

    // MARK: - Config / catalog

    func testWhichPteroIsTallerConfigIdTitleAndIntro() {
        XCTAssertEqual(templateConfig.id, "which-ptero-is-taller")
        XCTAssertEqual(templateConfig.title, "Which Ptero Is Taller")
        XCTAssertEqual(templateConfig.introAudio, "game-which-ptero-is-taller")
        XCTAssertEqual(templateConfig.poolKind, .pterosaurs)
    }

    func testWhichPteroIsTallerAppearsOnLevel1() {
        let level1 = PterosaurGameCatalog.games(level: .level1)
        XCTAssertTrue(
            level1.contains { $0.id == "which-ptero-is-taller" },
            "Which Ptero Is Taller should appear on air level 1"
        )
    }

    func testWhichPteroIsTallerProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("which-ptero-is-taller"), .air)
    }

    func testWhichPteroIsTallerPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-which-ptero-is-taller"), "Missing picker art: game-which-ptero-is-taller")
        XCTAssertTrue(
            known.contains("game-which-ptero-is-taller-success") || known.contains("game-which-ptero-is-taller"),
            "Missing victory art for which-ptero-is-taller"
        )
    }

    // MARK: - Playable pool

    func testEligiblePterosaurPoolIsLargeEnough() {
        XCTAssertGreaterThanOrEqual(eligiblePool.count, 9)
    }

    func testEligiblePterosaurPoolHasHeightAndMeasureArt() {
        let known = ImageAssetNames.knownAssets
        for item in eligiblePool {
            XCTAssertNotNil(
                AirPterosaurData.pterosaurStandingHeightMetersById[item.id],
                "\(item.name) needs standing height data"
            )
            guard let portrait = item.imageName else {
                XCTFail("\(item.name) missing portrait imageName")
                continue
            }
            XCTAssertTrue(portrait.hasPrefix("ptero-"), "\(item.name) should use ptero portrait")
            XCTAssertTrue(known.contains(portrait), "Missing grid portrait: \(portrait)")
            guard let measure = pteroMeasureImageName(forSquareBase: portrait) else {
                XCTFail("\(item.name) missing bundled ptero-measure art for \(portrait)")
                continue
            }
            XCTAssertTrue(known.contains(measure), "Missing measure imageset: \(measure)")
        }
    }

    // MARK: - Round mechanics

    func testWhichPteroIsTallerRandomizedConfigHasNineItems() {
        let config = WhoIsTallerGameConfigs.whoIsTallerPterosaurRandomized()
        XCTAssertEqual(config.id, "which-ptero-is-taller")
        XCTAssertEqual(config.items.count, 9)
    }

    func testWhichPteroIsTallerRoundHasNineDistinctCreatures() {
        let round = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .pterosaurs)
        XCTAssertEqual(round.count, 9)
        let ids = Set(round.map(\.id))
        XCTAssertEqual(ids.count, 9, "Each grid cell should feature a distinct pterosaur")
    }

    func testWhichPteroIsTallerExcludingUsedIdsProducesFreshCreatures() {
        let firstRound = WhoIsTallerGameConfigs.makeRoundItems(poolKind: .pterosaurs)
        let usedIds = Set(firstRound.map(\.id))
        XCTAssertEqual(usedIds.count, 9)
        let secondRound = WhoIsTallerGameConfigs.makeRoundItems(excluding: usedIds, poolKind: .pterosaurs)
        XCTAssertEqual(secondRound.count, 9)
        XCTAssertTrue(
            Set(secondRound.map(\.id)).isDisjoint(with: usedIds),
            "Second round should avoid pterosaurs already compared when the pool is large enough"
        )
    }

    // MARK: - Audio

    func testWhichPteroIsTallerGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        XCTAssertTrue(
            stems.contains("game-which-ptero-is-taller"),
            "Missing Which Ptero Is Taller intro audio on disk"
        )
    }

    @MainActor
    func testWhichPteroIsTallerGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "which-ptero-is-taller"),
            messagePrefix: "Which Ptero Is Taller"
        )
    }

    @MainActor
    func testWhichPteroIsTallerComparisonFeedbackAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["is-longer", "about-the-same-length"],
            messagePrefix: "Which Ptero Is Taller comparison"
        )
    }

    // MARK: - Helpers

    private func allEligiblePterosaurItems() -> [WhoIsTallerItem] {
        MatchingGameConfigs.allPterosaurs.compactMap { d in
            guard let imageName = d.imageName, imageName.hasPrefix("ptero-"),
                  AirPterosaurData.pterosaurStandingHeightMetersById[d.id] != nil,
                  ImageAssetCache.imageExists(named: imageName) else { return nil }
            return WhoIsTallerItem(
                id: d.id,
                name: d.name,
                imageName: d.imageName,
                emoji: d.icon,
                heightMeters: AirPterosaurData.pterosaurStandingHeightMetersById[d.id] ?? 1
            )
        }
    }

    /// Mirrors `WhoIsTallerGameView.pteroMeasureImageName(forSquareBase:)`.
    private func pteroMeasureImageName(forSquareBase base: String) -> String? {
        let prefix = "ptero-"
        guard base.hasPrefix(prefix) else { return nil }
        let tail = String(base.dropFirst(prefix.count))
        guard !tail.isEmpty else { return nil }
        let measureName = "ptero-measure-\(tail)"
        return ImageAssetCache.imageExists(named: measureName) ? measureName : nil
    }
}
