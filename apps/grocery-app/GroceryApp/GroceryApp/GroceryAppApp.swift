//
//  GroceryAppApp.swift
//  GroceryApp
//
//  Created by Timothy Stilwell on 1/6/26.
//

import SwiftUI

@main
struct GroceryAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
