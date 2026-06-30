//
//  MarineMatrixCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, round config, asset, and audio contracts for Marine Matrix (sea level 4).
//

import XCTest
@testable import DinoGames

final class MarineMatrixCatalogXCTests: XCTestCase {

    private var config: DinoMatrixGameConfig? { MarineMatrixGameConfigs.makeMarineMatrix() }

    // MARK: - Config / catalog

    func testMarineMatrixConfigIdAndIntro() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.id, "marine-matrix")
        XCTAssertEqual(config.title, "Marine Matrix!")
        XCTAssertEqual(config.introAudio, "game-marine-matrix")
        XCTAssertEqual(config.identifyStoneAudioKey, "game-dino-matrix-identify-the-stone")
        XCTAssertEqual(config.assetPrefix, "marine-matrix")
        XCTAssertEqual(config.progressKind, .marine)
        XCTAssertTrue(config.tuffRockUsesVolcanicPrefix)
        XCTAssertTrue(config.tuffFossilUsesVolcanicPrefix)
        XCTAssertNil(config.sourceHintsGridIntroAudioKey)
    }

    func testMarineMatrixAppearsOnLevel4() throws {
        guard config != nil else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let level4 = MarineReptileGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "marine-matrix" },
            "Marine Matrix should appear on marine level 4"
        )
    }

    func testMarineMatrixProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-matrix"), .marineReptiles)
    }

    func testMarineMatrixPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-matrix"), "Missing picker art: game-marine-matrix")
        XCTAssertTrue(
            known.contains("game-marine-matrix-success") || known.contains("game-marine-matrix"),
            "Missing victory art for marine-matrix"
        )
    }

    // MARK: - Rounds / materials

    func testMarineMatrixConfigBuildsThreeRoundsWithDistinctCorrectStones() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.rounds.count, 3)
        let correctMaterialIds = Set(config.rounds.map(\.correctMaterialId))
        XCTAssertEqual(
            correctMaterialIds.count,
            3,
            "Each round should feature a distinct correct matrix stone"
        )
    }

    func testMarineMatrixEachRoundHasThreeOptionsIncludingCorrectStone() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertNotNil(round.dinosaur, "Round \(round.id) should feature a creature")
            XCTAssertTrue(
                round.options.contains { $0.id == round.correctMaterialId },
                "Round \(round.id) options must include the correct stone"
            )
        }
    }

    func testMarineMatrixShipsSevenMarineMatrixMaterials() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.allMaterials.count, 7)
        let slugs = Set(config.allMaterials.map(\.materialSlug))
        XCTAssertEqual(
            slugs,
            ["chalk", "claystone", "ironstone", "limestone", "phosphorite", "shale", "tuff"]
        )
    }

    func testMarineMatrixAllMaterialsHaveRockOptionArt() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for material in config.allMaterials {
            let name = material.matrixRockImageAssetName(
                assetPrefix: config.assetPrefix,
                tuffRockUsesVolcanicPrefix: config.tuffRockUsesVolcanicPrefix
            )
            if !known.contains(name) {
                missing.append(name)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing rock option art: \(missing)")
    }

    func testMarineMatrixEveryRoundFossilCompositeExists() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for round in config.rounds {
            guard let marine = round.dinosaur,
                  let slug = config.fossilCreatureSlug(marine),
                  let material = config.allMaterials.first(where: { $0.id == round.correctMaterialId })
            else {
                XCTFail("Round \(round.id) missing creature or correct material")
                continue
            }
            let name = material.fossilMatrixImageAssetName(
                creatureSlug: slug,
                assetPrefix: config.assetPrefix,
                tuffFossilUsesVolcanicPrefix: config.tuffFossilUsesVolcanicPrefix
            )
            if !known.contains(name) {
                missing.append(name)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing fossil-in-matrix art for featured rounds: \(missing)")
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

    func testMarineMatrixTuffRockAndFossilUseVolcanicPrefixInAssetNames() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let tuff = config.allMaterials.first { $0.name == "Tuff" }
        XCTAssertNotNil(tuff)
        XCTAssertEqual(
            tuff!.matrixRockImageAssetName(
                assetPrefix: config.assetPrefix,
                tuffRockUsesVolcanicPrefix: true
            ),
            "marine-matrix-material-volcanic-tuff"
        )
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("marine-matrix-material-volcanic-tuff"))
        XCTAssertEqual(
            tuff!.fossilSegment(tuffFossilUsesVolcanicPrefix: true),
            "volcanic-tuff"
        )
    }

    func testMarineMatrixPairKeysUseMaterialAndCreatureSlugs() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        for round in config.rounds {
            guard let marine = round.dinosaur,
                  let creatureSlug = config.fossilCreatureSlug(marine),
                  let material = config.allMaterials.first(where: { $0.id == round.correctMaterialId })
            else { continue }
            let key = MarineMatrixProgress.pairKey(
                materialSlug: material.materialSlug,
                marineReptileSlug: creatureSlug
            )
            XCTAssertEqual(key, "\(material.materialSlug)|\(creatureSlug)")
        }
    }

    // MARK: - Source hints

    func testMarineMatrixSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in ["source-marine-matrix-material", "source-marine-matrix-color"] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testMarineMatrixSourceHintsMatchConfig() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.sourceHints.count, 2)
        XCTAssertEqual(config.sourceHintsTitle, "Source Matrix")
        XCTAssertNil(config.sourceHintsGridIntroAudioKey)
        for hint in config.sourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))
            XCTAssertFalse(hint.displayName.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-marine-matrix-"))
        }
    }

    // MARK: - Audio

    func testMarineMatrixMaterialAudioFilesExistOnDisk() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Materials")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for material in config.allMaterials {
            let key = material.audioKey(for: .marine)
            XCTAssertTrue(stems.contains(key), "Missing Marine Matrix material audio: \(key).m4a")
        }
    }

    func testMarineMatrixGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-marine-matrix",
            "game-dino-matrix-identify-the-stone",
            "game-marine-matrix-material",
            "game-marine-matrix-color",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Marine Matrix gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testMarineMatrixGameplayAudioResolvesInBundle() throws {
        guard config != nil else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            marineMatrixGameplayAudioKeys(),
            messagePrefix: "Marine Matrix"
        )
    }

    @MainActor
    func testMarineMatrixMaterialAudioResolvesInBundle() throws {
        guard let config else {
            throw XCTSkip("Marine Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let keys = config.allMaterials.map { $0.audioKey(for: .marine) }
        XCTAssertEqual(keys.count, config.allMaterials.count)
        TestBundleHelpers.assertBundleResolvesAudioKeys(keys, messagePrefix: "Marine Matrix materials")
    }

    /// Mirrors live `MarineMatrixGameConfigs` narration keys plus shared hint prompt used during rounds.
    private func marineMatrixGameplayAudioKeys() -> [String] {
        [
            "game-marine-matrix",
            "game-dino-matrix-identify-the-stone",
            "game-marine-matrix-material",
            "game-marine-matrix-color",
            "game-hint",
        ]
    }
}
