//
//  GroceryItem+CoreDataProperties.swift
//  GroceryApp
//
//  Core Data properties for GroceryItem entity
//

import Foundation
import CoreData

extension GroceryItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: Category?
    @NSManaged public var isInMasterList: Bool
    @NSManaged public var createdDate: Date
    @NSManaged public var lastUsedDate: Date?
    @NSManaged public var preferredStore: Store?
    @NSManaged public var shoppingListItems: NSSet?
    
    // MARK: - Convenience Methods
    
    /// Get shopping list items as an array
    var shoppingListItemsArray: [ShoppingListItem] {
        let set = shoppingListItems as? Set<ShoppingListItem> ?? []
        return set.sorted { $0.addedDate < $1.addedDate }
    }
}

// MARK: Generated accessors for shoppingListItems
extension GroceryItem {
    
    @objc(addShoppingListItemsObject:)
    @NSManaged public func addToShoppingListItems(_ value: ShoppingListItem)
    
    @objc(removeShoppingListItemsObject:)
    @NSManaged public func removeFromShoppingListItems(_ value: ShoppingListItem)
    
    @objc(addShoppingListItems:)
    @NSManaged public func addToShoppingListItems(_ values: NSSet)
    
    @objc(removeShoppingListItems:)
    @NSManaged public func removeFromShoppingListItems(_ values: NSSet)
}

