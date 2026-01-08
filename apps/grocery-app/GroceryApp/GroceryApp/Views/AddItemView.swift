//
//  AddItemView.swift
//  GroceryApp
//
//  View for adding/editing grocery items
//

import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName = ""
    @State private var selectedCategory: GroceryCategory? = nil
    @State private var selectedStore: Store? = nil
    @State private var addToShoppingList = false
    @State private var showDuplicateAlert = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Store.name, ascending: true)],
        animation: .default
    )
    private var stores: FetchedResults<Store>
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as GroceryCategory?)
                        ForEach(GroceryCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.displayName)
                            }
                            .tag(category as GroceryCategory?)
                        }
                    }
                    
                    Picker("Preferred Store", selection: $selectedStore) {
                        Text("None").tag(nil as Store?)
                        ForEach(stores) { store in
                            HStack {
                                Image(systemName: store.displayIconName)
                                Text(store.name)
                            }
                            .tag(store as Store?)
                        }
                    }
                }
                
                Section {
                    Toggle("Add to Shopping List", isOn: $addToShoppingList)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
            .alert("Duplicate Item", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let storeName = selectedStore?.name {
                    Text("An item named '\(itemName)' at \(storeName) already exists in your master list.")
                } else {
                    Text("An item named '\(itemName)' with no preferred store already exists in your master list.")
                }
            }
        }
    }
    
    private func saveItem() {
        // Check for duplicate: same name + same store (or both nil stores)
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        
        // Build predicate based on whether store is selected
        if let store = selectedStore {
            fetchRequest.predicate = NSPredicate(format: "name == %@ AND preferredStore == %@", itemName, store)
        } else {
            // Check for items with same name and no store
            fetchRequest.predicate = NSPredicate(format: "name == %@ AND preferredStore == nil", itemName)
        }
        
        do {
            let existingItems = try viewContext.fetch(fetchRequest)
            if !existingItems.isEmpty {
                // Duplicate found - show alert
                showDuplicateAlert = true
                return
            }
        } catch {
            print("Error checking for duplicates: \(error)")
        }
        
        withAnimation {
            // Create grocery item
            let item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemName
            item.setCategory(selectedCategory)
            item.preferredStore = selectedStore
            item.isInMasterList = true
            item.createdDate = Date()
            
            // Add to shopping list if requested
            if addToShoppingList {
                let shoppingItem = ShoppingListItem(context: viewContext)
                shoppingItem.id = UUID()
                shoppingItem.groceryItem = item
                shoppingItem.store = selectedStore
                shoppingItem.isChecked = false
                shoppingItem.addedDate = Date()
                shoppingItem.quantity = 1
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    AddItemView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

