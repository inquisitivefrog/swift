//
//  CategoryService.swift
//  GroceryApp
//
//  Service for managing Category entities
//

import Foundation
import CoreData

class CategoryService {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    /// Create default categories if none exist
    func createDefaultCategories() {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let existingCategories = try viewContext.fetch(fetchRequest)
            if !existingCategories.isEmpty {
                return // Categories already exist
            }
            
            // Default categories from the enum
            let defaultCategories: [(name: String, icon: String)] = [
                ("Produce", "leaf.fill"),
                ("Dairy", "drop.fill"),
                ("Meat & Seafood", "fish.fill"),
                ("Deli", "fork.knife"),
                ("Bakery", "birthday.cake.fill"),
                ("Pantry Staples", "cabinet.fill"),
                ("Canned Goods", "cylinder.fill"),
                ("Beverages", "cup.and.saucer.fill"),
                ("Snacks", "circle.grid.hex.fill"),
                ("Condiments & Spices", "sparkles"),
                ("Breakfast Items", "sunrise.fill"),
                ("Baking Supplies", "flame.fill"),
                ("Frozen", "snowflake"),
                ("Other", "questionmark.circle.fill")
            ]
            
            for categoryData in defaultCategories {
                let category = Category(context: viewContext)
                category.id = UUID()
                category.name = categoryData.name
                category.iconName = categoryData.icon
                category.isDefault = true
                category.createdDate = Date()
            }
            
            try viewContext.save()
        } catch {
            print("Error creating default categories: \(error)")
        }
    }
    
    /// Create a new category
    func createCategory(name: String, iconName: String? = nil) -> Category {
        let category = Category(context: viewContext)
        category.id = UUID()
        category.name = name
        category.iconName = iconName ?? Category.defaultIconName
        category.isDefault = false
        category.createdDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error creating category: \(error)")
        }
        
        return category
    }
    
    /// Delete a category (only if it has no items, or reassign items first)
    func deleteCategory(_ category: Category, reassignItemsTo: Category? = nil) throws {
        // Check if category has items
        if let items = category.groceryItems as? Set<GroceryItem>, !items.isEmpty {
            if let targetCategory = reassignItemsTo {
                // Reassign items to target category
                for item in items {
                    item.category = targetCategory
                }
            } else {
                throw CategoryError.categoryHasItems
            }
        }
        
        viewContext.delete(category)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting category: \(error)")
            throw error
        }
    }
    
    /// Fetch all categories
    func fetchAllCategories() -> [Category] {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    /// Get item count for a category
    func getItemCount(for category: Category) -> Int {
        guard let items = category.groceryItems as? Set<GroceryItem> else { return 0 }
        return items.count
    }
}

enum CategoryError: LocalizedError {
    case categoryHasItems
    
    var errorDescription: String? {
        switch self {
        case .categoryHasItems:
            return "Cannot delete category that contains items. Please reassign items first."
        }
    }
}

