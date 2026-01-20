//
//  PerformanceTests.swift
//  GroceryAppTests
//
//  Performance tests for CPU and memory usage
//

import XCTest
import CoreData
import Darwin.Mach
@testable import GroceryApp

final class PerformanceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var importService: MasterListImportService!
    var storeService: StoreService!
    var categoryService: CategoryService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        storeService = StoreService(context: viewContext)
        categoryService = CategoryService(context: viewContext)
        importService = MasterListImportService(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        importService = nil
        storeService = nil
        categoryService = nil
    }
    
    // MARK: - CPU Performance Tests
    
    func testImportPerformance() throws {
        // Measure time to import all common items
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        measure {
            // Clear existing items first
            let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            if let items = try? viewContext.fetch(fetchRequest) {
                for item in items {
                    viewContext.delete(item)
                }
                try? viewContext.save()
            }
            
            // Import items
            importService.importCommonItems()
        }
    }
    
    func testShoppingListSaveLoadPerformance() throws {
        // Measure time to save and load shopping list
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        // Create shopping list service
        let shoppingListService = ShoppingListService(
            context: viewContext,
            container: persistenceController.container
        )
        
        // Add items to shopping list
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.fetchLimit = 50 // Use first 50 items
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
        
        measure {
            // Save shopping list
            let expectation = self.expectation(description: "Save completes")
            shoppingListService.saveCurrentShoppingList { _ in
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
            
            // Load shopping list
            let loadExpectation = self.expectation(description: "Load completes")
            shoppingListService.loadSavedShoppingList { _ in
                loadExpectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
        }
    }
    
    func testCategoryItemCountPerformance() throws {
        // Measure time to calculate item counts for all categories
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        let categories = categoryService.fetchAllCategories()
        
        measure {
            for category in categories {
                _ = categoryService.getItemCount(for: category)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testImportMemoryUsage() throws {
        // Verify import doesn't cause excessive memory growth
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        // Get baseline memory
        let baselineMemory = getMemoryUsage()
        
        // Perform import
        importService.importCommonItems()
        
        // Force context save and refresh
        try viewContext.save()
        viewContext.reset() // Clear context cache
        
        // Get memory after import
        let afterImportMemory = getMemoryUsage()
        let memoryIncrease = afterImportMemory - baselineMemory
        
        // Memory increase should be reasonable (less than 50MB for typical import)
        // This is a rough check - actual values will vary
        let maxAcceptableIncrease: Int64 = 50 * 1024 * 1024 // 50MB
        XCTAssertLessThan(memoryIncrease, maxAcceptableIncrease,
                          "Import should not cause excessive memory growth. Increase: \(memoryIncrease / 1024 / 1024)MB")
    }
    
    func testShoppingListMemoryUsage() throws {
        // Verify shopping list operations don't leak memory
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        importService.importCommonItems()
        
        let shoppingListService = ShoppingListService(
            context: viewContext,
            container: persistenceController.container
        )
        
        // Add many items to shopping list
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let items = try viewContext.fetch(fetchRequest)
        
        for item in items.prefix(100) {
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
        }
        try viewContext.save()
        
        // Get baseline memory
        let baselineMemory = getMemoryUsage()
        
        // Perform multiple save/load cycles
        for _ in 0..<10 {
            let saveExpectation = expectation(description: "Save")
            shoppingListService.saveCurrentShoppingList { _ in
                saveExpectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
            
            let loadExpectation = expectation(description: "Load")
            shoppingListService.loadSavedShoppingList { _ in
                loadExpectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
        }
        
        // Force cleanup
        viewContext.reset()
        
        // Get memory after operations
        let afterOperationsMemory = getMemoryUsage()
        let memoryIncrease = afterOperationsMemory - baselineMemory
        
        // Memory increase should be reasonable (less than 20MB for repeated operations)
        let maxAcceptableIncrease: Int64 = 20 * 1024 * 1024 // 20MB
        XCTAssertLessThan(memoryIncrease, maxAcceptableIncrease,
                          "Shopping list operations should not leak memory. Increase: \(memoryIncrease / 1024 / 1024)MB")
    }
    
    // MARK: - Helper Methods
    
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
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}
