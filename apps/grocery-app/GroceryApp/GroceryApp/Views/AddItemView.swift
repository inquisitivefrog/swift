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
    let prefillCategory: Category?
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var itemName = ""
    @State private var selectedCategory: Category? = nil
    @State private var selectedStore: Store? = nil
    @State private var addToShoppingList = false
    @State private var selectedExistingItem: GroceryItem? = nil
    @State private var showDuplicateShoppingListAlert = false
    @State private var duplicateItemName = ""
    @State private var isSaving = false
    
    init(alwaysAddToShoppingList: Bool = false, itemToEdit: GroceryItem? = nil, prefillCategory: Category? = nil) {
        self.alwaysAddToShoppingList = alwaysAddToShoppingList
        self.itemToEdit = itemToEdit
        self.prefillCategory = prefillCategory
    }
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Store.name, ascending: true)],
        animation: .default
    )
    private var stores: FetchedResults<Store>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
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
                                    if let category = item.category {
                                        Image(systemName: category.displayIconName)
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            if let category = item.category {
                                                Text(category.name)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let store = item.firstPreferredStore {
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
                            if let category = existingItem.category {
                                Image(systemName: category.displayIconName)
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
                        
                        if let store = existingItem.firstPreferredStore {
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
                            Text("None").tag(nil as Category?)
                            ForEach(categories) { category in
                                HStack {
                                    Image(systemName: category.displayIconName)
                                    Text(category.name)
                                }
                                .tag(category as Category?)
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
                    .disabled(itemName.isEmpty || isSaving)
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
                selectedCategory = item.category
                selectedStore = item.firstPreferredStore
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
        selectedCategory = item.category
        selectedStore = item.firstPreferredStore
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
        guard !isSaving else { return }
        isSaving = true
        
        // Perform save operation asynchronously to avoid blocking UI
        Task { @MainActor in
            let item: GroceryItem
            
            // If editing an existing item, update it
            if let itemToEdit = itemToEdit {
                item = itemToEdit
                item.name = itemName
                item.category = selectedCategory
                item.setPreferredStore(selectedStore)
                
                // Add to shopping list if requested
                if addToShoppingList {
                    let added = addToShoppingList(item: item)
                    if !added {
                        duplicateItemName = item.name
                        showDuplicateShoppingListAlert = true
                        isSaving = false
                        return
                    }
                }
                
                do {
                    try viewContext.save()
                    isSaving = false
                    dismiss()
                } catch {
                    let nsError = error as NSError
                    print("Error saving item: \(nsError), \(nsError.userInfo)")
                    isSaving = false
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
                // Note: preferredStore is a to-many relationship, so we use ANY to check membership
                if let store = selectedStore {
                    fetchRequest.predicate = NSPredicate(format: "name == %@ AND ANY preferredStore == %@", itemName, store)
                } else {
                    // Check for items with same name and no store (empty set)
                    fetchRequest.predicate = NSPredicate(format: "name == %@ AND preferredStore.@count == 0", itemName)
                }
                
                do {
                    let existingItems = try viewContext.fetch(fetchRequest)
                    if !existingItems.isEmpty {
                        // Duplicate found - select the existing item instead
                        selectExistingItem(existingItems[0])
                        // If addToShoppingList is true, add it to shopping list
                        if addToShoppingList {
                            _ = addToShoppingList(item: existingItems[0])
                        }
                        isSaving = false
                        return
                    }
                } catch {
                    print("Error checking for duplicates: \(error)")
                    isSaving = false
                    return
                }
                
                // Create new grocery item
                item = GroceryItem(context: viewContext)
                item.id = UUID()
                item.name = itemName
                item.category = selectedCategory
                item.setPreferredStore(selectedStore)
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
                    isSaving = false
                    return
                }
            }
            
            do {
                try viewContext.save()
                isSaving = false
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Error saving item: \(nsError), \(nsError.userInfo)")
                isSaving = false
            }
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
                shoppingItem.store = item.firstPreferredStore ?? selectedStore
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

