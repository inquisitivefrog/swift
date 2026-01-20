//
//  ShoppingListView.swift
//  GroceryApp
//
//  View for the active shopping list
//

import SwiftUI
import CoreData

struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingSettings = false
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var showingSaveAlert = false
    @State private var showingLoadAlert = false
    @State private var hasSavedList = false
    
    // Service for managing saved shopping lists
    private var shoppingListService: ShoppingListService {
        ShoppingListService(context: viewContext)
    }
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingListItem.isChecked, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)
        ],
        animation: .default
    )
    private var items: FetchedResults<ShoppingListItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Store.name, ascending: true)],
        animation: .default
    )
    private var allStores: FetchedResults<Store>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)],
        animation: .default
    )
    private var allMasterItems: FetchedResults<GroceryItem>
    
    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }
    
    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }
    
    @State private var isClearingChecked = false
    @State private var cachedStoreCounts: [(store: Store?, count: Int)] = []
    
    // Get store counts from master list - cached to reduce memory usage
    var storeCounts: [(store: Store?, count: Int)] {
        cachedStoreCounts
    }
    
    // Calculate store counts from master list - only called when data changes
    private func calculateStoreCounts() {
        // Count master list items per store
        var storeItemCounts: [UUID?: Int] = [:]
        
        for item in allMasterItems {
            let storeId = item.firstPreferredStore?.id
            storeItemCounts[storeId, default: 0] += 1
        }
        
        // Build result array
        var result: [(store: Store?, count: Int)] = []
        
        // Add stores with items
        for store in allStores {
            let storeId = store.id
            if let count = storeItemCounts[storeId], count > 0 {
                result.append((store: store, count: count))
            }
        }
        
        // Add "No Store" if there are items without a store
        if let noStoreCount = storeItemCounts[nil], noStoreCount > 0 {
            result.append((store: nil, count: noStoreCount))
        }
        
        // Sort by count (most to least)
        cachedStoreCounts = result.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            // Store picker - scrollable grid of store buttons
            // Sorted by count (most to least), showing master list item counts
            ScrollView(.vertical, showsIndicators: true) {
                if storeCounts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "storefront")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No items imported yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Import default grocery lists from your preferred stores to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 12)
                    ], spacing: 20) {
                        ForEach(Array(storeCounts.enumerated()), id: \.offset) { index, storeData in
                            NavigationLink {
                                StoreCategoryView(store: storeData.store)
                            } label: {
                                StoreButtonContent(
                                    store: storeData.store,
                                    itemCount: storeData.count
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Build My List")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbar {
                // Settings button - place first to ensure it's always visible
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                // Leading toolbar items - Save and Load buttons
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // Save button
                    Button(action: {
                        saveShoppingList()
                    }) {
                        if isSaving {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    .disabled(isSaving)
                    
                    // Load button
                    Button(action: {
                        loadShoppingList()
                    }) {
                        if isLoading {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isLoading || !hasSavedList)
                }
                
                // Clear Checked button - only when there are checked items (separate item to avoid crowding)
                if !checkedItems.isEmpty && !isClearingChecked {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            clearCheckedItems()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                } else if isClearingChecked {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .alert("Shopping List Saved", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your shopping list has been saved. Use Load to restore it later.")
            }
            .alert("Shopping List Loaded", isPresented: $showingLoadAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Items from your saved shopping list have been added.")
            }
            .onAppear {
                // Check if saved list exists on view appear
                hasSavedList = shoppingListService.hasSavedList
                // Calculate store counts on appear
                calculateStoreCounts()
            }
            .onChange(of: allMasterItems.count) {
                // Recalculate when master items change
                calculateStoreCounts()
            }
            .onChange(of: allStores.count) {
                // Recalculate when stores change
                calculateStoreCounts()
            }
        }
    }
    
    private func saveShoppingList() {
        guard !isSaving else { return }
        isSaving = true
        
        shoppingListService.saveCurrentShoppingList { result in
            switch result {
            case .success(let count):
                self.hasSavedList = true // Update state to enable Load button
                self.showingSaveAlert = true
                print("Saved shopping list with \(count) items")
            case .failure(let error):
                print("Error saving shopping list: \(error)")
            }
            self.isSaving = false
        }
    }
    
    private func loadShoppingList() {
        guard !isLoading else { return }
        isLoading = true
        
        shoppingListService.loadSavedShoppingList { result in
            switch result {
            case .success(let count):
                if count > 0 {
                    self.showingLoadAlert = true
                    print("Loaded \(count) items from saved shopping list")
                } else {
                    // All items already in list - could show different message
                    print("All saved items are already in the shopping list")
                }
            case .failure(let error):
                print("Error loading shopping list: \(error)")
            }
            self.isLoading = false
        }
    }
    
    private func clearCheckedItems() {
        guard !isClearingChecked else { return }
        isClearingChecked = true
        
        // Get object IDs from main context first (where we know the checked items exist)
        let checkedItemIDs = checkedItems.compactMap { $0.objectID }
        
        guard !checkedItemIDs.isEmpty else {
            isClearingChecked = false
            return
        }
        
        // Use performBackgroundTask to avoid blocking main thread and FetchedResults conflicts
        let container = PersistenceController.shared.container
        container.performBackgroundTask { backgroundContext in
            defer {
                // Ensure context is processed and released
                backgroundContext.processPendingChanges()
            }
            
            do {
                // Delete objects in background context using the object IDs from main context
                for objectID in checkedItemIDs {
                    if let object = try? backgroundContext.existingObject(with: objectID) {
                        backgroundContext.delete(object)
                    }
                }
                
                // Save background context
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("Cleared \(checkedItemIDs.count) checked items")
                }
                
                // Reset flag on main thread after save completes
                DispatchQueue.main.async {
                    self.isClearingChecked = false
                }
            } catch {
                print("Error clearing checked items: \(error)")
                // Reset flag even on error
                DispatchQueue.main.async {
                    self.isClearingChecked = false
                }
            }
        }
    }
}

// View showing categories for a selected store
struct StoreCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let store: Store?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)],
        animation: .default
    )
    private var allMasterItems: FetchedResults<GroceryItem>
    
    @State private var cachedCategoryCounts: [(category: Category, count: Int)] = []
    
    // Get category counts for this store - cached to reduce memory usage
    var categoryCounts: [(category: Category, count: Int)] {
        cachedCategoryCounts
    }
    
    // Calculate category counts for this store - only called when data changes
    private func calculateCategoryCounts() {
        // Filter master items for this store
        let storeItems = allMasterItems.filter { item in
            if let store = store {
                return item.firstPreferredStore?.id == store.id
            } else {
                return item.firstPreferredStore == nil
            }
        }
        
        // Count items per category
        var itemCountsByCategory: [UUID: Int] = [:]
        for item in storeItems {
            if let categoryId = item.category?.id {
                itemCountsByCategory[categoryId, default: 0] += 1
            }
        }
        
        // Build result array
        cachedCategoryCounts = categories.compactMap { category in
            let count = itemCountsByCategory[category.id] ?? 0
            if count > 0 {
                return (category: category, count: count)
            }
            return nil
        }.sorted { $0.count > $1.count } // Sort by count, most to least
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Store header
                HStack {
                    if let store = store {
                        Image(systemName: store.displayIconName)
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text(store.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .font(.title2)
                        Text("No Store")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Category grid
                if categoryCounts.isEmpty {
                    Text("No items in master list for this store")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 12)
                    ], spacing: 20) {
                        ForEach(categoryCounts, id: \.category.id) { categoryData in
                            NavigationLink {
                                ShoppingListCategoryView(category: categoryData.category, store: store)
                            } label: {
                                CategoryButtonContent(
                                    category: categoryData.category,
                                    itemCount: categoryData.count
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .scrollIndicators(.visible)
        .navigationTitle(store?.name ?? "No Store")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateCategoryCounts()
        }
        .onChange(of: allMasterItems.count) {
            calculateCategoryCounts()
        }
        .onChange(of: categories.count) {
            calculateCategoryCounts()
        }
    }
}

// Category button content
struct CategoryButtonContent: View {
    let category: Category
    let itemCount: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: category.displayIconName)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(category.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(itemCount)")
                .font(.caption2)
                .foregroundColor(itemCount > 0 ? .secondary : Color.secondary.opacity(0.5))
            
            Spacer(minLength: 0)
        }
        .frame(width: 80, alignment: .top)
        .frame(minHeight: 80)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2)
    }
}

