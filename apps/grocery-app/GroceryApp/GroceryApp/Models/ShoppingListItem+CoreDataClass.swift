//
//  ShoppingListItem+CoreDataClass.swift
//  GroceryApp
//
//  Core Data entity for ShoppingListItem
//

import Foundation
import CoreData

@objc(ShoppingListItem)
public class ShoppingListItem: NSManagedObject {
    
    /// Toggle the checked status
    func toggleChecked() {
        isChecked.toggle()
        if isChecked {
            checkedDate = Date()
        } else {
            checkedDate = nil
        }
    }
    
    /// Mark as checked
    func markAsChecked() {
        isChecked = true
        checkedDate = Date()
    }
    
    /// Mark as unchecked
    func markAsUnchecked() {
        isChecked = false
        checkedDate = nil
    }
}

