//
//  MainTabView.swift
//  GroceryApp
//
//  Main tab view for navigation
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 1 // Start with Shopping List (index 1)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MasterListView()
                .tabItem {
                    Label("Master List", systemImage: "list.bullet")
                }
                .tag(0)
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart.fill")
                }
                .tag(1)
            
            StoreListView()
                .tabItem {
                    Label("Stores", systemImage: "storefront.fill")
                }
                .tag(2)
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

