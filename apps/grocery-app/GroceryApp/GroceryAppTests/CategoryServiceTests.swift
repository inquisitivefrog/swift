//
//  CategoryServiceTests.swift
//  GroceryAppTests
//
//  Unit tests for CategoryService
//

import XCTest
import CoreData
@testable import GroceryApp

final class CategoryServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var categoryService: CategoryService!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        categoryService = CategoryService(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        categoryService = nil
    }
    
    // MARK: - createDefaultCategories Tests
    
    func testCreateDefaultCategories_CreatesAllDefaultCategories() throws {
        // When
        categoryService.createDefaultCategories()
        
        // Then
        let categories = categoryService.fetchAllCategories()
        XCTAssertEqual(categories.count, 18, "Should create 18 default categories")
        
        let categoryNames = Set(categories.map { $0.name })
        XCTAssertTrue(categoryNames.contains("Produce Fruit"))
        XCTAssertTrue(categoryNames.contains("Produce Vegetables"))
        XCTAssertTrue(categoryNames.contains("Dairy"))
        XCTAssertTrue(categoryNames.contains("Meats"))
        XCTAssertTrue(categoryNames.contains("Seafood"))
        XCTAssertTrue(categoryNames.contains("Condiments"))
        XCTAssertTrue(categoryNames.contains("Spices"))
        XCTAssertTrue(categoryNames.contains("Packaged Goods"))
        XCTAssertTrue(categoryNames.contains("Other"))
    }
    
    func testCreateDefaultCategories_DoesNotDuplicateExistingCategories() throws {
        // Given
        _ = categoryService.createCategory(name: "Produce Fruit", iconName: "leaf.fill")
        try viewContext.save()
        
        // When
        categoryService.createDefaultCategories()
        
        // Then
        let categories = categoryService.fetchAllCategories()
        let produceFruitCategories = categories.filter { $0.name == "Produce Fruit" }
        XCTAssertEqual(produceFruitCategories.count, 1, "Should not create duplicate Produce Fruit category")
    }
    
    func testCreateDefaultCategories_SetsIsDefaultFlag() throws {
        // When
        categoryService.createDefaultCategories()
        
        // Then
        let categories = categoryService.fetchAllCategories()
        let defaultCategories = categories.filter { $0.isDefault == true }
        XCTAssertEqual(defaultCategories.count, 18, "All default categories should be marked as default")
    }
    
    // MARK: - createCategory Tests
    
    func testCreateCategory_CreatesCategoryWithName() throws {
        // When
        let category = categoryService.createCategory(name: "Test Category")
        
        // Then
        XCTAssertNotNil(category.id)
        XCTAssertEqual(category.name, "Test Category")
        XCTAssertEqual(category.iconName, GroceryApp.Category.defaultIconName)
        XCTAssertFalse(category.isDefault)
        XCTAssertNotNil(category.createdDate)
    }
    
    func testCreateCategory_CreatesCategoryWithCustomIcon() throws {
        // When
        let category = categoryService.createCategory(name: "Test Category", iconName: "star.fill")
        
        // Then
        XCTAssertEqual(category.iconName, "star.fill")
    }
    
    func testCreateCategory_PersistsToContext() throws {
        // When
        _ = categoryService.createCategory(name: "Test Category")
        
        // Then
        let fetchRequest: NSFetchRequest<GroceryApp.Category> = GroceryApp.Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Test Category")
        let categories = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "Test Category")
    }
    
    // MARK: - deleteCategory Tests
    
    func testDeleteCategory_RemovesEmptyCategory() throws {
        // Given
        let category = categoryService.createCategory(name: "Test Category")
        try viewContext.save()
        
        // When
        try categoryService.deleteCategory(category)
        
        // Then
        let fetchRequest: NSFetchRequest<GroceryApp.Category> = GroceryApp.Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Test Category")
        let categories = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(categories.count, 0, "Category should be deleted")
    }
    
    func testDeleteCategory_ThrowsErrorWhenCategoryHasItems() throws {
        // Given
        let category = categoryService.createCategory(name: "Test Category")
        let item = GroceryItem(context: viewContext)
        item.id = UUID()
        item.name = "Test Item"
        item.category = category
        item.isInMasterList = true
        item.createdDate = Date()
        try viewContext.save()
        
        // When/Then
        XCTAssertThrowsError(try categoryService.deleteCategory(category)) { error in
            if let categoryError = error as? CategoryError {
                XCTAssertEqual(categoryError, CategoryError.categoryHasItems)
            } else {
                XCTFail("Expected CategoryError.categoryHasItems")
            }
        }
    }
    
    func testDeleteCategory_ReassignsItemsWhenTargetProvided() throws {
        // Given
        let oldCategory = categoryService.createCategory(name: "Old Category")
        let newCategory = categoryService.createCategory(name: "New Category")
        let item = GroceryItem(context: viewContext)
        item.id = UUID()
        item.name = "Test Item"
        item.category = oldCategory
        item.isInMasterList = true
        item.createdDate = Date()
        try viewContext.save()
        
        // When
        try categoryService.deleteCategory(oldCategory, reassignItemsTo: newCategory)
        
        // Then
        viewContext.refresh(item, mergeChanges: true)
        XCTAssertEqual(item.category, newCategory, "Item should be reassigned to new category")
        
        // Verify old category is deleted
        let fetchRequest: NSFetchRequest<GroceryApp.Category> = GroceryApp.Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Old Category")
        let categories = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(categories.count, 0, "Old category should be deleted")
    }
    
    // MARK: - fetchAllCategories Tests
    
    func testFetchAllCategories_ReturnsEmptyArrayWhenNoCategories() throws {
        // When
        let categories = categoryService.fetchAllCategories()
        
        // Then
        XCTAssertEqual(categories.count, 0)
    }
    
    func testFetchAllCategories_ReturnsAllCategories() throws {
        // Given
        _ = categoryService.createCategory(name: "Category A")
        _ = categoryService.createCategory(name: "Category B")
        try viewContext.save()
        
        // When
        let categories = categoryService.fetchAllCategories()
        
        // Then
        XCTAssertEqual(categories.count, 2)
    }
    
    func testFetchAllCategories_SortsByName() throws {
        // Given
        _ = categoryService.createCategory(name: "Zebra Category")
        _ = categoryService.createCategory(name: "Alpha Category")
        _ = categoryService.createCategory(name: "Beta Category")
        try viewContext.save()
        
        // When
        let categories = categoryService.fetchAllCategories()
        
        // Then
        XCTAssertEqual(categories[0].name, "Alpha Category")
        XCTAssertEqual(categories[1].name, "Beta Category")
        XCTAssertEqual(categories[2].name, "Zebra Category")
    }
    
    // MARK: - getItemCount Tests
    
    func testGetItemCount_ReturnsZeroForEmptyCategory() throws {
        // Given
        let category = categoryService.createCategory(name: "Test Category")
        
        // When
        let count = categoryService.getItemCount(for: category)
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testGetItemCount_ReturnsCorrectCount() throws {
        // Given
        let category = categoryService.createCategory(name: "Test Category")
        for i in 1...5 {
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = "Item \(i)"
            item.category = category
            item.isInMasterList = true
            item.createdDate = Date()
        }
        try viewContext.save()
        
        // When
        let count = categoryService.getItemCount(for: category)
        
        // Then
        XCTAssertEqual(count, 5)
    }
}
