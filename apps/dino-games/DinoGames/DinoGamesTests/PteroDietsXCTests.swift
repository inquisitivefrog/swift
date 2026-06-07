//
//  PteroDietsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PteroDietsXCTests: XCTestCase {

    func testPteroDietTypesUseFilterFeederNotOmnivore() {
        XCTAssertTrue(AirPterosaurData.pterosaurDietTypes.contains("Filter Feeder"))
        XCTAssertFalse(AirPterosaurData.pterosaurDietTypes.contains("Omnivore"))
        XCTAssertFalse(AirPterosaurData.pterosaurDietTypes.contains("Herbivore"))
        XCTAssertEqual(AirPterosaurData.pterosaurDietTypes.count, 5)
    }

    func testPteroDietOptionImagesBundled() {
        let known = ImageAssetNames.knownAssets
        for dietType in AirPterosaurData.pterosaurDietTypes {
            let slug = AirPterosaurData.pterosaurDietAssetSlug(for: dietType)
            let asset = "ptero-diets-\(slug)"
            XCTAssertTrue(known.contains(asset), "Missing pterosaur diet imageset: \(asset)")
        }
    }

    func testPteroDietOptionsAlwaysFiveTiles() {
        XCTAssertEqual(MatchingGameConfigs.pteroDietOptions.count, 5)
        XCTAssertEqual(
            Set(MatchingGameConfigs.pteroDietOptions.map(\.type)),
            Set(AirPterosaurData.pterosaurDietTypes)
        )
    }

    func testPterosaurAssignedDietsAreOnlyPteroDietTypes() {
        let allowed = Set(AirPterosaurData.pterosaurDietTypes)
        for (id, diet) in AirPterosaurData.pterosaurDietById {
            XCTAssertTrue(
                allowed.contains(diet),
                "Pterosaur \(id) has diet \(diet), which is not one of the five Ptero Diets options"
            )
        }
    }

    func testPteroDietRoundIsPlayable() {
        let config = MatchingGameConfigs.pteroDietFeatures
        XCTAssertEqual(config.selectedDinosaurs.count, 3)
        XCTAssertEqual(config.selectedCharacteristics.count, 5)
        let roundDiets = Set(config.selectedCharacteristics.map(\.type))
        XCTAssertEqual(roundDiets, Set(AirPterosaurData.pterosaurDietTypes))
        let creatureDiets = Set(config.selectedDinosaurs.compactMap { AirPterosaurData.pterosaurDietById[$0.id] })
        XCTAssertEqual(creatureDiets.count, 3)
        XCTAssertTrue(creatureDiets.isSubset(of: roundDiets))
    }

    func testPteroDietAudioKeys() {
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Frugivore"), "ptero-diets-frugivore")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Filter Feeder"), "ptero-diets-filter-feeder")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Carnivore"), "ptero-diet-carnivore")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Insectivore"), "ptero-diet-insectivore")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Piscivore"), "ptero-diet-piscivore")
    }

    func testPteroDietAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Ptero-Diets")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for dietType in AirPterosaurData.pterosaurDietTypes {
            let key = AirPterosaurData.pterosaurDietAudioKey(for: dietType)
            XCTAssertTrue(stems.contains(key), "Missing Ptero Diets audio: \(key).m4a")
        }
    }

    @MainActor
    func testPteroDietAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            AirPterosaurData.pterosaurDietTypes.map { AirPterosaurData.pterosaurDietAudioKey(for: $0) },
            messagePrefix: "Ptero Diets"
        )
    }
}
