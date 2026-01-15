//
//  TestDataGenerator.swift
//  GroceryAppTests
//
//  Shared test data generator for unit tests and UI tests
//

import Foundation
import CoreData
@testable import GroceryApp

/// Test data generator for creating sample data in tests
class TestDataGenerator {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Store Creation
    
    /// Create a test store
    @discardableResult
    func createStore(name: String, iconName: String = "storefront.fill", isFavorite: Bool = false) -> Store {
        let store = Store(context: context)
        store.id = UUID()
        store.name = name
        store.iconName = iconName
        store.isFavorite = isFavorite
        store.createdDate = Date()
        return store
    }
    
    /// Create default test stores
    @discardableResult
    func createDefaultStores() -> [Store] {
        let stores = [
            createStore(name: "Berkeley Bowl", iconName: "storefront.fill", isFavorite: true),
            createStore(name: "Whole Foods", iconName: "storefront.fill", isFavorite: false),
            createStore(name: "Trader Joe's", iconName: "storefront.fill", isFavorite: false),
            createStore(name: "Safeway", iconName: "storefront.fill", isFavorite: false)
        ]
        try? context.save()
        return stores
    }
    
    // MARK: - Category Creation
    
    /// Create a test category
    @discardableResult
    func createCategory(name: String, iconName: String = "folder.fill", isDefault: Bool = false) -> Category {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.iconName = iconName
        category.isDefault = isDefault
        category.createdDate = Date()
        return category
    }
    
    /// Create default test categories
    @discardableResult
    func createDefaultCategories() -> [Category] {
        let categories = [
            createCategory(name: "Produce", iconName: "leaf.fill", isDefault: true),
            createCategory(name: "Dairy", iconName: "drop.fill", isDefault: true),
            createCategory(name: "Meat", iconName: "fork.knife", isDefault: true),
            createCategory(name: "Bakery", iconName: "birthday.cake.fill", isDefault: true),
            createCategory(name: "Frozen", iconName: "snowflake", isDefault: true)
        ]
        try? context.save()
        return categories
    }
    
    // MARK: - Grocery Item Creation
    
    /// Create a test grocery item
    @discardableResult
    func createGroceryItem(
        name: String,
        category: Category,
        store: Store? = nil,
        isInMasterList: Bool = true
    ) -> GroceryItem {
        let item = GroceryItem(context: context)
        item.id = UUID()
        item.name = name
        item.category = category
        item.isInMasterList = isInMasterList
        item.createdDate = Date()
        
        if let store = store {
            item.setPreferredStore(store)
        }
        
        return item
    }
    
    /// Create sample grocery items for testing
    @discardableResult
    func createSampleGroceryItems(categories: [Category], stores: [Store]) -> [GroceryItem] {
        guard !categories.isEmpty, !stores.isEmpty else { return [] }
        
        let produceCategory = categories.first { $0.name == "Produce" } ?? categories[0]
        let dairyCategory = categories.first { $0.name == "Dairy" } ?? (categories.count > 1 ? categories[1] : categories[0])
        let meatCategory = categories.first { $0.name == "Meat" } ?? (categories.count > 2 ? categories[2] : categories[0])
        
        let berkeleyBowl = stores.first { $0.name == "Berkeley Bowl" } ?? stores[0]
        let wholeFoods = stores.first { $0.name == "Whole Foods" } ?? (stores.count > 1 ? stores[1] : stores[0])
        
        let items = [
            // Produce items
            createGroceryItem(name: "Apples", category: produceCategory, store: berkeleyBowl),
            createGroceryItem(name: "Bananas", category: produceCategory, store: berkeleyBowl),
            createGroceryItem(name: "Lettuce", category: produceCategory, store: berkeleyBowl),
            createGroceryItem(name: "Tomatoes", category: produceCategory, store: berkeleyBowl),
            
            // Dairy items
            createGroceryItem(name: "Milk", category: dairyCategory, store: wholeFoods),
            createGroceryItem(name: "Cheese", category: dairyCategory, store: wholeFoods),
            createGroceryItem(name: "Yogurt", category: dairyCategory, store: wholeFoods),
            
            // Meat items
            createGroceryItem(name: "Chicken", category: meatCategory, store: wholeFoods),
            createGroceryItem(name: "Beef", category: meatCategory, store: wholeFoods)
        ]
        
        try? context.save()
        return items
    }
    
