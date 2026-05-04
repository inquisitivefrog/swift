//
//  DinosaurSourceFilesXCTests.swift
//  DinoGamesTests
//

import XCTest

final class DinosaurSourceFilesXCTests: XCTestCase {

    func testDinosaurAndSilhouetteSourceFoldersExistAndContainFiles() throws {
        let root = projectRootURL()
        let dinosaurJSON = root.appendingPathComponent("json/dinosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/dino-silhouettes")
        let dinosaurImages = root.appendingPathComponent("images/dinosaurs")
        let silhouetteImages = root.appendingPathComponent("images/dino-silhouettes")

        XCTAssertTrue(directoryExists(dinosaurJSON), "Missing directory: \(dinosaurJSON.path)")
        XCTAssertTrue(directoryExists(silhouetteJSON), "Missing directory: \(silhouetteJSON.path)")
        XCTAssertTrue(directoryExists(dinosaurImages), "Missing directory: \(dinosaurImages.path)")
        XCTAssertTrue(directoryExists(silhouetteImages), "Missing directory: \(silhouetteImages.path)")

        let dinosaurJSONFiles = try recursiveFiles(in: dinosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let dinosaurImageFiles = try recursiveFiles(in: dinosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        XCTAssertFalse(dinosaurJSONFiles.isEmpty, "Expected JSON files under \(dinosaurJSON.path)")
        XCTAssertFalse(silhouetteJSONFiles.isEmpty, "Expected JSON files under \(silhouetteJSON.path)")
        XCTAssertFalse(dinosaurImageFiles.isEmpty, "Expected image files under \(dinosaurImages.path)")
        XCTAssertFalse(silhouetteImageFiles.isEmpty, "Expected image files under \(silhouetteImages.path)")
    }

    func testDinosaurJSONSlugsHaveMatchingImageFiles() throws {
        let root = projectRootURL()
        let dinosaurJSON = root.appendingPathComponent("json/dinosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/dino-silhouettes")
        let dinosaurImages = root.appendingPathComponent("images/dinosaurs")
        let silhouetteImages = root.appendingPathComponent("images/dino-silhouettes")

        let dinosaurJSONFiles = try recursiveFiles(in: dinosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let dinosaurImageFiles = try recursiveFiles(in: dinosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        let dinosaurImageNames = Set(dinosaurImageFiles.map { $0.lastPathComponent.lowercased() })
        let silhouetteImageNames = Set(silhouetteImageFiles.map { $0.lastPathComponent.lowercased() })

        let missingDinos = missingSlugs(
            in: dinosaurJSONFiles,
            expectedPrefix: "char_",
            matchInImageNames: dinosaurImageNames,
            imagePrefix: nil
        )
        XCTAssertTrue(missingDinos.isEmpty, "Missing dinosaur base images for JSON slugs: \(missingDinos.sorted())")

        let missingSilhouettes = missingSlugs(
            in: silhouetteJSONFiles,
            expectedPrefix: "silh-",
            matchInImageNames: silhouetteImageNames,
            imagePrefix: "silh-"
        )
        XCTAssertTrue(missingSilhouettes.isEmpty, "Missing dinosaur silhouette images for JSON slugs: \(missingSilhouettes.sorted())")
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

    private func missingSlugs(
        in jsonFiles: [URL],
        expectedPrefix: String,
        matchInImageNames imageNames: Set<String>,
        imagePrefix: String?
    ) -> [String] {
        var missing: [String] = []

        for file in jsonFiles {
            let stem = file.deletingPathExtension().lastPathComponent
            guard stem.hasPrefix(expectedPrefix) else { continue }

            let slug = String(stem.dropFirst(expectedPrefix.count))
            let target = imagePrefix.map { "\($0)\(slug)-" } ?? "-\(slug)-"

            let hasMatch = imageNames.contains { $0.contains(target) }
            if !hasMatch {
                missing.append(slug)
            }
        }

        return missing
    }
}
