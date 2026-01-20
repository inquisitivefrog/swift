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
                    
                    Button(action: {
                        importItems()
                    }) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text("Import Default Items")
                        }
                    }
                    .disabled(isImporting)
                } footer: {
                    Text("Import default grocery lists from your preferred stores.")
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
                
                // Clear All Data
                Section {
                    Button(role: .destructive, action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            if isClearingData {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "trash.fill")
                            }
                            Text("Clear All Data")
                        }
                    }
                    .disabled(isClearingData)
                } footer: {
                    Text("This will delete all items, shopping lists, stores, and categories. Default stores and categories will be recreated on next launch.")
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
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all items, shopping lists, stores, and categories. This action cannot be undone. Default stores and categories will be recreated on next launch.")
            }
            .sheet(isPresented: $showingStoreSelection) {
                StoreSelectionView(isUpdating: true) {
                    showingStoreSelection = false
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
    
    private func importItems() {
        guard !isImporting else { return }
        isImporting = true
        
        Task { @MainActor in
            // Ensure categories and stores exist
            let categoryService = CategoryService(context: viewContext)
            categoryService.createDefaultCategories()
            
            let storeService = StoreService(context: viewContext)
            storeService.createDefaultStores()
            
            // Import items for selected stores
            let importService = MasterListImportService(context: viewContext)
            importService.importCommonItems()
            
            do {
                try viewContext.save()
                print("Import complete from Settings")
            } catch {
                print("Error during import: \(error)")
            }
            
            isImporting = false
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
