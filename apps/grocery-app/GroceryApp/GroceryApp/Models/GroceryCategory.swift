//
//  GroceryCategory.swift
//  GroceryApp
//
//  Grocery item categories with SF Symbol icons
//

import Foundation

/// Grocery item categories with associated SF Symbol icons
/// Focused on supermarket/grocery store items
enum GroceryCategory: String, CaseIterable, Identifiable, Hashable {
    // Fresh items
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case deli = "Deli"
    case bakery = "Bakery"
    
    // Shelf-stable items
    case pantry = "Pantry Staples"
    case canned = "Canned Goods"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case condiments = "Condiments & Spices"
    case breakfast = "Breakfast Items"
    case baking = "Baking Supplies"
    
    // Frozen
    case frozen = "Frozen"
    
    // Other
    case other = "Other"
    
    var id: String { rawValue }
    
    /// SF Symbol name for the category icon
    var iconName: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fish.fill"
        case .deli: return "fork.knife"
        case .bakery: return "birthday.cake.fill"
        case .pantry: return "cabinet.fill"
        case .canned: return "cylinder.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .snacks: return "circle.grid.hex.fill"
        case .condiments: return "sparkles"
        case .breakfast: return "sunrise.fill"
        case .baking: return "flame.fill"
        case .frozen: return "snowflake"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    /// Display name for the category
    var displayName: String {
        return rawValue
    }
}

