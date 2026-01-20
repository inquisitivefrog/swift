# Store Management System

## Overview

The grocery app supports shopping from multiple stores, allowing users to organize their shopping lists by store and track which items are typically purchased at which stores.

## Store Features

### Core Functionality
- **Multiple Stores**: Support for any number of stores (Safeway, Whole Foods, Trader Joe's, Sprouts, Ranch 99, etc.)
- **Store-Specific Lists**: Create shopping lists for specific stores
- **Item-Store Association**: Items in master list can be associated with preferred stores
- **Store Icons**: Visual identification of stores (optional custom icons or SF Symbols)

## Store Data Model

### Store Entity (Core Data)
- `id`: UUID (primary key)
- `name`: String (store name, e.g., "Safeway", "Whole Foods")
- `iconName`: String? (SF Symbol name or custom icon, optional)
- `color`: String? (hex color code for store branding, optional)
- `createdDate`: Date
- `lastUsedDate`: Date? (last time store was used in a shopping list)
- `isFavorite`: Bool (mark frequently used stores)

### Updated GroceryItem Entity
- Add relationship: `preferredStores`: Set<Store> (items can be associated with multiple stores)
- Or simpler: `preferredStore`: Store? (single preferred store per item)

### Updated ShoppingListItem Entity
- Add: `store`: Store? (which store this item is being purchased from)
- This allows a shopping list to be store-specific

## Store Management

### Default Stores
Common stores to pre-populate:
1. **Andronico's**
   - Icon: `storefront.fill`
   - Color: (default)

2. **Whole Foods**
   - Icon: `storefront.fill`
   - Color: (default)

3. **Trader Joe's**
   - Icon: `storefront.fill`
   - Color: (default)

4. **Sprouts**
   - Icon: `storefront.fill`
   - Color: (default)

5. **Safeway**
   - Icon: `storefront.fill`
   - Color: (default)

6. **Lucky's**
   - Icon: `storefront.fill`
   - Color: (default)

7. **Monterey Market**
   - Icon: `storefront.fill`
   - Color: (default)

8. **Ranch 99 (99 Ranch Market)**
   - Icon: `storefront.fill`
   - Color: (default)

9. **Costco**
   - Icon: `storefront.fill`
   - Color: (default)

10. **Berkeley Bowl**
   - Icon: `storefront.fill`
   - Color: (default)

11. **Target**
   - Icon: `target`
   - Color: (default)

12. **Walmart**
   - Icon: `storefront.fill`
   - Color: (default)

13. **Custom Store**
   - Users can add their own stores
   - Icon: `plus.circle.fill` or `storefront.fill`

## User Workflows

### Workflow 1: Store-Specific Shopping List
1. User creates a new shopping list
2. Selects a store (e.g., "Safeway")
3. Adds items to the list
4. Items are filtered/suggested based on store preference
5. Shopping list shows only items for that store

### Workflow 2: Multi-Store Shopping Trip
1. User creates shopping list
2. For each item, selects which store to buy it from
3. Shopping list groups items by store
4. User can check off items as they shop at each store

### Workflow 3: Store Preference Learning
1. When adding items to master list, user can set preferred store
2. When creating shopping list, items are suggested based on store
3. App learns user's shopping patterns

## UI Design Considerations

### Store Selection
- **Store Picker**: When creating shopping list, select store(s)
- **Store Filter**: Filter master list by store
- **Store Badge**: Show store icon/name on shopping list items
- **Store Grouping**: Group shopping list items by store

### Store Management View
- List of all stores
- Add new store
- Edit store (name, icon, color)
- Delete store
- Mark favorite stores
- Reorder stores (most used first)

### Shopping List Display Options
1. **Single Store Mode**: Show only items for one store
2. **Multi-Store Mode**: Show all items, grouped by store
3. **Store Tabs**: Separate tabs/sections for each store

## Implementation Options

### Option 1: Simple Store Association
- Shopping list has one store
- Items in shopping list are for that store
- Simple, straightforward

### Option 2: Multi-Store Shopping List
- Shopping list can have multiple stores
- Each item in shopping list has a store
- More flexible, handles multi-store trips

### Option 3: Store Preferences
- Master list items have preferred stores
- When creating shopping list, items are suggested based on store
- More intelligent, learns user preferences

### Recommended: Hybrid Approach
- Shopping list has a primary store (optional)
- Each shopping list item can have its own store
- Master list items can have preferred stores (optional)
- Supports both single-store and multi-store shopping trips

## Store Icons

### Using SF Symbols (Recommended)
- `storefront.fill` - Generic store
- `cart.fill` - Shopping cart
- `building.2.fill` - Building/store
- `map.fill` - Location-based
- `tag.fill` - Store tag

### Custom Icons (Optional)
- Store logos (if legally allowed)
- Custom designed icons
- Requires image assets

## Data Model Updates

### Core Data Schema

#### Store Entity
```
Store:
  - id: UUID
  - name: String
  - iconName: String?
  - color: String?
  - isFavorite: Bool
  - createdDate: Date
  - lastUsedDate: Date?
  - shoppingListItems: Relationship (one-to-many with ShoppingListItem)
```

#### Updated GroceryItem
```
GroceryItem:
  - ... (existing fields)
  - preferredStore: Store? (optional relationship)
```

#### Updated ShoppingListItem
```
ShoppingListItem:
  - ... (existing fields)
  - store: Store? (which store to buy from)
```

## Store Management Features

### Store List View
- Display all stores
- Add new store button
- Edit/delete stores
- Favorite toggle
- Usage statistics (how many items, last used)

### Add/Edit Store View
- Store name text field
- Icon picker (SF Symbols)
- Color picker (optional)
- Save/Cancel buttons

### Store Selection in Shopping List
- Store picker when creating list
- Store badge on each item
- Filter by store
- Group by store

## Future Enhancements

- Store locations (address, map integration)
- Store hours
- Price comparison across stores
- Store-specific deals/coupons
- Shopping route optimization (if multiple stores)
- Store loyalty cards integration

