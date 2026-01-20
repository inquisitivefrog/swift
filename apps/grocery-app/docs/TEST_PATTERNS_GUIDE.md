# Test Patterns Guide

**For Engineers Who Learn by Example** - Copy, paste, and modify these patterns to create new tests.

## Table of Contents

1. [Unit Test Patterns](#unit-test-patterns)
2. [UI Test Patterns](#ui-test-patterns)
3. [Performance Test Patterns](#performance-test-patterns)
4. [Timed Function Test Patterns](#timed-function-test-patterns)
5. [Asset Verification Test Patterns](#asset-verification-test-patterns)
6. [Test Data Patterns](#test-data-patterns)

---

## Unit Test Patterns

### Basic Service Test Structure

```swift
import XCTest
import CoreData
@testable import GroceryApp

final class MyServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var myService: MyService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        myService = MyService(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        myService = nil
    }
    
    func testMyFunction_DoesSomething() throws {
        // Given - set up test data
        // When - call the function
        // Then - verify the result
    }
}
```

**See:** `CategoryServiceTests.swift`, `StoreServiceTests.swift`, `ShoppingListServiceTests.swift`

### Testing Core Data Operations

```swift
func testCreateEntity_PersistsToContext() throws {
    // Given
    let entity = MyEntity(context: viewContext)
    entity.id = UUID()
    entity.name = "Test"
    
    // When
    try viewContext.save()
    
    // Then
    let fetchRequest: NSFetchRequest<MyEntity> = MyEntity.fetchRequest()
    let results = try viewContext.fetch(fetchRequest)
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.name, "Test")
}
```

**See:** `CategoryServiceTests.swift` - `testCreateCategory_PersistsToContext()`

### Testing Duplicate Prevention

```swift
func testCreateEntity_DoesNotDuplicate() throws {
    // Given - existing entity
    let existing = MyEntity(context: viewContext)
    existing.name = "Test"
    try viewContext.save()
    
    // When - try to create duplicate
    myService.createEntity(name: "Test")
    
    // Then - should not create duplicate
    let fetchRequest: NSFetchRequest<MyEntity> = MyEntity.fetchRequest()
    let results = try viewContext.fetch(fetchRequest)
    let testEntities = results.filter { $0.name == "Test" }
    XCTAssertEqual(testEntities.count, 1)
}
```

**See:** `CategoryServiceTests.swift` - `testCreateDefaultCategories_DoesNotDuplicateExistingCategories()`

### Testing Error Cases

```swift
func testDeleteEntity_ThrowsErrorWhenInvalid() throws {
    // Given
    let entity = MyEntity(context: viewContext)
    entity.name = "Test"
    // Set up invalid state
    
    // When/Then
    XCTAssertThrowsError(try myService.deleteEntity(entity)) { error in
        XCTAssertEqual(error as? MyServiceError, .invalidState)
    }
}
```

**See:** `CategoryServiceTests.swift` - `testDeleteCategory_ThrowsErrorWhenCategoryHasItems()`

---

## UI Test Patterns

### Basic UI Test Structure

```swift
import XCTest

final class MyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testMyFeature() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate past landing page if needed
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Your test steps here
    }
}
```

**See:** `GroceryAppUITests.swift`

### Testing Navigation

```swift
@MainActor
func testNavigationToView() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate
    app.buttons["Get Started"].tap()
    app.tabBars.buttons["My Tab"].tap()
    
    // Verify navigation
    let navBar = app.navigationBars["My View"]
    XCTAssertTrue(navBar.waitForExistence(timeout: 5))
}
```

**See:** `GroceryAppUITests.swift` - `testGetStartedButtonNavigatesToMainView()`

### Testing Button Existence

```swift
@MainActor
func testButtonExists() throws {
    let app = XCUIApplication()
    app.launch()
    app.buttons["Get Started"].tap()
    
    let button = app.buttons["My Button"]
    XCTAssertTrue(button.waitForExistence(timeout: 5))
}
```

**See:** `GroceryAppUITests.swift` - `testSettingsButtonExists()`

### Testing Empty States

```swift
@MainActor
func testEmptyStateAppears() throws {
    let app = XCUIApplication()
    app.launch()
    app.buttons["Get Started"].tap()
    
    // Clear data or navigate to empty state
    let emptyStateText = app.staticTexts["No items"]
    XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5))
}
```

**See:** `GroceryAppUITests.swift` - `testShopByStoresEmptyStateMessage()`

---

## Performance Test Patterns

### Measuring Operation Time

```swift
func testOperationPerformance() throws {
    // Set up test data
    setupTestData()
    
    measure {
        // Operation to measure
        myService.performOperation()
    }
}
```

**See:** `PerformanceTests.swift` - `testImportPerformance()`

### Memory Usage Testing

```swift
func testOperationMemoryUsage() throws {
    // Get baseline memory
    let baselineMemory = getMemoryUsage()
    
    // Perform operation
    myService.performOperation()
    viewContext.reset() // Clear cache
    
    // Get memory after operation
    let afterMemory = getMemoryUsage()
    let increase = afterMemory - baselineMemory
    
    // Verify reasonable memory increase
    let maxIncrease: Int64 = 50 * 1024 * 1024 // 50MB
    XCTAssertLessThan(increase, maxIncrease)
}

private func getMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
}
```

**See:** `PerformanceTests.swift` - `testImportMemoryUsage()`

---

## Timed Function Test Patterns

### Testing Operation Completes Within Timeout

```swift
func testOperationCompletesWithinTimeout() throws {
    let startTime = Date()
    
    // Perform operation
    myService.performOperation()
    
    let elapsedTime = Date().timeIntervalSince(startTime)
    let maxAllowedTime: TimeInterval = 5.0
    
    XCTAssertLessThan(elapsedTime, maxAllowedTime,
                     "Operation should complete within \(maxAllowedTime) seconds")
}
```

**See:** `TimedFunctionTests.swift` - `testImportCompletesWithinTimeout()`

### Testing Async Operations Complete

```swift
func testAsyncOperationCompletes() throws {
    var operationCompleted = false
    let expectation = self.expectation(description: "Operation completes")
    
    myService.performAsyncOperation { result in
        operationCompleted = true
        expectation.fulfill()
    }
    
    // Verify not completed immediately
    XCTAssertFalse(operationCompleted)
    
    // Wait for completion
    waitForExpectations(timeout: 5.0)
    
    // Verify it completed
    XCTAssertTrue(operationCompleted)
}
```

**See:** `TimedFunctionTests.swift` - `testAsyncOperationCompletes()`

### Testing Async Operation Timing

```swift
func testAsyncOperationTiming() throws {
    let expectation = self.expectation(description: "Operation completes")
    let startTime = Date()
    
    myService.performAsyncOperation { result in
        let elapsedTime = Date().timeIntervalSince(startTime)
        let maxAllowedTime: TimeInterval = 2.0
        
        XCTAssertLessThan(elapsedTime, maxAllowedTime,
                         "Operation should complete within timeout")
        expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3.0)
}
```

**See:** `TimedFunctionTests.swift` - `testSaveShoppingListCompletesWithinTimeout()`

### Testing Concurrent Operations

```swift
func testConcurrentOperations() throws {
    var op1Completed = false
    var op2Completed = false
    
    let expectation1 = expectation(description: "Operation 1")
    let expectation2 = expectation(description: "Operation 2")
    let startTime = Date()
    
    // Start concurrent operations
    myService.performAsyncOperation { _ in
        op1Completed = true
        expectation1.fulfill()
    }
    
    myService.performAsyncOperation { _ in
        op2Completed = true
        expectation2.fulfill()
    }
    
    waitForExpectations(timeout: 5.0)
    
    let totalTime = Date().timeIntervalSince(startTime)
    
    XCTAssertTrue(op1Completed)
    XCTAssertTrue(op2Completed)
    XCTAssertLessThan(totalTime, 4.0) // Should be faster than sequential
}
```

**See:** `TimedFunctionTests.swift` - `testConcurrentOperationsComplete()`

### Testing Timeout Behavior

```swift
func testOperationTimesOut() throws {
    let expectation = self.expectation(description: "Should not complete")
    expectation.isInverted = true // Expectation should NOT be fulfilled
    
    // Simulate long operation
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
        expectation.fulfill()
    }
    
    // Wait with short timeout
    let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
    
    // Should timeout
    XCTAssertEqual(result, .timedOut)
}
```

**See:** `TimedFunctionTests.swift` - `testOperationFailsAfterTimeout()`

---

## Asset Verification Test Patterns

### Testing File Existence

```swift
func testAssetExists() throws {
    let testFile = URL(fileURLWithPath: #file)
    let assetPath = testFile
        .deletingLastPathComponent() // Remove test file
        .deletingLastPathComponent() // Remove test directory
        .deletingLastPathComponent() // Remove GroceryApp directory
        .appendingPathComponent("GroceryApp")
        .appendingPathComponent("GroceryApp")
        .appendingPathComponent("Assets.xcassets")
        .appendingPathComponent("MyAsset.imageset")
        .appendingPathComponent("MyAsset.png")
    
    let fileExists = FileManager.default.fileExists(atPath: assetPath.path)
    XCTAssertTrue(fileExists, "Asset must exist at: \(assetPath.path)")
}
```

**See:** `AssetVerificationTests.swift` - `testAppIconExists()`

### Testing Image Dimensions

```swift
func testImageDimensions() throws {
    let imagePath = getAssetPath()
    guard let imageData = NSData(contentsOf: imagePath),
          let imageSource = CGImageSourceCreateWithData(imageData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
          let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
          let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
        XCTFail("Could not read image properties")
        return
    }
    
    XCTAssertEqual(width, 1024, "Width must be 1024 pixels")
    XCTAssertEqual(height, 1024, "Height must be 1024 pixels")
}
```

**See:** `AssetVerificationTests.swift` - `testAppIconMeetsSizeRequirements()`

### Testing File Format

```swift
func testFileFormat() throws {
    let filePath = getAssetPath()
    let data = try Data(contentsOf: filePath)
    
    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    let fileSignature = Array(data.prefix(8))
    
    XCTAssertEqual(fileSignature, pngSignature, "File must be valid PNG")
}
```

**See:** `AssetVerificationTests.swift` - `testAppIconIsPNGFormat()`

---

## Test Data Patterns

### Using TestDataGenerator

```swift
var testData: TestDataGenerator!

override func setUpWithError() throws {
    persistenceController = PersistenceController.test
    viewContext = persistenceController.container.viewContext
    testData = TestDataGenerator(context: viewContext)
}

func testMyFeature() throws {
    // Create complete scenario
    let scenario = testData.createShoppingListScenario()
    // scenario.stores, scenario.categories, scenario.items, scenario.shoppingItems
    
    // Or create individual items
    let store = testData.createStore(name: "My Store")
    let category = testData.createCategory(name: "My Category")
    let item = testData.createGroceryItem(name: "My Item", category: category, store: store)
    
    try viewContext.save()
    
    // Your test logic here
}
```

**See:** `TestDataGenerator.swift`, `TEST_DATA_GUIDE.md`

### Creating Test Scenarios

```swift
// Complete shopping scenario
let scenario = testData.createShoppingListScenario()

// Store-based scenario (for Shop By Stores testing)
let storeScenario = testData.createStoreBasedShoppingScenario()

// Completed shopping scenario (all items checked)
let completedScenario = testData.createCompletedShoppingListScenario()
```

**See:** `TestDataGenerator.swift` for all available scenarios

---

## Quick Reference

### Common Assertions

```swift
// Equality
XCTAssertEqual(actual, expected)
XCTAssertNotEqual(actual, expected)

// Truthiness
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Nil checks
XCTAssertNil(value)
XCTAssertNotNil(value)

// Comparisons
XCTAssertGreaterThan(value, threshold)
XCTAssertLessThan(value, threshold)
XCTAssertGreaterThanOrEqual(value, threshold)
XCTAssertLessThanOrEqual(value, threshold)

// Collections
XCTAssertEqual(array.count, expectedCount)
XCTAssertTrue(array.contains { $0.property == value })

// Errors
XCTAssertThrowsError(try operation())
XCTAssertNoThrow(try operation())
```

### Async Testing

```swift
// Basic async test
let expectation = self.expectation(description: "Operation completes")
asyncOperation { result in
    // Verify result
    expectation.fulfill()
}
waitForExpectations(timeout: 5.0)

// Multiple expectations
let exp1 = expectation(description: "Op 1")
let exp2 = expectation(description: "Op 2")
// ... start operations
waitForExpectations(timeout: 5.0)
```

### Performance Testing

```swift
// Measure execution time
measure {
    operation()
}

// Custom timing
let start = Date()
operation()
let elapsed = Date().timeIntervalSince(start)
XCTAssertLessThan(elapsed, maxTime)
```

---

## Test File Organization

```
GroceryAppTests/
├── AssetVerificationTests.swift    # Asset file tests
├── CategoryServiceTests.swift      # Category service tests
├── DataServiceTests.swift          # Data service tests
├── GroceryAppTests.swift           # App-level tests
├── MasterListImportServiceTests.swift  # Import service tests
├── PerformanceTests.swift          # CPU and memory tests
├── ShoppingListServiceTests.swift  # Shopping list tests
├── StoreServiceTests.swift         # Store service tests
├── TestDataGenerator.swift         # Shared test data
├── TestHelpers.swift               # Core Data test helpers
└── TimedFunctionTests.swift        # Timeout and timing tests
```

---

## Best Practices

1. **Always clean up in tearDown()** - Reset state between tests
2. **Use descriptive test names** - `testFunctionName_ExpectedBehavior()`
3. **Follow Given-When-Then** - Set up, execute, verify
4. **Test edge cases** - Empty data, nil values, boundaries
5. **Use TestDataGenerator** - Don't create test data from scratch
6. **Measure performance** - Use `measure {}` for operations that matter
7. **Test timeouts** - Verify async operations complete in reasonable time
8. **Verify memory** - Check for leaks in long-running operations

---

## Copy-Paste Templates

### New Unit Test File

```swift
import XCTest
import CoreData
@testable import GroceryApp

final class MyServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var myService: MyService!
    var testData: TestDataGenerator!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        myService = MyService(context: viewContext)
        testData = TestDataGenerator(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        testData.clearAll()
        persistenceController = nil
        viewContext = nil
        myService = nil
        testData = nil
    }
    
    func testMyFunction_DoesSomething() throws {
        // Given
        let scenario = testData.createShoppingListScenario()
        
        // When
        let result = myService.myFunction()
        
        // Then
        XCTAssertNotNil(result)
    }
}
```

### New UI Test

```swift
import XCTest

final class MyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testMyFeature() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate past landing if needed
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Your test steps
        let button = app.buttons["My Button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        
        // Verify result
        let result = app.staticTexts["Expected Result"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
    }
}
```

---

**Remember:** "Nobody Ever Died Drowning In Sweat" - More tests are better than fewer. Copy, paste, modify, and test!
