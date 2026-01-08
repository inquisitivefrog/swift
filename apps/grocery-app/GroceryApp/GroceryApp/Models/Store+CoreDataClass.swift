//
//  Store+CoreDataClass.swift
//  GroceryApp
//
//  Core Data entity for Store
//

import Foundation
import CoreData

@objc(Store)
public class Store: NSManagedObject {
    
    /// Default store icon if none is set
    static let defaultIconName = "storefront.fill"
    
    /// Get the icon name, or return default if nil
    var displayIconName: String {
        return iconName ?? Store.defaultIconName
    }
    
    /// Convenience property for favorite status
    var isFavoriteStore: Bool {
        get { isFavorite }
        set { isFavorite = newValue }
    }
}

// MARK: - Identifiable Conformance
extension Store: Identifiable {
    // Uses the 'id' property from Core Data as the identifier
}

