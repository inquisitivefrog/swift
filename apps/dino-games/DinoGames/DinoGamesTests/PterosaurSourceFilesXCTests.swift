//
//  PterosaurSourceFilesXCTests.swift
//  DinoGamesTests
//

import XCTest

final class PterosaurSourceFilesXCTests: XCTestCase {

    func testPterosaurAndSilhouetteSourceFoldersExistAndContainFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let pterosaurJSON = root.appendingPathComponent("json/pterosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/ptero-silhouettes")
        let pterosaurImages = root.appendingPathComponent("images/pterosaurs")
        let silhouetteImages = root.appendingPathComponent("images/ptero-silhouettes")

        XCTAssertTrue(TestBundleHelpers.directoryExists(pterosaurJSON), "Missing directory: \(pterosaurJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(silhouetteJSON), "Missing directory: \(silhouetteJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(pterosaurImages), "Missing directory: \(pterosaurImages.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(silhouetteImages), "Missing directory: \(silhouetteImages.path)")

        let pterosaurJSONFiles = try TestBundleHelpers.recursiveFiles(in: pterosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let pterosaurImageFiles = try TestBundleHelpers.recursiveFiles(in: pterosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        XCTAssertFalse(pterosaurJSONFiles.isEmpty, "Expected JSON files under \(pterosaurJSON.path)")
        XCTAssertFalse(silhouetteJSONFiles.isEmpty, "Expected JSON files under \(silhouetteJSON.path)")
        XCTAssertFalse(pterosaurImageFiles.isEmpty, "Expected image files under \(pterosaurImages.path)")
        XCTAssertFalse(silhouetteImageFiles.isEmpty, "Expected image files under \(silhouetteImages.path)")
    }

    func testPterosaurJSONSlugsHaveMatchingImageFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let pterosaurJSON = root.appendingPathComponent("json/pterosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/ptero-silhouettes")
        let pterosaurImages = root.appendingPathComponent("images/pterosaurs")
        let silhouetteImages = root.appendingPathComponent("images/ptero-silhouettes")

        let pterosaurJSONFiles = try TestBundleHelpers.recursiveFiles(in: pterosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let pterosaurImageFiles = try TestBundleHelpers.recursiveFiles(in: pterosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        let pterosaurImageNames = Set(pterosaurImageFiles.map { $0.lastPathComponent.lowercased() })
        let silhouetteImageNames = Set(silhouetteImageFiles.map { $0.lastPathComponent.lowercased() })

        let missingPterosaurs = missingSlugs(
            in: pterosaurJSONFiles,
            expectedPrefix: "char_",
            matchInImageNames: pterosaurImageNames,
            imagePrefix: nil
        )
        XCTAssertTrue(missingPterosaurs.isEmpty, "Missing pterosaur base images for JSON slugs: \(missingPterosaurs.sorted())")

        let missingSilhouettes = missingPterosaurSilhouetteSlugs(jsonFiles: silhouetteJSONFiles, imageNames: silhouetteImageNames)
        XCTAssertTrue(missingSilhouettes.isEmpty, "Missing pterosaur silhouette images for JSON slugs: \(missingSilhouettes.sorted())")
    }

    private func missingPterosaurSilhouetteSlugs(jsonFiles: [URL], imageNames: Set<String>) -> [String] {
        var missing: [String] = []
        for file in jsonFiles {
            let stem = file.deletingPathExtension().lastPathComponent.lowercased()
            guard stem.hasPrefix("silh-") else { continue }
            let slug = String(stem.dropFirst("silh-".count))
            if !TestBundleHelpers.pterosaurSilhouetteJsonSlugHasMatchingSourceImage(slug: slug, imageBasenamesLowercased: imageNames) {
                missing.append(slug)
            }
        }
        return missing
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
