# Test Data Generator Guide

The `TestDataGenerator` class provides reusable test data creation methods for both unit tests and UI tests.

## Usage in Unit Tests

### Basic Setup

```swift
import XCTest
import CoreData
@testable import GroceryApp

class MyTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var testData: TestDataGenerator!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.test
        viewContext = persistenceController.container.viewContext
        testData = TestDataGenerator(context: viewContext)
    }
    
    override func tearDownWithError() throws {
        testData.clearAll()
        persistenceController = nil
        viewContext = nil
        testData = nil
    }
}
```

### Creating Individual Test Objects

```swift
// Create a single store
let store = testData.createStore(name: "Berkeley Bowl", isFavorite: true)

// Create a category
let category = testData.createCategory(name: "Produce", iconName: "leaf.fill")

// Create a grocery item
let item = testData.createGroceryItem(
    name: "Apples",
    category: category,
    store: store
)

// Create a shopping list item
let shoppingItem = testData.createShoppingListItem(
    groceryItem: item,
    isChecked: false
)

try viewContext.save()
```

### Using Pre-built Scenarios

```swift
// Create a complete shopping scenario with stores, categories, items, and shopping list
let scenario = testData.createShoppingListScenario()
// scenario.stores - array of stores
// scenario.categories - array of categories
// scenario.items - array of grocery items
// scenario.shoppingItems - array of shopping list items

// Create a scenario where all shopping is complete
let completedScenario = testData.createCompletedShoppingListScenario()

// Create a scenario organized by stores (for Shop By Stores testing)
let storeBasedScenario = testData.createStoreBasedShoppingScenario()
```

### Example Test Using Test Data Generator

```swift
func testShopByStoresShowsCorrectStores() throws {
    // Set up test data
    let scenario = testData.createStoreBasedShoppingScenario()
    
    // Your test logic here
    // e.g., verify stores are displayed correctly
    XCTAssertEqual(scenario.stores.count, 4)
    XCTAssertEqual(scenario.shoppingItems.count, 8)
}
```

## Usage in UI Tests

UI tests run in a separate process and cannot directly access Core Data. You have a few options:

### Option 1: Use App's Import Functionality

1. Ensure your test data is in `ImportData.swift`
2. In your UI test, navigate to FoodStuffs tab
3. Tap "Import Data" button
4. Test the resulting UI

### Option 2: Launch Arguments (Requires App Support)

If you modify `GroceryAppApp.swift` to support launch arguments, you can:

```swift
let app = XCUIApplication()
app.launchWithScenario(.storeBasedShopping)
// App will set up test data based on scenario
```

### Option 3: Manual Test Scenarios

Document specific test scenarios that require manual setup:
- "Empty shopping list" - Clear all data
- "Single store with items" - Import data, add items to one store
- "Multiple stores" - Import data, distribute items across stores
- "Completed shopping" - Check all items

## Available Test Data Methods

### Stores
- `createStore(name:iconName:isFavorite:)` - Create a single store
- `createDefaultStores()` - Create 4 default stores (Berkeley Bowl, Whole Foods, Trader Joe's, Safeway)

### Categories
- `createCategory(name:iconName:isDefault:)` - Create a single category
- `createDefaultCategories()` - Create 5 default categories (Produce, Dairy, Meat, Bakery, Frozen)

### Grocery Items
- `createGroceryItem(name:category:store:isInMasterList:)` - Create a single grocery item
- `createSampleGroceryItems(categories:stores:)` - Create 9 sample items across categories

### Shopping List Items
- `createShoppingListItem(groceryItem:store:isChecked:quantity:)` - Create a shopping list item
- `createShoppingListScenario()` - Complete scenario with mixed checked/unchecked items
- `createCompletedShoppingListScenario()` - All items checked
- `createStoreBasedShoppingScenario()` - Items organized by specific stores

### Cleanup
- `clearAll()` - Remove all test data

## Best Practices

1. **Always clean up**: Call `testData.clearAll()` in `tearDown()` or at the start of each test
2. **Use scenarios for complex tests**: Pre-built scenarios save time and ensure consistency
3. **Create specific data when needed**: For edge cases, create custom test data
4. **Save context**: Remember to call `try viewContext.save()` after creating data
5. **Reuse across tests**: Create test data once in `setUp()` if multiple tests need the same data

## Example: Testing Shop By Stores Empty State

```swift
func testShopByStoresShowsEmptyState() throws {
    // Start with empty data (already cleared in setUp)
    // Navigate to Shop By Stores tab
    // Verify empty state message appears
}

func testShopByStoresShowsStores() throws {
    // Create store-based scenario
    let scenario = testData.createStoreBasedShoppingScenario()
    
    // Navigate to Shop By Stores tab
    // Verify stores are displayed
    // Verify store counts are correct
}

func testShopByStoresShowsEmptyAfterCompleting() throws {
    // Create scenario with unchecked items
    let scenario = testData.createShoppingListScenario()
    
    // Check all items (simulate shopping)
    for item in scenario.shoppingItems {
        item.isChecked = true
    }
    try viewContext.save()
    
    // Navigate to Shop By Stores tab
    // Verify empty state appears
}
```
