//
//  TestBundleHelpers.swift
//  DinoGamesTests
//
//  Shared filesystem helpers for tests that read repo files (Audio, json, images).
//  Resolves project root as the parent of `DinoGamesTests/` (two levels up from any test file in that folder).
//

import Foundation

enum TestBundleHelpers {
    /// Audio extensions scanned under `DinoGames/Assets/Audio`.
    static let audioExtensions: Set<String> = ["m4a", "mp3", "wav"]

    /// Repository root: parent of `DinoGamesTests/`. `#filePath` is resolved at each call site.
    static func projectRootURL(_ file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(file)", isDirectory: false)
            .deletingLastPathComponent() // DinoGamesTests
            .deletingLastPathComponent() // DinoGames app repo root
    }

    /// URL under repo root, e.g. `"DinoGames/Assets/Audio/Games"`.
    static func urlUnderProjectRoot(_ relativePath: String, file: StaticString = #filePath) -> URL {
        var base = projectRootURL(file)
        for component in relativePath.split(separator: "/") where !component.isEmpty {
            base = base.appendingPathComponent(String(component))
        }
        return base
    }

    static func directoryExists(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    static func recursiveFiles(in root: URL, allowedExtensions: Set<String>) throws -> [URL] {
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

    /// Lowercased filename stems (no extension) for audio files under `directory`.
    static func audioStems(in directory: URL) throws -> Set<String> {
        let files = try recursiveFiles(in: directory, allowedExtensions: audioExtensions)
        return Set(files.map { $0.deletingPathExtension().lastPathComponent.lowercased() })
    }
}
