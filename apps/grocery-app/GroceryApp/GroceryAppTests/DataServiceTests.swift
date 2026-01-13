//
//  DataServiceTests.swift
//  GroceryAppTests
//
//  Unit tests for DataService
//

import XCTest
import CoreData
@testable import GroceryApp

final class DataServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var dataService: DataService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        dataService = DataService(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        dataService = nil
    }
    
    // MARK: - clearAllData Tests
    
    func testClearAllData_DeletesAllGroceryItems() throws {
        // Given
        let item1 = GroceryItem(context: viewContext)
        item1.id = UUID()
        item1.name = "Item 1"
        item1.isInMasterList = true
        item1.createdDate = Date()
        
        let item2 = GroceryItem(context: viewContext)
        item2.id = UUID()
        item2.name = "Item 2"
        item2.isInMasterList = true
        item2.createdDate = Date()
        
        try viewContext.save()
        XCTAssertEqual(try viewContext.fetch(GroceryItem.fetchRequest()).count, 2)
        
        // When
        dataService.clearAllData()
        
        // Then
        let items = try viewContext.fetch(GroceryItem.fetchRequest())
        XCTAssertEqual(items.count, 0, "All grocery items should be deleted")
    }
    
    func testClearAllData_DeletesAllShoppingListItems() throws {
        // Given - create grocery items first (required for shopping list items)
        let groceryItem1 = GroceryItem(context: viewContext)
        groceryItem1.id = UUID()
        groceryItem1.name = "Item 1"
        groceryItem1.isInMasterList = true
        groceryItem1.createdDate = Date()
        
        let groceryItem2 = GroceryItem(context: viewContext)
        groceryItem2.id = UUID()
        groceryItem2.name = "Item 2"
        groceryItem2.isInMasterList = true
        groceryItem2.createdDate = Date()
        
        let shoppingItem1 = ShoppingListItem(context: viewContext)
        shoppingItem1.id = UUID()
        shoppingItem1.groceryItem = groceryItem1
        shoppingItem1.isChecked = false
        shoppingItem1.addedDate = Date()
        
        let shoppingItem2 = ShoppingListItem(context: viewContext)
        shoppingItem2.id = UUID()
        shoppingItem2.groceryItem = groceryItem2
        shoppingItem2.isChecked = true
        shoppingItem2.addedDate = Date()
        
        try viewContext.save()
        XCTAssertEqual(try viewContext.fetch(ShoppingListItem.fetchRequest()).count, 2)
        
        // When
        dataService.clearAllData()
        
        // Then
        let items = try viewContext.fetch(ShoppingListItem.fetchRequest())
        XCTAssertEqual(items.count, 0, "All shopping list items should be deleted")
    }
    
    func testClearAllData_DeletesAllStores() throws {
        // Given
        let store1 = Store(context: viewContext)
        store1.id = UUID()
        store1.name = "Store 1"
        store1.createdDate = Date()
        
        let store2 = Store(context: viewContext)
        store2.id = UUID()
        store2.name = "Store 2"
        store2.createdDate = Date()
        
        try viewContext.save()
        XCTAssertEqual(try viewContext.fetch(Store.fetchRequest()).count, 2)
        
        // When
        dataService.clearAllData()
        
        // Then
        let stores = try viewContext.fetch(Store.fetchRequest())
        XCTAssertEqual(stores.count, 0, "All stores should be deleted")
    }
    
    func testClearAllData_DeletesAllCategories() throws {
        // Given
        let category1 = Category(context: viewContext)
        category1.id = UUID()
        category1.name = "Category 1"
        category1.createdDate = Date()
        
        let category2 = Category(context: viewContext)
        category2.id = UUID()
        category2.name = "Category 2"
        category2.createdDate = Date()
        
        try viewContext.save()
        XCTAssertEqual(try viewContext.fetch(Category.fetchRequest()).count, 2)
        
        // When
        dataService.clearAllData()
        
        // Then
        let categories = try viewContext.fetch(Category.fetchRequest())
        XCTAssertEqual(categories.count, 0, "All categories should be deleted")
    }
    
    func testClearAllData_DeletesEverything() throws {
        // Given - create one of each entity type
        let store = Store(context: viewContext)
        store.id = UUID()
        store.name = "Test Store"
        store.createdDate = Date()
        
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = "Test Category"
        category.createdDate = Date()
        
        let item = GroceryItem(context: viewContext)
        item.id = UUID()
        item.name = "Test Item"
        item.category = category
        item.isInMasterList = true
        item.createdDate = Date()
        
        let shoppingItem = ShoppingListItem(context: viewContext)
        shoppingItem.id = UUID()
        shoppingItem.groceryItem = item
        shoppingItem.isChecked = false
        shoppingItem.addedDate = Date()
        
        try viewContext.save()
        
        // When
        dataService.clearAllData()
        
        // Then
        XCTAssertEqual(try viewContext.fetch(GroceryItem.fetchRequest()).count, 0)
        XCTAssertEqual(try viewContext.fetch(ShoppingListItem.fetchRequest()).count, 0)
        XCTAssertEqual(try viewContext.fetch(Store.fetchRequest()).count, 0)
        XCTAssertEqual(try viewContext.fetch(Category.fetchRequest()).count, 0)
    }
}
