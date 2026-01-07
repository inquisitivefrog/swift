//
//  Store+CoreDataProperties.swift
//  GroceryApp
//
//  Core Data properties for Store entity
//

import Foundation
import CoreData

extension Store {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Store> {
        return NSFetchRequest<Store>(entityName: "Store")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var iconName: String?
    @NSManaged public var color: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdDate: Date
    @NSManaged public var lastUsedDate: Date?
    @NSManaged public var shoppingListItems: NSSet?
    
    // MARK: - Convenience Methods
    
    /// Get shopping list items as an array
    var shoppingListItemsArray: [ShoppingListItem] {
        let set = shoppingListItems as? Set<ShoppingListItem> ?? []
        return set.sorted { $0.addedDate < $1.addedDate }
    }
}

// MARK: Generated accessors for shoppingListItems
extension Store {
    
    @objc(addShoppingListItemsObject:)
    @NSManaged public func addToShoppingListItems(_ value: ShoppingListItem)
    
    @objc(removeShoppingListItemsObject:)
    @NSManaged public func removeFromShoppingListItems(_ value: ShoppingListItem)
    
    @objc(addShoppingListItems:)
    @NSManaged public func addToShoppingListItems(_ values: NSSet)
    
    @objc(removeShoppingListItems:)
    @NSManaged public func removeFromShoppingListItems(_ values: NSSet)
}

