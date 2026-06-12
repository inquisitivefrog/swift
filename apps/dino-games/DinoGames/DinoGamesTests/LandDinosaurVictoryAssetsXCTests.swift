//
//  LandDinosaurVictoryAssetsXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class LandDinosaurVictoryAssetsXCTests: XCTestCase {

    /// Picker card + primary victory success imageset for each shipping land game.
    private let cardAndSuccess: [(configId: String, picker: String, successCandidates: [String])] = [
        ("weigh-dinosaur", "game-weigh-dinosaur", ["game-weigh-dinosaur-success", "game-weigh-dinosaur"]),
        ("which-dino-is-taller", "game-which-dino-is-taller", ["game-which-dino-is-taller-success", "game-which-dino-is-taller"]),
        ("dino-puzzle", "game-dino-puzzle", ["game-dino-puzzle-success", "game-dino-puzzle"]),
        ("name-that-dinosaur", "game-name-that-dinosaur", ["game-name-that-dinosaur-success", "game-name-that-dinosaur"]),
        ("racing-dinosaurs", "game-racing-dinosaurs", ["game-racing-dinosaurs-success", "game-racing-dinosaurs"]),
        ("dino-ages", "game-dino-ages", ["game-dino-ages-success", "game-dino-ages"]),
        ("dino-footprints", "game-dino-footprints", ["game-dino-footprints-success", "game-dino-footprints"]),
        ("dino-flora", "game-dino-flora", ["game-dino-flora-success", "game-dino-flora"]),
        ("dino-eggs", "game-dino-eggs", ["game-dino-eggs-success", "game-dino-eggs"]),
        ("dino-matrix", "game-dino-matrix", ["game-dino-matrix-success", "game-dino-matrix"]),
        ("match-the-diet", "game-dino-diets", ["game-dino-diets-success", "game-dino-diets", "game-match-the-diet-success", "game-match-the-diet"]),
        ("smiling-dinos", "game-dino-smile", ["game-dino-smile-success", "game-smiling-dinos-success", "game-smiling-dinos"]),
    ]

    func testShippingLandGamesHavePickerAndSuccessArt() {
        let known = ImageAssetNames.knownAssets
        for entry in cardAndSuccess {
            XCTAssertTrue(known.contains(entry.picker), "Missing picker art for `\(entry.configId)`: \(entry.picker)")
            let hasSuccess = entry.successCandidates.contains { known.contains($0) }
            XCTAssertTrue(hasSuccess, "Missing victory art for `\(entry.configId)`. Tried: \(entry.successCandidates)")
        }
    }

    @MainActor
    func testCrowdCheeringResolvesForVictoryFinish() {
        let speech = SpeechManager()
        XCTAssertNotNil(speech.urlForAudio(key: "crowd-cheering"), "Victory finish expects crowd-cheering in bundle")
    }
}
