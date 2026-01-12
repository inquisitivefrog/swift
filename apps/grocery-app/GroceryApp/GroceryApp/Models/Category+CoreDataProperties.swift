//
//  Category+CoreDataProperties.swift
//  GroceryApp
//
//  Core Data properties for Category entity
//

import Foundation
import CoreData

extension Category {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var iconName: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var isDefault: Bool
    @NSManaged public var groceryItems: NSSet?
}

// MARK: Generated accessors for groceryItems
extension Category {
    
    @objc(addGroceryItemsObject:)
    @NSManaged public func addToGroceryItems(_ value: GroceryItem)
    
    @objc(removeGroceryItemsObject:)
    @NSManaged public func removeFromGroceryItems(_ value: GroceryItem)
    
    @objc(addGroceryItems:)
    @NSManaged public func addToGroceryItems(_ values: NSSet)
    
    @objc(removeGroceryItems:)
    @NSManaged public func removeFromGroceryItems(_ values: NSSet)
}

