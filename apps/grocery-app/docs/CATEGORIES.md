# Grocery Item Categories

## Category System

Items in the grocery list can be organized by category to help with shopping organization and visual identification.

## Recommended Categories

### 1. Produce Fruit
- **Icon**: SF Symbol `leaf.fill`
- **Description**: Fresh fruits
- **Examples**: Apples, bananas, oranges, grapes, strawberries

### 2. Produce Vegetables
- **Icon**: SF Symbol `carrot.fill`
- **Description**: Fresh vegetables
- **Examples**: Lettuce, tomatoes, carrots, broccoli, spinach

### 3. Dairy
- **Icon**: SF Symbol `drop.fill` or `milk.fill`
- **Description**: Milk, cheese, yogurt, butter
- **Examples**: Milk, cheese, yogurt, butter, cream

### 4. Meats
- **Icon**: SF Symbol `fish.fill`
- **Description**: Fresh meat and poultry
- **Examples**: Chicken, beef, pork, lamb, turkey

### 5. Seafood
- **Icon**: SF Symbol `fish.fill`
- **Description**: Fresh fish and seafood
- **Examples**: Salmon, shrimp, cod, crab, mussels

### 6. Deli
- **Icon**: SF Symbol `fork.knife`
- **Description**: Prepared foods, deli items, refrigerated specialty items
- **Examples**: Sushi, soup, sandwiches, tofu, pickles, tamales

### 7. Bakery
- **Icon**: SF Symbol `birthday.cake.fill` or `circle.grid.hex.fill`
- **Description**: Bread, pastries, baked goods
- **Examples**: Bread, bagels, muffins, rolls

### 8. Pantry Staples
- **Icon**: SF Symbol `cabinet.fill`
- **Description**: Cooking essentials, grains, pasta
- **Examples**: Rice, pasta, flour, sugar, oil

### 9. Canned Goods
- **Icon**: SF Symbol `cylinder.fill`
- **Description**: Canned foods and jarred items
- **Examples**: Canned soup, canned vegetables, canned fruit, jarred sauces

### 10. Packaged Goods
- **Icon**: SF Symbol `shippingbox.fill`
- **Description**: Boxed and packaged items
- **Examples**: Broth, boxed macaroni & cheese, stuffing mix, cup of noodles

### 11. Frozen
- **Icon**: SF Symbol `snowflake` or `snowflake.circle.fill`
- **Description**: Frozen foods
- **Examples**: Frozen vegetables, ice cream, frozen meals

### 12. Beverages
- **Icon**: SF Symbol `cup.and.saucer.fill` or `drop.fill`
- **Description**: Drinks and beverages
- **Examples**: Juice, soda, water, coffee, tea

### 13. Snacks
- **Icon**: SF Symbol `circle.grid.hex.fill` or `square.stack.fill`
- **Description**: Chips, cookies, candy
- **Examples**: Chips, cookies, crackers, nuts

### 14. Condiments
- **Icon**: SF Symbol `sparkles`
- **Description**: Sauces, spreads, and condiments
- **Examples**: Ketchup, mustard, mayonnaise, soy sauce

### 15. Spices
- **Icon**: SF Symbol `sparkles`
- **Description**: Herbs, spices, and seasonings
- **Examples**: Salt, pepper, oregano, basil, curry

### 16. Breakfast Items
- **Icon**: SF Symbol `sunrise.fill`
- **Description**: Breakfast foods and ingredients
- **Examples**: Cereal, oatmeal, pancake mix, maple syrup, jam

### 17. Baking Supplies
- **Icon**: SF Symbol `flame.fill`
- **Description**: Baking ingredients and supplies
- **Examples**: Baking soda, baking powder, vanilla extract, chocolate chips

### 18. Personal Care
- **Icon**: SF Symbol `person.fill` or `hand.raised.fill`
- **Description**: Toiletries and personal items
- **Examples**: Shampoo, soap, toothpaste, toilet paper

### 19. Household
- **Icon**: SF Symbol `house.fill` or `wrench.and.screwdriver.fill`
- **Description**: Cleaning supplies, household items
- **Examples**: Detergent, paper towels, trash bags

### 20. Other
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
    case produceFruit = "Produce Fruit"
    case produceVegetables = "Produce Vegetables"
    case dairy = "Dairy"
    case meats = "Meats"
    case seafood = "Seafood"
    case deli = "Deli"
    case bakery = "Bakery"
    case pantry = "Pantry Staples"
    case canned = "Canned Goods"
    case packaged = "Packaged Goods"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case condiments = "Condiments"
    case spices = "Spices"
    case breakfast = "Breakfast Items"
    case baking = "Baking Supplies"
    case personalCare = "Personal Care"
    case household = "Household"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .produceFruit: return "leaf.fill"
        case .produceVegetables: return "carrot.fill"
        case .dairy: return "drop.fill"
        case .meats: return "fish.fill"
        case .seafood: return "fish.fill"
        case .deli: return "fork.knife"
        case .bakery: return "birthday.cake.fill"
        case .pantry: return "cabinet.fill"
        case .canned: return "cylinder.fill"
        case .packaged: return "shippingbox.fill"
        case .frozen: return "snowflake"
        case .beverages: return "cup.and.saucer.fill"
        case .snacks: return "circle.grid.hex.fill"
        case .condiments: return "sparkles"
        case .spices: return "sparkles"
        case .breakfast: return "sunrise.fill"
        case .baking: return "flame.fill"
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

