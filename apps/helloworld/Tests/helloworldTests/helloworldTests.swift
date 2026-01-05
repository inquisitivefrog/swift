import XCTest
@testable import helloworld

/// Test suite for the Hello World application.
///
/// This test suite verifies that the core functionality of the application
/// works correctly, including the greeting function.
final class helloworldTests: XCTestCase {
    
    /// Tests that the getGreeting() function returns the expected message.
    ///
    /// This test verifies:
    /// - The function returns a non-empty string
    /// - The returned string matches "Hello, World!" exactly
    func testGetGreeting() throws {
        // Test that getGreeting returns the expected message
        let greeting = getGreeting()
        XCTAssertEqual(greeting, "Hello, World!", "Greeting should be 'Hello, World!'")
    }
}

