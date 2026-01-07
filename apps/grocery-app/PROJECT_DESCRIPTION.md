# Grocery List Mobile Application

## Project Overview

A native iOS mobile application for managing grocery shopping lists on iPhone. The app allows users to create and manage a master list of grocery items, select items for shopping trips, and check off items as they are found and purchased.

## Target Platform

- **Device**: iPhone only
- **iOS Version**: iOS 17.0+ (to be confirmed based on deployment target)
- **Development Environment**: Xcode with SwiftUI and Core Data

## Core Features

### 1. Master Grocery List
- **Purpose**: Maintain a comprehensive list of all grocery items the user might purchase
- **Functionality**:
  - Add new items to the master list
  - Edit existing items
  - Delete items from the master list
  - View all items in the master list
  - Organize items by category (Produce, Dairy, Meat, etc.)
  - Visual category icons using SF Symbols

### 2. Shopping List (Active List)
- **Purpose**: Create a list of items to purchase on a specific shopping trip
- **Functionality**:
  - Select items from the master list to add to the shopping list
  - Add custom items directly to the shopping list (optionally add to master list)
  - Remove items from the shopping list
  - Reorder items in the shopping list
  - Associate shopping list with store(s) (Safeway, Whole Foods, Trader Joe's, etc.)
  - Support single-store or multi-store shopping trips
  - Group items by store in shopping list

### 3. Item Status Management
- **Purpose**: Track the status of items during shopping
- **Functionality**:
  - **Unchecked**: Item not yet found/selected (default state)
  - **Checked**: Item has been found and selected for purchase
  - Visual indication of checked/unchecked status
  - Ability to toggle check status

### 5. Store Management
- **Purpose**: Organize shopping by store location
- **Functionality**:
  - Create and manage multiple stores (Safeway, Whole Foods, Trader Joe's, Sprouts, Ranch 99, etc.)
  - Associate items with preferred stores
  - Create store-specific shopping lists
  - Support multi-store shopping trips
  - Store icons and visual identification

### 6. Data Persistence
- **Storage**: Core Data (local storage on iPhone)
- **Backup**: Automatic iCloud backup via iPhone backup (no iCloud sync needed)
- **Data Model**: 
  - Master list items (persistent)
  - Shopping list items (can be cleared after shopping)
  - Store entities (persistent)
  - Item metadata (name, category, category icon, preferred store, etc.)
  - Category system with visual icons (SF Symbols)

## Technical Architecture

### Technology Stack
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Development Tool**: Xcode
- **Language**: Swift 6.1+

### Project Structure
```
grocery-app/
├── GroceryShopping/
│   ├── GroceryShoppingApp.swift      # App entry point
│   ├── ContentView.swift              # Main view
│   ├── Models/
│   │   ├── GroceryItem.swift          # Core Data model
│   │   ├── ShoppingListItem.swift     # Shopping list item model
│   │   └── Store.swift                # Store model
│   ├── Views/
│   │   ├── MasterListView.swift       # Master list view
│   │   ├── ShoppingListView.swift     # Active shopping list view
│   │   ├── AddItemView.swift          # Add item view
│   │   ├── ItemDetailView.swift       # Item detail/edit view
│   │   ├── StoreListView.swift        # Store management view
│   │   └── AddStoreView.swift         # Add/edit store view
│   ├── ViewModels/
│   │   ├── MasterListViewModel.swift  # Master list view model
│   │   └── ShoppingListViewModel.swift # Shopping list view model
│   ├── Services/
│   │   ├── DataManager.swift          # Core Data manager
│   │   └── PersistenceController.swift # Core Data stack
│   └── Resources/
│       ├── Assets.xcassets            # App icons, images
│       └── GroceryShopping.xcdatamodeld # Core Data model file
├── PROJECT_DESCRIPTION.md             # This file
└── README.md                          # Project documentation
```

## Data Model

### Core Data Entities

#### GroceryItem
- `id`: UUID (primary key)
- `name`: String (item name)
- `category`: String? (optional category: Produce, Dairy, Meat & Seafood, etc.)
- `categoryIcon`: String? (SF Symbol name for category icon, e.g., "leaf.fill")
- `preferredStore`: Store? (optional relationship to preferred store)
- `isInMasterList`: Bool (true if in master list)
- `createdDate`: Date
- `lastUsedDate`: Date? (last time item was added to shopping list)

#### Store
- `id`: UUID (primary key)
- `name`: String (store name, e.g., "Safeway", "Whole Foods")
- `iconName`: String? (SF Symbol name for store icon, e.g., "storefront.fill")
- `color`: String? (hex color code for store branding, optional)
- `isFavorite`: Bool (mark frequently used stores)
- `createdDate`: Date
- `lastUsedDate`: Date? (last time store was used)
- `shoppingListItems`: Relationship (one-to-many with ShoppingListItem)

#### ShoppingListItem
- `id`: UUID (primary key)
- `groceryItem`: Relationship to GroceryItem
- `store`: Store? (which store to buy this item from)
- `isChecked`: Bool (found/selected status)
- `addedDate`: Date (when added to shopping list)
- `checkedDate`: Date? (when item was checked off)
- `quantity`: Int? (optional quantity)
- `notes`: String? (optional notes)

## User Interface Design

### Main Views

1. **Tab View** (Main Navigation)
   - Master List Tab
   - Shopping List Tab
   - Stores Tab (optional, or accessible from settings)

2. **Master List View**
   - List of all grocery items
   - Search/filter functionality
   - Add button (floating action button or toolbar)
   - Swipe actions: Edit, Delete
   - Tap to add to shopping list

3. **Shopping List View**
   - List of items for current shopping trip
   - Store selector/picker (single store or multi-store mode)
   - Items grouped by store (if multi-store)
   - Store badge/icon on each item
   - Checkbox for each item (unchecked/checked)
   - Visual distinction for checked items (strikethrough, grayed out)
   - Add button to add items from master list or create new
   - Clear/Reset button to uncheck all items
   - Option to clear completed items
   - Filter by store (if multi-store)

4. **Add/Edit Item View**
   - Text field for item name
   - Category picker with icons (Produce, Dairy, Meat, Bakery, Canned Goods, Packaged Goods, Frozen, Beverages, Pantry Staples, Snacks, Personal Care, Household, Other)
   - Visual category icons using SF Symbols
   - Preferred store picker (optional)
   - Save/Cancel buttons
   - Option to add to master list when creating from shopping list

5. **Store Management View**
   - List of all stores
   - Add new store button
   - Edit/delete stores
   - Favorite toggle
   - Store icons and colors
   - Usage statistics

6. **Add/Edit Store View**
   - Store name text field
   - Icon picker (SF Symbols)
   - Color picker (optional)
   - Favorite toggle
   - Save/Cancel buttons

## User Workflows

### Adding Items to Master List
1. Navigate to Master List tab
2. Tap "Add" button
3. Enter item name (and optionally category)
4. Save item

### Creating a Shopping List
1. Navigate to Shopping List tab
2. Select store(s) for this shopping trip (optional)
3. Tap "Add Items" button
4. Select items from master list (multi-select)
   - Items can be filtered by preferred store
5. Items are added to shopping list in unchecked state
6. Each item can be assigned to a specific store (if multi-store trip)

### Shopping Workflow
1. Open Shopping List view
2. As items are found, tap checkbox to mark as checked
3. Checked items are visually distinguished (strikethrough, grayed)
4. Continue until all items are checked or shopping is complete

### Post-Shopping
1. Option to clear all checked items from shopping list
2. Option to reset all items to unchecked for next trip
3. Master list remains intact

## Design Considerations

### User Experience
- Simple, intuitive interface
- Quick access to check/uncheck items
- Visual feedback for item status
- Easy navigation between master list and shopping list

### Performance
- Efficient Core Data queries
- Lazy loading for large lists
- Smooth scrolling performance

### Data Management
- Local-only storage (no cloud sync)
- Automatic backup via iPhone iCloud backup
- Efficient Core Data model
- Data persistence across app launches

## Development Phases

### Phase 1: Core Setup
- [x] Create Xcode project with SwiftUI and Core Data
- [ ] Rename project from GroceryApp to GroceryShopping
- [ ] Set up Core Data model
- [ ] Create basic app structure
- [ ] Implement data persistence layer

### Phase 2: Master List
- [ ] Create master list view
- [ ] Implement add item functionality
- [ ] Implement edit/delete functionality
- [ ] Add search/filter capability

### Phase 3: Shopping List
- [ ] Create shopping list view
- [ ] Implement item selection from master list
- [ ] Implement check/uncheck functionality
- [ ] Add visual indicators for checked items

### Phase 4: Categories & Organization
- [ ] Implement category system (enum or string-based)
- [ ] Add category icons using SF Symbols
- [ ] Category picker in Add/Edit Item view
- [ ] Display category icons in list views
- [ ] Filter/group by category (optional)

### Phase 5: Store Management
- [ ] Create Store Core Data entity
- [ ] Store management view (list, add, edit, delete)
- [ ] Pre-populate common stores (Safeway, Whole Foods, Trader Joe's, etc.)
- [ ] Store icons using SF Symbols
- [ ] Associate items with preferred stores
- [ ] Store selection in shopping list
- [ ] Group shopping list items by store
- [ ] Multi-store shopping trip support

### Phase 5: Polish
- [ ] Improve UI/UX
- [ ] Add quantity support
- [ ] Testing and bug fixes

## Future Enhancements (Optional)

- Quantity tracking
- Price tracking
- Shopping history
- Favorite/frequently used items
- Custom item ordering
- Dark mode support (automatic with SF Symbols)
- Haptic feedback for checking items
- Category-based sorting in shopping list
- Store layout organization (group by store section)

## Notes

- This is a single-user, single-device application
- No cloud sync or sharing functionality required
- Data is stored locally using Core Data
- iPhone backup to iCloud will automatically backup the app data
- Focus on simplicity and ease of use for grocery shopping

