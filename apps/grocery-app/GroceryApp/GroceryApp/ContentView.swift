//
//  ContentView.swift
//  GroceryApp
//
//  Created by Timothy Stilwell on 1/6/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        // This view is no longer used - MainTabView is the main entry point
        // Keeping this file for reference, but it's replaced by MainTabView
        Text("This view is replaced by MainTabView")
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
