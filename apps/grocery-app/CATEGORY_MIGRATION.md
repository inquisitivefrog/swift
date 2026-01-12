# Category Migration Guide

## Overview
Converting categories from a hardcoded enum to dynamic Core Data entities (like Stores).

## Step 1: Create Category Entity in Core Data

In Xcode, open `GroceryApp.xcdatamodeld`:

1. **Add Category Entity:**
   - Click "+" to add new entity
   - Name it `Category`
   - Set Codegen to "Manual/None" (like Store, GroceryItem, ShoppingListItem)

2. **Add Attributes:**
   - `id` (UUID) - Required
   - `name` (String) - Required
   - `iconName` (String) - Optional (defaults to SF Symbol)
   - `createdDate` (Date) - Optional
   - `isDefault` (Boolean) - Optional (marks pre-populated categories)

3. **Add Relationship:**
   - `groceryItems` (To Many) - Inverse relationship to GroceryItem.category

## Step 2: Update GroceryItem Entity

1. **Remove old attribute:**
   - Delete `category` (String) attribute
   - Delete `categoryIcon` (String) attribute

2. **Add relationship:**
   - `category` (To One) - Relationship to Category entity
   - Set inverse to `groceryItems`

## Step 3: Migration Notes

- Existing items with category strings will need to be migrated
- Default categories will be created on first launch
- The enum `GroceryCategory` will be kept for default category definitions only

