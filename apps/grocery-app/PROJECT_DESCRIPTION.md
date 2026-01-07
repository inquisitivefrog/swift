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

### 2. Shopping List (Active List)
- **Purpose**: Create a list of items to purchase on a specific shopping trip
- **Functionality**:
  - Select items from the master list to add to the shopping list
  - Add custom items directly to the shopping list (optionally add to master list)
  - Remove items from the shopping list
  - Reorder items in the shopping list

### 3. Item Status Management
- **Purpose**: Track the status of items during shopping
- **Functionality**:
  - **Unchecked**: Item not yet found/selected (default state)
  - **Checked**: Item has been found and selected for purchase
  - Visual indication of checked/unchecked status
  - Ability to toggle check status

### 4. Data Persistence
- **Storage**: Core Data (local storage on iPhone)
- **Backup**: Automatic iCloud backup via iPhone backup (no iCloud sync needed)
- **Data Model**: 
  - Master list items (persistent)
  - Shopping list items (can be cleared after shopping)
  - Item metadata (name, category, etc.)

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
│   │   └── ShoppingList.swift         # Shopping list model
│   ├── Views/
│   │   ├── MasterListView.swift       # Master list view
│   │   ├── ShoppingListView.swift     # Active shopping list view
│   │   ├── AddItemView.swift          # Add item view
│   │   └── ItemDetailView.swift       # Item detail/edit view
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
- `category`: String? (optional category: produce, dairy, meat, etc.)
- `isInMasterList`: Bool (true if in master list)
- `createdDate`: Date
- `lastUsedDate`: Date? (last time item was added to shopping list)

#### ShoppingListItem
- `id`: UUID (primary key)
- `groceryItem`: Relationship to GroceryItem
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

2. **Master List View**
   - List of all grocery items
   - Search/filter functionality
   - Add button (floating action button or toolbar)
   - Swipe actions: Edit, Delete
   - Tap to add to shopping list

3. **Shopping List View**
   - List of items for current shopping trip
   - Checkbox for each item (unchecked/checked)
   - Visual distinction for checked items (strikethrough, grayed out)
   - Add button to add items from master list or create new
   - Clear/Reset button to uncheck all items
   - Option to clear completed items

4. **Add/Edit Item View**
   - Text field for item name
   - Optional category picker
   - Save/Cancel buttons
   - Option to add to master list when creating from shopping list

## User Workflows

### Adding Items to Master List
1. Navigate to Master List tab
2. Tap "Add" button
3. Enter item name (and optionally category)
4. Save item

### Creating a Shopping List
1. Navigate to Shopping List tab
2. Tap "Add Items" button
3. Select items from master list (multi-select)
4. Items are added to shopping list in unchecked state

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

### Phase 4: Polish
- [ ] Improve UI/UX
- [ ] Add categories and organization
- [ ] Add quantity support
- [ ] Testing and bug fixes

## Future Enhancements (Optional)

- Item categories with icons
- Quantity tracking
- Price tracking
- Shopping history
- Favorite/frequently used items
- Custom item ordering
- Dark mode support
- Haptic feedback for checking items

## Notes

- This is a single-user, single-device application
- No cloud sync or sharing functionality required
- Data is stored locally using Core Data
- iPhone backup to iCloud will automatically backup the app data
- Focus on simplicity and ease of use for grocery shopping

