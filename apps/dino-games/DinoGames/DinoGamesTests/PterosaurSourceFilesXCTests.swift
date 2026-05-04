//
//  PterosaurSourceFilesXCTests.swift
//  DinoGamesTests
//

import XCTest

final class PterosaurSourceFilesXCTests: XCTestCase {

    func testPterosaurAndSilhouetteSourceFoldersExistAndContainFiles() throws {
        let root = projectRootURL()
        let pterosaurJSON = root.appendingPathComponent("json/pterosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/ptero-silhouettes")
        let pterosaurImages = root.appendingPathComponent("images/pterosaurs")
        let silhouetteImages = root.appendingPathComponent("images/ptero-silhouettes")

        XCTAssertTrue(directoryExists(pterosaurJSON), "Missing directory: \(pterosaurJSON.path)")
        XCTAssertTrue(directoryExists(silhouetteJSON), "Missing directory: \(silhouetteJSON.path)")
        XCTAssertTrue(directoryExists(pterosaurImages), "Missing directory: \(pterosaurImages.path)")
        XCTAssertTrue(directoryExists(silhouetteImages), "Missing directory: \(silhouetteImages.path)")

        let pterosaurJSONFiles = try recursiveFiles(in: pterosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let pterosaurImageFiles = try recursiveFiles(in: pterosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        XCTAssertFalse(pterosaurJSONFiles.isEmpty, "Expected JSON files under \(pterosaurJSON.path)")
        XCTAssertFalse(silhouetteJSONFiles.isEmpty, "Expected JSON files under \(silhouetteJSON.path)")
        XCTAssertFalse(pterosaurImageFiles.isEmpty, "Expected image files under \(pterosaurImages.path)")
        XCTAssertFalse(silhouetteImageFiles.isEmpty, "Expected image files under \(silhouetteImages.path)")
    }

    func testPterosaurJSONSlugsHaveMatchingImageFiles() throws {
        let root = projectRootURL()
        let pterosaurJSON = root.appendingPathComponent("json/pterosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/ptero-silhouettes")
        let pterosaurImages = root.appendingPathComponent("images/pterosaurs")
        let silhouetteImages = root.appendingPathComponent("images/ptero-silhouettes")

        let pterosaurJSONFiles = try recursiveFiles(in: pterosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let pterosaurImageFiles = try recursiveFiles(in: pterosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        let pterosaurImageNames = Set(pterosaurImageFiles.map { $0.lastPathComponent.lowercased() })
        let silhouetteImageNames = Set(silhouetteImageFiles.map { $0.lastPathComponent.lowercased() })

        let missingPterosaurs = missingSlugs(
            in: pterosaurJSONFiles,
            expectedPrefix: "char_",
            matchInImageNames: pterosaurImageNames,
            imagePrefix: nil
        )
        XCTAssertTrue(missingPterosaurs.isEmpty, "Missing pterosaur base images for JSON slugs: \(missingPterosaurs.sorted())")

        let missingSilhouettes = missingSlugs(
            in: silhouetteJSONFiles,
            expectedPrefix: "silh-",
            matchInImageNames: silhouetteImageNames,
            imagePrefix: "silh-"
        )
        XCTAssertTrue(missingSilhouettes.isEmpty, "Missing pterosaur silhouette images for JSON slugs: \(missingSilhouettes.sorted())")
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
