//
//  DinosaurAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class DinosaurAudioFilesXCTests: XCTestCase {

    func testDinosaurAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = dinosaurAudioDirectoryURL()
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        XCTAssertFalse(audioFiles.isEmpty, "Expected dinosaur audio files under \(directory.path)")
    }

    func testDinosaurAudioExistsForAllDinosaurBaseAssets() throws {
        let directory = dinosaurAudioDirectoryURL()
        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })

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
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
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

    private func dinosaurAudioDirectoryURL() -> URL {
        projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Dinosaurs")
    }

    private func projectRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func recursiveFiles(in root: URL, allowedExtensions: Set<String>) throws -> [URL] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys)
        var output: [URL] = []
        while let item = enumerator?.nextObject() as? URL {
            let values = try item.resourceValues(forKeys: Set(keys))
            guard values.isRegularFile == true else { continue }
            if allowedExtensions.contains(item.pathExtension.lowercased()) {
                output.append(item)
            }
        }
        return output
    }
}
