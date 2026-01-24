//
//  StoreSelectionView.swift
//  GroceryApp
//
//  View for first-time users to select their preferred stores
//

import SwiftUI
import CoreData

struct StoreSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStores: Set<UUID> = [] // For quick lookup
    @State private var selectedStoreOrder: [UUID] = [] // Preserve selection order
    @State private var allStores: [Store] = []
    
    let onComplete: () -> Void
    let isUpdating: Bool
    
    init(isUpdating: Bool = false, onComplete: @escaping () -> Void) {
        self.isUpdating = isUpdating
        self.onComplete = onComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text(isUpdating ? "Update Preferred Stores" : "Select Your Preferred Stores")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(isUpdating ? 
                         "Update your preferred stores. New items from selected stores will be available for import." :
                         "Choose the stores where you typically shop. We'll import items available at these locations.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Store selection grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 16)
                    ], spacing: 20) {
                        ForEach(allStores) { store in
                            StoreSelectionButton(
                                store: store,
                                isSelected: selectedStores.contains(store.id)
                            ) {
                                toggleStore(store)
                            }
                        }
                    }
                    .padding()
                }
                
                // Continue/Save button
                Button(action: {
                    saveSelectedStores()
                    
                    // Post notification that preferred stores were updated
                    NotificationCenter.default.post(name: NSNotification.Name("PreferredStoresUpdated"), object: nil)
                    
                    if isUpdating {
                        // Dismiss this view and Settings view, returning to Build My List
                        dismiss()
                        onComplete()
                    } else {
                        onComplete()
                    }
                }) {
                    HStack {
                        Text(isUpdating ? "Save" : "Continue")
                        Image(systemName: isUpdating ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedStores.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(selectedStores.isEmpty)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle(isUpdating ? "Update Stores" : "Store Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isUpdating {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                loadStores()
            }
        }
    }
    
    private func loadStores() {
        let storeService = StoreService(context: viewContext)
        storeService.createDefaultStores()
        allStores = storeService.fetchAllStores()
            .sorted { $0.name < $1.name }
        
        // Load existing selected stores if updating
        if isUpdating {
            // Load from UserDefaults (selected store names) - preserve order
            let selectedStoreNames = UserDefaults.standard.stringArray(forKey: "selectedStoreNames") ?? []
            
            // Preserve the order from UserDefaults
            for storeName in selectedStoreNames {
                if let store = allStores.first(where: { $0.name == storeName }) {
                    selectedStores.insert(store.id)
                    selectedStoreOrder.append(store.id)
                }
            }
            
            // Also check Store.isFavorite as backup (for stores not in UserDefaults)
            for store in allStores {
                if !selectedStores.contains(store.id) && store.isFavorite {
                    selectedStores.insert(store.id)
                    selectedStoreOrder.append(store.id)
                }
            }
        }
    }
    
    private func toggleStore(_ store: Store) {
        if selectedStores.contains(store.id) {
            selectedStores.remove(store.id)
            selectedStoreOrder.removeAll { $0 == store.id }
        } else {
            selectedStores.insert(store.id)
            selectedStoreOrder.append(store.id) // Add to end to preserve selection order
        }
    }
    
    private func saveSelectedStores() {
        // Mark selected stores as favorites (we'll use this to filter imports)
        for store in allStores {
            store.isFavorite = selectedStores.contains(store.id)
        }
        
        // Save selected store names to UserDefaults in selection order
        var storeMap: [UUID: Store] = [:]
        for store in allStores {
            storeMap[store.id] = store
        }
        
        let selectedStoreNames = selectedStoreOrder
            .compactMap { storeMap[$0] }
            .map { $0.name }
        UserDefaults.standard.set(selectedStoreNames, forKey: "selectedStoreNames")
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving selected stores: \(error)")
        }
        
        // Auto-import items after store selection (both first-time and updating)
        // This ensures items are always created with correct store assignments
        autoImportItems()
    }
    
    private func autoImportItems() {
        // Ensure categories and stores exist
        let categoryService = CategoryService(context: viewContext)
        categoryService.createDefaultCategories()
        
        // Import items for selected stores
        // This will create items for the newly selected stores
        let importService = MasterListImportService(context: viewContext)
        importService.importCommonItems()
        
        do {
            try viewContext.save()
            print("Auto-imported items after store selection")
        } catch {
            print("Error during auto-import: \(error)")
        }
    }
}

struct StoreSelectionButton: View {
    let store: Store
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: store.displayIconName)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(store.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 100, height: 100)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 8 : 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StoreSelectionView(onComplete: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
