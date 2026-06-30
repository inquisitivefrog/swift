//
//  DinoMatrixCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, round config, asset, and audio contracts for Dino Matrix (land level 4).
//

import XCTest
@testable import DinoGames

final class DinoMatrixCatalogXCTests: XCTestCase {

    private var config: DinoMatrixGameConfig { DinoMatrixGameConfigs.dinoMatrix }

    // MARK: - Config / catalog

    func testDinoMatrixConfigIdAndIntro() {
        XCTAssertEqual(config.id, "dino-matrix")
        XCTAssertEqual(config.title, "Dino Matrix!")
        XCTAssertEqual(config.introAudio, "game-dino-matrix")
        XCTAssertEqual(config.identifyStoneAudioKey, "game-dino-matrix-identify-the-stone")
        XCTAssertEqual(config.assetPrefix, "dino-matrix")
        XCTAssertEqual(config.progressKind, .dino)
        XCTAssertTrue(config.tuffRockUsesVolcanicPrefix)
        XCTAssertFalse(config.tuffFossilUsesVolcanicPrefix)
    }

    func testDinoMatrixAppearsOnLevel4() {
        let level4 = DinosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "dino-matrix" },
            "Dino Matrix should appear on land level 4"
        )
    }

    func testDinoMatrixProgressCategoryIsLand() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("dino-matrix"), .land)
    }

    func testDinoMatrixIsPrerequisiteForFormations() {
        XCTAssertTrue(
            LandDinosaurGamePairing.prerequisites(before: "dino-formations").contains("dino-matrix"),
            "Expected dino-matrix to gate dino-formations"
        )
    }

    func testDinoMatrixPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-matrix"), "Missing picker art: game-dino-matrix")
        XCTAssertTrue(
            known.contains("game-dino-matrix-success") || known.contains("game-dino-matrix"),
            "Missing victory art for dino-matrix"
        )
    }

    // MARK: - Rounds / materials

    func testDinoMatrixConfigBuildsThreeRoundsWithDistinctCorrectStones() {
        XCTAssertEqual(config.rounds.count, 3)
        let correctMaterialIds = Set(config.rounds.map(\.correctMaterialId))
        XCTAssertEqual(
            correctMaterialIds.count,
            3,
            "Each round should feature a distinct correct matrix stone"
        )
    }

    func testDinoMatrixEachRoundHasThreeOptionsIncludingCorrectStone() {
        for round in config.rounds {
            XCTAssertEqual(round.options.count, 3)
            XCTAssertNotNil(round.dinosaur, "Round \(round.id) should feature a creature")
            XCTAssertTrue(
                round.options.contains { $0.id == round.correctMaterialId },
                "Round \(round.id) options must include the correct stone"
            )
        }
    }

    func testDinoMatrixShipsTenLandMatrixMaterials() {
        XCTAssertEqual(config.allMaterials.count, 10)
        let slugs = Set(config.allMaterials.map(\.materialSlug))
        XCTAssertEqual(
            slugs,
            [
                "limestone", "mudstone", "sandstone", "siltstone", "tuff", "shale",
                "ironstone", "claystone", "lignite", "conglomerate",
            ]
        )
    }

    func testDinoMatrixAllMaterialsHaveRockOptionArt() {
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

    func testDinoMatrixEveryRoundFossilCompositeExists() {
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for round in config.rounds {
            guard let dino = round.dinosaur,
                  let slug = config.fossilCreatureSlug(dino),
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

    func testDinoMatrixFossilSlugMatchesBundledComposites() {
        let trex = LandDinosaurData.allDinosaurs.first { $0.imageName == "dino-trex" }
        XCTAssertNotNil(trex)
        XCTAssertEqual(config.fossilCreatureSlug(trex!), "trex")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-matrix-sandstone-trex"))

        let ankyl = LandDinosaurData.allDinosaurs.first { $0.imageName == "dino-ankylosaurus" }
        XCTAssertNotNil(ankyl)
        XCTAssertEqual(config.fossilCreatureSlug(ankyl!), "ankylosaurus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-matrix-ironstone-ankylosaurus"))
    }

    func testDinoMatrixTuffRockUsesVolcanicPrefixInAssetNames() {
        let tuff = config.allMaterials.first { $0.name == "Tuff" }
        XCTAssertNotNil(tuff)
        XCTAssertEqual(
            tuff!.matrixRockImageAssetName(
                assetPrefix: config.assetPrefix,
                tuffRockUsesVolcanicPrefix: true
            ),
            "dino-matrix-material-volcanic-tuff"
        )
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("dino-matrix-material-volcanic-tuff"))
    }

    func testDinoMatrixPairKeysUseMaterialAndCreatureSlugs() {
        for round in config.rounds {
            guard let dino = round.dinosaur,
                  let creatureSlug = config.fossilCreatureSlug(dino),
                  let material = config.allMaterials.first(where: { $0.id == round.correctMaterialId })
            else { continue }
            let key = DinoMatrixProgress.pairKey(
                materialSlug: material.materialSlug,
                dinosaurSlug: creatureSlug
            )
            XCTAssertEqual(key, "\(material.materialSlug)|\(creatureSlug)")
        }
    }

    // MARK: - Source hints

    func testDinoMatrixSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in ["source-dino-matrix-materials", "source-dino-matrix-color"] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testDinoMatrixSourceHintsMatchConfig() {
        XCTAssertEqual(config.sourceHints.count, 2)
        XCTAssertEqual(config.sourceHintsTitle, "Source Matrix")
        XCTAssertEqual(config.sourceHintsGridIntroAudioKey, "game-dino-matrix-tap-the-image")
        for hint in config.sourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))
            XCTAssertFalse(hint.displayName.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-dino-matrix-"))
        }
    }

    // MARK: - Audio

    func testDinoMatrixMaterialAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Materials")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for material in config.allMaterials {
            let key = material.audioKey(for: .dino)
            XCTAssertTrue(stems.contains(key), "Missing Dino Matrix material audio: \(key).m4a")
        }
    }

    func testDinoMatrixGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-dino-matrix",
            "game-dino-matrix-identify-the-stone",
            "game-dino-matrix-material",
            "game-dino-matrix-color",
            "game-dino-matrix-tap-the-image",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Dino Matrix gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testDinoMatrixGameplayAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurGameAudioContracts.allRequiredKeys(forConfigId: "dino-matrix"),
            messagePrefix: "Dino Matrix"
        )
    }

    @MainActor
    func testDinoMatrixMaterialAudioResolvesInBundle() {
        let keys = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-matrix")
        XCTAssertEqual(keys.count, config.allMaterials.count)
        TestBundleHelpers.assertBundleResolvesAudioKeys(keys, messagePrefix: "Dino Matrix materials")
    }
}
