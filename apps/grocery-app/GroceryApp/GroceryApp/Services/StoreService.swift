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
    
    /// Create default stores if none exist
    func createDefaultStores() {
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        
        do {
            let existingStores = try viewContext.fetch(fetchRequest)
            if !existingStores.isEmpty {
                return // Stores already exist
            }
            
            // Default stores to create
            let defaultStores: [(name: String, icon: String)] = [
                ("Safeway", "storefront.fill"),
                ("Whole Foods", "storefront.fill"),
                ("Trader Joe's", "storefront.fill"),
                ("Sprouts", "storefront.fill"),
                ("Ranch 99", "storefront.fill"),
                ("Costco", "storefront.fill"),
                ("Target", "target"),
                ("Walmart", "storefront.fill")
            ]
            
            for storeData in defaultStores {
                let store = Store(context: viewContext)
                store.id = UUID()
                store.name = storeData.name
                store.iconName = storeData.icon
                store.isFavorite = false
                store.createdDate = Date()
            }
            
            try viewContext.save()
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

