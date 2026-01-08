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
    
    /// Get category enum from string
    var categoryEnum: GroceryCategory? {
        guard let categoryString = category else { return nil }
        return GroceryCategory(rawValue: categoryString)
    }
    
    /// Set category from enum
    func setCategory(_ category: GroceryCategory?) {
        self.category = category?.rawValue
        self.categoryIcon = category?.iconName
    }
    
    /// Get category icon name
    var displayCategoryIcon: String {
        if let icon = categoryIcon, !icon.isEmpty {
            return icon
        }
        return categoryEnum?.iconName ?? GroceryCategory.other.iconName
    }
}

// MARK: - Identifiable Conformance
extension GroceryItem: Identifiable {
    // Uses the 'id' property from Core Data as the identifier
}

