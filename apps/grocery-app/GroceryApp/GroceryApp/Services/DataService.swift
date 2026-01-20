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
    /// Runs on the main thread but uses efficient batch deletes
    func clearAllData() {
        // Clear UserDefaults first to prevent any auto-import triggers
        UserDefaults.standard.removeObject(forKey: "selectedStoreNames")
        UserDefaults.standard.removeObject(forKey: "hasSeenLanding")
        
        // Use batch delete to avoid relationship access issues and UUID exceptions
        // Delete in order: child entities first, then parent entities
        
        // 1. Delete all ShoppingListItems (child of GroceryItem)
        let shoppingItemsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShoppingListItem")
        let shoppingItemsDelete = NSBatchDeleteRequest(fetchRequest: shoppingItemsRequest)
        shoppingItemsDelete.resultType = .resultTypeObjectIDs
        
        // 2. Delete all GroceryItems (has relationships to Category and Store)
        let itemsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GroceryItem")
        let itemsDelete = NSBatchDeleteRequest(fetchRequest: itemsRequest)
        itemsDelete.resultType = .resultTypeObjectIDs
        
        // 3. Delete all Stores
        let storesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Store")
        let storesDelete = NSBatchDeleteRequest(fetchRequest: storesRequest)
        storesDelete.resultType = .resultTypeObjectIDs
        
        // 4. Delete all Categories
        let categoriesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        let categoriesDelete = NSBatchDeleteRequest(fetchRequest: categoriesRequest)
        categoriesDelete.resultType = .resultTypeObjectIDs
        
        // Execute batch deletes
        do {
            // Execute deletes
            let shoppingItemsResult = try viewContext.execute(shoppingItemsDelete) as? NSBatchDeleteResult
            let itemsResult = try viewContext.execute(itemsDelete) as? NSBatchDeleteResult
            let storesResult = try viewContext.execute(storesDelete) as? NSBatchDeleteResult
            let categoriesResult = try viewContext.execute(categoriesDelete) as? NSBatchDeleteResult
            
            // Merge changes from batch delete into context
            if let objectIDs = shoppingItemsResult?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [viewContext])
            }
            if let objectIDs = itemsResult?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [viewContext])
            }
            if let objectIDs = storesResult?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [viewContext])
            }
            if let objectIDs = categoriesResult?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [viewContext])
            }
            
            // Save the context
            try viewContext.save()
            
            print("All data cleared successfully")
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
