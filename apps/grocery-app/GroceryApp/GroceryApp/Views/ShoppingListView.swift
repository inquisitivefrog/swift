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
    
    // Fetch master list items for category browsing
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)
        ],
        animation: .default
    )
    private var masterItems: FetchedResults<GroceryItem>
    
    @State private var showingAddItem = false
    @State private var isClearingChecked = false
    @State private var selectedCategory: GroceryCategory? = nil
    
    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }
    
    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }
    
    // Get shopping list items filtered by selected category
    var categoryShoppingItems: [ShoppingListItem] {
        guard let category = selectedCategory else { return [] }
        return items.filter { item in
            item.groceryItem.categoryEnum == category
        }
    }
    
    // Get category counts from shopping list (not master list)
    var categoryCounts: [(category: GroceryCategory, count: Int)] {
        GroceryCategory.allCases.map { category in
            let count = items.filter { $0.groceryItem.categoryEnum == category }.count
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
            .navigationDestination(for: GroceryCategory.self) { category in
                ShoppingListCategoryView(
                    category: category,
                    onDelete: { item in
                        deleteShoppingItem(item)
                    },
                    onAddItem: {
                        // Handled in ShoppingListCategoryView
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
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
            .sheet(isPresented: $showingAddItem) {
                AddItemView(alwaysAddToShoppingList: true)
            }
        }
    }
    
    private func deleteShoppingItem(_ item: ShoppingListItem) {
        viewContext.delete(item)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting shopping item: \(error)")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        // Get all items as array to avoid issues with FetchedResults during deletion
        let allItems = Array(items)
        let itemsToDelete = offsets.map { allItems[$0] }
        
        withAnimation {
            itemsToDelete.forEach(viewContext.delete)
        }
        
        // Save outside animation to avoid CoreGraphics NaN issues
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error deleting items: \(nsError), \(nsError.userInfo)")
            // Don't fatalError - just log the error
        }
    }
    
    private func clearCheckedItems() {
        guard !isClearingChecked else { return }
        isClearingChecked = true
        
        // Use performBackgroundTask to avoid blocking main thread and FetchedResults conflicts
        let container = PersistenceController.shared.container
        container.performBackgroundTask { backgroundContext in
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
            } catch {
                print("Error clearing checked items: \(error)")
            }
        }
        
        // Reset flag after a delay to allow background task to complete
        // The view will update automatically when changes merge from background context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isClearingChecked = false
        }
    }
}

struct ShoppingListItemRow: View {
    @ObservedObject var item: ShoppingListItem
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            // Checkbox
            Button(action: {
                item.toggleChecked()
                saveContext()
            }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.groceryItem.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                
                HStack {
                    // Category
                    if let category = item.groceryItem.categoryEnum {
                        Label(category.displayName, systemImage: category.iconName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Store
                    if let store = item.store {
                        Label(store.name, systemImage: store.displayIconName)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// Category button content (for use in NavigationLink)
struct CategoryButtonContent: View {
    let category: GroceryCategory
    let itemCount: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(category.displayName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
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

// Category button widget (for backward compatibility if needed)
struct CategoryButton: View {
    let category: GroceryCategory
    let isSelected: Bool
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(itemCount)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : (itemCount > 0 ? .secondary : Color.secondary.opacity(0.5)))
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 4 : 2)
        }
        .buttonStyle(.plain)
    }
}

// View showing shopping list items in a selected category with edit options
struct ShoppingListCategoryView: View {
    let category: GroceryCategory
    let onDelete: (ShoppingListItem) -> Void
    let onAddItem: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItem = false
    
    // Fetch master list items for this category
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)],
        animation: .default
    )
    private var allMasterItems: FetchedResults<GroceryItem>
    
    // Fetch all shopping list items dynamically
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingListItem.addedDate, ascending: true)],
        animation: .default
    )
    private var allShoppingItems: FetchedResults<ShoppingListItem>
    
    // Get master list items in this category
    var masterItemsInCategory: [GroceryItem] {
        allMasterItems.filter { $0.categoryEnum == category }
    }
    
    // Get shopping list items in this category (dynamic)
    var shoppingItemsInCategory: [ShoppingListItem] {
        allShoppingItems.filter { $0.groceryItem.categoryEnum == category }
    }
    
    // Check if a master item is in shopping list
    func isInShoppingList(_ item: GroceryItem) -> Bool {
        shoppingItemsInCategory.contains { $0.groceryItem == item }
    }
    
    // Toggle item in shopping list
    func toggleItemInShoppingList(_ item: GroceryItem) {
        if let shoppingItem = shoppingItemsInCategory.first(where: { $0.groceryItem == item }) {
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
        List {
            Section {
                // Category title and add button
                HStack {
                    Text(category.displayName)
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
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color(.systemGroupedBackground))
            }
            
            Section {
                // Master list items
                if masterItemsInCategory.isEmpty {
                    Text("No items in master list")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(masterItemsInCategory) { item in
                        Button(action: {
                            toggleItemInShoppingList(item)
                        }) {
                            HStack {
                                // Category icon
                                Image(systemName: category.iconName)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundColor(isInShoppingList(item) ? .white : .primary)
                                    
                                    if let store = item.preferredStore {
                                        HStack(spacing: 4) {
                                            Image(systemName: store.displayIconName)
                                                .foregroundColor(isInShoppingList(item) ? .white.opacity(0.8) : .orange)
                                                .font(.caption)
                                            Text(store.name)
                                                .font(.caption)
                                                .foregroundColor(isInShoppingList(item) ? .white.opacity(0.8) : .orange)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(isInShoppingList(item) ? Color.green.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.visible)
        .navigationTitle(category.displayName)
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

