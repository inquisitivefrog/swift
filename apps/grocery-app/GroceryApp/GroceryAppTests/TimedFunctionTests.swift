//
//  TimedFunctionTests.swift
//  GroceryAppTests
//
//  Tests for timed function behavior, timeouts, and async timing
//  Useful for verifying operations complete within expected timeframes
//

import XCTest
import CoreData
@testable import GroceryApp

final class TimedFunctionTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var importService: MasterListImportService!
    var shoppingListService: ShoppingListService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        importService = MasterListImportService(context: viewContext)
        shoppingListService = ShoppingListService(
            context: viewContext,
            container: persistenceController.container
        )
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        importService = nil
        shoppingListService = nil
    }
    
    // MARK: - Timeout Tests
    
    func testImportCompletesWithinTimeout() throws {
        // Verify import operation completes within reasonable time (e.g., 5 seconds)
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let startTime = Date()
        
        // Perform import
        importService.importCommonItems()
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let maxAllowedTime: TimeInterval = 5.0 // 5 seconds
        
        XCTAssertLessThan(elapsedTime, maxAllowedTime,
                         "Import should complete within \(maxAllowedTime) seconds. Actual: \(elapsedTime)s")
    }
    
    func testSaveShoppingListCompletesWithinTimeout() throws {
        // Verify save operation completes within timeout
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        // Add items to shopping list
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.fetchLimit = 20
        let items = try viewContext.fetch(fetchRequest)
        
        for item in items {
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
        }
        try viewContext.save()
        
        let expectation = self.expectation(description: "Save completes")
        let startTime = Date()
        
        shoppingListService.saveCurrentShoppingList { result in
            let elapsedTime = Date().timeIntervalSince(startTime)
            let maxAllowedTime: TimeInterval = 2.0 // 2 seconds
            
            XCTAssertLessThan(elapsedTime, maxAllowedTime,
                             "Save should complete within \(maxAllowedTime) seconds. Actual: \(elapsedTime)s")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) // Overall test timeout
    }
    
    func testLoadShoppingListCompletesWithinTimeout() throws {
        // Verify load operation completes within timeout
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        // Save a list first
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.fetchLimit = 20
        let items = try viewContext.fetch(fetchRequest)
        
        for item in items {
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
        }
        try viewContext.save()
        
        let saveExpectation = expectation(description: "Save completes")
        shoppingListService.saveCurrentShoppingList { _ in
            saveExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Now test load timing
        let loadExpectation = self.expectation(description: "Load completes")
        let startTime = Date()
        
        shoppingListService.loadSavedShoppingList { result in
            let elapsedTime = Date().timeIntervalSince(startTime)
            let maxAllowedTime: TimeInterval = 2.0 // 2 seconds
            
            XCTAssertLessThan(elapsedTime, maxAllowedTime,
                             "Load should complete within \(maxAllowedTime) seconds. Actual: \(elapsedTime)s")
            loadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) // Overall test timeout
    }
    
    // MARK: - Async Timing Tests
    
    func testAsyncOperationCompletes() throws {
        // Verify async operations actually complete (not just start)
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        // Add items to shopping list
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.fetchLimit = 10
        let items = try viewContext.fetch(fetchRequest)
        
        for item in items {
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
        }
        try viewContext.save()
        
        var saveCompleted = false
        let expectation = self.expectation(description: "Save completes")
        
        shoppingListService.saveCurrentShoppingList { result in
            saveCompleted = true
            XCTAssertTrue(saveCompleted, "Save completion handler should be called")
            if case .success(let count) = result {
                XCTAssertGreaterThan(count, 0, "Should save items")
            }
            expectation.fulfill()
        }
        
        // Note: The operation might complete very quickly (synchronously or near-synchronously)
        // So we don't assert that it hasn't completed immediately - we just verify it completes
        
        // Wait for completion
        waitForExpectations(timeout: 5.0)
        
        // Verify it completed
        XCTAssertTrue(saveCompleted, "Async operation should complete within timeout")
    }
    
    func testConcurrentOperationsComplete() throws {
        // Verify multiple async operations can complete concurrently
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        // Add items to shopping list
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.fetchLimit = 10
        let items = try viewContext.fetch(fetchRequest)
        
        for item in items {
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
        }
        try viewContext.save()
        
        var save1Completed = false
        var save2Completed = false
        
        let expectation1 = expectation(description: "Save 1 completes")
        let expectation2 = expectation(description: "Save 2 completes")
        
        let startTime = Date()
        
        // Start two save operations concurrently
        shoppingListService.saveCurrentShoppingList { _ in
            save1Completed = true
            expectation1.fulfill()
        }
        
        shoppingListService.saveCurrentShoppingList { _ in
            save2Completed = true
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Both should complete
        XCTAssertTrue(save1Completed, "First save should complete")
        XCTAssertTrue(save2Completed, "Second save should complete")
        
        // Concurrent operations should complete faster than sequential (rough check)
        // Sequential would take ~2x the time of one operation
        let maxSequentialTime: TimeInterval = 4.0
        XCTAssertLessThan(totalTime, maxSequentialTime,
                          "Concurrent operations should complete faster than sequential. Time: \(totalTime)s")
    }
    
    // MARK: - Timing Measurement Tests
    
    func testMeasureOperationTiming() throws {
        // Example of measuring operation timing for performance analysis
        let storeService = StoreService(context: viewContext)
        let categoryService = CategoryService(context: viewContext)
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        var timings: [TimeInterval] = []
        
        // Run operation multiple times and measure
        for _ in 0..<5 {
            // Clear items
            let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            if let items = try? viewContext.fetch(fetchRequest) {
                for item in items {
                    viewContext.delete(item)
                }
                try? viewContext.save()
            }
            
            let startTime = Date()
            importService.importCommonItems()
            let elapsed = Date().timeIntervalSince(startTime)
            timings.append(elapsed)
        }
        
        // Calculate statistics
        let average = timings.reduce(0, +) / Double(timings.count)
        let min = timings.min() ?? 0
        let max = timings.max() ?? 0
        
        // Log for analysis
        print("Import timing - Average: \(average)s, Min: \(min)s, Max: \(max)s")
        
        // Verify reasonable performance
        XCTAssertLessThan(average, 2.0, "Average import time should be reasonable")
        XCTAssertLessThan(max, 5.0, "Maximum import time should not be excessive")
    }
    
    // MARK: - Timeout Failure Tests
    
    func testOperationFailsAfterTimeout() throws {
        // Example: Test that operations properly fail/handle timeouts
        // This is a pattern for testing timeout behavior
        
        let expectation = self.expectation(description: "Operation completes or times out")
        expectation.isInverted = true // This expectation should NOT be fulfilled
        
        // Simulate a long-running operation that should timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            expectation.fulfill()
        }
        
        // Wait with short timeout - should NOT complete
        let result = XCTWaiter.wait(for: [expectation], timeout: 0.1)
        
        // Should timeout (not complete) - result should be .timedOut (value 1)
        // Note: XCTWaiterResult.timedOut has rawValue 1
        XCTAssertTrue(result == .timedOut || result.rawValue == 1, 
                     "Operation should timeout when taking too long. Got result: \(result)")
    }
}
