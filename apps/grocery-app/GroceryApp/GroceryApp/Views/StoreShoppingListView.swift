//
//  StoreShoppingListView.swift
//  GroceryApp
//
//  View showing shopping list items organized by store
//

import SwiftUI
import CoreData

struct StoreShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var cachedStoresWithItems: [(store: Store?, count: Int)] = []
    @State private var showingCelebrationAlert = false
    @State private var hasShownCelebration = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingListItem.isChecked, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)
        ],
        animation: .default
    )
    private var shoppingItems: FetchedResults<ShoppingListItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Store.name, ascending: true)],
        animation: .default
    )
    private var allStores: FetchedResults<Store>
    
    // Get stores with shopping list items, sorted by item count (most to least) - cached
    var storesWithItems: [(store: Store?, count: Int)] {
        cachedStoresWithItems
    }
    
    // Count of checked items - used to trigger onChange when items are toggled
    var checkedItemsCount: Int {
        shoppingItems.filter { $0.isChecked }.count
    }
    
    // Calculate stores with items - only called when data changes
    private func calculateStoresWithItems() {
        // Get preferred store names in selection order
        let selectedStoreNames = UserDefaults.standard.stringArray(forKey: "selectedStoreNames") ?? []
        
        var storeCounts: [UUID?: Int] = [:]
        
        // Count items per store (only unchecked items)
        for item in shoppingItems where !item.isChecked {
            let storeId = item.store?.id
            storeCounts[storeId, default: 0] += 1
        }
        
        // Build result array - only include preferred stores, in selection order
        var result: [(store: Store?, count: Int)] = []
        
        // First, add stores in the order they were selected (preferred stores only)
        for storeName in selectedStoreNames {
            if let store = allStores.first(where: { $0.name == storeName }) {
                let storeId = store.id
                if let count = storeCounts[storeId], count > 0 {
                    result.append((store: store, count: count))
                }
            }
        }
        
        // If no preferred stores selected, show all stores alphabetically (fallback)
        if selectedStoreNames.isEmpty {
            for store in allStores.sorted(by: { $0.name < $1.name }) {
                let storeId = store.id
                if let count = storeCounts[storeId], count > 0 {
                    result.append((store: store, count: count))
                }
            }
        }
        
        // Do NOT add "No Store" - filter it out
        // Do NOT sort by count - preserve selection order
        cachedStoresWithItems = result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if storesWithItems.isEmpty {
                    // Simple empty state (alert provides the celebration message)
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No items to shop")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 12)
                    ], spacing: 20) {
                        ForEach(Array(storesWithItems.enumerated()), id: \.offset) { index, storeData in
                            NavigationLink {
                                StoreShoppingListItemsView(store: storeData.store)
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
            .navigationTitle("Shop By Stores")
            .sheet(isPresented: $showingSettings) {
                SettingsView(selectedTab: $selectedTab)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onAppear {
                // Calculate stores with items on appear
                calculateStoresWithItems()
                // Check if shopping is already complete
                checkShoppingComplete()
            }
            .onChange(of: shoppingItems.count) {
                // Recalculate when shopping items change
                calculateStoresWithItems()
                checkShoppingComplete()
            }
            .onChange(of: allStores.count) {
                // Recalculate when stores change
                calculateStoresWithItems()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PreferredStoresUpdated"))) { _ in
                // Refresh when preferred stores are updated
                calculateStoresWithItems()
            }
            .onChange(of: storesWithItems.isEmpty) {
                // Check if shopping is complete (all items checked)
                checkShoppingComplete()
            }
            .onChange(of: checkedItemsCount) {
                // Check if shopping is complete when items are toggled
                checkShoppingComplete()
            }
            .alert("Shopping Complete! 🎉", isPresented: $showingCelebrationAlert) {
                Button("Great!", role: .cancel) { }
            } message: {
                Text("Congratulations! You've completed your shopping. Come back next week to build your next shopping list!")
            }
        }
    }
    
    private func checkShoppingComplete() {
        // Check if there are any unchecked items
        let hasUncheckedItems = shoppingItems.contains { !$0.isChecked }
        
        // If no unchecked items and we haven't shown the alert yet, show celebration
        // Only show if there were items to begin with (not just empty list)
        if !hasUncheckedItems && !hasShownCelebration && !shoppingItems.isEmpty {
            hasShownCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingCelebrationAlert = true
            }
        } else if hasUncheckedItems {
            // Reset flag if items are unchecked again
            hasShownCelebration = false
        }
    }
    
}

