# Store Categories by Store Type

## Approach
Work backwards from store types to determine appropriate categories. This ensures categories align with where items are actually purchased.

## Store Types

### 1. Supermarket / Grocery Store
**Primary Focus:** Food and beverages for home consumption

**Common Categories:**
- Produce (fresh fruits and vegetables)
- Dairy (milk, cheese, yogurt, butter)
- Meat & Seafood (fresh meat, poultry, fish)
- Deli (prepared foods, sliced meats, cheeses)
- Bakery (bread, pastries, cakes)
- Frozen Foods (frozen vegetables, ice cream, frozen meals)
- Beverages (soda, juice, water, coffee, tea)
- Pantry Staples (canned goods, pasta, rice, flour, sugar)
- Snacks (chips, crackers, cookies, candy)
- Condiments & Spices (ketchup, mustard, salt, pepper, spices)
- Breakfast Items (cereal, oatmeal, breakfast bars)
- Baking Supplies (flour, sugar, baking powder, vanilla extract)

### 2. Department Store / Wholesale Club
**Primary Focus:** Household items, personal care, cleaning supplies, some food items

**Common Categories:**
- Household Cleaning (detergent, cleaning sprays, paper towels, trash bags)
- Personal Care (shampoo, soap, toothpaste, deodorant)
- Toiletries (toilet paper, tissues, cotton swabs)
- Health & Wellness (vitamins, supplements, first aid)
- Baby Care (diapers, baby wipes, formula)
- Pet Supplies (pet food, litter, toys)
- Office Supplies (paper, pens, notebooks)
- Home Goods (light bulbs, batteries, storage containers)
- Clothing & Apparel (basic clothing items)
- Seasonal Items (holiday decorations, seasonal goods)

### 3. Pharmacy / Drug Store
**Primary Focus:** Medications, health products, personal care

**Common Categories:**
- Prescription Medications (pharmacy prescriptions)
- Over-the-Counter Medications (pain relievers, cold medicine, antacids)
- Health & Wellness (vitamins, supplements, protein bars)
- Personal Care (shampoo, soap, toothpaste, deodorant)
- First Aid (bandages, antiseptic, gauze)
- Medical Supplies (thermometers, blood pressure monitors)
- Beauty Products (makeup, skincare, hair care)
- Baby Care (diapers, baby wipes, formula)
- Reading Glasses / Eye Care
- Foot Care (insoles, foot powder)

## Implementation Strategy

### Option 1: Store-Specific Categories
- Each store type has its own set of categories
- When adding an item, categories shown depend on selected store
- Pros: Very organized, clear separation
- Cons: More complex UI, items can't span multiple store types easily

### Option 2: Unified Categories with Store Preferences
- All categories available, but items have preferred store
- Categories are tagged with "common at" store types
- Pros: Flexible, simple UI
- Cons: Less structured

### Option 3: Category Groups
- Categories grouped by store type (Supermarket, Department Store, Pharmacy)
- Items can belong to one category group
- Pros: Clear organization, still flexible
- Cons: Some items might fit multiple groups

## Recommendation
**Option 3: Category Groups** - This provides clear organization while maintaining flexibility. Users can:
- See categories organized by store type
- Add items to appropriate category group
- Still have preferred store for each item
- Expand categories within each group as needed

## Next Steps
1. Define category groups (Supermarket, Department Store, Pharmacy)
2. List categories within each group
3. Update GroceryCategory enum to support groups
4. Update UI to show categories by group
5. Allow adding custom categories within groups

