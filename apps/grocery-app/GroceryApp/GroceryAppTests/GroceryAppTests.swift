//
//  GroceryAppTests.swift
//  GroceryAppTests
//
//  Main test suite - all service tests are in separate files
//

import XCTest
@testable import GroceryApp

final class GroceryAppTests: XCTestCase {
    
    func testAppLaunches() throws {
        // Basic smoke test - verify the app can be imported and basic types exist
        XCTAssertNotNil(StoreService.self)
        XCTAssertNotNil(CategoryService.self)
        XCTAssertNotNil(MasterListImportService.self)
        XCTAssertNotNil(DataService.self)
    }
}
