//
//  MasterListView.swift
//  GroceryApp
//
//  View for managing the master grocery list
//

import SwiftUI
import CoreData

struct MasterListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true),
            NSSortDescriptor(keyPath: \GroceryItem.createdDate, ascending: true)
        ],
        animation: .default
    )
    private var items: FetchedResults<GroceryItem>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category? = nil
    @State private var isImporting = false
    @State private var cachedCategoryCounts: [(category: Category, count: Int)] = []
    
    // Get category counts from master list - cached to reduce memory usage
    var categoryCounts: [(category: Category, count: Int)] {
        cachedCategoryCounts
    }
    
    // Calculate category counts - only called when data changes
    private func calculateCategoryCounts() {
        // Use Dictionary for O(1) lookups instead of filtering
        var itemCountsByCategory: [UUID: Int] = [:]
        for item in items {
            if let categoryId = item.category?.id {
                itemCountsByCategory[categoryId, default: 0] += 1
            }
        }
        
        // Build result array efficiently
        cachedCategoryCounts = categories.map { category in
            let count = itemCountsByCategory[category.id] ?? 0
            return (category: category, count: count)
        }.sorted { $0.count > $1.count } // Sort by count, most to least
    }
    
    var body: some View {
        NavigationStack {
            // Category picker - scrollable grid of category buttons
            // Sorted by count (most to least), showing master list counts
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 12)
                ], spacing: 20) {
                ForEach(categoryCounts, id: \.category.id) { categoryData in
                    NavigationLink(destination: MasterListCategoryView(category: categoryData.category)) {
                        VStack(alignment: .center, spacing: 6) {
                            Image(systemName: categoryData.category.displayIconName)
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(categoryData.category.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("\(categoryData.count)")
                                .font(.caption2)
                                .foregroundColor(categoryData.count > 0 ? .secondary : Color.secondary.opacity(0.5))
                            
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
                    .disabled(isImporting)
                    .opacity(isImporting ? 0.6 : 1.0)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            deleteCategory(categoryData.category)
                        }) {
                            Label("Delete Category", systemImage: "trash")
                        }
                        .disabled(categoryData.count > 0) // Can't delete if it has items
                        
                        Button(action: {
                            categoryToEdit = categoryData.category
                            showingAddCategory = true
                        }) {
                            Label("Edit Category", systemImage: "pencil")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("FoodStuffs")
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        categoryToEdit = nil
                        showingAddCategory = true 
                    }) {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            ToolbarItem(placement: .navigationBarLeading) {
                // Import button - always visible, shows state clearly
                // Allow re-import to update store assignments and add new items
                let canImport = !isImporting
                
                Button {
                    if canImport {
                        importCommonItems()
                    }
                } label: {
                    if isImporting {
                        ProgressView()
                            .frame(width: 20, height: 20)
                            .tint(.blue)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.body)
                            .foregroundColor(canImport ? .blue : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canImport)
            }
        }
        .onAppear {
            // Calculate category counts on appear
            calculateCategoryCounts()
        }
        .onChange(of: items.count) {
            // Recalculate when items change
            calculateCategoryCounts()
        }
        .onChange(of: categories.count) {
            // Recalculate when categories change
            calculateCategoryCounts()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(categoryToEdit: categoryToEdit)
                .onDisappear {
                    categoryToEdit = nil
                }
        }
        .onAppear {
            // Force reset import state if stuck (safety measure)
            if isImporting {
                isImporting = false
            }
        }
        }
    }
    
    private func deleteCategory(_ category: Category) {
        let categoryService = CategoryService(context: viewContext)
        do {
            try categoryService.deleteCategory(category)
        } catch {
            print("Error deleting category: \(error)")
            // Could show an alert here if category has items
        }
    }
    
    private func importCommonItems() {
        guard !isImporting else {
            return
        }
        
        isImporting = true
        
        // Run import on main thread (Core Data context must be used on its creating thread)
        // Use async to allow UI to update first
        Task { @MainActor in
            // Import on main context (items will appear immediately)
            let importService = MasterListImportService(context: viewContext)
            importService.importCommonItems()
            
            // Reset flag after import completes (save is synchronous, so this happens after save)
            isImporting = false
        }
    }
}

