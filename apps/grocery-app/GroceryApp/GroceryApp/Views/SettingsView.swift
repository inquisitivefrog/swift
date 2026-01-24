//
//  SettingsView.swift
//  GroceryApp
//
//  Settings menu view
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var showingClearDataAlert = false
    @State private var showingStoreSelection = false
    @State private var isImporting = false
    @State private var isClearingData = false
    
    var body: some View {
        NavigationStack {
            List {
                // FoodStuffs (Master List)
                Section {
                    NavigationLink(destination: MasterListView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("FoodStuffs")
                        }
                    }
                } footer: {
                    Text("Manage your master grocery list.")
                }
                
                // Stores
                Section {
                    NavigationLink(destination: StoreListView()) {
                        HStack {
                            Image(systemName: "storefront.fill")
                            Text("Stores")
                        }
                    }
                    
                    Button(action: {
                        showingStoreSelection = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Update Preferred Stores")
                        }
                    }
                } footer: {
                    Text("Manage your stores and update which stores you prefer for item imports.")
                }
                
                // Reset App Data and Import Defaults
                Section {
                    Button(role: .destructive, action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            if isClearingData || isImporting {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Reset App Data and Import Defaults")
                        }
                    }
                    .disabled(isClearingData || isImporting)
                } footer: {
                    Text("This will delete all items, shopping lists, stores, and categories, then import default items. You'll be asked to select your preferred stores.")
                }
                
                // Help
                Section {
                    NavigationLink(destination: HelpView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Getting Started")
                        }
                    }
                }
                
                // About
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset App Data and Import Defaults", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset and Import", role: .destructive) {
                    resetAndImport()
                }
            } message: {
                Text("This will permanently delete all items, shopping lists, stores, and categories, then import default items. You'll be asked to select your preferred stores. This action cannot be undone.")
            }
            .sheet(isPresented: $showingStoreSelection) {
                StoreSelectionView(isUpdating: true) {
                    showingStoreSelection = false
                    // Dismiss Settings view after store selection completes
                    dismiss()
                    // Switch to Build My List tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTab = 0 // Build My List tab
                    }
                }
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func clearAllData() {
        guard !isClearingData else { return }
        isClearingData = true
        
        Task { @MainActor in
            let dataService = DataService(context: viewContext)
            dataService.clearAllData()
            isClearingData = false
        }
    }
    
    private func resetAndImport() {
        guard !isClearingData && !isImporting else { return }
        isClearingData = true
        
        Task { @MainActor in
            // Step 1: Clear all data (this also clears selectedStoreNames)
            let dataService = DataService(context: viewContext)
            dataService.clearAllData()
            isClearingData = false
            
            // Step 2: Create default stores and categories (but don't import items yet)
            // Items will be imported AFTER user selects preferred stores
            let categoryService = CategoryService(context: viewContext)
            categoryService.createDefaultCategories()
            
            let storeService = StoreService(context: viewContext)
            storeService.createDefaultStores()
            
            do {
                try viewContext.save()
                print("Reset complete - ready for store selection")
            } catch {
                print("Error during reset: \(error)")
            }
            
            // Step 3: Automatically show Update Preferred Stores
            // Items will be imported after user selects stores
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingStoreSelection = true
            }
            
            // Step 4: Switch to Build My List tab after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedTab = 0 // Build My List tab
            }
        }
    }
    
}

#Preview {
    SettingsView(selectedTab: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
