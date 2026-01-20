//
//  StoreService.swift
//  GroceryApp
//
//  Service for managing Store entities
//

import Foundation
import CoreData

class StoreService {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    /// Create default stores - adds any missing stores from the default list
    func createDefaultStores() {
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        
        do {
            let existingStores = try viewContext.fetch(fetchRequest)
            let existingStoreNames = Set(existingStores.map { $0.name.lowercased() })
            
            // Default stores to create
            let defaultStores: [(name: String, icon: String)] = [
                ("Andronico's", "storefront.fill"),
                ("Whole Foods", "storefront.fill"),
                ("Trader Joe's", "storefront.fill"),
                ("Sprouts", "storefront.fill"),
                ("Safeway", "storefront.fill"),
                ("Monterey Market", "storefront.fill"),
                ("Ranch 99", "storefront.fill"),
                ("Costco", "storefront.fill"),
                ("Berkeley Bowl", "storefront.fill"),
                ("Target", "target"),
                ("Walmart", "storefront.fill")
            ]
            
            // Only create stores that don't already exist
            var createdCount = 0
            for storeData in defaultStores {
                if !existingStoreNames.contains(storeData.name.lowercased()) {
                    let store = Store(context: viewContext)
                    store.id = UUID()
                    store.name = storeData.name
                    store.iconName = storeData.icon
                    store.isFavorite = false
                    store.createdDate = Date()
                    createdCount += 1
                }
            }
            
            if createdCount > 0 {
                try viewContext.save()
            }
        } catch {
            print("Error creating default stores: \(error)")
        }
    }
    
    /// Create a new store
    func createStore(name: String, iconName: String? = nil, color: String? = nil) -> Store {
        let store = Store(context: viewContext)
        store.id = UUID()
        store.name = name
        store.iconName = iconName ?? Store.defaultIconName
        store.color = color
        store.isFavorite = false
        store.createdDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error creating store: \(error)")
        }
        
        return store
    }
    
    /// Delete a store
    func deleteStore(_ store: Store) {
        viewContext.delete(store)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting store: \(error)")
        }
    }
    
    /// Fetch all stores
    func fetchAllStores() -> [Store] {
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Store.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching stores: \(error)")
            return []
        }
    }
    
    /// Fetch favorite stores
    func fetchFavoriteStores() -> [Store] {
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Store.name, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching favorite stores: \(error)")
            return []
        }
    }
}

