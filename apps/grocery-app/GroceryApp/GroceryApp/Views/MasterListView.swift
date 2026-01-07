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
            NSSortDescriptor(keyPath: \GroceryItem.name, ascending: true)
        ],
        animation: .default
    )
    private var items: FetchedResults<GroceryItem>
    
    @State private var showingAddItem = false
    @State private var searchText = ""
    
    var filteredItems: [GroceryItem] {
        if searchText.isEmpty {
            return Array(items)
        }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredItems) { item in
                    MasterListItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .searchable(text: $searchText, prompt: "Search items")
            .navigationTitle("Master List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct MasterListItemRow: View {
    let item: GroceryItem
    
    var body: some View {
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
                
                if let category = item.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Preferred store icon
            if let store = item.preferredStore {
                Image(systemName: store.displayIconName)
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    MasterListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

