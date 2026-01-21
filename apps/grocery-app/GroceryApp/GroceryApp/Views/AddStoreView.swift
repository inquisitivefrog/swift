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
    
    let storeToEdit: Store?
    
    @FocusState private var isTextFieldFocused: Bool
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
    
    init(storeToEdit: Store? = nil) {
        self.storeToEdit = storeToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Store Details") {
                    TextField("Store Name", text: $storeName)
                        .focused($isTextFieldFocused)
                    
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
            .navigationTitle(storeToEdit == nil ? "Add Store" : "Edit Store")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let store = storeToEdit {
                    // Populate fields for editing
                    storeName = store.name
                    selectedIcon = store.iconName ?? "storefront.fill"
                    isFavorite = store.isFavorite
                } else {
                    // Auto-focus text field when adding new store
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Resign text field focus before dismissing to prevent keyboard warnings
                        isTextFieldFocused = false
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
        if let store = storeToEdit {
            // Update existing store
            store.name = storeName
            store.iconName = selectedIcon
            store.isFavorite = isFavorite
            store.lastUsedDate = Date()
        } else {
            // Create new store
            let storeService = StoreService(context: viewContext)
            let newStore = storeService.createStore(name: storeName, iconName: selectedIcon)
            newStore.isFavorite = isFavorite
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving store: \(error)")
        }
    }
}

#Preview {
    AddStoreView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

