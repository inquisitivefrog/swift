//
//  MasterListImportService.swift
//  GroceryApp
//
//  Service for bulk importing common grocery items
//

import Foundation
import CoreData

class MasterListImportService {
    private let viewContext: NSManagedObjectContext
    private let categoryService: CategoryService
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.categoryService = CategoryService(context: context)
    }
    
    /// Import common grocery items organized by category
    func importCommonItems() {
        // Ensure categories exist first
        categoryService.createDefaultCategories()
        
        // Fetch all categories to map names to entities
        let allCategories = categoryService.fetchAllCategories()
        var categoryMap: [String: Category] = [:]
        for category in allCategories {
            categoryMap[category.name.lowercased()] = category
        }
        
        // Common grocery items by category
        let commonItems: [(name: String, category: String, store: String?)] = [
            // Produce
            ("Apples", "Produce", nil),
            ("Bananas", "Produce", nil),
            ("Oranges", "Produce", nil),
            ("Grapes", "Produce", nil),
            ("Strawberries", "Produce", nil),
            ("Blueberries", "Produce", nil),
            ("Lettuce", "Produce", nil),
            ("Spinach", "Produce", nil),
            ("Tomatoes", "Produce", nil),
            ("Carrots", "Produce", nil),
            ("Broccoli", "Produce", nil),
            ("Onions", "Produce", nil),
            ("Potatoes", "Produce", nil),
            ("Bell Peppers", "Produce", nil),
            ("Cucumbers", "Produce", nil),
            ("Avocados", "Produce", nil),
            ("Mushrooms", "Produce", nil),
            ("Celery", "Produce", nil),
            
            // Dairy
            ("Milk", "Dairy", nil),
            ("Eggs", "Dairy", nil),
            ("Butter", "Dairy", nil),
            ("Cheese", "Dairy", nil),
            ("Yogurt", "Dairy", nil),
            ("Sour Cream", "Dairy", nil),
            ("Cream Cheese", "Dairy", nil),
            ("Cottage Cheese", "Dairy", nil),
            ("Heavy Cream", "Dairy", nil),
            ("Half and Half", "Dairy", nil),
            
            // Meat & Seafood
            ("Chicken Breast", "Meat & Seafood", nil),
            ("Ground Beef", "Meat & Seafood", nil),
            ("Salmon", "Meat & Seafood", nil),
            ("Shrimp", "Meat & Seafood", nil),
            ("Pork Chops", "Meat & Seafood", nil),
            ("Bacon", "Meat & Seafood", nil),
            ("Turkey", "Meat & Seafood", nil),
            ("Tuna", "Meat & Seafood", nil),
            
            // Deli
            ("Deli Turkey", "Deli", nil),
            ("Deli Ham", "Deli", nil),
            ("Deli Roast Beef", "Deli", nil),
            ("Deli Cheese", "Deli", nil),
            
            // Bakery
            ("Bread", "Bakery", nil),
            ("Bagels", "Bakery", nil),
            ("English Muffins", "Bakery", nil),
            ("Tortillas", "Bakery", nil),
            ("Croissants", "Bakery", nil),
            
            // Pantry Staples
            ("Rice", "Pantry Staples", nil),
            ("Pasta", "Pantry Staples", nil),
            ("Flour", "Pantry Staples", nil),
            ("Sugar", "Pantry Staples", nil),
            ("Salt", "Pantry Staples", nil),
            ("Pepper", "Pantry Staples", nil),
            ("Olive Oil", "Pantry Staples", nil),
            ("Vegetable Oil", "Pantry Staples", nil),
            ("Vinegar", "Pantry Staples", nil),
            ("Honey", "Pantry Staples", nil),
            
            // Canned Goods
            ("Canned Tomatoes", "Canned Goods", nil),
            ("Canned Beans", "Canned Goods", nil),
            ("Canned Corn", "Canned Goods", nil),
            ("Canned Tuna", "Canned Goods", nil),
            ("Chicken Broth", "Canned Goods", nil),
            ("Beef Broth", "Canned Goods", nil),
            
            // Beverages
            ("Water", "Beverages", nil),
            ("Orange Juice", "Beverages", nil),
            ("Apple Juice", "Beverages", nil),
            ("Coffee", "Beverages", nil),
            ("Tea", "Beverages", nil),
            ("Soda", "Beverages", nil),
            ("Beer", "Beverages", nil),
            ("Wine", "Beverages", nil),
            
            // Snacks
            ("Chips", "Snacks", nil),
            ("Crackers", "Snacks", nil),
            ("Nuts", "Snacks", nil),
            ("Popcorn", "Snacks", nil),
            ("Cookies", "Snacks", nil),
            ("Granola Bars", "Snacks", nil),
            
            // Condiments & Spices
            ("Ketchup", "Condiments & Spices", nil),
            ("Mustard", "Condiments & Spices", nil),
            ("Mayonnaise", "Condiments & Spices", nil),
            ("Soy Sauce", "Condiments & Spices", nil),
            ("Garlic Powder", "Condiments & Spices", nil),
            ("Onion Powder", "Condiments & Spices", nil),
            ("Paprika", "Condiments & Spices", nil),
            ("Cumin", "Condiments & Spices", nil),
            ("Oregano", "Condiments & Spices", nil),
            ("Basil", "Condiments & Spices", nil),
            
            // Breakfast Items
            ("Cereal", "Breakfast Items", nil),
            ("Oatmeal", "Breakfast Items", nil),
            ("Pancake Mix", "Breakfast Items", nil),
            ("Syrup", "Breakfast Items", nil),
            ("Jam", "Breakfast Items", nil),
            ("Peanut Butter", "Breakfast Items", nil),
            
            // Baking Supplies
            ("Baking Soda", "Baking Supplies", nil),
            ("Baking Powder", "Baking Supplies", nil),
            ("Vanilla Extract", "Baking Supplies", nil),
            ("Chocolate Chips", "Baking Supplies", nil),
            ("Brown Sugar", "Baking Supplies", nil),
            ("Powdered Sugar", "Baking Supplies", nil),
            
            // Frozen
            ("Frozen Vegetables", "Frozen", nil),
            ("Frozen Fruit", "Frozen", nil),
            ("Ice Cream", "Frozen", nil),
            ("Frozen Pizza", "Frozen", nil),
            ("Frozen Burritos", "Frozen", nil),
        ]
        
        // Check if items already exist
        let existingItems = try? viewContext.fetch(GroceryItem.fetchRequest())
        let existingNames = Set(existingItems?.map { $0.name.lowercased() } ?? [])
        
        var importedCount = 0
        for itemData in commonItems {
            // Skip if item already exists
            if existingNames.contains(itemData.name.lowercased()) {
                continue
            }
            
            // Find category
            guard let category = categoryMap[itemData.category.lowercased()] else {
                print("Warning: Category '\(itemData.category)' not found, skipping '\(itemData.name)'")
                continue
            }
            
            // Create item
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemData.name
            item.category = category
            item.isInMasterList = true
            item.createdDate = Date()
            
            importedCount += 1
        }
        
        // Save all imported items
        do {
            try viewContext.save()
            print("Successfully imported \(importedCount) items")
        } catch {
            print("Error importing items: \(error)")
        }
    }
    
    /// Import items for a specific category
    func importItemsForCategory(_ category: Category) -> Int {
        // Fetch existing items in this category to prevent duplicates
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        let existingItems = try? viewContext.fetch(fetchRequest)
        let existingNames = Set(existingItems?.map { $0.name.lowercased() } ?? [])
        
        // Get items for this category from the common items list
        let categoryName = category.name.lowercased()
        let commonItems: [(name: String, category: String, store: String?)] = [
            // Produce
            ("Apples", "Produce", nil), ("Bananas", "Produce", nil), ("Oranges", "Produce", nil),
            ("Grapes", "Produce", nil), ("Strawberries", "Produce", nil), ("Blueberries", "Produce", nil),
            ("Lettuce", "Produce", nil), ("Spinach", "Produce", nil), ("Tomatoes", "Produce", nil),
            ("Carrots", "Produce", nil), ("Broccoli", "Produce", nil), ("Onions", "Produce", nil),
            ("Potatoes", "Produce", nil), ("Bell Peppers", "Produce", nil), ("Cucumbers", "Produce", nil),
            ("Avocados", "Produce", nil), ("Mushrooms", "Produce", nil), ("Celery", "Produce", nil),
            
            // Dairy
            ("Milk", "Dairy", nil), ("Eggs", "Dairy", nil), ("Butter", "Dairy", nil),
            ("Cheese", "Dairy", nil), ("Yogurt", "Dairy", nil), ("Sour Cream", "Dairy", nil),
            ("Cream Cheese", "Dairy", nil), ("Cottage Cheese", "Dairy", nil), ("Heavy Cream", "Dairy", nil),
            ("Half and Half", "Dairy", nil),
            
            // Meat & Seafood
            ("Chicken Breast", "Meat & Seafood", nil), ("Ground Beef", "Meat & Seafood", nil),
            ("Salmon", "Meat & Seafood", nil), ("Shrimp", "Meat & Seafood", nil),
            ("Pork Chops", "Meat & Seafood", nil), ("Bacon", "Meat & Seafood", nil),
            ("Turkey", "Meat & Seafood", nil), ("Tuna", "Meat & Seafood", nil),
            
            // Deli
            ("Deli Turkey", "Deli", nil), ("Deli Ham", "Deli", nil),
            ("Deli Roast Beef", "Deli", nil), ("Deli Cheese", "Deli", nil),
            
            // Bakery
            ("Bread", "Bakery", nil), ("Bagels", "Bakery", nil), ("English Muffins", "Bakery", nil),
            ("Tortillas", "Bakery", nil), ("Croissants", "Bakery", nil),
            
            // Pantry Staples
            ("Rice", "Pantry Staples", nil), ("Pasta", "Pantry Staples", nil),
            ("Flour", "Pantry Staples", nil), ("Sugar", "Pantry Staples", nil),
            ("Salt", "Pantry Staples", nil), ("Pepper", "Pantry Staples", nil),
            ("Olive Oil", "Pantry Staples", nil), ("Vegetable Oil", "Pantry Staples", nil),
            ("Vinegar", "Pantry Staples", nil), ("Honey", "Pantry Staples", nil),
            
            // Canned Goods
            ("Canned Tomatoes", "Canned Goods", nil), ("Canned Beans", "Canned Goods", nil),
            ("Canned Corn", "Canned Goods", nil), ("Canned Tuna", "Canned Goods", nil),
            ("Chicken Broth", "Canned Goods", nil), ("Beef Broth", "Canned Goods", nil),
            
            // Beverages
            ("Water", "Beverages", nil), ("Orange Juice", "Beverages", nil),
            ("Apple Juice", "Beverages", nil), ("Coffee", "Beverages", nil),
            ("Tea", "Beverages", nil), ("Soda", "Beverages", nil),
            ("Beer", "Beverages", nil), ("Wine", "Beverages", nil),
            
            // Snacks
            ("Chips", "Snacks", nil), ("Crackers", "Snacks", nil), ("Nuts", "Snacks", nil),
            ("Popcorn", "Snacks", nil), ("Cookies", "Snacks", nil), ("Granola Bars", "Snacks", nil),
            
            // Condiments & Spices
            ("Ketchup", "Condiments & Spices", nil), ("Mustard", "Condiments & Spices", nil),
            ("Mayonnaise", "Condiments & Spices", nil), ("Soy Sauce", "Condiments & Spices", nil),
            ("Garlic Powder", "Condiments & Spices", nil), ("Onion Powder", "Condiments & Spices", nil),
            ("Paprika", "Condiments & Spices", nil), ("Cumin", "Condiments & Spices", nil),
            ("Oregano", "Condiments & Spices", nil), ("Basil", "Condiments & Spices", nil),
            
            // Breakfast Items
            ("Cereal", "Breakfast Items", nil), ("Oatmeal", "Breakfast Items", nil),
            ("Pancake Mix", "Breakfast Items", nil), ("Syrup", "Breakfast Items", nil),
            ("Jam", "Breakfast Items", nil), ("Peanut Butter", "Breakfast Items", nil),
            
            // Baking Supplies
            ("Baking Soda", "Baking Supplies", nil), ("Baking Powder", "Baking Supplies", nil),
            ("Vanilla Extract", "Baking Supplies", nil), ("Chocolate Chips", "Baking Supplies", nil),
            ("Brown Sugar", "Baking Supplies", nil), ("Powdered Sugar", "Baking Supplies", nil),
            
            // Frozen
            ("Frozen Vegetables", "Frozen", nil), ("Frozen Fruit", "Frozen", nil),
            ("Ice Cream", "Frozen", nil), ("Frozen Pizza", "Frozen", nil),
            ("Frozen Burritos", "Frozen", nil),
        ]
        
        // Filter items for this category
        let categoryItems = commonItems.filter { $0.category.lowercased() == categoryName }
        
        var importedCount = 0
        for itemData in categoryItems {
            // Skip if item already exists
            if existingNames.contains(itemData.name.lowercased()) {
                continue
            }
            
            // Create item
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemData.name
            item.category = category
            item.isInMasterList = true
            item.createdDate = Date()
            
            importedCount += 1
        }
        
        // Save imported items
        if importedCount > 0 {
            do {
                try viewContext.save()
                print("Successfully imported \(importedCount) items for category '\(category.name)'")
            } catch {
                print("Error importing items for category: \(error)")
            }
        }
        
        return importedCount
    }
    
    /// Clear all items from master list (use with caution!)
    func clearAllItems() {
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        
        do {
            let items = try viewContext.fetch(fetchRequest)
            for item in items {
                viewContext.delete(item)
            }
            try viewContext.save()
            print("Cleared all items from master list")
        } catch {
            print("Error clearing items: \(error)")
        }
    }
}

