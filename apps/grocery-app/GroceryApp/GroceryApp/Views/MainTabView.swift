//
//  MainTabView.swift
//  GroceryApp
//
//  Main tab view for navigation
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0 // Start with Shopping List (index 0)
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ShoppingListView(selectedTab: Binding(
                get: { selectedTab },
                set: { selectedTab = $0 }
            ))
                .tabItem {
                    Label("Build My List", systemImage: "cart.fill")
                }
                .tag(0)
            
            StoreShoppingListView(selectedTab: Binding(
                get: { selectedTab },
                set: { selectedTab = $0 }
            ))
                .tabItem {
                    Label("Shop By Stores", systemImage: "storefront.fill")
                }
                .tag(1)
        }
        .onAppear {
            // Create default stores on first launch
            let storeService = StoreService(context: viewContext)
            storeService.createDefaultStores()
            
            // Create default categories on first launch
            let categoryService = CategoryService(context: viewContext)
            categoryService.createDefaultCategories()
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

