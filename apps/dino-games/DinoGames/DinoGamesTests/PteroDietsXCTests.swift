//
//  PteroDietsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PteroDietsXCTests: XCTestCase {

    private var dietMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingAirMoments().filter { $0.gameConfigId == "ptero-diets" }
    }

    func testPteroDietsConfigIdAndIntro() {
        let config = MatchingGameConfigs.pteroDietFeatures
        XCTAssertEqual(config.id, "ptero-diets")
        XCTAssertEqual(config.title, "Ptero Diets!")
        XCTAssertEqual(config.introAudio, "game-ptero-diets")
    }

    func testPteroDietsAppearsOnLevel4() {
        let level4 = PterosaurGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "ptero-diets" })
    }

    func testPteroDietsProgressCategoryIsAir() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("ptero-diets"), .air)
    }

    func testPteroDietsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-ptero-diets"), "Missing picker art: game-ptero-diets")
        XCTAssertTrue(
            known.contains("game-ptero-diets-success") || known.contains("game-ptero-diets"),
            "Missing victory art for ptero-diets"
        )
    }

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
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Carnivore"), "ptero-diets-carnivore")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Insectivore"), "ptero-diets-insectivore")
        XCTAssertEqual(AirPterosaurData.pterosaurDietAudioKey(for: "Piscivore"), "ptero-diets-piscivore")
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

    func testPteroDietsDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(dietMoments.isEmpty)
        let dietTiles = dietMoments.filter { $0.context.hasPrefix("diet ") }
        XCTAssertEqual(dietTiles.count, 5)
    }

    func testPteroDietsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = dietMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testPteroDietsDisplayMomentsHaveResolvableAudio() {
        let speech = SpeechManager()
        let missing = dietMoments.filter { moment in
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
    func testPteroDietsGameplayInstructionAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            PterosaurGameAudioContracts.allRequiredKeys(forConfigId: "ptero-diets"),
            messagePrefix: "Ptero Diets gameplay"
        )
    }
}
