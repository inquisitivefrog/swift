//
//  MarineReptileSourceFilesXCTests.swift
//  DinoGamesTests
//

import XCTest

final class MarineReptileSourceFilesXCTests: XCTestCase {

    func testMarineReptileAndSilhouetteSourceFoldersExistAndContainFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let marineReptileJSON = root.appendingPathComponent("json/marine-reptiles")
        let marineSilhouetteJSON = root.appendingPathComponent("json/marine-silhouettes")
        let marineReptileImages = root.appendingPathComponent("images/marine-reptiles")
        let marineSilhouetteImages = root.appendingPathComponent("images/marine-silhouettes")

        XCTAssertTrue(TestBundleHelpers.directoryExists(marineReptileJSON), "Missing directory: \(marineReptileJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(marineSilhouetteJSON), "Missing directory: \(marineSilhouetteJSON.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(marineReptileImages), "Missing directory: \(marineReptileImages.path)")
        XCTAssertTrue(TestBundleHelpers.directoryExists(marineSilhouetteImages), "Missing directory: \(marineSilhouetteImages.path)")

        let marineReptileJSONFiles = try TestBundleHelpers.recursiveFiles(in: marineReptileJSON, allowedExtensions: ["json"])
        let marineSilhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: marineSilhouetteJSON, allowedExtensions: ["json"])
        let marineReptileImageFiles = try TestBundleHelpers.recursiveFiles(in: marineReptileImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let marineSilhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: marineSilhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        XCTAssertFalse(marineReptileJSONFiles.isEmpty, "Expected JSON files under \(marineReptileJSON.path)")
        XCTAssertFalse(marineSilhouetteJSONFiles.isEmpty, "Expected JSON files under \(marineSilhouetteJSON.path)")
        XCTAssertFalse(marineReptileImageFiles.isEmpty, "Expected image files under \(marineReptileImages.path)")
        XCTAssertFalse(marineSilhouetteImageFiles.isEmpty, "Expected image files under \(marineSilhouetteImages.path)")
    }

    func testMarineJSONSlugsHaveMatchingImageFiles() throws {
        let root = TestBundleHelpers.projectRootURL()
        let marineReptileJSON = root.appendingPathComponent("json/marine-reptiles")
        let marineSilhouetteJSON = root.appendingPathComponent("json/marine-silhouettes")
        let marineReptileImages = root.appendingPathComponent("images/marine-reptiles")
        let marineSilhouetteImages = root.appendingPathComponent("images/marine-silhouettes")

        let marineReptileJSONFiles = try TestBundleHelpers.recursiveFiles(in: marineReptileJSON, allowedExtensions: ["json"])
        let marineSilhouetteJSONFiles = try TestBundleHelpers.recursiveFiles(in: marineSilhouetteJSON, allowedExtensions: ["json"])
        let marineReptileImageFiles = try TestBundleHelpers.recursiveFiles(in: marineReptileImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])
        let marineSilhouetteImageFiles = try TestBundleHelpers.recursiveFiles(in: marineSilhouetteImages, allowedExtensions: ["png", "jpg", "jpeg", "webp"])

        let marineImageNames = Set(marineReptileImageFiles.map { $0.lastPathComponent.lowercased() })
        let silhouetteImageNames = Set(marineSilhouetteImageFiles.map { $0.lastPathComponent.lowercased() })

        let missingMarine = missingSlugs(
            in: marineReptileJSONFiles,
            expectedPrefix: "char_",
            matchInImageNames: marineImageNames,
            imagePrefix: nil
        )
        XCTAssertTrue(missingMarine.isEmpty, "Missing marine base images for JSON slugs: \(missingMarine.sorted())")

        let missingSilhouettes = missingMarineSilhouetteSlugs(jsonFiles: marineSilhouetteJSONFiles, imageNames: silhouetteImageNames)
        XCTAssertTrue(missingSilhouettes.isEmpty, "Missing marine silhouette images for JSON slugs: \(missingSilhouettes.sorted())")
    }

    private func missingMarineSilhouetteSlugs(jsonFiles: [URL], imageNames: Set<String>) -> [String] {
        var missing: [String] = []
        for file in jsonFiles {
            let stemRaw = file.deletingPathExtension().lastPathComponent
            let stem = stemRaw.lowercased()
            let slug: String
            if stem.hasPrefix("silh-") {
                slug = String(stem.dropFirst("silh-".count))
            } else if stem.hasPrefix("silh_") {
                slug = String(stem.dropFirst("silh_".count))
            } else {
                continue
            }
            if !TestBundleHelpers.marineSilhouetteJsonSlugHasMatchingSourceImage(slug: slug, imageBasenamesLowercased: imageNames) {
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
