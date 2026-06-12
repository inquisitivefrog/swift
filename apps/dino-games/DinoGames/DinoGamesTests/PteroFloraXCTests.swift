//
//  PteroFloraXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Ptero Flora. Parallels Dino Flora coverage in
//  `LandDinosaurMechanicCatalogXCTests` and `LandGameDisplayMomentXCTests`.
//

import XCTest
@testable import DinoGames

final class PteroFloraXCTests: XCTestCase {

    private var moments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingPteroFloraMoments()
    }

    // MARK: - Config / catalog

    func testPteroFloraConfigId() {
        XCTAssertEqual(PteroFloraGameConfigs.pteroFloraKarabastau.id, "ptero-flora")
    }

    func testPteroFloraAppearsOnLevel3() {
        let level3 = PterosaurGameCatalog.games(level: .level3)
        XCTAssertTrue(level3.contains { $0.id == "ptero-flora" })
    }

    func testPteroFloraPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-flora"), "Missing picker art: game-ptero-flora")
        XCTAssertTrue(
            known.contains("game-ptero-flora-success") || known.contains("game-ptero-flora"),
            "Missing victory art for ptero-flora"
        )
    }

    // MARK: - Registry naming + images

    func testPteroFloraPlantIdsAlignWithAudioAndImageSlugs() {
        for plant in pteroFloraPlants {
            XCTAssertTrue(plant.displayName.count >= 2, "Plant `\(plant.id)` needs display text")
            XCTAssertTrue(
                plant.treeImageName.hasPrefix("ptero-flora-"),
                "Plant `\(plant.id)` habitat image should use ptero-flora prefix: `\(plant.treeImageName)`"
            )
            XCTAssertEqual(plant.audioKey, plant.assetStem, "Plant `\(plant.id)` audio key should match asset stem")
            XCTAssertTrue(
                plant.treeImageName.contains(plant.formation),
                "Plant `\(plant.id)` image should include formation slug `\(plant.formation)`"
            )
            XCTAssertTrue(
                plant.treeImageName.contains(plant.taxon),
                "Plant `\(plant.id)` image should include taxon slug `\(plant.taxon)`"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.treeImageName),
                "Plant `\(plant.id)` missing habitat imageset `\(plant.treeImageName)`"
            )
            XCTAssertTrue(
                ImageAssetNames.knownAssets.contains(plant.seedsImageName),
                "Plant `\(plant.id)` missing seeds imageset `\(plant.seedsImageName)`"
            )
        }
    }

    func testPteroFloraPlantAudioKeysListedInContract() {
        let keys = PterosaurGameAudioContracts.supplementalAudioKeys(forConfigId: "ptero-flora")
        let expected = pteroFloraPlants.map(\.audioKey)
        XCTAssertEqual(keys.count, expected.count)
        XCTAssertEqual(Set(keys), Set(expected))
    }

    // MARK: - Shipped gameplay (Karabastau)

    func testPteroFloraShippedPlantEaterMapsCoverRegistry() {
        let plantIds = PteroFloraMechanics.shippedPlantIds
        XCTAssertEqual(PteroFloraMechanics.eaterMapPlantIds, plantIds)
        XCTAssertEqual(PteroFloraMechanics.nonEaterMapPlantIds, plantIds)
        for plant in PteroFloraMechanics.shippedPlants {
            let eaters = PteroFloraMechanics.eaterIds(forPlantId: plant.id)
            let nonEaters = PteroFloraMechanics.nonEaterIds(forPlantId: plant.id)
            XCTAssertFalse(eaters.isEmpty, "Plant `\(plant.id)` needs eaters")
            XCTAssertFalse(nonEaters.isEmpty, "Plant `\(plant.id)` needs non-eaters")
            XCTAssertTrue(
                eaters.isDisjoint(with: nonEaters),
                "Plant `\(plant.id)` eaters and non-eaters must not overlap"
            )
            XCTAssertGreaterThanOrEqual(
                PteroFloraMechanics.poolEaterCount(forPlantId: plant.id),
                3,
                "Plant `\(plant.id)` needs at least 3 pool eaters for a round"
            )
            XCTAssertGreaterThanOrEqual(
                PteroFloraMechanics.poolNonEaterCount(forPlantId: plant.id),
                2,
                "Plant `\(plant.id)` needs at least 2 pool non-eaters for a round"
            )
        }
    }

    // MARK: - Display moments (hints + plants)

    func testPteroFloraDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(moments.isEmpty)
        XCTAssertEqual(Set(moments.map(\.gameConfigId)), ["ptero-flora"])
    }

    func testPteroFloraDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = moments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    func testPteroFloraDisplayMomentsHaveNonEmptyDisplayText() {
        let empty = moments.filter { $0.displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let labels = empty.map(\.context)
        XCTAssertTrue(labels.isEmpty, "Moments with empty display text: \(labels.joined(separator: ", "))")
    }

    @MainActor
    func testPteroFloraDisplayMomentsHaveResolvableAudio() {
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

    func testPteroFloraCategoryHintImagesContainHintIdSlug() {
        let hints = LandGameDisplayMomentCatalog.pteroFloraCategoryHints
        let misaligned = hints.filter { hint in
            let slug = hint.id.replacingOccurrences(of: "-", with: "")
            return !hint.imageAssetName.lowercased().contains(hint.id)
                && !hint.imageAssetName.lowercased().contains(slug)
        }
        let labels = misaligned.map { "\($0.id): image `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Hint images should include hint id slug: \(labels.joined(separator: "; "))")
    }
}
