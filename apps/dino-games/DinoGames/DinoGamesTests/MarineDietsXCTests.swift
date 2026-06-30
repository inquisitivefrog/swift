//
//  MarineDietsXCTests.swift
//  DinoGamesTests
//
//  Catalog, asset, audio, and round-mechanic contracts for Marine Diets (sea L4).
//

import XCTest
@testable import DinoGames

final class MarineDietsXCTests: XCTestCase {

    private var dietMoments: [LandGameDisplayMoment] {
        LandGameDisplayMomentCatalog.shippingMarineMoments()
            .filter { $0.gameConfigId == "marine-diets" }
    }

    // MARK: - Config / catalog

    func testMarineDietsConfigIdAndIntro() {
        let config = MatchingGameConfigs.marineDietFeatures
        XCTAssertEqual(config.id, "marine-diets")
        XCTAssertEqual(config.title, "Marine Diets!")
        XCTAssertEqual(config.introAudio, "game-marine-diets")
    }

    func testMarineDietsAppearsOnLevel4() {
        let level4 = MarineReptileGameCatalog.games(level: .level4)
        XCTAssertTrue(level4.contains { $0.id == "marine-diets" })
    }

    func testMarineDietsProgressCategoryIsMarine() {
        XCTAssertEqual(GameCategory.forCatalogConfigId("marine-diets"), .marineReptiles)
    }

    func testMarineDietsPickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        XCTAssertTrue(known.contains("game-marine-diets"), "Missing picker art: game-marine-diets")
        XCTAssertTrue(
            known.contains("game-marine-diets-success") || known.contains("game-marine-diets"),
            "Missing victory art for marine-diets"
        )
    }

    func testMarineDietTypesAreFiveMarineLabels() {
        XCTAssertEqual(SeaMarineReptileData.marineDietTypes.count, 5)
        XCTAssertEqual(
            Set(SeaMarineReptileData.marineDietTypes),
            Set(["Herbivore", "Piscivore", "Apex Predator", "Durophage", "Teuthivore"])
        )
    }

    func testMarineDietOptionImagesBundled() {
        let known = ImageAssetNames.knownAssets
        for dietType in SeaMarineReptileData.marineDietTypes {
            let slug = SeaMarineReptileData.dietAssetSlug(for: dietType)
            let asset = "marine-diets-\(slug)"
            XCTAssertTrue(known.contains(asset), "Missing marine diet imageset: \(asset)")
        }
    }

    func testMarineDietOptionsAlwaysFiveTiles() {
        XCTAssertEqual(MatchingGameConfigs.marineDietOptions.count, 5)
        XCTAssertEqual(
            Set(MatchingGameConfigs.marineDietOptions.map(\.type)),
            Set(SeaMarineReptileData.marineDietTypes)
        )
    }

    func testMarineReptileAssignedDietsAreOnlyMarineDietTypes() {
        let allowed = Set(SeaMarineReptileData.marineDietTypes)
        for (id, diet) in SeaMarineReptileData.marineReptileDietById {
            XCTAssertTrue(
                allowed.contains(diet),
                "Marine reptile \(id) has diet \(diet), which is not one of the five Marine Diets options"
            )
        }
        for marine in SeaMarineReptileData.allMarineReptiles {
            XCTAssertNotNil(
                SeaMarineReptileData.marineReptileDietById[marine.id],
                "Marine pool creature \(marine.name) (id \(marine.id)) needs a diet assignment for Marine Diets"
            )
        }
    }

    func testHenodusIsHerbivoreInMarineDiets() {
        let henodus = SeaMarineReptileData.allMarineReptiles.first {
            $0.imageName == "marine-notho-henodus"
        }
        XCTAssertNotNil(henodus, "Expected Henodus in marine reptile catalog")
        XCTAssertEqual(SeaMarineReptileData.diet(for: henodus!), "Herbivore")
        XCTAssertEqual(SeaMarineReptileData.marineReptileDietById[henodus!.id], "Herbivore")
    }

    func testMarineDietRoundIsPlayable() {
        let config = MatchingGameConfigs.marineDietFeatures
        XCTAssertEqual(config.selectedDinosaurs.count, 3)
        XCTAssertEqual(config.selectedCharacteristics.count, 5)
        let roundDiets = Set(config.selectedCharacteristics.map(\.type))
        XCTAssertEqual(roundDiets, Set(SeaMarineReptileData.marineDietTypes))
        let creatureDiets = Set(config.selectedDinosaurs.compactMap { SeaMarineReptileData.marineReptileDietById[$0.id] })
        XCTAssertEqual(creatureDiets.count, 3)
        XCTAssertTrue(creatureDiets.isSubset(of: roundDiets))
    }

    // MARK: - Audio

    func testMarineDietAudioKeys() {
        XCTAssertEqual(SeaMarineReptileData.dietAudioKey(for: "Herbivore"), "marine-diets-herbivore")
        XCTAssertEqual(SeaMarineReptileData.dietAudioKey(for: "Piscivore"), "marine-diets-piscivore")
        XCTAssertEqual(SeaMarineReptileData.dietAudioKey(for: "Apex Predator"), "marine-diets-apex-predator")
        XCTAssertEqual(SeaMarineReptileData.dietAudioKey(for: "Durophage"), "marine-diets-durophage")
        XCTAssertEqual(SeaMarineReptileData.dietAudioKey(for: "Teuthivore"), "marine-diets-teuthivore")
    }

    func testMarineDietAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Marine-Diets")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for dietType in SeaMarineReptileData.marineDietTypes {
            let key = SeaMarineReptileData.dietAudioKey(for: dietType)
            XCTAssertTrue(stems.contains(key), "Missing Marine Diets audio: \(key).m4a")
        }
    }

    @MainActor
    func testMarineDietAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            SeaMarineReptileData.marineDietTypes.map { SeaMarineReptileData.dietAudioKey(for: $0) },
            messagePrefix: "Marine Diets"
        )
    }

    @MainActor
    func testMarineDietsGameplayInstructionAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            ["game-marine-diets"],
            messagePrefix: "Marine Diets gameplay"
        )
    }

    // MARK: - Display moments

    func testMarineDietsDisplayMomentsAreNonEmpty() {
        XCTAssertFalse(dietMoments.isEmpty)
        let dietTiles = dietMoments.filter { $0.context.hasPrefix("diet ") }
        XCTAssertEqual(dietTiles.count, 5)
    }

    func testMarineDietsDisplayMomentsHaveImagesInAssetCatalog() {
        let known = ImageAssetNames.knownAssets
        let missing = dietMoments.filter { !known.contains($0.imageAssetName) }
        let labels = missing.map { "\($0.context) → `\($0.imageAssetName)`" }
        XCTAssertTrue(labels.isEmpty, "Missing imagesets: \(labels.joined(separator: "; "))")
    }

    @MainActor
    func testMarineDietsDisplayMomentsHaveResolvableAudio() {
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
}
