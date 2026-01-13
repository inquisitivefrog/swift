# Import Data Guide

## Overview

The import data is stored in `GroceryApp/GroceryApp/Services/ImportData.swift`. This file contains a list of common grocery items that can be imported into the master list.

## How to Update the Import List

1. **Open the file**: `GroceryApp/GroceryApp/Services/ImportData.swift`

2. **Edit the `commonItems` array**: Each item is a tuple with:
   - `name`: Item name (String)
   - `category`: Category name (String) - must match an existing category
   - `store`: Store name (String?) - optional, must match an existing store name or `nil`

3. **Example entries**:
   ```swift
   ("Milk", "Dairy", "Safeway"),
   ("Eggs", "Dairy", "Whole Foods"),
   ("Butter", "Dairy", nil),  // No store assigned
   ```

## Available Categories

- Produce
- Dairy
- Meat & Seafood
- Deli
- Bakery
- Pantry Staples
- Canned Goods
- Beverages
- Snacks
- Condiments & Spices
- Breakfast Items
- Baking Supplies
- Frozen
- Other

## Available Stores

Default stores (you can add more in the app):
- Safeway
- Whole Foods
- Trader Joe's
- Sprouts
- Ranch 99
- Costco
- Target
- Walmart

## How Import Works

1. **First Import**: Creates new items with store assignments (if specified)

2. **Re-Import**: 
   - Updates existing items with store assignments from the import data
   - Adds any new items that weren't in the previous import
   - Does NOT delete items that are no longer in the import list

3. **Store Assignment**:
   - If an item in the import data has a store name, it will be assigned to that store
   - If the store name doesn't match an existing store, a warning is printed but the item is still created
   - If store is `nil`, the item is created without a store assignment

## How to Re-Import

1. Update `ImportData.swift` with your changes
2. Build and deploy the app
3. Open the Master List tab
4. Tap the import button (down arrow icon)
5. The import will:
   - Add any new items from the updated list
   - Update store assignments for existing items if the import data specifies a store

## Notes

- Store names are case-insensitive but must match exactly (e.g., "Safeway" not "safeway" in the data, though matching is case-insensitive)
- Category names must match exactly (case-insensitive)
- Items are matched by name (case-insensitive), so "Milk" and "milk" are considered the same item
- The import button is always available (no longer limited to < 50 items)
