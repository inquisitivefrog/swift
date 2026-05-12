//
//  PterosaurAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurAudioFilesXCTests: XCTestCase {

    func testPterosaurAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Pterosaurs")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try TestBundleHelpers.recursiveFiles(in: directory, allowedExtensions: TestBundleHelpers.audioExtensions)
        XCTAssertFalse(audioFiles.isEmpty, "Expected pterosaur audio files under \(directory.path)")
    }

    func testPterosaurAudioExistsForAllPterosaurBaseAssets() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Pterosaurs")
        let availableStems = try TestBundleHelpers.audioStems(in: directory)

        // Creature-name coverage is derived from the in-app catalog so adding a pterosaur to the
        // pool automatically requires adding its spoken-name audio file.
        let expectedStems = Set(
            MatchingGameConfigs.allPterosaurs
                .compactMap { $0.imageName?.lowercased() }
        )
        XCTAssertFalse(expectedStems.isEmpty, "Expected pterosaur base asset keys to be present.")

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing pterosaur creature audio files: \(missing)")
    }

    func testPterosaurGameplayAudioExists() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        // Keep gameplay prompts explicit and static to catch accidental regressions in required
        // narration files.
        let expectedStems: Set<String> = [
            "game-name-that-pterosaur",
            "game-ptero-footprints",
            "game-weigh-pterosaur",
            "game-choose-your-first-pterosaur",
            "game-choose-your-second-pterosaur",
            "game-which-ptero-is-taller",
            "game-ptero-puzzle",
            "game-racing-pterosaurs",
        ]

        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing pterosaur gameplay audio files in Games/: \(missing)")
    }

    func testPterosaurCladeAudioFilesExist() throws {
        let directory = TestBundleHelpers.urlUnderProjectRoot("DinoGames/Assets/Audio/Pterosaur-Clades")
        XCTAssertTrue(TestBundleHelpers.directoryExists(directory), "Missing directory: \(directory.path)")

        let availableStems = try TestBundleHelpers.audioStems(in: directory)
        let expectedStems: Set<String> = [
            "clade-azhdarchid",
            "clade-basal",
            "clade-ornithocheiroid",
            "clade-specialist",
            "clade-tapejarid",
            "clade-thalassodromid",
            "clade-transition",
        ]
        let missing = expectedStems.subtracting(availableStems).sorted()
        XCTAssertTrue(missing.isEmpty, "Missing pterosaur clade audio under Pterosaur-Clades/: \(missing)")
    }
}
