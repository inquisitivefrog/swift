//
//  ShoppingListServiceTests.swift
//  GroceryAppTests
//
//  Unit tests for ShoppingListService
//

import XCTest
import CoreData
@testable import GroceryApp

final class ShoppingListServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var shoppingListService: ShoppingListService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        shoppingListService = ShoppingListService(context: viewContext, container: persistenceController.container)
        
        // Clear any existing saved list
        UserDefaults.standard.removeObject(forKey: "savedShoppingListItems")
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        shoppingListService = nil
        
        // Clean up saved list
        UserDefaults.standard.removeObject(forKey: "savedShoppingListItems")
    }
    
    // MARK: - Save Tests
    
    func testSaveCurrentShoppingList_SavesItemIDs() throws {
        // Given - create items and add to shopping list
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.createdDate = Date()
        
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Item 1"
        item1.category = category
        item1.isInMasterList = true
        item1.createdDate = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Item 2"
        item2.category = category
        item2.isInMasterList = true
        item2.createdDate = Date()
        
        let shoppingItem1 = ShoppingListItem(context: viewContext)
        shoppingItem1.id = UUID()
        shoppingItem1.groceryItem = item1
        shoppingItem1.isChecked = false
        shoppingItem1.addedDate = Date()
        
        let shoppingItem2 = ShoppingListItem(context: viewContext)
        shoppingItem2.id = UUID()
        shoppingItem2.groceryItem = item2
        shoppingItem2.isChecked = false
        shoppingItem2.addedDate = Date()
        
        try viewContext.save()
        
        // When
        let expectation = expectation(description: "Save completes")
        var savedCount: Int?
        shoppingListService.saveCurrentShoppingList { result in
            if case .success(let count) = result {
                savedCount = count
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Then
        XCTAssertEqual(savedCount, 2, "Should save 2 items")
        let savedIDs = UserDefaults.standard.array(forKey: "savedShoppingListItems") as? [String]
        XCTAssertNotNil(savedIDs)
        XCTAssertEqual(savedIDs?.count, 2)
    }
    
    func testSaveCurrentShoppingList_ExcludesCheckedItems() throws {
        // Given - create items, one checked, one unchecked
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.createdDate = Date()
        
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Item 1"
        item1.category = category
        item1.isInMasterList = true
        item1.createdDate = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Item 2"
        item2.category = category
        item2.isInMasterList = true
        item2.createdDate = Date()
        
        let shoppingItem1 = ShoppingListItem(context: viewContext)
        shoppingItem1.id = UUID()
        shoppingItem1.groceryItem = item1
        shoppingItem1.isChecked = false // Unchecked
        shoppingItem1.addedDate = Date()
        
        let shoppingItem2 = ShoppingListItem(context: viewContext)
        shoppingItem2.id = UUID()
        shoppingItem2.groceryItem = item2
        shoppingItem2.isChecked = true // Checked - should be excluded
        shoppingItem2.addedDate = Date()
        
        try viewContext.save()
        
        // When
        let expectation = expectation(description: "Save completes")
        var savedCount: Int?
        shoppingListService.saveCurrentShoppingList { result in
            if case .success(let count) = result {
                savedCount = count
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Then
        XCTAssertEqual(savedCount, 1, "Should save only unchecked item")
        let savedIDs = UserDefaults.standard.array(forKey: "savedShoppingListItems") as? [String]
        XCTAssertEqual(savedIDs?.count, 1)
    }
    
    // MARK: - Load Tests
    
    func testLoadSavedShoppingList_AddsItemsToShoppingList() throws {
        // Given - create items and save them
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.createdDate = Date()
        
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Item 1"
        item1.category = category
        item1.isInMasterList = true
        item1.createdDate = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Item 2"
        item2.category = category
        item2.isInMasterList = true
        item2.createdDate = Date()
        
        try viewContext.save()
        
        // Save the list
        let itemIDs = [item1.id.uuidString, item2.id.uuidString]
        UserDefaults.standard.set(itemIDs, forKey: "savedShoppingListItems")
        
        // When
        let expectation = expectation(description: "Load completes")
        var loadedCount: Int?
        shoppingListService.loadSavedShoppingList { result in
            if case .success(let count) = result {
                loadedCount = count
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Then
        XCTAssertEqual(loadedCount, 2, "Should load 2 items")
        
        // Verify items were added to shopping list
        let fetchRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let shoppingItems = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(shoppingItems.count, 2)
    }
    
    func testLoadSavedShoppingList_SkipsItemsAlreadyInList() throws {
        // Given - create items, one already in shopping list
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.createdDate = Date()
        
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Item 1"
        item1.category = category
        item1.isInMasterList = true
        item1.createdDate = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Item 2"
        item2.category = category
        item2.isInMasterList = true
        item2.createdDate = Date()
        
        // Item 1 is already in shopping list
        let existingItem = ShoppingListItem(context: viewContext)
        existingItem.id = UUID()
        existingItem.groceryItem = item1
        existingItem.isChecked = false
        existingItem.addedDate = Date()
        
        try viewContext.save()
        
        // Save both items to saved list
        let itemIDs = [item1.id.uuidString, item2.id.uuidString]
        UserDefaults.standard.set(itemIDs, forKey: "savedShoppingListItems")
        
        // When
        let expectation = expectation(description: "Load completes")
        var loadedCount: Int?
        shoppingListService.loadSavedShoppingList { result in
            if case .success(let count) = result {
                loadedCount = count
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Then
        XCTAssertEqual(loadedCount, 1, "Should load only item 2 (item 1 already exists)")
        
        // Verify only one new item was added
        let fetchRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        let shoppingItems = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(shoppingItems.count, 2) // Original + 1 new
    }
    
    func testLoadSavedShoppingList_ReturnsErrorWhenNoSavedList() throws {
        // Given - no saved list exists
        UserDefaults.standard.removeObject(forKey: "savedShoppingListItems")
        
        // When
        let expectation = expectation(description: "Load completes")
        var loadError: Error?
        shoppingListService.loadSavedShoppingList { result in
            if case .failure(let error) = result {
                loadError = error
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        
        // Then
        XCTAssertNotNil(loadError, "Should return error when no saved list exists")
    }
    
    // MARK: - hasSavedList Tests
    
    func testHasSavedList_ReturnsFalseWhenNoSavedList() {
        // Given
        UserDefaults.standard.removeObject(forKey: "savedShoppingListItems")
        
        // When
        let hasList = shoppingListService.hasSavedList
        
        // Then
        XCTAssertFalse(hasList, "Should return false when no saved list exists")
    }
    
    func testHasSavedList_ReturnsTrueWhenSavedListExists() {
        // Given
        UserDefaults.standard.set(["test-id"], forKey: "savedShoppingListItems")
        
        // When
        let hasList = shoppingListService.hasSavedList
        
        // Then
        XCTAssertTrue(hasList, "Should return true when saved list exists")
    }
}