    // MARK: - Shopping List Item Creation
    
    /// Create a shopping list item from a grocery item
    @discardableResult
    func createShoppingListItem(
        groceryItem: GroceryItem,
        store: Store? = nil,
        isChecked: Bool = false,
        quantity: Int32 = 1
    ) -> ShoppingListItem {
        let shoppingItem = ShoppingListItem(context: context)
        shoppingItem.id = UUID()
        shoppingItem.groceryItem = groceryItem
        shoppingItem.store = store ?? groceryItem.firstPreferredStore
        shoppingItem.isChecked = isChecked
        shoppingItem.quantity = quantity
        shoppingItem.addedDate = Date()
        
        if isChecked {
            shoppingItem.checkedDate = Date()
        }
        
        return shoppingItem
    }
    
    /// Create a complete shopping list scenario for testing
    @discardableResult
    func createShoppingListScenario() -> (stores: [Store], categories: [Category], items: [GroceryItem], shoppingItems: [ShoppingListItem]) {
        // Create stores and categories
        let stores = createDefaultStores()
        let categories = createDefaultCategories()
        
        // Create grocery items
        let items = createSampleGroceryItems(categories: categories, stores: stores)
        
        // Create shopping list items (some checked, some unchecked)
        let shoppingItems = items.enumerated().map { index, item in
            createShoppingListItem(
                groceryItem: item,
                isChecked: index % 3 == 0  // Every 3rd item is checked
            )
        }
        
        try? context.save()
        
        return (stores: stores, categories: categories, items: items, shoppingItems: shoppingItems)
    }
    
    /// Create a scenario where all shopping is complete (all items checked)
    @discardableResult
    func createCompletedShoppingListScenario() -> (stores: [Store], categories: [Category], items: [GroceryItem], shoppingItems: [ShoppingListItem]) {
        let scenario = createShoppingListScenario()
        
        // Mark all shopping items as checked
        for shoppingItem in scenario.shoppingItems {
            shoppingItem.isChecked = true
            shoppingItem.checkedDate = Date()
        }
        
        try? context.save()
        
        return scenario
    }
    
    /// Create a scenario with items for specific stores (for Shop By Stores testing)
    @discardableResult
    func createStoreBasedShoppingScenario() -> (stores: [Store], categories: [Category], items: [GroceryItem], shoppingItems: [ShoppingListItem]) {
        let stores = createDefaultStores()
        let categories = createDefaultCategories()
        
        let berkeleyBowl = stores.first { $0.name == "Berkeley Bowl" }!
        let wholeFoods = stores.first { $0.name == "Whole Foods" }!
        let traderJoes = stores.first { $0.name == "Trader Joe's" }!
        
        let produceCategory = categories.first { $0.name == "Produce" }!
        let dairyCategory = categories.first { $0.name == "Dairy" }!
        let meatCategory = categories.first { $0.name == "Meat" }!
        
        // Create items assigned to specific stores
        let items = [
            // Berkeley Bowl items
            createGroceryItem(name: "Organic Apples", category: produceCategory, store: berkeleyBowl),
            createGroceryItem(name: "Organic Lettuce", category: produceCategory, store: berkeleyBowl),
            createGroceryItem(name: "Fresh Herbs", category: produceCategory, store: berkeleyBowl),
            
            // Whole Foods items
            createGroceryItem(name: "Organic Milk", category: dairyCategory, store: wholeFoods),
            createGroceryItem(name: "Artisan Cheese", category: dairyCategory, store: wholeFoods),
            
            // Trader Joe's items
            createGroceryItem(name: "Frozen Pizza", category: categories.first { $0.name == "Frozen" }!, store: traderJoes),
            createGroceryItem(name: "Organic Chicken", category: meatCategory, store: traderJoes)
        ]
        
        // Create shopping list items (all unchecked for testing)
        let shoppingItems = items.map { item in
            createShoppingListItem(groceryItem: item, isChecked: false)
        }
        
        try? context.save()
        
        return (stores: stores, categories: categories, items: items, shoppingItems: shoppingItems)
    }
    
    // MARK: - Cleanup
    
    /// Clear all test data
    func clearAll() {
        let entities = ["ShoppingListItem", "GroceryItem", "Category", "Store"]
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
        try? context.save()
    }
}
