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
    
    @State private var showingAddItem = false
    @State private var itemToEdit: GroceryItem? = nil
    @State private var selectedCategory: GroceryCategory? = nil
    
    // Get category counts from master list
    var categoryCounts: [(category: GroceryCategory, count: Int)] {
        GroceryCategory.allCases.map { category in
            let count = items.filter { $0.categoryEnum == category }.count
            return (category: category, count: count)
        }.sorted { $0.count > $1.count } // Sort by count, most to least
    }
    
    // Get items from master list filtered by selected category
    var categoryItems: [GroceryItem] {
        guard let category = selectedCategory else { return [] }
        return items.filter { item in
            item.categoryEnum == category
        }
    }
    
    var body: some View {
        NavigationStack {
            // Category picker - scrollable grid of category buttons
            // Sorted by count (most to least), showing master list counts
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 12)
                ], spacing: 12) {
                    ForEach(categoryCounts, id: \.category.id) { categoryData in
                        NavigationLink(value: categoryData.category) {
                            VStack(spacing: 6) {
                                Image(systemName: categoryData.category.iconName)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(categoryData.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("\(categoryData.count)")
                                    .font(.caption2)
                                    .foregroundColor(categoryData.count > 0 ? .secondary : Color.secondary.opacity(0.5))
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
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Master List")
            .navigationDestination(for: GroceryCategory.self) { category in
                MasterListCategoryView(
                    category: category,
                    items: items.filter { $0.categoryEnum == category },
                    onItemTap: { item in
                        itemToEdit = item
                        showingAddItem = true
                    },
                    onDelete: { item in
                        deleteItem(item)
                    },
                    onAddItem: {
                        showingAddItem = true
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        itemToEdit = nil
                        showingAddItem = true 
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(itemToEdit: itemToEdit)
                    .onDisappear {
                        itemToEdit = nil
                    }
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
}

// View showing master list items in a selected category
struct MasterListCategoryView: View {
    let category: GroceryCategory
    let items: [GroceryItem]
    let onItemTap: (GroceryItem) -> Void
    let onDelete: (GroceryItem) -> Void
    let onAddItem: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItem = false
    @State private var itemToEdit: GroceryItem? = nil
    
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
                        itemToEdit = nil
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
                // Items list
                if items.isEmpty {
                    Text("No items in this category")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(items) { item in
                        MasterListItemRow(item: item, onTap: {
                            itemToEdit = item
                            showingAddItem = true
                        })
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            onDelete(items[index])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.visible)
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddItemView(itemToEdit: itemToEdit, prefillCategory: category)
                .onDisappear {
                    itemToEdit = nil
                }
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
                if let category = item.categoryEnum {
                    Image(systemName: category.iconName)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    // Preferred store name and icon
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MasterListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

