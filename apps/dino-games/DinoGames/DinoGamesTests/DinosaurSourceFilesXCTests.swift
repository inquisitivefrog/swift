//
//  DinosaurSourceFilesXCTests.swift
//  DinoGamesTests
//

import XCTest

final class DinosaurSourceFilesXCTests: XCTestCase {

    func testDinosaurAndSilhouetteSourceFoldersExistAndContainFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let dinosaurJSON = root.appendingPathComponent("json/dinosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/dino-silhouettes")
        let dinosaurImages = root.appendingPathComponent("images/dinosaurs")
        let silhouetteImages = root.appendingPathComponent("images/dino-silhouettes")

        XCTAssertTrue(TestBundleHelpers.directoryExists(dinosaurJSON), "Missing directory: \(dinosaurJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(silhouetteJSON), "Missing directory: \(silhouetteJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(dinosaurImages), "Missing directory: \(dinosaurImages.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(silhouetteImages), "Missing directory: \(silhouetteImages.path)")

        let dinosaurJSONFiles = try TestBundleHelpers.recursiveFiles(in: dinosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let dinosaurImageFiles = try TestBundleHelpers.recursiveFiles(in: dinosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        XCTAssertFalse(dinosaurJSONFiles.isEmpty, "Expected JSON files under \(dinosaurJSON.path)")
        XCTAssertFalse(silhouetteJSONFiles.isEmpty, "Expected JSON files under \(silhouetteJSON.path)")
        XCTAssertFalse(dinosaurImageFiles.isEmpty, "Expected image files under \(dinosaurImages.path)")
        XCTAssertFalse(silhouetteImageFiles.isEmpty, "Expected image files under \(silhouetteImages.path)")
    }

    func testDinosaurJSONSlugsHaveMatchingImageFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let dinosaurJSON = root.appendingPathComponent("json/dinosaurs")
        let silhouetteJSON = root.appendingPathComponent("json/dino-silhouettes")
        let dinosaurImages = root.appendingPathComponent("images/dinosaurs")
        let silhouetteImages = root.appendingPathComponent("images/dino-silhouettes")

        let dinosaurJSONFiles = try TestBundleHelpers.recursiveFiles(in: dinosaurJSON, allowedExtensions: ["json"])
        let silhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteJSON, allowedExtensions: ["json"])
        let dinosaurImageFiles = try TestBundleHelpers.recursiveFiles(in: dinosaurImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let silhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: silhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

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
