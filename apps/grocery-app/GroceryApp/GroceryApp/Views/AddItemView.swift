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
    
    let alwaysAddToShoppingList: Bool
    let itemToEdit: GroceryItem?
    let prefillCategory: GroceryCategory?
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var itemName = ""
    @State private var selectedCategory: GroceryCategory? = nil
    @State private var selectedStore: Store? = nil
    @State private var addToShoppingList = false
    @State private var selectedExistingItem: GroceryItem? = nil
    @State private var showDuplicateShoppingListAlert = false
    @State private var duplicateItemName = ""
    
    init(alwaysAddToShoppingList: Bool = false, itemToEdit: GroceryItem? = nil, prefillCategory: GroceryCategory? = nil) {
        self.alwaysAddToShoppingList = alwaysAddToShoppingList
        self.itemToEdit = itemToEdit
        self.prefillCategory = prefillCategory
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Store.name, ascending: true)],
        animation: .default
    )
    private var stores: FetchedResults<Store>
    
    // Fetch existing grocery items for matching
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)],
        animation: .default
    )
    private var allGroceryItems: FetchedResults<GroceryItem>
    
    // Filtered items matching the search text
    var matchingItems: [GroceryItem] {
        guard !itemName.isEmpty else { return [] }
        let searchText = itemName.lowercased()
        return allGroceryItems.filter { item in
            item.name.lowercased().contains(searchText)
        }
    }
    
    // Whether we're creating a new item or using an existing one
    var isCreatingNew: Bool {
        selectedExistingItem == nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Name") {
                    TextField("Type to search or create new", text: $itemName)
                        .focused($isTextFieldFocused)
                        .onChange(of: itemName) { oldValue, newValue in
                            // Clear selected item when text changes
                            if selectedExistingItem != nil {
                                selectedExistingItem = nil
                                selectedCategory = nil
                                selectedStore = nil
                            }
                        }
                    
                    // Show matching items from master list
                    if !matchingItems.isEmpty && selectedExistingItem == nil {
                        ForEach(matchingItems.prefix(5)) { item in
                            Button(action: {
                                selectExistingItem(item)
                            }) {
                                HStack {
                                    if let category = item.categoryEnum {
                                        Image(systemName: category.iconName)
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            if let category = item.category {
                                                Text(category)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let store = item.preferredStore {
                                                Image(systemName: store.displayIconName)
                                                    .foregroundColor(.orange)
                                                    .font(.caption)
                                                Text(store.name)
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Show selected item info or new item form
                if let existingItem = selectedExistingItem {
                    Section("Selected Item") {
                        HStack {
                            if let category = existingItem.categoryEnum {
                                Image(systemName: category.iconName)
                                    .foregroundColor(.blue)
                            }
                            Text(existingItem.name)
                            Spacer()
                            Button("Change") {
                                selectedExistingItem = nil
                                itemName = existingItem.name
                            }
                            .font(.caption)
                        }
                        
                        if let store = existingItem.preferredStore {
                            HStack {
                                Image(systemName: store.displayIconName)
                                    .foregroundColor(.orange)
                                Text("Store: \(store.name)")
                            }
                        }
                    }
                } else {
                    Section("Item Details") {
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
                }
                
                // Only show toggle if not always adding to shopping list
                if !alwaysAddToShoppingList {
                    Section {
                        Toggle("Add to Shopping List", isOn: $addToShoppingList)
                    }
                }
            }
            .navigationTitle(itemToEdit != nil ? "Edit Item" : (selectedExistingItem == nil ? "Add Item" : "Add to Shopping List"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selectedExistingItem == nil ? "Save" : "Add") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
            .alert("Already in Shopping List", isPresented: $showDuplicateShoppingListAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("'\(duplicateItemName)' is already in your shopping list.")
            }
        }
        .onAppear {
            // If editing an existing item, populate the form
            if let item = itemToEdit {
                itemName = item.name
                selectedCategory = item.categoryEnum
                selectedStore = item.preferredStore
                addToShoppingList = false // Don't add to shopping list when editing
            } else {
                // Pre-fill category if provided
                if let category = prefillCategory {
                    selectedCategory = category
                }
                if alwaysAddToShoppingList {
                    addToShoppingList = true
                }
            }
            // Auto-focus the text field and show keyboard (only if not editing)
            if itemToEdit == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func selectExistingItem(_ item: GroceryItem) {
        selectedExistingItem = item
        itemName = item.name
        selectedCategory = item.categoryEnum
        selectedStore = item.preferredStore
        // Default to adding to shopping list when selecting existing item
        addToShoppingList = true
        
        // If always adding to shopping list, auto-add immediately
        if alwaysAddToShoppingList {
            // Add directly without showing confirmation screen
            addExistingItemToShoppingList(item)
        }
    }
    
    private func addExistingItemToShoppingList(_ item: GroceryItem) {
        let added = addToShoppingList(item: item)
        if !added {
            // Duplicate in shopping list - show error
            duplicateItemName = item.name
            showDuplicateShoppingListAlert = true
            // Reset selection so user can try again
            selectedExistingItem = nil
            itemName = item.name
        } else {
            // Successfully added - save and dismiss
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func saveItem() {
        let item: GroceryItem
        
        // If editing an existing item, update it
        if let itemToEdit = itemToEdit {
            item = itemToEdit
            item.name = itemName
            item.setCategory(selectedCategory)
            item.preferredStore = selectedStore
            
            // Add to shopping list if requested
            if addToShoppingList {
                let added = addToShoppingList(item: item)
                if !added {
                    duplicateItemName = item.name
                    showDuplicateShoppingListAlert = true
                    return
                }
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving item: \(nsError), \(nsError.userInfo)")
            }
            return
        }
        
        if let existingItem = selectedExistingItem {
            // Using existing item - just add to shopping list if requested
            item = existingItem
        } else {
            // Creating new item - check for duplicate first
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
                    // Duplicate found - select the existing item instead
                    selectExistingItem(existingItems[0])
                    // If addToShoppingList is true, add it to shopping list
                    if addToShoppingList {
                        addToShoppingList(item: existingItems[0])
                    }
                    return
                }
            } catch {
                print("Error checking for duplicates: \(error)")
            }
            
            // Create new grocery item
            item = GroceryItem(context: viewContext)
            item.id = UUID()
            item.name = itemName
            item.setCategory(selectedCategory)
            item.preferredStore = selectedStore
            item.isInMasterList = true
            item.createdDate = Date()
        }
        
        // Add to shopping list if requested or always required
        if addToShoppingList || alwaysAddToShoppingList {
            let added = addToShoppingList(item: item)
            if !added {
                // Duplicate in shopping list - show error and don't save
                duplicateItemName = item.name
                showDuplicateShoppingListAlert = true
                return
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving item: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func addToShoppingList(item: GroceryItem) -> Bool {
        // Check if item is already in shopping list
        let fetchRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "groceryItem == %@", item)
        
        do {
            let existingItems = try viewContext.fetch(fetchRequest)
            if existingItems.isEmpty {
                // Not in shopping list yet - add it
                let shoppingItem = ShoppingListItem(context: viewContext)
                shoppingItem.id = UUID()
                shoppingItem.groceryItem = item
                shoppingItem.store = item.preferredStore ?? selectedStore
                shoppingItem.isChecked = false
                shoppingItem.addedDate = Date()
                shoppingItem.quantity = 1
                return true
            } else {
                // Already in shopping list - return false to indicate duplicate
                return false
            }
        } catch {
            print("Error checking shopping list: \(error)")
            return false
        }
    }
}

#Preview {
    AddItemView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

