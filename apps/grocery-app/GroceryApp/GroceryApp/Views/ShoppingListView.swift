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
    
    @State private var showingAddItem = false
    
    var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }
    
    var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Unchecked items
                if !uncheckedItems.isEmpty {
                    Section("To Buy") {
                        ForEach(uncheckedItems) { item in
                            ShoppingListItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                // Checked items
                if !checkedItems.isEmpty {
                    Section("Found") {
                        ForEach(checkedItems) { item in
                            ShoppingListItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                // Empty state
                if items.isEmpty {
                    Section {
                        Text("No items in shopping list")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !checkedItems.isEmpty {
                        Button("Clear Checked") {
                            clearCheckedItems()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
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
        // Get a snapshot of checked items before deletion to avoid issues during iteration
        let itemsToDelete = checkedItems
        
        withAnimation {
            itemsToDelete.forEach(viewContext.delete)
        }
        
        // Save outside animation to avoid CoreGraphics NaN issues
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error clearing checked items: \(nsError), \(nsError.userInfo)")
            // Don't fatalError - just log the error
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

#Preview {
    ShoppingListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

