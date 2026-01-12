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
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingListItem.isChecked, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)
        ],
        animation: .default
    )
    private var items: FetchedResults<ShoppingListItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }
    
    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }
    
    @State private var isClearingChecked = false
    
    // Get category counts from shopping list (not master list) - optimized
    var categoryCounts: [(category: Category, count: Int)] {
        // Use Dictionary for O(1) lookups instead of filtering
        var itemCountsByCategory: [UUID: Int] = [:]
        for item in items {
            // groceryItem is non-optional, but category might be optional
            if let categoryId = item.groceryItem.category?.id {
                itemCountsByCategory[categoryId, default: 0] += 1
            }
        }
        
        // Build result array efficiently
        return categories.map { category in
            let count = itemCountsByCategory[category.id] ?? 0
            return (category: category, count: count)
        }.sorted { $0.count > $1.count } // Sort by count, most to least
    }
    
    var body: some View {
        NavigationStack {
            // Category picker - scrollable grid of category buttons
            // Sorted by count (most to least), showing shopping list counts
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 12)
                ], spacing: 12) {
                    ForEach(categoryCounts, id: \.category.id) { categoryData in
                        NavigationLink(value: categoryData.category) {
                            CategoryButtonContent(
                                category: categoryData.category,
                                itemCount: categoryData.count
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Shopping List")
            .navigationDestination(for: Category.self) { category in
                ShoppingListCategoryView(category: category)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !checkedItems.isEmpty && !isClearingChecked {
                        Button("Clear Checked") {
                            clearCheckedItems()
                        }
                    } else if isClearingChecked {
                        ProgressView()
                    }
                }
            }
        }
    }
    
    private func clearCheckedItems() {
        guard !isClearingChecked else { return }
        isClearingChecked = true
        
        // Use performBackgroundTask to avoid blocking main thread and FetchedResults conflicts
        let container = PersistenceController.shared.container
        container.performBackgroundTask { backgroundContext in
            defer {
                // Ensure context is processed and released
                backgroundContext.processPendingChanges()
            }
            
            // Fetch object IDs in background context
            let fetchRequest: NSFetchRequest<NSManagedObjectID> = NSFetchRequest(entityName: "ShoppingListItem")
            fetchRequest.predicate = NSPredicate(format: "isChecked == YES")
            fetchRequest.resultType = .managedObjectIDResultType
            
            do {
                let objectIDs = try backgroundContext.fetch(fetchRequest)
                
                // Delete objects in background context
                for objectID in objectIDs {
                    if let object = try? backgroundContext.existingObject(with: objectID) {
                        backgroundContext.delete(object)
                    }
                }
                
                // Save background context
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
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

// Category button content
struct CategoryButtonContent: View {
    let category: Category
    let itemCount: Int
    
    var body: some View {
        VStack(spacing: 6) {
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
        }
        .frame(width: 80, height: 80)
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
    @State private var showingAddItem = false
    
    // Fetch all master list items for this category
    @FetchRequest var allMasterItems: FetchedResults<GroceryItem>
    
    // Fetch shopping list items for this category
    @FetchRequest var shoppingItems: FetchedResults<ShoppingListItem>
    
    // Sorted items: by store name, then by item name
    var sortedMasterItems: [GroceryItem] {
        allMasterItems.sorted { item1, item2 in
            let store1Name = item1.preferredStore?.name ?? ""
            let store2Name = item2.preferredStore?.name ?? ""
            
            if store1Name != store2Name {
                return store1Name < store2Name
            }
            return item1.name < item2.name
        }
    }
    
    init(category: Category) {
        self.category = category
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
    
    // Toggle item in shopping list
    func toggleItemInShoppingList(_ item: GroceryItem) {
        if let shoppingItem = shoppingItems.first(where: { $0.groceryItem == item }) {
            // Item is in shopping list - remove it
            viewContext.delete(shoppingItem)
        } else {
            // Item is not in shopping list - add it
            let shoppingItem = ShoppingListItem(context: viewContext)
            shoppingItem.id = UUID()
            shoppingItem.groceryItem = item
            shoppingItem.store = item.preferredStore
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
                // Category title and add button
                HStack {
                    Text(category.name)
                        .font(.title2)
                        .fontWeight(.semibold)
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
                
                // Master list items
                if sortedMasterItems.isEmpty {
                    Text("No items in master list")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(sortedMasterItems) { item in
                        Button(action: {
                            toggleItemInShoppingList(item)
                        }) {
                            HStack {
                                // Checkmark indicator for selected items (colorblind-friendly)
                                if isInShoppingList(item) {
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
                                Image(systemName: category.displayIconName)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundColor(.primary)
                                    
                                    if let store = item.preferredStore {
                                        HStack(spacing: 4) {
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
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isInShoppingList(item) ? Color.blue.opacity(0.1) : Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isInShoppingList(item) ? Color.blue : Color.clear, lineWidth: 2)
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
        .scrollIndicators(.visible)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddItemView(alwaysAddToShoppingList: true, prefillCategory: category)
        }
    }
}

#Preview {
    ShoppingListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
