//
//  AddStoreView.swift
//  GroceryApp
//
//  View for adding/editing stores
//

import SwiftUI
import CoreData

struct AddStoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var storeName = ""
    @State private var selectedIcon = "storefront.fill"
    @State private var isFavorite = false
    
    let iconOptions = [
        "storefront.fill",
        "cart.fill",
        "building.2.fill",
        "map.fill",
        "tag.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Store Details") {
                    TextField("Store Name", text: $storeName)
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(iconOptions, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                    
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Add Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStore()
                    }
                    .disabled(storeName.isEmpty)
                }
            }
        }
    }
    
    private func saveStore() {
        let storeService = StoreService(context: viewContext)
        _ = storeService.createStore(name: storeName, iconName: selectedIcon)
        
        dismiss()
    }
}

#Preview {
    AddStoreView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

