# Core Data Model Setup Guide

## Important: Xcode Configuration Required

The Swift files for the Core Data entities have been created, but you need to configure the Core Data model in Xcode to match them.

## Steps to Configure Core Data Model

### 1. Open the Core Data Model File

In Xcode, navigate to:
```
GroceryApp/GroceryApp/GroceryApp.xcdatamodeld
```

Double-click `GroceryApp.xcdatamodel` to open it in the Core Data Model Editor.

### 2. Delete the Default "Item" Entity

- Select the "Item" entity in the editor
- Press Delete to remove it

### 3. Create the Three Entities

Create the following three entities with their attributes and relationships:

#### Entity 1: GroceryItem

**Attributes:**
- `id` - UUID (not optional)
- `name` - String (not optional)
- `category` - String (optional)
- `categoryIcon` - String (optional)
- `isInMasterList` - Boolean (not optional, default: true)
- `createdDate` - Date (not optional)
- `lastUsedDate` - Date (optional)

**Relationships:**
- `preferredStore` - To One → Store (optional)
- `shoppingListItems` - To Many → ShoppingListItem (optional)

**Codegen:** Class Definition

#### Entity 2: ShoppingListItem

**Attributes:**
- `id` - UUID (not optional)
- `isChecked` - Boolean (not optional, default: false)
- `addedDate` - Date (not optional)
- `checkedDate` - Date (optional)
- `quantity` - Integer 32 (not optional, default: 1)
- `notes` - String (optional)

**Relationships:**
- `groceryItem` - To One → GroceryItem (not optional, delete rule: Nullify)
- `store` - To One → Store (optional)

**Codegen:** Class Definition

#### Entity 3: Store

**Attributes:**
- `id` - UUID (not optional)
- `name` - String (not optional)
- `iconName` - String (optional)
- `color` - String (optional)
- `isFavorite` - Boolean (not optional, default: false)
- `createdDate` - Date (not optional)
- `lastUsedDate` - Date (optional)

**Relationships:**
- `shoppingListItems` - To Many → ShoppingListItem (optional)

**Codegen:** Class Definition

### 4. Update Persistence.swift Model Name

The Persistence.swift file currently references "GroceryApp" as the model name. If you renamed the model file, update this line:

```swift
container = NSPersistentContainer(name: "GroceryApp")
```

Change "GroceryApp" to match your actual .xcdatamodeld file name.

### 5. Verify Code Generation

For each entity, make sure:
- **Codegen** is set to **"Class Definition"**
- This will generate the base NSManagedObject classes
- Our custom extensions (in the +CoreDataProperties.swift files) will add the properties

### 6. Build and Test

After configuring the Core Data model:
1. Clean build folder (Shift+Cmd+K)
2. Build (Cmd+B)
3. Run the app in the simulator

## Troubleshooting

### If you get "Entity not found" errors:
- Make sure entity names match exactly: `GroceryItem`, `ShoppingListItem`, `Store`
- Check that Codegen is set to "Class Definition"
- Clean build folder and rebuild

### If relationships don't work:
- Verify relationship names match the Swift code
- Check delete rules are set correctly
- Ensure inverse relationships are set

### If the app crashes on launch:
- Check that the model name in Persistence.swift matches your .xcdatamodeld file name
- Verify all required attributes are marked as "not optional" where needed

## Next Steps

Once the Core Data model is configured:
1. The app should build and run
2. Default stores will be created on first launch
3. You can start adding items to the master list
4. Add items to shopping lists and check them off

