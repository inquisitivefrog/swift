//
//  PteroMatrixCatalogXCTests.swift
//  DinoGamesTests
//
//  Catalog, round config, asset, and audio contracts for Ptero Matrix (air level 4).
//

import XCTest
@testable import DinoGames

final class PteroMatrixCatalogXCTests: XCTestCase {

    private var config: DinoMatrixGameConfig? { PteroMatrixGameConfigs.makePteroMatrix() }

    // MARK: - Config / catalog

    func testPteroMatrixConfigIdAndIntro() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.id, "ptero-matrix")
        XCTAssertEqual(config.title, "Ptero Matrix!")
        XCTAssertEqual(config.introAudio, "game-ptero-matrix")
        XCTAssertEqual(config.identifyStoneAudioKey, "game-ptero-matrix-identify-the-stone")
        XCTAssertEqual(config.assetPrefix, "ptero-matrix")
        XCTAssertEqual(config.progressKind, .ptero)
        XCTAssertFalse(config.tuffRockUsesVolcanicPrefix)
        XCTAssertTrue(config.tuffFossilUsesVolcanicPrefix)
    }

    func testPteroMatrixAppearsOnLevel4() throws {
        guard config != nil else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(
            level4.contains { $0.id == "ptero-matrix" },
            "Ptero Matrix should appear on air level 4"
        )
    }

    func testPteroMatrixProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("ptero-matrix"), .air)
    }

    func testPteroMatrixPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-matrix"), "Missing picker art: game-ptero-matrix")
        XCTAssertTrue(
            known.contains("game-ptero-matrix-success") || known.contains("game-ptero-matrix"),
            "Missing victory art for ptero-matrix"
        )
    }

    // MARK: - Rounds / materials

    func testPteroMatrixConfigBuildsThreeRoundsWithDistinctCorrectStones() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.rounds.count, 3)
        let correctMaterialIds = Set(config.rounds.map(\.correctMaterialId))
        XCTAssertEqual(
            correctMaterialIds.count,
            3,
            "Each round should feature a distinct correct matrix stone"
        )
    }

    func testPteroMatrixEachRoundHasThreeOptionsIncludingCorrectStone() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
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

    func testPteroMatrixShipsSixPterosaurMatrixMaterials() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.allMaterials.count, 6)
        let slugs = Set(config.allMaterials.map(\.materialSlug))
        XCTAssertEqual(
            slugs,
            ["bentonite", "chalk", "lignite", "sandstone", "shale", "tuff"]
        )
    }

    func testPteroMatrixAllMaterialsHaveRockOptionArt() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
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

    func testPteroMatrixEveryRoundFossilCompositeExists() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let known = ImageAssetNames.knownAssets
        var missing: [String] = []
        for round in config.rounds {
            guard let ptero = round.dinosaur,
                  let slug = config.fossilCreatureSlug(ptero),
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

    func testPteroMatrixFossilSlugMatchesBundledComposites() {
        let dimorphodon = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-basal-dimorphodon" }
        XCTAssertNotNil(dimorphodon)
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: dimorphodon!), "dimorphodon")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-shale-dimorphodon"))

        let quetz = AirPterosaurData.allPterosaurs.first { $0.imageName == "ptero-azhd-quetzalcoatlus" }
        XCTAssertNotNil(quetz)
        XCTAssertEqual(AirPterosaurData.matrixFossilSlug(for: quetz!), "quetzalcoatlus")
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-lignite-quetzalcoatlus"))
    }

    func testPteroMatrixTuffFossilUsesVolcanicPrefixInAssetNames() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let tuff = config.allMaterials.first { $0.name == "Tuff" }
        XCTAssertNotNil(tuff)
        XCTAssertEqual(
            tuff!.matrixRockImageAssetName(
                assetPrefix: config.assetPrefix,
                tuffRockUsesVolcanicPrefix: false
            ),
            "ptero-matrix-material-tuff"
        )
        XCTAssertTrue(ImageAssetNames.knownAssets.contains("ptero-matrix-material-tuff"))
        XCTAssertEqual(
            tuff!.fossilSegment(tuffFossilUsesVolcanicPrefix: true),
            "volcanic-tuff"
        )
    }

    func testPteroMatrixPairKeysUseMaterialAndCreatureSlugs() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        for round in config.rounds {
            guard let ptero = round.dinosaur,
                  let creatureSlug = config.fossilCreatureSlug(ptero),
                  let material = config.allMaterials.first(where: { $0.id == round.correctMaterialId })
            else { continue }
            let key = PteroMatrixProgress.pairKey(
                materialSlug: material.materialSlug,
                pterosaurSlug: creatureSlug
            )
            XCTAssertEqual(key, "\(material.materialSlug)|\(creatureSlug)")
        }
    }

    // MARK: - Source hints

    func testPteroMatrixSourceHintArtExists() {
        let known = ImageAssetNames.knownAssets
        for name in ["source-ptero-matrix-material", "source-ptero-matrix-color"] {
            XCTAssertTrue(known.contains(name), "Missing bundled asset: \(name)")
        }
    }

    func testPteroMatrixSourceHintsMatchConfig() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        XCTAssertEqual(config.sourceHints.count, 2)
        XCTAssertEqual(config.sourceHintsTitle, "Source Matrix")
        XCTAssertEqual(config.sourceHintsGridIntroAudioKey, "game-ptero-matrix-tap-the-image")
        for hint in config.sourceHints {
            XCTAssertTrue(ImageAssetNames.knownAssets.contains(hint.imageName))
            XCTAssertFalse(hint.displayName.isEmpty)
            XCTAssertTrue(hint.audioKey.hasPrefix("game-ptero-matrix-"))
        }
    }

    // MARK: - Audio

    func testPteroMatrixMaterialAudioFilesExistOnDisk() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Materials")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for material in config.allMaterials {
            let key = material.audioKey(for: .ptero)
            XCTAssertTrue(stems.contains(key), "Missing Ptero Matrix material audio: \(key).m4a")
        }
    }

    func testPteroMatrixGameplayAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for key in [
            "game-ptero-matrix",
            "game-ptero-matrix-identify-the-stone",
            "game-ptero-matrix-material",
            "game-ptero-matrix-color",
            "game-ptero-matrix-tap-the-image",
        ] {
            XCTAssertTrue(stems.contains(key), "Missing Ptero Matrix gameplay audio: \(key).m4a")
        }
    }

    @MainActor
    func testPteroMatrixGameplayAudioResolvesInBundle() throws {
        guard config != nil else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-matrix"),
            messagePrefix: "Ptero Matrix"
        )
    }

    @MainActor
    func testPteroMatrixMaterialAudioResolvesInBundle() throws {
        guard let config else {
            throw XCTSkip("Ptero Matrix needs at least three bundled fossil-in-matrix image sets.")
        }
        let keys = PterosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "ptero-matrix")
        XCTAssertEqual(keys.count, config.allMaterials.count)
        TestBundleHelpers.assertBundleResolvesAudioKeys(keys, messagePrefix: "Ptero Matrix materials")
    }
}
