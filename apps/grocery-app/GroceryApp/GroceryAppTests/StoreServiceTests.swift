//
//  StoreServiceTests.swift
//  GroceryAppTests
//
//  Unit tests for StoreService
//

import XCTest
import CoreData
@testable import GroceryApp

final class StoreServiceTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var storeService: StoreService!
    
    override func setUpWithError() throws {
        // Create in-memory Core Data stack for testing
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        storeService = StoreService(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        storeService = nil
    }
    
    // MARK: - createDefaultStores Tests
    
    func testCreateDefaultStores_CreatesAllDefaultStores() throws {
        // When
        storeService.createDefaultStores()
        
        // Then
        let stores = storeService.fetchAllStores()
        XCTAssertEqual(stores.count, 10, "Should create 10 default stores")
        
        let storeNames = Set(stores.map { $0.name })
        XCTAssertTrue(storeNames.contains("Andronico's"), "Should contain Andronico's")
        XCTAssertTrue(storeNames.contains("Whole Foods"), "Should contain Whole Foods")
        XCTAssertTrue(storeNames.contains("Trader Joe's"), "Should contain Trader Joe's")
        XCTAssertTrue(storeNames.contains("Sprouts"), "Should contain Sprouts")
        XCTAssertTrue(storeNames.contains("Monterey Market"), "Should contain Monterey Market")
        XCTAssertTrue(storeNames.contains("Berkeley Bowl"), "Should contain Berkeley Bowl")
    }
    
    func testCreateDefaultStores_DoesNotDuplicateExistingStores() throws {
        // Given - create a store first
        let existingStore = storeService.createStore(name: "Trader Joe's", iconName: "storefront.fill")
        try viewContext.save()
        
        // When
        storeService.createDefaultStores()
        
        // Then - should only create missing stores, not duplicate Trader Joe's
        let stores = storeService.fetchAllStores()
        let traderJoesStores = stores.filter { $0.name == "Trader Joe's" }
        XCTAssertEqual(traderJoesStores.count, 1, "Should not create duplicate Trader Joe's")
    }
    
    func testCreateDefaultStores_AddsMissingStores() throws {
        // Given - create one store
        _ = storeService.createStore(name: "Custom Store", iconName: "storefront.fill")
        try viewContext.save()
        
        // When
        storeService.createDefaultStores()
        
        // Then - should have custom store + default stores
        let stores = storeService.fetchAllStores()
        XCTAssertGreaterThan(stores.count, 1, "Should add default stores in addition to existing")
        
        let storeNames = Set(stores.map { $0.name })
        XCTAssertTrue(storeNames.contains("Custom Store"), "Should preserve existing store")
        XCTAssertTrue(storeNames.contains("Trader Joe's"), "Should add default stores")
    }
    
    // MARK: - createStore Tests
    
    func testCreateStore_CreatesStoreWithName() throws {
        // When
        let store = storeService.createStore(name: "Test Store")
        
        // Then
        XCTAssertNotNil(store.id)
        XCTAssertEqual(store.name, "Test Store")
        XCTAssertEqual(store.iconName, Store.defaultIconName)
        XCTAssertFalse(store.isFavorite)
        XCTAssertNotNil(store.createdDate)
    }
    
    func testCreateStore_CreatesStoreWithCustomIcon() throws {
        // When
        let store = storeService.createStore(name: "Test Store", iconName: "cart.fill")
        
        // Then
        XCTAssertEqual(store.iconName, "cart.fill")
    }
    
    func testCreateStore_CreatesStoreWithColor() throws {
        // When
        let store = storeService.createStore(name: "Test Store", iconName: nil, color: "#FF0000")
        
        // Then
        XCTAssertEqual(store.color, "#FF0000")
    }
    
    func testCreateStore_PersistsToContext() throws {
        // When
        _ = storeService.createStore(name: "Test Store")
        
        // Then
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Test Store")
        let stores = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(stores.count, 1)
        XCTAssertEqual(stores.first?.name, "Test Store")
    }
    
    // MARK: - deleteStore Tests
    
    func testDeleteStore_RemovesStoreFromContext() throws {
        // Given
        let store = storeService.createStore(name: "Test Store")
        try viewContext.save()
        
        // When
        storeService.deleteStore(store)
        
        // Then
        let fetchRequest: NSFetchRequest<Store> = Store.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "Test Store")
        let stores = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(stores.count, 0, "Store should be deleted")
    }
    
    // MARK: - fetchAllStores Tests
    
    func testFetchAllStores_ReturnsEmptyArrayWhenNoStores() throws {
        // When
        let stores = storeService.fetchAllStores()
        
        // Then
        XCTAssertEqual(stores.count, 0)
    }
    
    func testFetchAllStores_ReturnsAllStores() throws {
        // Given
        _ = storeService.createStore(name: "Store A")
        _ = storeService.createStore(name: "Store B")
        _ = storeService.createStore(name: "Store C")
        try viewContext.save()
        
        // When
        let stores = storeService.fetchAllStores()
        
        // Then
        XCTAssertEqual(stores.count, 3)
    }
    
    func testFetchAllStores_SortsByFavoriteThenName() throws {
        // Given
        let store1 = storeService.createStore(name: "Zebra Store")
        let store2 = storeService.createStore(name: "Alpha Store")
        store2.isFavorite = true
        let store3 = storeService.createStore(name: "Beta Store")
        try viewContext.save()
        
        // When
        let stores = storeService.fetchAllStores()
        
        // Then - favorites first, then alphabetical
        XCTAssertEqual(stores[0].name, "Alpha Store", "Favorite should be first")
        XCTAssertEqual(stores[1].name, "Beta Store")
        XCTAssertEqual(stores[2].name, "Zebra Store")
    }
    
    // MARK: - fetchFavoriteStores Tests
    
    func testFetchFavoriteStores_ReturnsOnlyFavorites() throws {
        // Given
        let favorite1 = storeService.createStore(name: "Favorite A")
        favorite1.isFavorite = true
        let favorite2 = storeService.createStore(name: "Favorite B")
        favorite2.isFavorite = true
        _ = storeService.createStore(name: "Not Favorite")
        try viewContext.save()
        
        // When
        let favorites = storeService.fetchFavoriteStores()
        
        // Then
        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.allSatisfy { $0.isFavorite })
    }
    
    func testFetchFavoriteStores_ReturnsEmptyWhenNoFavorites() throws {
        // Given
        _ = storeService.createStore(name: "Not Favorite 1")
        _ = storeService.createStore(name: "Not Favorite 2")
        try viewContext.save()
        
        // When
        let favorites = storeService.fetchFavoriteStores()
        
        // Then
        XCTAssertEqual(favorites.count, 0)
    }
}
