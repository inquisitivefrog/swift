//
//  DinosaurAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinosaurAudioFilesXCTests: XCTestCase {

    func testDinosaurAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dinosaurs")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try TestBundleHelpers.recursiveFiles(in: directory, allowedExtensions: TestBundleHelpers.audioExtensions)
        XCTAssertFalse(audioFiles.isEmpty, "Expected dinosaur audio files under \(directory.path)")
    }

    func testDinosaurAudioExistsForAllDinosaurBaseAssets() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Dinosaurs")
        let availableStems = try TestBundleHelpers.audioStems(in: directory)

        // Creature-name coverage is derived from the in-app catalog so any newly added dinosaur
        // automatically requires a matching spoken-name file in Audio/Dinosaurs/.
        let expectedStems = Set(
            MatchingGameConfigs.allDinosaurs
                .compactMap { $0.imageName?.lowercased() }
        )
        XCTAssertFalse(expectedStems.isEmpty, "Expected dinosaur base asset keys to be present.")

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing dinosaur creature audio files: \(missing)")
    }

    func testDinosaurGameplayAudioExists() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        // Gameplay prompts stay a static contract: if game scripting changes, this list must be
        // updated intentionally so missing prompts fail loudly in CI.
        let expectedStems: Set<String> = [
            "game-can-you-name-that-dinosaur",
            "game-name-that-dinosaur",
            "game-weigh-dinosaur",
            "game-choose-your-first-dinosaur",
            "game-choose-your-second-dinosaur",
        ]

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing dinosaur gameplay audio files in Games/: \(missing)")
    }
}
