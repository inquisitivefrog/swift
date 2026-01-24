//
//  GroceryAppApp.swift
//  GroceryApp
//
//  Created by Timothy Stilwell on 1/6/26.
//

import SwiftUI
import CoreData

@main
struct GroceryAppApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Set up test data if running UI tests
        if ProcessInfo.processInfo.arguments.contains("--uitest") {
            setupTestData()
        }
    }

    var body: some Scene {
        WindowGroup {
            LandingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func setupTestData() {
        let context = persistenceController.container.viewContext
        
        // Check for specific test scenario
        if let scenarioIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--test-scenario"),
           scenarioIndex + 1 < ProcessInfo.processInfo.arguments.count {
            let scenarioName = ProcessInfo.processInfo.arguments[scenarioIndex + 1]
            setupScenario(scenarioName, context: context)
        } else if ProcessInfo.processInfo.arguments.contains("--setup-test-data") {
            // Default test data setup
            setupDefaultTestData(context: context)
        }
    }
    
    private func setupScenario(_ scenarioName: String, context: NSManagedObjectContext) {
        // Import TestDataGenerator (it's in the test target, so we'll create data directly)
        // For UI tests, we need to set up data in the app's context
        
        switch scenarioName {
        case "store-based-shopping":
            setupStoreBasedShoppingData(context: context)
        case "completed-shopping":
            setupCompletedShoppingData(context: context)
        default:
            setupDefaultTestData(context: context)
        }
    }
    
    private func setupDefaultTestData(context: NSManagedObjectContext) {
        setupStoreBasedShoppingData(context: context)
    }
    
    private func setupStoreBasedShoppingData(context: NSManagedObjectContext) {
        // Create stores
        let storeService = StoreService(context: context)
        storeService.createDefaultStores()
        
        // Create categories
        let categoryService = CategoryService(context: context)
        categoryService.createDefaultCategories()
        
        // Get stores and categories
        let stores = storeService.fetchAllStores()
        let categories = categoryService.fetchAllCategories()
        
        guard let berkeleyBowl = stores.first(where: { $0.name == "Berkeley Bowl" }),
              let wholeFoods = stores.first(where: { $0.name == "Whole Foods" }),
              let produceCategory = categories.first(where: { $0.name == "Produce" }),
              let dairyCategory = categories.first(where: { $0.name == "Dairy" }) else {
            return
        }
        
        // Create grocery items
        let items = [
            createGroceryItem(name: "Apples", category: produceCategory, store: berkeleyBowl, context: context),
            createGroceryItem(name: "Bananas", category: produceCategory, store: berkeleyBowl, context: context),
            createGroceryItem(name: "Milk", category: dairyCategory, store: wholeFoods, context: context),
            createGroceryItem(name: "Cheese", category: dairyCategory, store: wholeFoods, context: context)
        ]
        
        // Create shopping list items (all unchecked for testing)
        for item in items {
            let shoppingItem = ShoppingListItem(context: context)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
            shoppingItem.quantity = 1
        }
        
        // Set selected stores for the test
        UserDefaults.standard.set(["Berkeley Bowl", "Whole Foods"], forKey: "selectedStoreNames")
        UserDefaults.standard.set(true, forKey: "hasSeenLanding")
        
        do {
            try context.save()
        } catch {
            print("Error setting up test data: \(error)")
        }
    }
    
    private func setupCompletedShoppingData(context: NSManagedObjectContext) {
        // Same setup but with all items checked
        setupStoreBasedShoppingData(context: context)
        
        // Mark all shopping items as checked
        let fetchRequest = ShoppingListItem.fetchRequest()
        if let shoppingItems = try? context.fetch(fetchRequest) {
            for item in shoppingItems {
                item.isChecked = true
                item.checkedDate = Date()
            }
            try? context.save()
        }
    }
    
    private func createGroceryItem(name: String, category: Category, store: Store, context: NSManagedObjectContext) -> GroceryItem {
        let item = GroceryItem(context: context)
        item.id = UUID()
        item.name = name
        item.category = category
        item.isInMasterList = true
        item.createdDate = Date()
        item.setPreferredStore(store)
        return item
    }
}
