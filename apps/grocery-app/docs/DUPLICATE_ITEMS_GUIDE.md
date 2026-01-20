# Duplicate Items from Different Stores

## Overview

The app now supports having the same grocery item from different stores as separate items in the master list. This allows users to choose where to buy items based on availability, price, or preference.

## How It Works

### Before (Old Behavior)
- Item name was the uniqueness key
- Importing "Eggs" from Costco, then "Eggs" from Whole Foods would overwrite the store assignment
- Only one "Eggs" item could exist

### After (New Behavior)
- Item name + Store is the uniqueness key
- Importing "Eggs" from Costco and "Eggs" from Whole Foods creates **two separate items**
- Both appear in the master list
- Users can add either (or both) to their shopping list

## Example in ImportData.swift

You can now add duplicate items with different stores:

```swift
static let commonItems: [(name: String, category: String, store: String?)] = [
    // Same item from different stores
    ("Eggs", "Dairy", "Costco"),
    ("Eggs", "Dairy", "Whole Foods"),
    ("Eggs", "Dairy", "Trader Joe's"),
    
    // Other items...
]
```

## User Experience

### Master List View
- Both "Eggs" items appear in the Dairy category
- Each shows its assigned store
- Users can add either to their shopping list

### Shopping List View
- If both are added, both appear in the shopping list
- Each can be checked off independently
- "Shop By Stores" tab will show both under their respective stores

### Use Cases
1. **Store-Specific Items**: "Eggs only available at Costco" vs "Regular eggs at Whole Foods"
2. **Price Comparison**: Add both to compare prices while shopping
3. **Backup Options**: If one store is out of stock, you have the other
4. **Different Brands**: "Organic Eggs (Whole Foods)" vs "Conventional Eggs (Costco)"

## Testing

The test suite has been updated to support this behavior:

- `testImportCommonItems_DoesNotDuplicateExistingItems()` - Verifies items with same name AND same store don't duplicate
- `testImportCommonItems_AllowsSameItemFromDifferentStores()` - Verifies same item from different stores creates separate items
- `testImportCommonItems_CreatesNewItemWhenStoreDiffers()` - Verifies new items are created when store differs

## Performance Considerations

- Import performance: O(n) where n is number of items (unchanged)
- Memory usage: Slightly higher due to more items, but still reasonable
- See `PerformanceTests.swift` for CPU and memory benchmarks

## Migration Notes

If you have existing data:
- Items imported before this change used name-only uniqueness
- Re-importing will create new items for different stores
- Old items without stores will remain
- You may want to clean and re-import for consistency

## Best Practices

1. **Be Specific**: Use descriptive names when items differ significantly
   - "Organic Eggs" vs "Conventional Eggs"
   - "Large Eggs" vs "Extra Large Eggs"

2. **Keep It Reasonable**: Don't create 10+ duplicates of the same item
   - 2-3 store options per item is usually sufficient

3. **User Choice**: Let users decide which version to add to their list
   - Some may prefer one store over another
   - Some may want both for comparison
