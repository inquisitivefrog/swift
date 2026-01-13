//
//  Category+CoreDataClass.swift
//  GroceryApp
//
//  Core Data entity for Category
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {
    
    /// Default category icon if none is set
    static let defaultIconName = "questionmark.circle.fill"
    
    /// Get the icon name, or return default if nil
    var displayIconName: String {
        return iconName ?? Category.defaultIconName
    }
}

// MARK: - Identifiable Conformance
extension Category: Identifiable {
    // Uses the 'id' property from Core Data as the identifier
}

// Note: Category already conforms to Hashable via NSObject (NSManagedObject's parent class)
// Core Data does not allow overriding isEqual: or hash on NSManagedObject subclasses
// SwiftUI navigation will work with the default NSObject hash/equality implementation

