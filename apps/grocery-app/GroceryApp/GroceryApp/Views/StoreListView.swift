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
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
                List {
                    ForEach(stores) { store in
                        StoreRow(store: store) {
                            // Tap to edit
                            storeToEdit = store
                            showingAddStore = true
                        }
                        .contextMenu {
                            Button(role: .destructive, action: {
                                deleteStore(store)
                            }) {
                                Label("Delete Store", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteStores)
                    
                    // Clear All Data section
                    Section {
                        Button(role: .destructive, action: {
                            showingClearDataAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Clear All Data")
                            }
                        }
                    } footer: {
                        Text("This will delete all items, shopping lists, stores, and categories. Default stores and categories will be recreated on next launch.")
                    }
                    
                    // About section
                    Section {
                        NavigationLink(destination: AboutView()) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("About")
                            }
                        }
                    }
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
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all items, shopping lists, stores, and categories. This action cannot be undone. Default stores and categories will be recreated on next launch.")
            }
            .sheet(isPresented: $showingAddStore) {
                AddStoreView(storeToEdit: storeToEdit)
                    .onDisappear {
                        storeToEdit = nil
                    }
            }
        }
    }
    
    private func clearAllData() {
        let dataService = DataService(context: viewContext)
        dataService.clearAllData()
    }
    
        private func deleteStore(_ store: Store) {
            // Use background context to avoid blocking main thread
            let container = PersistenceController.shared.container
            let storeID = store.objectID
            
            container.performBackgroundTask { backgroundContext in
                defer {
                    // Ensure context is processed and released
                    backgroundContext.processPendingChanges()
                }
                
                do {
                    if let storeToDelete = try? backgroundContext.existingObject(with: storeID) {
                        backgroundContext.delete(storeToDelete)
                        
                        if backgroundContext.hasChanges {
                            try backgroundContext.save()
                        }
                    }
                } catch {
                    print("Error deleting store: \(error)")
                }
            }
        }
        
        private func deleteStores(offsets: IndexSet) {
            let storesToDelete = offsets.map { stores[$0] }
            let storeIDs = storesToDelete.map { $0.objectID }
            
            // Use background context to avoid blocking main thread
            let container = PersistenceController.shared.container
            
            container.performBackgroundTask { backgroundContext in
                defer {
                    // Ensure context is processed and released
                    backgroundContext.processPendingChanges()
                }
                
                do {
                    for storeID in storeIDs {
                        if let storeToDelete = try? backgroundContext.existingObject(with: storeID) {
                            backgroundContext.delete(storeToDelete)
                        }
                    }
                    
                    if backgroundContext.hasChanges {
                        try backgroundContext.save()
                    }
                } catch {
                    print("Error deleting stores: \(error)")
                }
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

