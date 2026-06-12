//
//  LandVictorySequenceUITests.swift
//  DinoGamesUITests
//
//  Navigation smoke test for land games entry. Victory flow is covered by
//  StandardVictorySequenceXCTests (same unit-test style as air/sea catalogs).
//

import XCTest

final class LandVictorySequenceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSkipSplashReachesCategoryPicker() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-uiTestSkipSplash"]
        app.launchEnvironment = [
            "UITEST_ACTIVE": "1",
            "UITEST_SKIP_SPLASH": "1",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Choose A Game Type"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["category-dinosaurs"].waitForExistence(timeout: 3))
    }
}
