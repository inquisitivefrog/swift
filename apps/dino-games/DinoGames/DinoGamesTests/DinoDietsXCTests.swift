//
//  DinoDietsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinoDietsXCTests: XCTestCase {

    func testDinoDietAudioKeys() {
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Herbivore"), "dino-diet-herbivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Carnivore"), "dino-diet-carnivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Piscivore"), "dino-diet-piscivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Insectivore"), "dino-diet-insectivore")
        XCTAssertEqual(LandDinosaurData.dinosaurDietAudioKey(for: "Omnivore"), "dino-diet-omnivore")
    }

    func testDinoDietAudioFilesExistOnDisk() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dino-Diets")
        let stems = try TestBundleHelpers.audioStems(in: directory)
        for dietType in LandDinosaurData.dinosaurDietTypes {
            let key = LandDinosaurData.dinosaurDietAudioKey(for: dietType)
            XCTAssertTrue(stems.contains(key), "Missing Dino Diets audio: \(key).m4a")
        }
    }

    @MainActor
    func testDinoDietAudioResolvesInBundle() {
        TestBundleHelpers.assertBundleResolvesAudioKeys(
            LandDinosaurData.dinosaurDietTypes.map { LandDinosaurData.dinosaurDietAudioKey(for: $0) },
            messagePrefix: "Dino Diets"
        )
    }
}
