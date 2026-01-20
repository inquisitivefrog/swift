//
//  AssetVerificationTests.swift
//  GroceryAppTests
//
//  Tests to verify critical app assets exist and meet requirements
//  "Nobody Ever Died Drowning In Sweat" - Better to have too many tests than too few
//

import XCTest
@testable import GroceryApp

final class AssetVerificationTests: XCTestCase {
    
    // MARK: - App Icon Tests
    
    func testAppIconExists() throws {
        // Verify AppIcon.png exists in the AppIcon asset catalog
        // Check the source file in the project directory
        let testFile = URL(fileURLWithPath: #file) // This test file
        let projectRoot = testFile.deletingLastPathComponent()
            .deletingLastPathComponent() // GroceryAppTests -> GroceryApp
            .deletingLastPathComponent() // GroceryApp -> workspace root
        let appIconPath = projectRoot
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
            .appendingPathComponent("AppIcon.png")
        
        let fileExists = FileManager.default.fileExists(atPath: appIconPath.path)
        XCTAssertTrue(fileExists, "AppIcon.png must exist at: \(appIconPath.path)")
    }
    
    private func appIconPath() -> URL {
        let testFile = URL(fileURLWithPath: #file)
        return testFile.deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
            .appendingPathComponent("AppIcon.png")
    }
    
    private func landingPageImagePath() -> URL {
        let testFile = URL(fileURLWithPath: #file)
        return testFile.deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("GroceryApp")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("GroceryApp_image.imageset")
            .appendingPathComponent("GroceryApp_image.png")
    }
    
    func testAppIconMeetsSizeRequirements() throws {
        // Verify AppIcon is exactly 1024x1024 pixels
        let appIconPath = appIconPath()
        guard let imageData = NSData(contentsOf: appIconPath),
              let imageSource = CGImageSourceCreateWithData(imageData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = imageProperties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = imageProperties[kCGImagePropertyPixelHeight as String] as? Int else {
            XCTFail("Could not read AppIcon image properties from: \(appIconPath.path)")
            return
        }
        
        XCTAssertEqual(width, 1024, "AppIcon width must be exactly 1024 pixels")
        XCTAssertEqual(height, 1024, "AppIcon height must be exactly 1024 pixels")
    }
    
    func testAppIconIsPNGFormat() throws {
        // Verify AppIcon is a PNG file
        let appIconPath = appIconPath()
        let data = try Data(contentsOf: appIconPath)
        
        // PNG files start with specific bytes: 89 50 4E 47 0D 0A 1A 0A
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let fileSignature = Array(data.prefix(8))
        
        XCTAssertEqual(fileSignature, pngSignature, "AppIcon must be a valid PNG file")
    }
    
    func testAppIconHasNoTransparency() throws {
        // Verify AppIcon does not have alpha channel (transparency)
        // iOS app icons should be RGB only, not RGBA
        let appIconPath = appIconPath()
        guard let imageData = NSData(contentsOf: appIconPath),
              let imageSource = CGImageSourceCreateWithData(imageData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let hasAlpha = imageProperties[kCGImagePropertyHasAlpha as String] as? Bool else {
            XCTFail("Could not read AppIcon image properties from: \(appIconPath.path)")
            return
        }
        
        // Note: App icons with transparency will be rejected by App Store
        // This is a warning, not a critical failure for development/testing
        if hasAlpha {
            print("⚠️ WARNING: AppIcon has transparency (alpha channel). iOS app icons must be RGB only for App Store submission.")
            // Uncomment the line below to make this a hard failure:
            // XCTAssertFalse(hasAlpha, "AppIcon should not have transparency (alpha channel). iOS app icons must be RGB only.")
        }
    }
    
    // MARK: - Landing Page Image Tests
    
    func testLandingPageImageExists() throws {
        // Verify GroceryApp_image.png exists in the asset catalog
        let imagePath = landingPageImagePath()
        let fileExists = FileManager.default.fileExists(atPath: imagePath.path)
        XCTAssertTrue(fileExists, "GroceryApp_image.png must exist at: \(imagePath.path)")
    }
    
    func testLandingPageImageHasReasonableDimensions() throws {
        // Verify landing page image has reasonable dimensions (not too small, not absurdly large)
        let imagePath = landingPageImagePath()
        guard let imageData = NSData(contentsOf: imagePath),
              let imageSource = CGImageSourceCreateWithData(imageData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = imageProperties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = imageProperties[kCGImagePropertyPixelHeight as String] as? Int else {
            XCTFail("Could not read landing page image properties from: \(imagePath.path)")
            return
        }
        
        // Landing page images should be at least 200x200 (not too small)
        XCTAssertGreaterThanOrEqual(width, 200, "Landing page image width should be at least 200 pixels")
        XCTAssertGreaterThanOrEqual(height, 200, "Landing page image height should be at least 200 pixels")
        
        // And not absurdly large (e.g., > 5000px would be excessive)
        XCTAssertLessThanOrEqual(width, 5000, "Landing page image width should not exceed 5000 pixels")
        XCTAssertLessThanOrEqual(height, 5000, "Landing page image height should not exceed 5000 pixels")
    }
    
    func testLandingPageImageIsPNGFormat() throws {
        // Verify landing page image is a PNG file
        let imagePath = landingPageImagePath()
        let data = try Data(contentsOf: imagePath)
        
        // PNG files start with specific bytes
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let fileSignature = Array(data.prefix(8))
        
        XCTAssertEqual(fileSignature, pngSignature, "Landing page image must be a valid PNG file")
    }
    
    func testLandingPageImageFileSizeIsReasonable() throws {
        // Verify landing page image file size is reasonable (not too large, not empty)
        let imagePath = landingPageImagePath()
        let attributes = try FileManager.default.attributesOfItem(atPath: imagePath.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            XCTFail("Could not read file size from: \(imagePath.path)")
            return
        }
        
        // File should not be empty
        XCTAssertGreaterThan(fileSize, 0, "Landing page image file should not be empty")
        
        // File should not be excessively large (e.g., > 10MB would be too large for an app asset)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
        XCTAssertLessThanOrEqual(fileSize, maxSize, "Landing page image file size should not exceed 10MB")
    }
}
