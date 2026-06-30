//
//  MarineReptileGameCatalogXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineReptileGameCatalogXCTests: XCTestCase {

    /// Canonical progress ids (runtime config ids may differ, e.g. `racing-marine-reptiles-jurassic`).
    private let shippingCanonicalByLevel: [GameLevel: [String]] = [
        .level1: ["weigh-marine-reptile", "which-marine-reptile-is-longer", "marine-reptile-puzzle"],
        .level2: ["name-that-marine-reptile", "racing-marine-reptiles", "marine-ages"],
    ]

    private func expectedLevel3CanonicalIds() -> [String] {
        var ids: [String] = []
        if GuessGameConfigs.makeMarineFootprints() != nil {
            ids.append("marine-footprints")
        }
        if MarineFloraGameConfigs.isPlayable {
            ids.append("marine-flora")
        }
        if MarineEggsGameConfigs.makeMarineEggs() != nil {
            ids.append("marine-eggs")
        }
        return ids
    }

    private func expectedLevel4CanonicalIds() -> [String] {
        var ids: [String] = []
        if MarineMatrixGameConfigs.makeMarineMatrix() != nil {
            ids.append("marine-matrix")
        }
        ids.append("marine-diets")
        if GuessGameConfigs.makeMarineSmile() != nil {
            ids.append("marine-smile")
        }
        return ids
    }

    func testVisibleMarineLevelsAreOneThroughFour() {
        XCTAssertEqual(GameLevel.visibleInGamePicker, [.level1, .level2, .level3, .level4])
    }

    func testEachShippingMarineLevelOneAndTwoHasThreeGamesInCatalogOrder() {
        for level in [GameLevel.level1, .level2] {
            let expected = shippingCanonicalByLevel[level] ?? []
            let games = MarineReptileGameCatalog.games(level: level)
            XCTAssertEqual(games.count, 3, "Marine level \(level.number) should list three games")
            let actual = games.compactMap { $0.id.map { MarineReptileProgress.canonicalId(for: $0) } }
            XCTAssertEqual(actual, expected, "Marine level \(level.number) canonical catalog order")
        }
    }

    func testShippingMarineLevelThreeMatchesPlacedOptionalGames() {
        let expected = expectedLevel3CanonicalIds()
        XCTAssertFalse(expected.isEmpty, "Marine level 3 should include at least one placed game when assets ship")
        let games = MarineReptileGameCatalog.games(level: .level3)
        XCTAssertEqual(games.count, expected.count, "Marine level 3 game count should match placed optional games")
        let actual = games.compactMap { $0.id.map { MarineReptileProgress.canonicalId(for: $0) } }
        XCTAssertEqual(actual, expected, "Marine level 3 canonical catalog order")
    }

    func testShippingMarineLevelFourMatchesPlacedOptionalGames() {
        let expected = expectedLevel4CanonicalIds()
        XCTAssertFalse(expected.isEmpty, "Marine level 4 should always include Marine Diets")
        let games = MarineReptileGameCatalog.games(level: .level4)
        XCTAssertEqual(games.count, expected.count, "Marine level 4 game count should match placed optional games")
        let actual = games.compactMap { $0.id.map { MarineReptileProgress.canonicalId(for: $0) } }
        XCTAssertEqual(actual, expected, "Marine level 4 canonical catalog order")
    }

    func testShippingMarineGamesMapToMarineProgressCategory() {
        let ids = GameLevel.visibleInGamePicker.flatMap { MarineReptileGameCatalog.games(level: $0).compactMap(\.id) }
        for id in ids {
            XCTAssertEqual(
                GameCategory.forCatalogConfigId(id),
                .marineReptiles,
                "Config `\(id)` should map to marine reptiles"
            )
        }
    }

    func testMarineCatalogBuildsWithoutFatalError() {
        XCTAssertNoThrow({
            _ = MarineReptileGameCatalog.games
            _ = MarineReptileProgress.allMarineGameCanonicalIds
        }())
    }

    func testAllMarineGameCanonicalIdsMatchFlattenedCatalog() {
        let fromCatalog = Set(
            MarineReptileGameCatalog.games.compactMap { game in
                game.id.map { MarineReptileProgress.canonicalId(for: $0) }
            }
        )
        XCTAssertEqual(fromCatalog, MarineReptileProgress.allMarineGameCanonicalIds)
    }

    func testRacingMarineReptilesCanonicalIdNormalization() {
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles"),
            "racing-marine-reptiles"
        )
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles-jurassic"),
            "racing-marine-reptiles"
        )
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles-cretaceous"),
            "racing-marine-reptiles"
        )
        XCTAssertEqual(
            MarineReptileProgress.canonicalId(for: "racing-marine-reptiles-both"),
            "racing-marine-reptiles"
        )
    }

    func testMarineMatrixFossilSlugMatchesBundledComposites() {
        let elasmosaurus = SeaMarineReptileData.allMarineReptiles.first { $0.imageName == "marine-plesio-elasmosaurus" }
        XCTAssertNotNil(elasmosaurus)
        XCTAssertEqual(SeaMarineReptileData.matrixFossilSlug(for: elasmosaurus!), "elasmosaurus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-matrix-chalk-elasmosaurus"))

        let tylosaurus = SeaMarineReptileData.allMarineReptiles.first { $0.imageName == "marine-tylo-tylosaurus" }
        XCTAssertNotNil(tylosaurus)
        XCTAssertEqual(SeaMarineReptileData.matrixFossilSlug(for: tylosaurus!), "tylosaurus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-matrix-chalk-tylosaurus"))
    }

    func testMarineMatrixConfigBuildsAndAppearsInLevel4WhenPlayable() throws {
        guard MarineMatrixGameConfigs.makeMarineMatrix() != nil else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let level4 = MarineReptileGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "marine-matrix" },
            "Expected Marine Matrix in marine level 4 when matrix config builds."
        )
        XCTAssertTrue(
            level4.contains { $0.id == "marine-diets" },
            "Expected Marine Diets in marine level 4."
        )
    }

    func testMarineMatrixGameCardImageExistsWhenPlayable() throws {
        guard MarineMatrixGameConfigs.makeMarineMatrix() != nil else {
            throw XCTSkip("Marine Matrix not playable in this asset snapshot.")
        }
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-marine-matrix"),
            "Missing picker/transition art: game-marine-matrix.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-marine-matrix-success"),
            "Missing victory art: game-marine-matrix-success.imageset"
        )
    }

    func testMarineSmileIsInCatalogWhenPlayable() throws {
        guard MarineSmileMorphology.isPlayable else {
            throw XCTSkip("Marine Smile reference tooth art not bundled yet")
        }
        let allIds = Set(MarineReptileGameCatalog.games.compactMap(\.id))
        XCTAssertTrue(
            allIds.contains("marine-smile"),
            "Marine Smile should appear in the marine catalog when smile/tooth assets are bundled."
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-marine-smile"),
            "Missing game card art: game-marine-smile.imageset"
        )
        XCTAssertTrue(
            ImageAssetCache.imageExists(named: "game-marine-smile-success"),
            "Missing victory art: game-marine-smile-success.imageset"
        )
        let level4 = MarineReptileGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "marine-smile" },
            "Expected Marine Smile in marine level 4."
        )
    }
}
