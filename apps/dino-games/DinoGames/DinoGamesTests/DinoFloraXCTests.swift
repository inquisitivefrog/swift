//
//  DinoFloraXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Dino Flora. Parallels Ptero/Marine Flora coverage.
//

import XCTest
@testable import DinoGames

final class DinoFloraXCTests: XCTestCase {

    private var moments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingDinoFloraMoments()
    }

    func testDinoFloraConfigId() {
        XCTAssertEqual(DinoFloraGameConfigs.dinoFlora.id, "dino-flora")
    }

    func testDinoFloraAppearsOnLevel3() {
        let level3 = DinosaurGameCatalog.games(level: .level3)
        XCTAssertTrue(level3.contains {
            guard case .dinoFlora = $0 else { return false }
            return true
        })
    }

    func testDinoFloraPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-dino-flora"), "Missing picker art: game-dino-flora")
        XCTAssertTrue(
            known.contains("game-dino-flora-success") || known.contains("game-dino-flora"),
            "Missing victory art for dino-flora"
        )
    }

    func testDinoFloraPlantIdsAlignWithAudioAndImageSlugs() {
        for plant in dinoFloraPlants {
            XCTAssertTrue(plant.displayName.count >= 2, "Plant `\(plant.id)` needs display text")
            XCTAssertTrue(
                plant.treeImageName.hasPrefix("dino-flora-"),
                "Plant `\(plant.id)` habitat image should use dino-flora prefix: `\(plant.treeImageName)`"
            )
            XCTAssertEqual(plant.audioKey, plant.assetStem, "Plant `\(plant.id)` audio key should match asset stem")
            XCTAssertTrue(plant.treeImageName.contains(plant.formation))
            XCTAssertTrue(plant.treeImageName.contains(plant.taxon))
        }
    }

    func testDinoFloraPlantAudioKeysListedInContract() {
        let keys = LandDinosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "dino-flora")
        let expected = dinoFloraPlants.map(\.audioKey)
        XCTAssertEqual(keys.count, expected.count)
        XCTAssertEqual(Set(keys), Set(expected))
    }

    func testDinoFloraRegistryCoversEaterMaps() {
        XCTAssertEqual(DinoFloraMechanics.registryPlantIds, DinoFloraMechanics.eaterMapPlantIds)
        XCTAssertEqual(DinoFloraMechanics.registryPlantIds, DinoFloraMechanics.nonEaterMapPlantIds)
    }

    func testDinoFloraRegistryPlantsHavePoolCapacity() {
        for plant in dinoFloraPlants {
            XCTAssertFalse(DinoFloraMechanics.eaterIds(forPlantId: plant.id).isEmpty)
            XCTAssertFalse(DinoFloraMechanics.nonEaterIds(forPlantId: plant.id).isEmpty)
            XCTAssertTrue(
                DinoFloraMechanics.eaterIds(forPlantId: plant.id)
                    .isDisjoint(with: DinoFloraMechanics.nonEaterIds(forPlantId: plant.id))
            )
            XCTAssertGreaterThanOrEqual(DinoFloraMechanics.poolEaterCount(forPlantId: plant.id), 3)
            XCTAssertGreaterThanOrEqual(DinoFloraMechanics.poolNonEaterCount(forPlantId: plant.id), 2)
        }
    }

    func testDinoFloraBundledPlantsHaveHabitatAndSeedsImages() {
        for plant in dinoFloraPlants {
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.treeImageName),
                "Missing habitat imageset `\(plant.treeImageName)`"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.seedsImageName),
                "Missing seeds imageset `\(plant.seedsImageName)`"
            )
        }
    }

    func testDinoFloraDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(moments.isEmpty)
        XCTAssertEqual(Set(moments.map(\.gameConfigId)), ["dino-flora"])
    }

    func testDinoFloraDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = moments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    func testDinoFloraDisplayMomentsHaveNonEmptyDisplayText() {
        let empty = moments.filter { $0.displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let labels = empty.map(\.context)
        XCTAssertTrue(labels.isEmpty, "Moments with empty display text: \(labels.joined(separator: ", "))")
    }

    func testDinoFloraCategoryHintImagesContainHintIdSlug() {
        let hints = LandGameDisplayMomentCatalog.dinoFloraCategoryHints
        let misaligned = hints.filter { hint in
            let slug = hint.id.replacingOccurrences(of: "-", with: "")
            return !hint.imageAssetName.lowercased().contains(hint.id)
                && !hint.imageAssetName.lowercased().contains(slug)
        }
        let labels = misaligned.map { "\($0.id): image `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Hint images should include hint id slug: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testDinoFloraDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = moments.filter { moment in
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

    @MainActor
    func testDinoFloraCoreGameplayAudioExists() {
        let speech = SpeechManager()
        let keys = [
            "game-dino-flora",
            "game-dino-flora-which-three-dinosaurs",
            "game-dino-flora-tap-the-image",
            "game-hint",
            "dino-hint-browsers",
            "dino-hint-periods",
            "dino-hint-diets",
        ]
        let missing = keys.filter { speech.urlForAudio(key: $0) == nil }
        XCTAssertTrue(missing.isEmpty, "Missing dino flora gameplay audio: \(missing)")
    }

    func testDinoFloraPlantAudioFilesExistOnDisk() throws {
        let root = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Flora")
        var missing: [String] = []
        for plant in dinoFloraPlants {
            let path = root
                .appendingPathComponent(plant.formationFolder)
                .appendingPathComponent("\(plant.audioKey).m4a")
            if !FileManager.default.fileExists(atPath: path.path) {
                missing.append("\(plant.formationFolder)/\(plant.audioKey).m4a")
            }
        }
        XCTAssertTrue(missing.isEmpty, "Missing dino flora plant audio: \(missing)")
    }

    @MainActor
    func testDinoFloraPlantAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            dinoFloraPlants.map(\.audioKey),
            messagePrefix: "Dino Flora plant"
        )
    }
}
