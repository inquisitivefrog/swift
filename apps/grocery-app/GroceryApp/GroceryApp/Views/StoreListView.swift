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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(stores) { store in
                    StoreRow(store: store)
                }
                .onDelete(perform: deleteStores)
            }
            .navigationTitle("Stores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddStore = true }) {
                        Label("Add Store", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStore) {
                AddStoreView()
            }
        }
    }
    
    private func deleteStores(offsets: IndexSet) {
        withAnimation {
            offsets.map { stores[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct StoreRow: View {
    @ObservedObject var store: Store
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            Image(systemName: store.displayIconName)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(store.name)
                .font(.body)
            
            Spacer()
            
            if store.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    StoreListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

