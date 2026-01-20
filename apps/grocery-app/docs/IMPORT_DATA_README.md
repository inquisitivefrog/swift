# Import Data Guide

## Overview

The import data is stored in `GroceryApp/GroceryApp/Services/ImportData.swift`. This file uses a hybrid structure with two types of items:
- **commonItems**: Items available at ALL selected stores (expanded to each selected store during import)
- **specialtyItems**: Items available only at specific stores

## Data Structure

### Common Items
Items in `commonItems` are available at ALL stores that the user has selected. During import, each common item is expanded to create a separate item for each selected store.

**Format**: `(name: String, category: String)`
- No store specified - expands to all selected stores
- Example: `("Apples", "Produce Fruit")` → Creates "Apples" for each selected store

### Specialty Items
Items in `specialtyItems` are only available at the explicitly listed stores, and only if those stores are also selected by the user.

**Format**: `(name: String, category: String, stores: [String])`
- Store names specified - only created for those stores if selected
- Example: `("Dragon Fruit", "Produce Fruit", ["Ranch 99"])` → Only creates "Dragon Fruit" if Ranch 99 is selected

## How to Update the Import List

1. **Open the file**: `GroceryApp/GroceryApp/Services/ImportData.swift`

2. **For common items** (available at all stores):
   ```swift
   ("Milk", "Dairy"),
   ("Eggs", "Dairy"),
   ("Butter", "Dairy"),
   ```

3. **For specialty items** (store-specific):
   ```swift
   ("Dragon Fruit", "Produce Fruit", ["Ranch 99"]),
   ("Cranberry Walnut Bread", "Bakery", ["Berkeley Bowl"]),
   ("Frozen Pizza Rolls", "Frozen", ["Safeway"]),
   ```

## Available Categories

- Produce Fruit
- Produce Vegetables
- Dairy
- Meats
- Seafood
- Deli
- Bakery
- Pantry Staples
- Canned Goods
- Packaged Goods
- Beverages
- Snacks
- Condiments
- Spices
- Breakfast Items
- Baking Supplies
- Frozen
- Other

## Available Stores

Default stores (you can add more in the app):
- Andronico's
- Whole Foods
- Trader Joe's
- Sprouts
- Safeway
- Lucky's
- Monterey Market
- Ranch 99
- Costco
- Berkeley Bowl
- Target
- Walmart

## How Import Works

1. **First Import**: 
   - Creates items from `commonItems` for each selected store
   - Creates items from `specialtyItems` only if the listed stores are selected
   - Items are matched by name and store (case-insensitive)

2. **Re-Import**: 
   - Adds any new items that weren't in the previous import
   - Does NOT delete items that are no longer in the import list
   - Does NOT update existing items (prevents overwriting user changes)

3. **Store Filtering**:
   - Only items from stores selected by the user are imported
   - Common items are expanded to all selected stores
   - Specialty items are only created if their listed stores are selected

## How to Re-Import

1. Update `ImportData.swift` with your changes
2. Build and deploy the app
3. Go to Settings → FoodStuffs
4. Tap the import button (down arrow icon)
5. The import will:
   - Add any new items from the updated list
   - Only import items for stores you've selected
   - Skip items that already exist (by name and store)

## Notes

- Store names in specialty items must match exactly (case-insensitive matching)
- Category names must match exactly (case-insensitive)
- Items are matched by name AND store, so "Apples" at "Safeway" and "Apples" at "Whole Foods" are different items
- The import respects user's store selections - only items for selected stores are imported
- Common items are duplicated across all selected stores to allow store-specific shopping lists
