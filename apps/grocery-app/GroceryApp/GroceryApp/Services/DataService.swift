//
//  DataService.swift
//  GroceryApp
//
//  Service for managing all app data operations
//

import Foundation
import CoreData

class DataService {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    /// Clear all data from the app (items, shopping lists, stores, categories)
    /// This will delete everything and allow a fresh start
    func clearAllData() {
        // Delete all GroceryItems
        let itemsRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        if let items = try? viewContext.fetch(itemsRequest) {
            for item in items {
                viewContext.delete(item)
            }
        }
        
        // Delete all ShoppingListItems
        let shoppingItemsRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        if let shoppingItems = try? viewContext.fetch(shoppingItemsRequest) {
            for item in shoppingItems {
                viewContext.delete(item)
            }
        }
        
        // Delete all Stores
        let storesRequest: NSFetchRequest<Store> = Store.fetchRequest()
        if let stores = try? viewContext.fetch(storesRequest) {
            for store in stores {
                viewContext.delete(store)
            }
        }
        
        // Delete all Categories
        let categoriesRequest: NSFetchRequest<Category> = Category.fetchRequest()
        if let categories = try? viewContext.fetch(categoriesRequest) {
            for category in categories {
                viewContext.delete(category)
            }
        }
        
        // Save changes
        do {
            try viewContext.save()
            print("All data cleared successfully")
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
