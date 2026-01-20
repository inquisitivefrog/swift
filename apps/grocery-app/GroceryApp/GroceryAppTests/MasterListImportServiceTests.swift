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
        // Given - create an existing item with a specific store
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let category = categoryService.fetchAllCategories().first { $0.name == "Produce Fruit" }
        XCTAssertNotNil(category, "Produce Fruit category should exist")
        
        let stores = storeService.fetchAllStores()
        let traderJoes = stores.first { $0.name == "Trader Joe's" }
        XCTAssertNotNil(traderJoes, "Trader Joe's should exist")
        
        // Create an existing item with Trader Joe's as the store
        let existingItem = GroceryItem(context: viewContext)
        existingItem.id = UUID()
        existingItem.name = "Apples"
        existingItem.category = category
        existingItem.setPreferredStore(traderJoes!)
        existingItem.isInMasterList = true
        existingItem.createdDate = Date()
        try viewContext.save()
        
        let initialCount = try viewContext.fetch(GroceryItem.fetchRequest()).count
        
        // When - import (if ImportData has "Apples" with "Trader Joe's", it should skip)
        importService.importCommonItems()
        
        // Then - should not create duplicate item with same name AND same store
        let finalItems = try viewContext.fetch(GroceryItem.fetchRequest())
        let appleItemsWithTraderJoes = finalItems.filter { item in
            item.name == "Apples" && item.firstPreferredStore?.name == "Trader Joe's"
        }
        XCTAssertEqual(appleItemsWithTraderJoes.count, 1, "Should not create duplicate Apples from Trader Joe's")
        XCTAssertGreaterThan(finalItems.count, initialCount, "Should still import other items")
    }
    
    func testImportCommonItems_AllowsSameItemFromDifferentStores() throws {
        // Given - verify that same item from different stores creates separate items
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let category = categoryService.fetchAllCategories().first { $0.name == "Dairy" }
        XCTAssertNotNil(category, "Dairy category should exist")
        
        let stores = storeService.fetchAllStores()
        let wholeFoods = stores.first { $0.name == "Whole Foods" }
        let traderJoes = stores.first { $0.name == "Trader Joe's" }
        XCTAssertNotNil(wholeFoods, "Whole Foods should exist")
        XCTAssertNotNil(traderJoes, "Trader Joe's should exist")
        
        // Create "Eggs" from Whole Foods
        let eggsWholeFoods = GroceryItem(context: viewContext)
        eggsWholeFoods.id = UUID()
        eggsWholeFoods.name = "Eggs"
        eggsWholeFoods.category = category
        eggsWholeFoods.setPreferredStore(wholeFoods!)
        eggsWholeFoods.isInMasterList = true
        eggsWholeFoods.createdDate = Date()
        try viewContext.save()
        
        // When - manually add "Eggs" from Trader Joe's (simulating import with different store)
        let eggsTraderJoes = GroceryItem(context: viewContext)
        eggsTraderJoes.id = UUID()
        eggsTraderJoes.name = "Eggs"
        eggsTraderJoes.category = category
        eggsTraderJoes.setPreferredStore(traderJoes!)
        eggsTraderJoes.isInMasterList = true
        eggsTraderJoes.createdDate = Date()
        try viewContext.save()
        
        // Then - both should exist as separate items
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Eggs")
        let allEggs = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(allEggs.count, 2, "Should allow same item from different stores")
        XCTAssertTrue(allEggs.contains { $0.firstPreferredStore?.name == "Whole Foods" })
        XCTAssertTrue(allEggs.contains { $0.firstPreferredStore?.name == "Trader Joe's" })
    }
    
    func testImportCommonItems_CreatesNewItemWhenStoreDiffers() throws {
        // Given - item exists with one store, import same item with different store
        storeService.createDefaultStores()
        categoryService.createDefaultCategories()
        
        let category = categoryService.fetchAllCategories().first { $0.name == "Dairy" }
        XCTAssertNotNil(category, "Dairy category should exist")
        
        let stores = storeService.fetchAllStores()
        let wholeFoods = stores.first { $0.name == "Whole Foods" }
        XCTAssertNotNil(wholeFoods, "Whole Foods should exist")
        
        // Create "Milk" from Whole Foods
        let existingItem = GroceryItem(context: viewContext)
        existingItem.id = UUID()
        existingItem.name = "Milk"
        existingItem.category = category
        existingItem.setPreferredStore(wholeFoods!)
        existingItem.isInMasterList = true
        existingItem.createdDate = Date()
        try viewContext.save()
        
        let initialCount = try viewContext.fetch(GroceryItem.fetchRequest()).count
        
        // When - manually create "Milk" from different store (simulating import)
        let traderJoes = stores.first { $0.name == "Trader Joe's" }
        let newItem = GroceryItem(context: viewContext)
        newItem.id = UUID()
        newItem.name = "Milk"
        newItem.category = category
        newItem.setPreferredStore(traderJoes!)
        newItem.isInMasterList = true
        newItem.createdDate = Date()
        try viewContext.save()
        
        // Then - should have two separate "Milk" items
        let finalItems = try viewContext.fetch(GroceryItem.fetchRequest())
        let milkItems = finalItems.filter { $0.name == "Milk" }
        XCTAssertEqual(milkItems.count, 2, "Should allow same item from different stores as separate items")
        XCTAssertEqual(finalItems.count, initialCount + 1, "Should create new item when store differs")
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
        let produceFruitCategory = categoryService.fetchAllCategories().first { $0.name == "Produce Fruit" }
        
        // When
        _ = importService.importItemsForCategory(dairyCategory!)
        
        // Then
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", produceFruitCategory!)
        let produceFruitItems = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(produceFruitItems.count, 0, "Should not import items for other categories")
    }
}
