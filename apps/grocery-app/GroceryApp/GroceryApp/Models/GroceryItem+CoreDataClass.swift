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
}

// MARK: - Identifiable Conformance
extension GroceryItem: Identifiable {
    // Uses the 'id' property from Core Data as the identifier
}

