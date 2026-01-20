//
//  ImportData.swift
//  GroceryApp
//
//  Import data for common grocery items
//  This file uses a hybrid structure:
//  - commonItems: Items available at ALL selected stores (most items)
//  - specialtyItems: Items available only at specific stores
//
//  Format:
//  - commonItems: (name: String, category: String) - no store, expands to all selected stores
//  - specialtyItems: (name: String, category: String, stores: [String]) - specific stores only
//

import Foundation

struct ImportData {
    /// Common grocery items available at ALL stores
    /// These items will be expanded to all selected stores during import
    static let commonItems: [(name: String, category: String)] = [
        // Produce Fruit - Common items (none - all moved to specialty items excluding Ranch 99)
        
        // Produce Vegetables - Common items (available at all stores including Ranch 99)
        ("Garlic", "Produce Vegetables"),
        
        // Dairy - Common items
        ("Whole Milk", "Dairy"),
        ("Soy Milk", "Dairy"),
        ("Oat Milk", "Dairy"),
        ("Eggs", "Dairy"),
        ("Butter", "Dairy"),
        ("Cheddar Cheese", "Dairy"),
        ("Swiss Cheese", "Dairy"),
        ("Meunster Cheese", "Dairy"),
        ("Blue Cheese", "Dairy"),
        ("Artisan Cheese", "Dairy"),
        ("Cream Cheese", "Dairy"),
        ("Cottage Cheese", "Dairy"),
        ("Shaved Parmigiano Cheese", "Dairy"),
        ("Fresh Mozzarella", "Dairy"),
        ("Fresh Ricotta", "Dairy"),
        ("Sliced Provolone", "Dairy"),
        ("Yogurt", "Dairy"),
        ("Heavy Cream", "Dairy"),
        ("Sour Cream", "Dairy"),
        ("Half and Half", "Dairy"),
        
        // Meats - Common items
        ("Chicken Breast", "Meats"),
        ("Chicken Thighs", "Meats"),
        ("Chicken Legs", "Meats"),
        ("Whole Chicken", "Meats"),
        ("Chicken Wings", "Meats"),
        ("Ground Beef", "Meats"),
        ("Beef Tri Tip Steak", "Meats"),
        ("Beef Round Roast", "Meats"),
        ("Beef Stew Meat", "Meats"),
        ("Beef Top Sirloin Steak", "Meats"),
        ("Beef Ribeye Steak", "Meats"),
        ("Pork Chops", "Meats"),
        ("Pork Ribs", "Meats"),
        ("Pork Sausage", "Meats"),
        ("Pork Bacon", "Meats"),
        ("Pork Shoulder", "Meats"),
        ("Ground Turkey", "Meats"),
        ("Leg of Lamb", "Meats"),
        ("Lamb Loin Chops", "Meats"),
        ("Rack of Lamb", "Meats"),
        ("Lamb Shank", "Meats"),
        ("Lamb Shoulder", "Meats"),
        
        // Seafood - Common items
        ("Wild caught Salmon", "Seafood"),
        ("Farm raised Salmon", "Seafood"),
        ("Wild caught Shrimp", "Seafood"),
        ("Farm raised Shrimp", "Seafood"),
        ("Wild caught Pacific Cod", "Seafood"),
        ("Wild caught Tuna", "Seafood"),
        ("Wild caught Tilapia", "Seafood"),
        ("Farm raised Tilapia", "Seafood"),
        ("Wild caught Scallops", "Seafood"),
        ("Farm raised Scallops", "Seafood"),
        ("Wild caught Mussels", "Seafood"),
        ("Farm raised Mussels", "Seafood"),
        ("Wild caught Lobster", "Seafood"),
        ("Wild caught Sea Bass", "Seafood"),
        ("Wild caught Mahi-Mahi", "Seafood"),
        
        // Deli - Common items
        ("Sushi", "Deli"),
        ("Firm Tofu", "Deli"),
        ("Silken Tofu", "Deli"),
        ("Jarred Sauerkraut", "Deli"),
        ("Pickles", "Deli"),
        ("Orange Juice", "Deli"),
        ("Tomato Juice", "Deli"),
        ("Tamales", "Deli"),
        
        // Bakery - Common items
        ("Sliced Bread", "Bakery"),
        ("French Bread", "Bakery"),
        ("Italian Bread", "Bakery"),
        ("Sourdough", "Bakery"),
        ("Banana Bread", "Bakery"),
        ("Muffins", "Bakery"),
        ("Danish", "Bakery"),
        ("Donuts", "Bakery"),
        ("Cookies", "Bakery"),
        ("Tortillas", "Bakery"),
        
        // Pantry Staples - Common items
        ("Long grain Rice", "Pantry Staples"),
        ("Wild Rice", "Pantry Staples"),
        ("Barley", "Pantry Staples"),
        ("Spaghetti Pasta", "Pantry Staples"),
        ("Angel Hair Pasta", "Pantry Staples"),
        ("Macaroni Pasta", "Pantry Staples"),
        ("Fusilli Pasta", "Pantry Staples"),
        ("Orzo", "Pantry Staples"),
        ("Couscous", "Pantry Staples"),
        ("Vermicelli Noodles", "Pantry Staples"),
        ("Egg Noodles", "Pantry Staples"),
        ("Ramen Noodles", "Pantry Staples"),
        ("White Sugar", "Pantry Staples"),
        ("Olive Oil", "Pantry Staples"),
        ("Vegetable Oil", "Pantry Staples"),
        ("Vinegar", "Pantry Staples"),
        ("Peanut Butter", "Pantry Staples"),
        ("Seed Butter", "Pantry Staples"),
        ("Corn Bread Mix", "Pantry Staples"),
        
        // Canned Goods - Common items
        ("Canned Diced Tomatoes", "Canned Goods"),
        ("Canned Tomato Paste", "Canned Goods"),
        ("Canned Tomato Sauce", "Canned Goods"),
        ("Jarred Tomato Sauce", "Canned Goods"),
        ("Jarred Alfredo Sauce", "Canned Goods"),
        ("Jarred Clam Sauce", "Canned Goods"),
        ("Canned Navy Beans", "Canned Goods"),
        ("Canned Kidney Beans", "Canned Goods"),
        ("Canned Pinto Beans", "Canned Goods"),
        ("Canned Black Beans", "Canned Goods"),
        ("Canned Refried Beans", "Canned Goods"),
        ("Canned Garbanzo Beans", "Canned Goods"),
        ("Canned Salmon", "Canned Goods"),
        ("Canned Tuna", "Canned Goods"),
        ("Canned Peas", "Canned Goods"),
        ("Canned Corn", "Canned Goods"),
        ("Canned Peaches", "Canned Goods"),
        ("Canned Pears", "Canned Goods"),
        ("Canned Olives", "Canned Goods"),
        ("Canned Cream Soup", "Canned Goods"),
        ("Canned Vegetable Soup", "Canned Goods"),
        ("Canned Chicken Soup", "Canned Goods"),
        ("Canned Tomato Soup", "Canned Goods"),
        
        // Packaged Goods - Common items
        ("Packaged Chicken Broth", "Packaged Goods"),
        ("Packaged Beef Broth", "Packaged Goods"),
        ("Packaged Vegetable Broth", "Packaged Goods"),
        ("Boxed Macaroni & Cheese", "Packaged Goods"),
        ("Boxed Cream Soup", "Packaged Goods"),
        ("Packaged Stuffing Mix", "Packaged Goods"),
        ("Cup of Noodles", "Packaged Goods"),
        ("Dried Ramen", "Packaged Goods"),
        
        // Beverages - Common items
        ("Bottled Water", "Beverages"),
        ("Canned Flavored Water", "Beverages"),
        ("Ground Coffee", "Beverages"),
        ("Coffee Beans", "Beverages"),
        ("Canned Beer", "Beverages"),
        ("Bottled Beer", "Beverages"),
        ("Bottled Wine", "Beverages"),
        ("Canned Soda Pop", "Beverages"),
        ("Packaged Tea", "Beverages"),
        
        // Snacks - Common items
        ("Nacho Chips", "Snacks"),
        ("Round Crackers", "Snacks"),
        ("Peanuts", "Snacks"),
        ("Cashews", "Snacks"),
        ("Almonds", "Snacks"),
        ("Pistachios", "Snacks"),
        ("Popcorn", "Snacks"),
        ("Seaweed", "Snacks"),
        ("Jerky", "Snacks"),
        ("Boxed Raisins", "Snacks"),
        ("Granola Bars", "Snacks"),
        ("Fruit Bars", "Snacks"),
        ("Packaged Cookies", "Snacks"),
        
        // Condiments - Common items
        ("Ketchup", "Condiments"),
        ("Mustard", "Condiments"),
        ("Relish", "Condiments"),
        ("Mayonnaise", "Condiments"),
        ("Hot Sauce", "Condiments"),
        ("Horseradish", "Condiments"),
        
        // Spices - Common items
        ("Salt", "Spices"),
        ("Pepper", "Spices"),
        ("Oregano", "Spices"),
        ("Basil", "Spices"),
        ("Parsley", "Spices"),
        ("Garlic Powder", "Spices"),
        ("Onion Powder", "Spices"),
        ("Paprika", "Spices"),
        ("Rosemary", "Spices"),
        ("Thyme", "Spices"),
        ("Cumin", "Spices"),
        ("Curry", "Spices"),
        ("Ginger", "Spices"),
        ("Bay Leaves", "Spices"),
        ("Sloppy Joe Seasoning", "Spices"),
        ("Fish Fry Seasoning", "Spices"),
        ("Taco Seasoning", "Spices"),
        
        // Breakfast Items - Common items
        ("Cold Cereal", "Breakfast Items"),
        ("Oatmeal", "Breakfast Items"),
        ("Quinoa", "Breakfast Items"),
        ("Pancake Mix", "Breakfast Items"),
        ("Waffle Mix", "Breakfast Items"),
        ("Maple Syrup", "Breakfast Items"),
        ("Wild Honey", "Breakfast Items"),
        ("Fruit Jam", "Breakfast Items"),
        ("Fruit Jelly", "Breakfast Items"),
        ("Fruit Marmalade", "Breakfast Items"),
        
        // Baking Supplies - Common items
        ("Flour", "Baking Supplies"),
        ("Bread Crumbs", "Baking Supplies"),
        ("Brown Sugar", "Baking Supplies"),
        
        // Frozen - Common items
        ("Frozen Fruit Popsicles", "Frozen"),
        ("Ice Cream", "Frozen"),
        ("Frozen Desserts", "Frozen"),
        ("Gyoza Dumplings", "Frozen"),
    ]
    
