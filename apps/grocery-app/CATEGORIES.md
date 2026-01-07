# Grocery Item Categories

## Category System

Items in the grocery list can be organized by category to help with shopping organization and visual identification.

## Recommended Categories

### 1. Produce
- **Icon**: SF Symbol `leaf.fill` or `carrot.fill`
- **Description**: Fresh fruits and vegetables
- **Examples**: Apples, bananas, lettuce, tomatoes, carrots

### 2. Dairy
- **Icon**: SF Symbol `drop.fill` or `milk.fill`
- **Description**: Milk, cheese, yogurt, butter
- **Examples**: Milk, cheese, yogurt, butter, cream

### 3. Meat & Seafood
- **Icon**: SF Symbol `fish.fill` or `fork.knife`
- **Description**: Fresh meat, poultry, fish
- **Examples**: Chicken, beef, salmon, turkey

### 4. Bakery
- **Icon**: SF Symbol `birthday.cake.fill` or `circle.grid.hex.fill`
- **Description**: Bread, pastries, baked goods
- **Examples**: Bread, bagels, muffins, rolls

### 5. Canned Goods
- **Icon**: SF Symbol `cylinder.fill` or `can.fill`
- **Description**: Canned foods and preserves
- **Examples**: Canned soup, canned vegetables, canned fruit

### 6. Packaged Goods
- **Icon**: SF Symbol `square.fill` or `shippingbox.fill`
- **Description**: Boxed and packaged items
- **Examples**: Pasta, cereal, crackers, snacks

### 7. Frozen
- **Icon**: SF Symbol `snowflake` or `snowflake.circle.fill`
- **Description**: Frozen foods
- **Examples**: Frozen vegetables, ice cream, frozen meals

### 8. Beverages
- **Icon**: SF Symbol `cup.and.saucer.fill` or `drop.fill`
- **Description**: Drinks and beverages
- **Examples**: Juice, soda, water, coffee, tea

### 9. Pantry Staples
- **Icon**: SF Symbol `cabinet.fill` or `shelves.fill`
- **Description**: Cooking essentials, spices, condiments
- **Examples**: Flour, sugar, salt, oil, spices

### 10. Snacks
- **Icon**: SF Symbol `circle.grid.hex.fill` or `square.stack.fill`
- **Description**: Chips, cookies, candy
- **Examples**: Chips, cookies, crackers, nuts

### 11. Personal Care
- **Icon**: SF Symbol `person.fill` or `hand.raised.fill`
- **Description**: Toiletries and personal items
- **Examples**: Shampoo, soap, toothpaste, toilet paper

### 12. Household
- **Icon**: SF Symbol `house.fill` or `wrench.and.screwdriver.fill`
- **Description**: Cleaning supplies, household items
- **Examples**: Detergent, paper towels, trash bags

### 13. Other
- **Icon**: SF Symbol `questionmark.circle.fill` or `ellipsis.circle.fill`
- **Description**: Items that don't fit other categories
- **Examples**: Miscellaneous items

## Implementation Options

### Option 1: SF Symbols (Recommended)
- **Pros**: 
  - Built into iOS, no image files needed
  - Automatically adapts to light/dark mode
  - Scales perfectly at any size
  - Consistent with iOS design language
- **Cons**: Limited to Apple's icon set
- **Usage**: Use `Image(systemName: "leaf.fill")` in SwiftUI

### Option 2: Custom Image Assets
- **Pros**: 
  - Complete design freedom
  - Can match specific brand or style
- **Cons**: 
  - Need to create/find images
  - Need multiple sizes (@1x, @2x, @3x)
  - More storage space
  - Need to handle dark mode manually
- **Usage**: Add images to Assets.xcassets, use `Image("category-name")`

### Option 3: Hybrid Approach
- Use SF Symbols for most categories
- Use custom images for specific categories if needed
- Best of both worlds

## Recommended Approach

**Use SF Symbols** - They're perfect for this use case:
- No image files to manage
- Native iOS look and feel
- Automatic dark mode support
- Easy to implement
- Professional appearance

## Category Data Model

Each grocery item can have:
- `category`: String? (optional category name)
- `categoryIcon`: String? (SF Symbol name, e.g., "leaf.fill")

Or we can create a Category enum:
```swift
enum GroceryCategory: String, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case bakery = "Bakery"
    case canned = "Canned Goods"
    case packaged = "Packaged Goods"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case pantry = "Pantry Staples"
    case snacks = "Snacks"
    case personalCare = "Personal Care"
    case household = "Household"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .canned: return "cylinder.fill"
        case .packaged: return "square.fill"
        case .frozen: return "snowflake"
        case .beverages: return "cup.and.saucer.fill"
        case .pantry: return "cabinet.fill"
        case .snacks: return "circle.grid.hex.fill"
        case .personalCare: return "person.fill"
        case .household: return "house.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}
```

## UI Display

Categories can be displayed as:
- Icons in list items
- Filter buttons
- Section headers when grouping by category
- Color coding (optional)
- Category picker when adding/editing items

