//
//  MainTabView.swift
//  GroceryApp
//
//  Main tab view for navigation
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            MasterListView()
                .tabItem {
                    Label("Master List", systemImage: "list.bullet")
                }
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart.fill")
                }
            
            StoreListView()
                .tabItem {
                    Label("Stores", systemImage: "storefront.fill")
                }
        }
        .onAppear {
            // Create default stores on first launch
            let storeService = StoreService(context: viewContext)
            storeService.createDefaultStores()
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

