//
//  PterosaurAudioFilesXCTests.swift
//  DinoGamesTests
//

import XCTest
@testable import DinoGames

final class PterosaurAudioFilesXCTests: XCTestCase {

    func testPterosaurAudioDirectoryExistsAndHasAudioFiles() throws {
        let directory = pterosaurAudioDirectoryURL()
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        XCTAssertFalse(audioFiles.isEmpty, "Expected pterosaur audio files under \(directory.path)")
    }

    func testPterosaurAudioExistsForAllPterosaurBaseAssets() throws {
        let directory = pterosaurAudioDirectoryURL()
        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })

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
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Games")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
        // Keep gameplay prompts explicit and static to catch accidental regressions in required
        // narration files.
        let expectedStems: Set<String> = [
            "game-name-that-pterosaur",
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
        let directory = projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Pterosaur-Clades")
        XCTAssertTrue(directoryExists(directory), "Missing directory: \(directory.path)")

        let audioFiles = try recursiveFiles(in: directory, allowedExtensions: ["m4a", "mp3", "wav"])
        let availableStems = Set(audioFiles.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
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

    private func pterosaurAudioDirectoryURL() -> URL {
        projectRootURL().appendingPathComponent("DinoGames/Assets/Audio/Pterosaurs")
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
