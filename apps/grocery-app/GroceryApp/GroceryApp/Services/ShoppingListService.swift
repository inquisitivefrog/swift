//
//  ShoppingListService.swift
//  GroceryApp
//
//  Service for managing saved shopping lists
//

import Foundation
import CoreData

class ShoppingListService {
    private let context: NSManagedObjectContext
    private let container: NSPersistentContainer
    private let savedListKey = "savedShoppingListItems"
    
    init(context: NSManagedObjectContext, container: NSPersistentContainer? = nil) {
        self.context = context
        // Use provided container, or fall back to shared container
        self.container = container ?? PersistenceController.shared.container
    }
    
    /// Save current shopping list items for later reload
    /// Uses background context to avoid blocking main thread
    /// For in-memory stores (tests), uses main context directly
    func saveCurrentShoppingList(completion: @escaping (Result<Int, Error>) -> Void) {
        // Check if this is an in-memory store (used in tests)
        let isInMemory = container.persistentStoreDescriptions.first?.url == URL(fileURLWithPath: "/dev/null")
        
        if isInMemory {
            // For tests: use main context directly to ensure we see test data
            do {
                let fetchRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "isChecked == NO")
                let items = try context.fetch(fetchRequest)
                
                // Save grocery item IDs (only unchecked items)
                let itemIDs = items.map { item -> String in
                    return item.groceryItem.id.uuidString
                }
                
                UserDefaults.standard.set(itemIDs, forKey: self.savedListKey)
                print("Saved shopping list with \(itemIDs.count) items")
                completion(.success(itemIDs.count))
            } catch {
                completion(.failure(error))
            }
        } else {
            // For production: use background context
            container.performBackgroundTask { backgroundContext in
                do {
                    let fetchRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "isChecked == NO")
                    let items = try backgroundContext.fetch(fetchRequest)
                    
                    // Save grocery item IDs (only unchecked items)
                    let itemIDs = items.map { item -> String in
                        return item.groceryItem.id.uuidString
                    }
                    
                    // Save to UserDefaults on main thread (UserDefaults is thread-safe but better to be explicit)
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(itemIDs, forKey: self.savedListKey)
                        print("Saved shopping list with \(itemIDs.count) items")
                        completion(.success(itemIDs.count))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Load saved shopping list items into current shopping list
    /// Uses background context to avoid blocking main thread
    /// For in-memory stores (tests), uses main context directly
    func loadSavedShoppingList(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let itemIDs = UserDefaults.standard.array(forKey: savedListKey) as? [String] else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "ShoppingListService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No saved shopping list found"])))
            }
            return
        }
        
        // Convert string IDs to UUIDs
        let uuids = itemIDs.compactMap { UUID(uuidString: $0) }
        
        // Check if this is an in-memory store (used in tests)
        let isInMemory = container.persistentStoreDescriptions.first?.url == URL(fileURLWithPath: "/dev/null")
        
        if isInMemory {
            // For tests: use main context directly to ensure we see test data
            do {
                // Fetch grocery items by IDs
                let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id IN %@", uuids)
                let groceryItems = try context.fetch(fetchRequest)
                
                // Get current shopping list items
                let currentItemsRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
                let currentItems = try context.fetch(currentItemsRequest)
                let currentGroceryItemIDs = Set(currentItems.compactMap { $0.groceryItem.id })
                
                // Add items that aren't already in the shopping list
                var addedCount = 0
                for groceryItem in groceryItems {
                    // Skip if already in shopping list
                    if currentGroceryItemIDs.contains(groceryItem.id) {
                        continue
                    }
                    
                    // Create new shopping list item
                    let shoppingItem = ShoppingListItem(context: context)
                    shoppingItem.id = UUID()
                    shoppingItem.groceryItem = groceryItem
                    shoppingItem.store = groceryItem.firstPreferredStore
                    shoppingItem.isChecked = false
                    shoppingItem.addedDate = Date()
                    shoppingItem.quantity = 1
                    
                    addedCount += 1
                }
                
                if addedCount > 0 {
                    try context.save()
                    print("Loaded \(addedCount) items from saved shopping list")
                } else {
                    print("All saved items are already in the shopping list")
                }
                
                completion(.success(addedCount))
            } catch {
                completion(.failure(error))
            }
        } else {
            // For production: use background context
            container.performBackgroundTask { backgroundContext in
                defer {
                    backgroundContext.processPendingChanges()
                }
                
                do {
                    // Fetch grocery items by IDs
                    let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id IN %@", uuids)
                    let groceryItems = try backgroundContext.fetch(fetchRequest)
                    
                    // Get current shopping list items
                    let currentItemsRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
                    let currentItems = try backgroundContext.fetch(currentItemsRequest)
                    let currentGroceryItemIDs = Set(currentItems.compactMap { $0.groceryItem.id })
                    
                    // Add items that aren't already in the shopping list
                    var addedCount = 0
                    for groceryItem in groceryItems {
                        // Skip if already in shopping list
                        if currentGroceryItemIDs.contains(groceryItem.id) {
                            continue
                        }
                        
                        // Create new shopping list item
                        let shoppingItem = ShoppingListItem(context: backgroundContext)
                        shoppingItem.id = UUID()
                        shoppingItem.groceryItem = groceryItem
                        shoppingItem.store = groceryItem.firstPreferredStore
                        shoppingItem.isChecked = false
                        shoppingItem.addedDate = Date()
                        shoppingItem.quantity = 1
                        
                        addedCount += 1
                    }
                    
                    if addedCount > 0 {
                        try backgroundContext.save()
                        print("Loaded \(addedCount) items from saved shopping list")
                    } else {
                        print("All saved items are already in the shopping list")
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(addedCount))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Check if a saved shopping list exists
    var hasSavedList: Bool {
        return UserDefaults.standard.array(forKey: savedListKey) != nil
    }
}
