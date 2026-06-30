//
//  LandVictorySequenceUITests.swift
//  DinoGamesUITests
//
//  Navigation smoke tests for land games entry and Dino Puzzle launch.
//  Victory flow is covered by StandardVictorySequenceXCTests (unit tests).
//

import XCTest

final class LandVictorySequenceUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchAppForNavigationSmoke() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-uiTestSkipSplash", "-uiTestFastNavigation"]
        app.launchEnvironment = [
            "UITEST_ACTIVE": "1",
            "UITEST_SKIP_SPLASH": "1",
            "UITEST_FAST_NAVIGATION": "1",
        ]
        app.launch()
        return app
    }

    @MainActor
    func testSkipSplashReachesCategoryPicker() throws {
        let app = launchAppForNavigationSmoke()
        XCTAssertTrue(app.staticTexts["Choose A Game Type"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["category-dinosaurs"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testDinoPuzzleOpensFromLevel1GameList() throws {
        let app = launchAppForNavigationSmoke()

        let dinosaurs = app.buttons["category-dinosaurs"]
        XCTAssertTrue(dinosaurs.waitForExistence(timeout: 5))
        dinosaurs.tap()

        // `level-picker` is a ScrollView in the accessibility tree, not an Other.
        XCTAssertTrue(app.scrollViews["level-picker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Choose a level"].waitForExistence(timeout: 3))

        let levelOne = app.buttons["level-level1"]
        XCTAssertTrue(levelOne.waitForExistence(timeout: 3))
        levelOne.tap()

        let dinoPuzzle = app.buttons["game-dino-puzzle"]
        XCTAssertTrue(dinoPuzzle.waitForExistence(timeout: 5))
        dinoPuzzle.tap()

        XCTAssertTrue(app.staticTexts["Dino Puzzle"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Round 1 of 3"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["dino-puzzle-screen"].waitForExistence(timeout: 3))
    }
}