    /// Specialty items available only at specific stores
    /// Format: (name, category, [store names])
    static let specialtyItems: [(name: String, category: String, stores: [String])] = [
        // Produce Fruit - Specialty items (available at all stores except Ranch 99)
        ("Apples", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Bananas", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Oranges", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Mandarins", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Grapes", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Strawberries", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Blueberries", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Raspberries", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Blackberries", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Avocados", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cantaloupe", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Watermelon", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Honeydew", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Grapefruit", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Lemons", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Limes", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cherries", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Peaches", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Plums", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Nectarines", "Produce Fruit", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        
        // Produce Fruit - Specialty items (Ranch 99 only)
        ("Dragon Fruit", "Produce Fruit", ["Ranch 99"]),
        ("Rambutan", "Produce Fruit", ["Ranch 99"]),
        ("Lychee", "Produce Fruit", ["Ranch 99"]),
        ("Mango", "Produce Fruit", ["Ranch 99"]),
        ("Durian", "Produce Fruit", ["Ranch 99"]),
        ("Jackfruit", "Produce Fruit", ["Ranch 99"]),
        ("Pomelo", "Produce Fruit", ["Ranch 99"]),
        ("Longan", "Produce Fruit", ["Ranch 99"]),
        ("Papaya", "Produce Fruit", ["Ranch 99"]),
        
        // Produce Vegetables - Specialty items (available at all stores except Ranch 99)
        ("Lettuce", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Spinach", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Tomatoes", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Carrots", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cabbage", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cauliflower", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Asparagus", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Broccoli", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Corn on the Cob", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Eggplant", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Summer Squash", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Spaghetti Squash", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Zucchini", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Pumpkin", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Turnips", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Kale", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Collard Greens", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Mustard Greens", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Radish", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Red Beets", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Acorn Squash", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Brussel Sprouts", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Onions", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Potatoes", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Sweet Potatoes", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Baby Bell Peppers", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cucumbers", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Green Beans", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Button Mushrooms", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cremini Mushrooms", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Celery", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Sugar Snap Peas", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Red Onions", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Green Onions", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("Leeks", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        ("English Peas", "Produce Vegetables", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Berkeley Bowl", "Target", "Walmart"]),
        
        // Produce Vegetables - Specialty items (Ranch 99 only)
        ("Gai Lan", "Produce Vegetables", ["Ranch 99"]),
        ("Baby Bok Choy", "Produce Vegetables", ["Ranch 99"]),
        ("Napa Cabbage", "Produce Vegetables", ["Ranch 99"]),
        ("Choy Dim", "Produce Vegetables", ["Ranch 99"]),
        ("Snow Peas", "Produce Vegetables", ["Ranch 99"]),
        ("Daikon Radish", "Produce Vegetables", ["Ranch 99"]),
        ("Japanese Eggplant", "Produce Vegetables", ["Ranch 99"]),
        ("Kombucha", "Produce Vegetables", ["Ranch 99"]),
        ("Lotus Root", "Produce Vegetables", ["Ranch 99"]),
        ("Ginger Root", "Produce Vegetables", ["Ranch 99"]),
        ("Baby Oyster Mushrooms", "Produce Vegetables", ["Ranch 99"]),
        ("Enoki Mushrooms", "Produce Vegetables", ["Ranch 99"]),
        ("Wood Ear Mushrooms", "Produce Vegetables", ["Ranch 99"]),
        ("Shiitake Mushrooms", "Produce Vegetables", ["Ranch 99"]),
        ("Shimeji Mushrooms", "Produce Vegetables", ["Ranch 99"]),
        ("Choy Sum", "Produce Vegetables", ["Ranch 99"]),
        ("Bitter Melon", "Produce Vegetables", ["Ranch 99"]),
        ("Pak Choy", "Produce Vegetables", ["Ranch 99"]),
        ("Ginger", "Produce Vegetables", ["Ranch 99"]),
        ("Bean Sprouts", "Produce Vegetables", ["Ranch 99"]),
        ("Portobello Mushrooms", "Produce Vegetables", ["Monterey Market"]),
        ("Porcini Mushrooms", "Produce Vegetables", ["Monterey Market"]),
        ("Morel Mushrooms", "Produce Vegetables", ["Monterey Market"]),
        ("Chanterelle Mushrooms", "Produce Vegetables", ["Monterey Market"]),
        ("Maitake Mushrooms", "Produce Vegetables", ["Monterey Market"]),
        
        // Dairy - Specialty items
        ("Duck Eggs", "Dairy", ["Ranch 99"]),
        ("Quail Eggs", "Dairy", ["Ranch 99"]),
        
        // Meats - Specialty items
        ("Sliced Pork", "Meats", ["Ranch 99"]),
        ("Sliced Beef Short Ribs", "Meats", ["Ranch 99"]),
        ("Sliced Beef Brisket", "Meats", ["Ranch 99"]),
        ("Sliced Beef Ribeye", "Meats", ["Ranch 99"]),
        ("Sliced Beef Chuck", "Meats", ["Ranch 99"]),
        ("Sliced Beef Flank Steak", "Meats", ["Ranch 99"]),
        
        // Seafood - Specialty items
        ("Dungeness Crab", "Seafood", ["Ranch 99"]),
        ("P.E.I. Mussels", "Seafood", ["Andronico's"]),
        
        // Deli - Specialty items
        ("Soup", "Deli", ["Andronico's"]),
        ("Chowder", "Deli", ["Andronico's"]),
        ("Bisque", "Deli", ["Andronico's"]),
        ("Jambalaya", "Deli", ["Andronico's"]),
        ("Artisan Sandwich", "Deli", ["Andronico's"]),
        ("Pizza", "Deli", ["Andronico's"]),
        ("Kimchi", "Deli", ["Ranch 99"]),
        ("Udon Noodles", "Deli", ["Ranch 99"]),
        ("Ramen Noodles", "Deli", ["Ranch 99"]),
        ("Sukiyaki Noodles", "Deli", ["Ranch 99"]),
        ("Narutomaki", "Deli", ["Ranch 99"]),
        
        // Bakery - Specialty items
        ("Cranberry Walnut Bread", "Bakery", ["Berkeley Bowl"]),
        ("Olive Bread", "Bakery", ["Berkeley Bowl"]),
        
        // Pantry Staples - Specialty items
        ("Short grain Rice", "Pantry Staples", ["Ranch 99"]),
        
        // Canned Goods - Specialty items
        ("Jarred Bechtel Sauce", "Canned Goods", ["Trader Joe's"]),
        ("Canned Coconut Milk", "Canned Goods", ["Ranch 99"]),
        ("Jarred Bamboo", "Canned Goods", ["Ranch 99"]),
        ("Jarred Fried Gluten", "Canned Goods", ["Ranch 99"]),
        ("Jarred Pickled Radish", "Canned Goods", ["Ranch 99"]),
        
        // Packaged Goods - Specialty items
        ("Packaged Red Curry", "Packaged Goods", ["Ranch 99"]),
        ("Packaged Green Curry", "Packaged Goods", ["Ranch 99"]),
        ("Packaged Yellow Curry", "Packaged Goods", ["Ranch 99"]),
        
        // Beverages - Specialty items
        ("Ginger Tea", "Beverages", ["Ranch 99"]),
        ("Green Tea", "Beverages", ["Ranch 99"]),
        ("Barley Tea", "Beverages", ["Ranch 99"]),
        
        // Snacks - Specialty items
        ("Potato Chips", "Snacks", ["Andronico's"]),
        ("Saltine Crackers", "Snacks", ["Andronico's"]),
        
        // Condiments - Specialty items
        ("Soy Sauce", "Condiments", ["Ranch 99"]),
        ("Dumpling Sauce", "Condiments", ["Ranch 99"]),
        ("Hoison Sauce", "Condiments", ["Ranch 99"]),
        ("Stir Fry Sauce", "Condiments", ["Ranch 99"]),
        ("Plum Sauce", "Condiments", ["Ranch 99"]),
        ("Korean BBQ Sauce", "Condiments", ["Ranch 99"]),
        ("Rice Vinegar", "Condiments", ["Ranch 99"]),
        ("Mirin Sauce", "Condiments", ["Ranch 99"]),
        ("Kewpie Mayo", "Condiments", ["Ranch 99"]),
        ("Fish Sauce", "Condiments", ["Ranch 99"]),
        ("Curry Sauce", "Condiments", ["Ranch 99"]),
        ("Ponzu Sauce", "Condiments", ["Ranch 99"]),
        ("Sesame Sauce", "Condiments", ["Ranch 99"]),
        
        // Spices - Specialty items
        ("Dashi", "Spices", ["Ranch 99"]),
        ("Lemongrass", "Spices", ["Ranch 99"]),
        
        // Baking Supplies - Specialty items (available at all stores except Ranch 99)
        ("Baking Soda", "Baking Supplies", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Baking Powder", "Baking Supplies", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Vanilla Extract", "Baking Supplies", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Chocolate Chips", "Baking Supplies", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Powdered Sugar", "Baking Supplies", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        
        // Baking Supplies - Specialty items (Ranch 99 only)
        ("Panko Crumbs", "Baking Supplies", ["Ranch 99"]),
        
        // Frozen - Specialty items (available at all stores except Ranch 99)
        ("Frozen Peas", "Frozen", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Frozen Corn", "Frozen", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("Cookie Dough", "Frozen", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        ("TV Dinners", "Frozen", ["Andronico's", "Whole Foods", "Trader Joe's", "Sprouts", "Safeway", "Lucky's", "Monterey Market", "Costco", "Berkeley Bowl", "Target", "Walmart"]),
        
        // Frozen - Specialty items (store-specific)
        ("Frozen Pizza Rolls", "Frozen", ["Safeway"]),
        ("Frozen Tater Tots", "Frozen", ["Andronico's"]),
        ("Frozen Chicken Pot Pies", "Frozen", ["Andronico's"]),
        ("Chinese Dumplings", "Frozen", ["Ranch 99"]),
        ("Shu Mai Dumplings", "Frozen", ["Ranch 99"]),
    ]
}
