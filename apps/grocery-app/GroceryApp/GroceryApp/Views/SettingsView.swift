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
                }
                
                // Stores
                Section {
                    NavigationLink(destination: StoreListView()) {
                        HStack {
                            Image(systemName: "storefront.fill")
                            Text("Stores")
                        }
                    }
                }
                
                // Clear All Data
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
        }
    }
    
    private func clearAllData() {
        let dataService = DataService(context: viewContext)
        dataService.clearAllData()
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
