//
//  AddCategoryView.swift
//  GroceryApp
//
//  View for adding/editing categories
//

import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let categoryToEdit: Category?
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var categoryName = ""
    @State private var selectedIcon = "questionmark.circle.fill"
    @State private var showDuplicateAlert = false
    
    let iconOptions = [
        "leaf.fill",
        "drop.fill",
        "fish.fill",
        "fork.knife",
        "birthday.cake.fill",
        "cabinet.fill",
        "cylinder.fill",
        "cup.and.saucer.fill",
        "circle.grid.hex.fill",
        "sparkles",
        "sunrise.fill",
        "flame.fill",
        "snowflake",
        "questionmark.circle.fill",
        "cart.fill",
        "bag.fill",
        "basket.fill",
        "tag.fill",
        "star.fill",
        "heart.fill"
    ]
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<Category>
    
    init(categoryToEdit: Category? = nil) {
        self.categoryToEdit = categoryToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                        .focused($isTextFieldFocused)
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(iconOptions, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                }
            }
            .navigationTitle(categoryToEdit == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let category = categoryToEdit {
                    // Populate fields for editing
                    categoryName = category.name
                    selectedIcon = category.iconName ?? Category.defaultIconName
                }
                // Auto-focus the text field and show keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
            .alert("Duplicate Category", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A category named '\(categoryName)' already exists.")
            }
        }
    }
    
    private func saveCategory() {
        if let category = categoryToEdit {
            // Update existing category - check for duplicate only if name changed
            if category.name != categoryName {
                // Check if another category with this name exists
                let duplicateExists = categories.contains { $0.name.lowercased() == categoryName.lowercased() && $0 != category }
                if duplicateExists {
                    showDuplicateAlert = true
                    return
                }
            }
            category.name = categoryName
            category.iconName = selectedIcon
        } else {
            // Create new category - check for duplicate
            let duplicateExists = categories.contains { $0.name.lowercased() == categoryName.lowercased() }
            if duplicateExists {
                showDuplicateAlert = true
                return
            }
            
            // Create new category
            let categoryService = CategoryService(context: viewContext)
            _ = categoryService.createCategory(name: categoryName, iconName: selectedIcon)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving category: \(error)")
        }
    }
}

#Preview {
    AddCategoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