// View showing master list items in a selected category
struct MasterListCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let category: Category
    
    @FetchRequest var items: FetchedResults<GroceryItem>
    
    @State private var showingAddItem = false
    @State private var itemToEdit: GroceryItem? = nil
    @State private var isImporting = false
    @State private var cachedSortedItems: [GroceryItem] = []
    
    // Sorted items: by store name, then by item name - cached to prevent crashes
    var sortedItems: [GroceryItem] {
        cachedSortedItems
    }
    
    // Calculate sorted items - only called when data changes
    private func calculateSortedItems() {
        // Convert to array and ensure objects are loaded (not faulted)
        let itemsArray = Array(items)
        
        // Pre-fetch store relationships to avoid faults during sorting
        let itemIDs = itemsArray.compactMap { $0.objectID }
        let fetchRequest = NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
        fetchRequest.predicate = NSPredicate(format: "SELF IN %@", itemIDs)
        fetchRequest.relationshipKeyPathsForPrefetching = ["preferredStore"]
        
        do {
            let context = viewContext
            let loadedItems = try context.fetch(fetchRequest)
            
            // Now sort with fully loaded objects
            cachedSortedItems = loadedItems.sorted { item1, item2 in
                // Safely access store names
                let store1 = item1.firstPreferredStore
                let store2 = item2.firstPreferredStore
                let store1Name = store1?.name ?? ""
                let store2Name = store2?.name ?? ""
                
                if store1Name != store2Name {
                    return store1Name < store2Name
                }
                return item1.name < item2.name
            }
        } catch {
            // Fallback to simple name sorting if fetch fails
            cachedSortedItems = itemsArray.sorted { $0.name < $1.name }
            print("Error prefetching stores for sorting: \(error)")
        }
    }
    
    init(category: Category) {
        self.category = category
        _items = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)
            ],
            predicate: NSPredicate(format: "category == %@", category),
            animation: .default
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category title
                HStack {
                    Text(category.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Items list
                if sortedItems.isEmpty {
                    Text("No items in this category")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(sortedItems) { item in
                        MasterListItemRow(item: item, onTap: {
                            itemToEdit = item
                            showingAddItem = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .scrollIndicators(.visible)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Calculate sorted items on appear
            calculateSortedItems()
        }
        .onChange(of: items.count) {
            // Recalculate when items change
            calculateSortedItems()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Import button for this category
                    Button {
                        if !isImporting {
                            importCategoryItems()
                        }
                    } label: {
                        if isImporting {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isImporting)
                    .opacity(isImporting ? 0.5 : 1.0)
                    
                    // Add item button
                    Button(action: {
                        itemToEdit = nil
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(itemToEdit: itemToEdit, prefillCategory: category)
                .onDisappear {
                    itemToEdit = nil
                }
        }
    }
    
        private func deleteItem(_ item: GroceryItem) {
            viewContext.delete(item)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
        
        private func importCategoryItems() {
            guard !isImporting else { return }
            isImporting = true
            
            // Run import on main thread (Core Data context must be used on its creating thread)
            // Use async to allow UI to update first
            Task { @MainActor in
                let importService = MasterListImportService(context: viewContext)
                _ = importService.importItemsForCategory(category)
                
                // Reset flag after import completes (save is synchronous, so this happens after save)
                isImporting = false
            }
        }
    }

struct MasterListItemRow: View {
    let item: GroceryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Category icon
                if let category = item.category {
                    Image(systemName: category.displayIconName)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // Preferred store name and icon
                    if let store = item.firstPreferredStore {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MasterListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
