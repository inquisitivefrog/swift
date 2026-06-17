//
//  MarineFloraXCTests.swift
//  DinoGamesTests
//
//  Catalog + asset/audio/mechanic contracts for Marine Flora. Parallels Ptero Flora coverage.
//

import XCTest
@testable import DinoGames

final class MarineFloraXCTests: XCTestCase {

    private var moments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingMarineFloraMoments()
    }

    func testMarineFloraConfigId() {
        XCTAssertEqual(MarineFloraGameConfigs.marineFlora.id, "marine-flora")
    }

    func testMarineFloraAppearsOnLevel3WhenPlayable() {
        let level3 = MarineReptileGameCatalog.games(level: .level3)
        if MarineFloraGameConfigs.isPlayable {
            XCTAssertTrue(level3.contains { $0.id == "marine-flora" })
        } else {
            XCTAssertFalse(level3.contains { $0.id == "marine-flora" })
        }
    }

    func testMarineFloraPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-flora"), "Missing picker art: game-marine-flora")
        XCTAssertTrue(
            known.contains("game-marine-flora-success") || known.contains("game-marine-flora"),
            "Missing victory art for marine-flora"
        )
    }

    func testMarineFloraPlantIdsAlignWithAudioAndImageSlugs() {
        for plant in marineFloraPlants {
            XCTAssertTrue(plant.displayName.count >= 2, "Plant `\(plant.id)` needs display text")
            XCTAssertTrue(
                plant.treeImageName.hasPrefix("marine-flora-"),
                "Plant `\(plant.id)` habitat image should use marine-flora prefix"
            )
            XCTAssertEqual(plant.audioKey, plant.assetStem, "Plant `\(plant.id)` audio key should match asset stem")
            XCTAssertTrue(plant.treeImageName.contains(plant.formation))
            XCTAssertTrue(plant.treeImageName.contains(plant.taxon))
        }
    }

    func testMarineFloraRegistryHasTenFormationsOnePlantEach() {
        XCTAssertEqual(marineFloraPlants.count, 10)
        XCTAssertEqual(MarineFloraMechanics.registryFormationSlugs.count, 10)
        for formation in MarineFloraMechanics.registryFormationSlugs {
            let plants = marineFloraPlants.filter { $0.formation == formation }
            XCTAssertEqual(plants.count, 1, "Formation `\(formation)` should have one plant for now")
        }
    }

    func testMarineFloraPlayabilityRequiresThreeShippedFormations() {
        let expected = MarineFloraMechanics.shippedFormationSlugs.count >= 3
        XCTAssertEqual(MarineFloraGameConfigs.isPlayable, expected)
    }

    func testMarineFloraShippedPlantsGroupByFormation() {
        for formation in MarineFloraMechanics.shippedFormationSlugs {
            let grouped = MarineFloraMechanics.shippedPlants(forFormation: formation)
            XCTAssertFalse(grouped.isEmpty)
            XCTAssertTrue(grouped.allSatisfy { $0.formation == formation })
        }
    }

    func testMarineFloraRegistryCoversEaterMaps() {
        XCTAssertEqual(MarineFloraMechanics.registryPlantIds, MarineFloraMechanics.eaterMapPlantIds)
    }

    func testMarineFloraShippedPlantEaterMapsHavePoolCapacity() {
        for plant in MarineFloraMechanics.shippedPlants {
            XCTAssertFalse(MarineFloraMechanics.eaterIds(forPlantId: plant.id).isEmpty)
            XCTAssertFalse(MarineFloraMechanics.nonEaterIds(forPlantId: plant.id).isEmpty)
            XCTAssertTrue(
                MarineFloraMechanics.eaterIds(forPlantId: plant.id)
                    .isDisjoint(with: MarineFloraMechanics.nonEaterIds(forPlantId: plant.id))
            )
            XCTAssertGreaterThanOrEqual(MarineFloraMechanics.poolEaterCount(forPlantId: plant.id), 3)
            XCTAssertGreaterThanOrEqual(MarineFloraMechanics.poolNonEaterCount(forPlantId: plant.id), 2)
        }
    }

    func testMarineFloraBundledPlantsHaveHabitatAndSeedsImages() {
        for plant in MarineFloraMechanics.shippedPlants {
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

    func testMarineFloraDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(moments.isEmpty)
        XCTAssertEqual(Set(moments.map(\.gameConfigId)), ["marine-flora"])
    }

    func testMarineFloraCategoryHintImagesContainHintIdSlug() {
        let hints = LandGameDisplayMomentCatalog.marineFloraCategoryHints
        let misaligned = hints.filter { hint in
            let slug = hint.id.replacingOccurrences(of: "-", with: "")
            return !hint.imageAssetName.lowercased().contains(hint.id)
                && !hint.imageAssetName.lowercased().contains(slug)
        }
        XCTAssertTrue(misaligned.isEmpty, "Hint images should include hint id slug")
    }

    @MainActor
    func testMarineFloraCoreGameplayAudioExists() {
        let speech = SpeechManager()
        let keys = [
            "game-marine-flora",
            "game-marine-flora-which-three-marine-reptiles",
            "game-hint",
            "marine-hint-protection",
            "marine-hint-periods",
            "marine-hint-diets",
        ]
        let missing = keys.filter { speech.urlForAudio(key: $0) == nil }
        XCTAssertTrue(missing.isEmpty, "Missing marine flora gameplay audio: \(missing)")
    }
}
