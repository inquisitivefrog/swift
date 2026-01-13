//
//  MasterListImportService.swift
//  GroceryApp
//
//  Service for bulk importing common grocery items
//

import Foundation
import CoreData

class MasterListImportService {
    private let viewContext: NSManagedObjectContext
    private let categoryService: CategoryService
    private let storeService: StoreService
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.categoryService = CategoryService(context: context)
        self.storeService = StoreService(context: context)
    }
    
    /// Import common grocery items organized by category
    /// Updates existing items if they already exist (updates store assignment)
    func importCommonItems() {
        // Ensure categories and stores exist first
        categoryService.createDefaultCategories()
        storeService.createDefaultStores()
        
        // Fetch all categories to map names to entities
        let allCategories = categoryService.fetchAllCategories()
        var categoryMap: [String: Category] = [:]
        for category in allCategories {
            categoryMap[category.name.lowercased()] = category
        }
        
        // Fetch all stores to map names to entities
        let allStores = storeService.fetchAllStores()
        var storeMap: [String: Store] = [:]
        for store in allStores {
            storeMap[store.name.lowercased()] = store
        }
        
        // Get import data from ImportData.swift (single source of truth)
        let commonItems = ImportData.commonItems
        
        // Fetch existing items to check for updates
        let existingItems = try? viewContext.fetch(GroceryItem.fetchRequest())
        var existingItemsMap: [String: GroceryItem] = [:]
        for item in existingItems ?? [] {
            existingItemsMap[item.name.lowercased()] = item
        }
        
        var importedCount = 0
        var updatedCount = 0
        
        for itemData in commonItems {
            // Find category
            guard let category = categoryMap[itemData.category.lowercased()] else {
                print("Warning: Category '\(itemData.category)' not found, skipping '\(itemData.name)'")
                continue
            }
            
            // Find store if specified
            var store: Store? = nil
            if let storeName = itemData.store {
                store = storeMap[storeName.lowercased()]
                if store == nil {
                    print("Warning: Store '\(storeName)' not found for item '\(itemData.name)', skipping store assignment")
                }
            }
            
            // Check if item already exists
            let itemKey = itemData.name.lowercased()
            if let existingItem = existingItemsMap[itemKey] {
                // Update existing item: update store assignment if import data has a store
                if let store = store {
                    existingItem.setPreferredStore(store)
                    updatedCount += 1
                }
                // Skip creating new item
                continue
            }
            
            // Create new item
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemData.name
            item.category = category
            if let store = store {
                item.setPreferredStore(store)
            }
            item.isInMasterList = true
            item.createdDate = Date()
            
            importedCount += 1
        }
        
        // Save all imported/updated items
        do {
            try viewContext.save()
            if importedCount > 0 || updatedCount > 0 {
                var message = "Import complete: "
                if importedCount > 0 {
                    message += "\(importedCount) new items"
                }
                if updatedCount > 0 {
                    if importedCount > 0 { message += ", " }
                    message += "\(updatedCount) items updated"
                }
                print(message)
            }
        } catch {
            print("Error importing items: \(error)")
        }
    }
    
    /// Import items for a specific category
    func importItemsForCategory(_ category: Category) -> Int {
        // Ensure stores exist
        storeService.createDefaultStores()
        
        // Fetch all stores to map names to entities
        let allStores = storeService.fetchAllStores()
        var storeMap: [String: Store] = [:]
        for store in allStores {
            storeMap[store.name.lowercased()] = store
        }
        
        // Fetch existing items in this category
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        let existingItems = try? viewContext.fetch(fetchRequest)
        var existingItemsMap: [String: GroceryItem] = [:]
        for item in existingItems ?? [] {
            existingItemsMap[item.name.lowercased()] = item
        }
        
        // Get items for this category from ImportData
        let categoryName = category.name.lowercased()
        let commonItems = ImportData.commonItems
        
        // Filter items for this category
        let categoryItems = commonItems.filter { $0.category.lowercased() == categoryName }
        
        var importedCount = 0
        var updatedCount = 0
        
        for itemData in categoryItems {
            // Find store if specified
            var store: Store? = nil
            if let storeName = itemData.store {
                store = storeMap[storeName.lowercased()]
                if store == nil {
                    print("Warning: Store '\(storeName)' not found for item '\(itemData.name)', skipping store assignment")
                }
            }
            
            // Check if item already exists
            let itemKey = itemData.name.lowercased()
            if let existingItem = existingItemsMap[itemKey] {
                // Update existing item: update store assignment if import data has a store
                if let store = store {
                    existingItem.setPreferredStore(store)
                    updatedCount += 1
                }
                // Skip creating new item
                continue
            }
            
            // Create new item
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemData.name
            item.category = category
            if let store = store {
                item.setPreferredStore(store)
            }
            item.isInMasterList = true
            item.createdDate = Date()
            
            importedCount += 1
        }
        
        // Save imported/updated items
        if importedCount > 0 || updatedCount > 0 {
            do {
                try viewContext.save()
            } catch {
                print("Error importing items for category: \(error)")
            }
        }
        
        return importedCount + updatedCount
    }
    
    /// Clear all items from master list (use with caution!)
    func clearAllItems() {
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        
        do {
            let items = try viewContext.fetch(fetchRequest)
            for item in items {
                viewContext.delete(item)
            }
            try viewContext.save()
            print("Cleared all items from master list")
        } catch {
            print("Error clearing items: \(error)")
        }
    }
}

