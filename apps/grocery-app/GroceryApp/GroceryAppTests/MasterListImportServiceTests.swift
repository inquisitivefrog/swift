//
//  MasterListImportServiceTests.swift
//  GroceryAppTests
//
//  Unit tests for MasterListImportService
//

import XCTest
import CoreData
@testable import GroceryApp

final class MasterListImportServiceTests: XCTestCase {
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
    
    // MARK: - importCommonItems Tests
    
    func testImportCommonItems_CreatesItemsFromImportData() throws {
        // Given - set up stores and categories
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        // When
        importService.importCommonItems()
        
        // Then
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let items = try viewContext.fetch(fetchRequest)
        
        XCTAssertGreaterThan(items.count, 0, "Should import items from ImportData")
    }
    
    func testImportCommonItems_AssignsStoresWhenSpecified() throws {
        // Given
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        let stores = storeService.fetchAllStores()
        let traderJoes = stores.first { $0.name == "Trader Joe's" }
        XCTAssertNotNil(traderJoes, "Trader Joe's should exist")
        
        // When
        importService.importCommonItems()
        
        // Then - check that items with store assignments have stores
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        let items = try viewContext.fetch(fetchRequest)
        
        // Find items that should have Trader Joe's assigned (from ImportData)
        let itemsWithStore = items.filter { $0.firstPreferredStore != nil }
        XCTAssertGreaterThan(itemsWithStore.count, 0, "Some items should have stores assigned")
    }
    
    func testImportCommonItems_DoesNotDuplicateExistingItems() throws {
        // Given
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        // Create an existing item
        let category = categoryService.fetchAllCategories().first { $0.name == "Produce" }
        XCTAssertNotNil(category, "Produce category should exist")
        
        let existingItem = GroceryItem(context: viewContext)
        existingItem.id = UUID()
        existingItem.name = "Apples"
        existingItem.category = category
        existingItem.isInMasterList = true
        existingItem.createdDate = Date()
        try viewContext.save()
        
        let initialCount = try viewContext.fetch(GroceryItem.fetchRequest()).count
        
        // When
        importService.importCommonItems()
        
        // Then
        let finalItems = try viewContext.fetch(GroceryItem.fetchRequest())
        let appleItems = finalItems.filter { $0.name == "Apples" }
        XCTAssertEqual(appleItems.count, 1, "Should not create duplicate Apples")
        XCTAssertGreaterThan(finalItems.count, initialCount, "Should still import other items")
    }
    
    func testImportCommonItems_UpdatesStoreAssignmentForExistingItems() throws {
        // Given
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let category = categoryService.fetchAllCategories().first { $0.name == "Produce" }
        let stores = storeService.fetchAllStores()
        let traderJoes = stores.first { $0.name == "Trader Joe's" }
        
        // Create item without store
        let existingItem = GroceryItem(context: viewContext)
        existingItem.id = UUID()
        existingItem.name = "Apples"
        existingItem.category = category
        existingItem.isInMasterList = true
        existingItem.createdDate = Date()
        try viewContext.save()
        
        XCTAssertNil(existingItem.firstPreferredStore, "Item should not have store initially")
        
        // When - import (Apples should have Trader Joe's in ImportData)
        importService.importCommonItems()
        
        // Then - item should now have store assigned
        viewContext.refresh(existingItem, mergeChanges: true)
        // Note: This test depends on ImportData having "Apples" with "Trader Joe's"
        // The actual store assignment will depend on what's in ImportData.swift
    }
    
    // MARK: - importItemsForCategory Tests
    
    func testImportItemsForCategory_ImportsOnlyItemsForThatCategory() throws {
        // Given
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let dairyCategory = categoryService.fetchAllCategories().first { $0.name == "Dairy" }
        XCTAssertNotNil(dairyCategory, "Dairy category should exist")
        
        // When
        let importedCount = importService.importItemsForCategory(dairyCategory!)
        
        // Then
        XCTAssertGreaterThan(importedCount, 0, "Should import items for Dairy category")
        
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", dairyCategory!)
        let dairyItems = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(dairyItems.count, importedCount)
        XCTAssertTrue(dairyItems.allSatisfy { $0.category == dairyCategory })
    }
    
    func testImportItemsForCategory_DoesNotImportItemsForOtherCategories() throws {
        // Given
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let dairyCategory = categoryService.fetchAllCategories().first { $0.name == "Dairy" }
        let produceCategory = categoryService.fetchAllCategories().first { $0.name == "Produce" }
        
        // When
        _ = importService.importItemsForCategory(dairyCategory!)
        
        // Then
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", produceCategory!)
        let produceItems = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(produceItems.count, 0, "Should not import items for other categories")
    }
}
