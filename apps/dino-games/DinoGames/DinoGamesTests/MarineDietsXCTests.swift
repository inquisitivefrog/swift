//
//  MarineDietsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class MarineDietsXCTests: XCTestCase {

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
}
