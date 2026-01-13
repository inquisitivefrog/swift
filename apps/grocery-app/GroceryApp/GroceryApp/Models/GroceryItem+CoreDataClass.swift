//
//  GroceryItem+CoreDataClass.swift
//  GroceryApp
//
//  Core Data entity for GroceryItem
//

import Foundation
import CoreData

@objc(GroceryItem)
public class GroceryItem: NSManagedObject {
    
    /// Get category icon name
    /// Uses Category relationship (new model)
    var displayCategoryIcon: String {
        // Category is now a Category entity (relationship)
        if let categoryEntity = category {
            return categoryEntity.displayIconName
        }
        // Final fallback
        return Category.defaultIconName
    }
    
    /// Get the first preferred store (since preferredStore is a to-many relationship)
    /// Returns nil if no stores are set
    var firstPreferredStore: Store? {
        // preferredStore is actually an NSSet due to to-many relationship
        // Access it safely and return the first store
        if let stores = value(forKey: "preferredStore") as? NSSet,
           let store = stores.anyObject() as? Store {
            return store
        }
        return nil
    }
    
    /// Set the preferred store (replaces any existing stores)
    /// Since preferredStore is a to-many relationship, we need to handle it as a set
    func setPreferredStore(_ store: Store?) {
        if let store = store {
            // Set as a single-item set
            setValue(NSSet(object: store), forKey: "preferredStore")
        } else {
            // Clear the set
            setValue(NSSet(), forKey: "preferredStore")
        }
    }
}

// MARK: - Identifiable Conformance
extension GroceryItem: Identifiable {
    // Uses the 'id' property from Core Data as the identifier
}

