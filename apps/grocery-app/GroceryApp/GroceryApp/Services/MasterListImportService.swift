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
    /// Only imports items from stores selected by the user
    func importCommonItems() {
        // Ensure categories and stores exist first
        categoryService.createDefaultCategories()
        storeService.createDefaultStores()
        
        // Get selected store names from UserDefaults (set during store selection)
        let selectedStoreNames = UserDefaults.standard.stringArray(forKey: "selectedStoreNames") ?? []
        let selectedStoreNamesSet = Set(selectedStoreNames.map { $0.lowercased() })
        
        // If no stores are selected, import all items (backward compatibility)
        let filterByStore = !selectedStoreNames.isEmpty
        
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
        // Use composite key: name + store ID (allows same item from different stores)
        let existingItems = try? viewContext.fetch(GroceryItem.fetchRequest())
        var existingItemsMap: [String: GroceryItem] = [:]
        for item in existingItems ?? [] {
            let storeId = item.firstPreferredStore?.id.uuidString ?? "nostore"
            let compositeKey = "\(item.name.lowercased()):\(storeId)"
            existingItemsMap[compositeKey] = item
        }
        
        var importedCount = 0
        
        for itemData in commonItems {
            // Filter by selected stores if store selection has been made
            if filterByStore {
                if let storeName = itemData.store {
                    // Item has a store - only import if store is selected
                    if !selectedStoreNamesSet.contains(storeName.lowercased()) {
                        continue // Skip items from unselected stores
                    }
                } else {
                    // Item has no store - skip if filtering is enabled (only import items with selected stores)
                    continue
                }
            }
            
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
            
            // Check if item already exists (using composite key: name + store)
            // This allows the same item from different stores to exist as separate items
            let storeId = store?.id.uuidString ?? "nostore"
            let itemKey = "\(itemData.name.lowercased()):\(storeId)"
            if existingItemsMap[itemKey] != nil {
                // Item with same name and store already exists - skip
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
        
        // Save all imported items
        do {
            try viewContext.save()
            if importedCount > 0 {
                print("Import complete: \(importedCount) new items")
            }
        } catch {
            print("Error importing items: \(error)")
        }
    }
    
    /// Import items for a specific category
    /// Only imports items from stores selected by the user
    func importItemsForCategory(_ category: Category) -> Int {
        // Ensure stores exist
        storeService.createDefaultStores()
        
        // Get selected store names from UserDefaults (set during store selection)
        let selectedStoreNames = UserDefaults.standard.stringArray(forKey: "selectedStoreNames") ?? []
        let selectedStoreNamesSet = Set(selectedStoreNames.map { $0.lowercased() })
        
        // If no stores are selected, import all items (backward compatibility)
        let filterByStore = !selectedStoreNames.isEmpty
        
        // Fetch all stores to map names to entities
        let allStores = storeService.fetchAllStores()
        var storeMap: [String: Store] = [:]
        for store in allStores {
            storeMap[store.name.lowercased()] = store
        }
        
        // Fetch existing items in this category
        // Use composite key: name + store ID (allows same item from different stores)
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        let existingItems = try? viewContext.fetch(fetchRequest)
        var existingItemsMap: [String: GroceryItem] = [:]
        for item in existingItems ?? [] {
            let storeId = item.firstPreferredStore?.id.uuidString ?? "nostore"
            let compositeKey = "\(item.name.lowercased()):\(storeId)"
            existingItemsMap[compositeKey] = item
        }
        
        // Get items for this category from ImportData
        let categoryName = category.name.lowercased()
        let commonItems = ImportData.commonItems
        
        // Filter items for this category
        let categoryItems = commonItems.filter { $0.category.lowercased() == categoryName }
        
        var importedCount = 0
        
        for itemData in categoryItems {
            // Filter by selected stores if store selection has been made
            if filterByStore {
                if let storeName = itemData.store {
                    // Item has a store - only import if store is selected
                    if !selectedStoreNamesSet.contains(storeName.lowercased()) {
                        continue // Skip items from unselected stores
                    }
                } else {
                    // Item has no store - skip if filtering is enabled
                    continue
                }
            }
            // Find store if specified
            var store: Store? = nil
            if let storeName = itemData.store {
                store = storeMap[storeName.lowercased()]
                if store == nil {
                    print("Warning: Store '\(storeName)' not found for item '\(itemData.name)', skipping store assignment")
                }
            }
            
            // Check if item already exists (using composite key: name + store)
            // This allows the same item from different stores to exist as separate items
            let storeId = store?.id.uuidString ?? "nostore"
            let itemKey = "\(itemData.name.lowercased()):\(storeId)"
            if existingItemsMap[itemKey] != nil {
                // Item with same name and store already exists - skip
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
        
        // Save imported items
        if importedCount > 0 {
            do {
                try viewContext.save()
            } catch {
                print("Error importing items for category: \(error)")
            }
        }
        
        return importedCount
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

