//
//  ShoppingListItem+CoreDataProperties.swift
//  GroceryApp
//
//  Core Data properties for ShoppingListItem entity
//

import Foundation
import CoreData

extension ShoppingListItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingListItem> {
        return NSFetchRequest<ShoppingListItem>(entityName: "ShoppingListItem")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var isChecked: Bool
    @NSManaged public var addedDate: Date
    @NSManaged public var checkedDate: Date?
    @NSManaged public var quantity: Int32
    @NSManaged public var notes: String?
    @NSManaged public var groceryItem: GroceryItem
    @NSManaged public var store: Store?
}