// Store button content for the grid
struct StoreButtonContent: View {
    let store: Store?
    let itemCount: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: store?.displayIconName ?? "questionmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(store?.name ?? "No Store")
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
        .frame(width: 100, alignment: .top)
        .frame(minHeight: 100)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2)
    }
}

// View showing shopping list items for a specific store, grouped by category
struct StoreShoppingListItemsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let store: Store?
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingListItem.isChecked, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)
        ],
        animation: .default
    )
    private var allShoppingItems: FetchedResults<ShoppingListItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
    @State private var cachedStoreShoppingItems: [ShoppingListItem] = []
    @State private var cachedItemsByCategory: [(category: Category, items: [ShoppingListItem])] = []
    
    // Get shopping list items for this store (unchecked only) - cached
    var storeShoppingItems: [ShoppingListItem] {
        cachedStoreShoppingItems
    }
    
    // Group items by category - cached to reduce memory usage
    var itemsByCategory: [(category: Category, items: [ShoppingListItem])] {
        cachedItemsByCategory
    }
    
    // Calculate store shopping items - only called when data changes
    private func calculateStoreShoppingItems() {
        cachedStoreShoppingItems = allShoppingItems.filter { item in
            !item.isChecked && item.store == store
        }
    }
    
    // Calculate items by category - only called when data changes
    private func calculateItemsByCategory() {
        var grouped: [UUID: (category: Category, items: [ShoppingListItem])] = [:]
        
        for item in cachedStoreShoppingItems {
            if let category = item.groceryItem.category {
                let categoryId = category.id
                if grouped[categoryId] == nil {
                    grouped[categoryId] = (category: category, items: [])
                }
                grouped[categoryId]?.items.append(item)
            }
        }
        
        // Convert to array and sort by category name
        cachedItemsByCategory = grouped.values.sorted { $0.category.name < $1.category.name }
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
                
                // Items grouped by category
                if itemsByCategory.isEmpty {
                    Text("No items to purchase")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(itemsByCategory, id: \.category.id) { categoryData in
                        // Category header - larger and more prominent
                        HStack {
                            Image(systemName: categoryData.category.displayIconName)
                                .foregroundColor(.blue)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(categoryData.category.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color(.systemGroupedBackground))
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.blue.opacity(0.3))
                                .offset(y: -1),
                            alignment: .top
                        )
                        
                        // Items in this category
                        ForEach(categoryData.items) { shoppingItem in
                            Button(action: {
                                toggleItem(shoppingItem)
                            }) {
                                HStack {
                                    // Checkmark indicator
                                    if shoppingItem.isChecked {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                            .frame(width: 24)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray.opacity(0.3))
                                            .font(.title3)
                                            .frame(width: 24)
                                    }
                                    
                                    // Category icon
                                    Image(systemName: categoryData.category.displayIconName)
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text(shoppingItem.groceryItem.name)
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .padding(.leading, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(shoppingItem.isChecked ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(shoppingItem.isChecked ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .scrollIndicators(.visible)
        .navigationTitle(store?.name ?? "No Store")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Calculate store shopping items and category grouping on appear
            calculateStoreShoppingItems()
            calculateItemsByCategory()
        }
        .onChange(of: allShoppingItems.count) {
            // Recalculate when shopping items change
            calculateStoreShoppingItems()
            calculateItemsByCategory()
        }
        .onChange(of: cachedStoreShoppingItems.count) {
            // Recalculate when store shopping items change
            calculateItemsByCategory()
        }
    }
    
    private func toggleItem(_ shoppingItem: ShoppingListItem) {
        shoppingItem.isChecked.toggle()
        if shoppingItem.isChecked {
            shoppingItem.checkedDate = Date()
        } else {
            shoppingItem.checkedDate = nil
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error toggling item: \(error)")
        }
    }
}

#Preview {
    StoreShoppingListView(selectedTab: .constant(1))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
