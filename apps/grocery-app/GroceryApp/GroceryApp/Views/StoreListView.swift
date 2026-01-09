//
//  StoreListView.swift
//  GroceryApp
//
//  View for managing stores
//

import SwiftUI
import CoreData

struct StoreListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Store.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \Store.name, ascending: true)
        ],
        animation: .default
    )
    private var stores: FetchedResults<Store>
    
    @State private var showingAddStore = false
    @State private var storeToEdit: Store? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(stores) { store in
                    StoreRow(store: store) {
                        // Tap to edit
                        storeToEdit = store
                        showingAddStore = true
                    }
                }
                .onDelete(perform: deleteStores)
            }
            .navigationTitle("Stores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        storeToEdit = nil
                        showingAddStore = true 
                    }) {
                        Label("Add Store", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStore) {
                AddStoreView(storeToEdit: storeToEdit)
                    .onDisappear {
                        storeToEdit = nil
                    }
            }
        }
    }
    
    private func deleteStores(offsets: IndexSet) {
        let storesToDelete = offsets.map { stores[$0] }
        
        withAnimation {
            storesToDelete.forEach(viewContext.delete)
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error deleting stores: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct StoreRow: View {
    @ObservedObject var store: Store
    @Environment(\.managedObjectContext) private var viewContext
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: store.displayIconName)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(store.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if store.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StoreListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

