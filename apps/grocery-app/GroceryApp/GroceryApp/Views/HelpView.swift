//
//  HelpView.swift
//  GroceryApp
//
//  Help and instructions for first-time users
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to GroceryApp!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Here's how to get started:")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Import Items
                    HelpSection(
                        icon: "square.and.arrow.down.fill",
                        title: "Import Items",
                        description: "Go to the FoodStuffs tab (accessible from Settings) and tap the 'Import Data' button. This will add common grocery items organized by category to your master list."
                    )
                    
                    // Modify or Delete Items
                    HelpSection(
                        icon: "pencil.circle.fill",
                        title: "Modify or Delete Items",
                        description: "In the FoodStuffs tab, tap any category icon to see items. Tap an item to add it to your shopping list, or long-press to edit or delete it. You can also add new items using the '+' button."
                    )
                    
                    // Add Categories
                    HelpSection(
                        icon: "folder.badge.plus",
                        title: "Add Categories",
                        description: "In the FoodStuffs tab, tap the '+' button in the navigation bar to create a new category. Categories help organize your grocery items."
                    )
                    
                    // Add Stores
                    HelpSection(
                        icon: "storefront.fill",
                        title: "Add Stores",
                        description: "Go to Settings and select 'Stores'. Tap the '+' button to add a new store. You can assign preferred stores to items to help organize your shopping."
                    )
                    
                    // Build Shopping List
                    HelpSection(
                        icon: "cart.fill",
                        title: "Build Your Shopping List",
                        description: "Use the 'Build My List' tab to add items to your shopping list. Tap category icons to browse items, then tap any item to add or remove it from your list. Check off items as you shop!"
                    )
                    
                    // Shop By Stores
                    HelpSection(
                        icon: "storefront.2.fill",
                        title: "Shop By Stores",
                        description: "The 'Shop By Stores' tab organizes your shopping list by store, showing which items to buy at each location. Stores are sorted by the number of items you need."
                    )
                    
                    // Save and Load
                    HelpSection(
                        icon: "square.and.arrow.down.on.square.fill",
                        title: "Save and Load Lists",
                        description: "Use the 'Save' button in 'Build My List' to save your current shopping list. Use 'Load' to restore it later - perfect for recurring shopping trips!"
                    )
                }
                .padding()
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HelpView()
}
