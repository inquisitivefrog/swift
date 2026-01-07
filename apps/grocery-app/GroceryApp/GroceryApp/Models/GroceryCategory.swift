//
//  GroceryCategory.swift
//  GroceryApp
//
//  Grocery item categories with SF Symbol icons
//

import Foundation

/// Grocery item categories with associated SF Symbol icons
enum GroceryCategory: String, CaseIterable, Identifiable {
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
    
    var id: String { rawValue }
    
    /// SF Symbol name for the category icon
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
    
    /// Display name for the category
    var displayName: String {
        return rawValue
    }
}