// View showing shopping list items in a selected category with edit options
struct ShoppingListCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let category: Category
    let store: Store? // NEW: filter by store
    @State private var showingAddItem = false
    @State private var itemToEdit: GroceryItem? = nil
    
    // Fetch master list items for this category and store
    @FetchRequest var allMasterItems: FetchedResults<GroceryItem>
    
    // Fetch shopping list items for this category
    @FetchRequest var shoppingItems: FetchedResults<ShoppingListItem>
    
    // Cached items for this store - recalculated only when needed
    @State private var cachedItems: [GroceryItem] = []
    
    // Filter items by store - optimized to reduce memory usage
    private func calculateItems() -> [GroceryItem] {
        // Filter items for this store
        let filteredItems = allMasterItems.filter { item in
            if let store = store {
                return item.firstPreferredStore?.id == store.id
            } else {
                return item.firstPreferredStore == nil
            }
        }
        
        // Sort by name
        return filteredItems.sorted { $0.name < $1.name }
    }
    
    init(category: Category, store: Store?) {
        self.category = category
        self.store = store
        _allMasterItems = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)
            ],
            predicate: NSPredicate(format: "category == %@", category),
            animation: .default
        )
        _shoppingItems = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)],
            predicate: NSPredicate(format: "groceryItem.category == %@", category),
            animation: .default
        )
    }
    
    // Check if a master item is in shopping list
    func isInShoppingList(_ item: GroceryItem) -> Bool {
        shoppingItems.contains { $0.groceryItem == item }
    }
    
    // Get the shopping list item for a grocery item
    func getShoppingItem(_ item: GroceryItem) -> ShoppingListItem? {
        shoppingItems.first { $0.groceryItem == item }
    }
    
    // Toggle item in shopping list - true toggle: add if not in list, remove if in list
    func toggleItemInShoppingList(_ item: GroceryItem) {
        if let shoppingItem = shoppingItems.first(where: { $0.groceryItem == item }) {
            // Item is in shopping list - remove it (Wax Off)
            viewContext.delete(shoppingItem)
        } else {
            // Item is not in shopping list - add it (Wax On)
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.firstPreferredStore
            shoppingItem.isChecked = false
            shoppingItem.addedDate = Date()
            shoppingItem.quantity = 1
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error toggling item in shopping list: \(error)")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category and store header with add button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        if let store = store {
                            HStack(spacing: 4) {
                                Image(systemName: store.displayIconName)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(store.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .font(.body)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Master list items for this store
                if cachedItems.isEmpty {
                    Text("No items in master list")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(cachedItems) { item in
                        Button(action: {
                            // Toggle item in/out of shopping list or check/uncheck if already in list
                            toggleItemInShoppingList(item)
                        }) {
                            HStack {
                                // Category icon
                                Image(systemName: category.displayIconName)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text(item.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                isInShoppingList(item) ? Color.blue.opacity(0.15) : Color(.systemBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        isInShoppingList(item) ? Color.blue : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(action: {
                                itemToEdit = item
                                showingAddItem = true
                            }) {
                                Label("Edit Item", systemImage: "pencil")
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .scrollIndicators(.visible)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddItemView(alwaysAddToShoppingList: true, itemToEdit: itemToEdit, prefillCategory: category, prefillStore: store)
                .onDisappear {
                    itemToEdit = nil
                }
        }
        .onAppear {
            // Recalculate when view appears
            cachedItems = calculateItems()
        }
        .onChange(of: allMasterItems.count) {
            // Recalculate when items change
            cachedItems = calculateItems()
        }
    }
}

#Preview {
    ShoppingListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
