//
//  GroceryAppUITestsLaunchTests.swift
//  GroceryAppUITests
//
//  Created by Timothy Stilwell on 1/6/26.
//

import XCTest

final class GroceryAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for landing page to appear
        let landingPageTitle = app.staticTexts["GroceryApp"]
        XCTAssertTrue(landingPageTitle.waitForExistence(timeout: 5), "Landing page should appear on launch")

        // Take screenshot of landing page
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen (Landing Page)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Navigate to main view for additional screenshots
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
            
            // Wait for main view
            let buildMyListTab = app.tabBars.buttons["Build My List"]
            if buildMyListTab.waitForExistence(timeout: 5) {
                let mainViewAttachment = XCTAttachment(screenshot: app.screenshot())
                mainViewAttachment.name = "Main View (Build My List)"
                mainViewAttachment.lifetime = .keepAlways
                add(mainViewAttachment)
            }
        }
    }
}
