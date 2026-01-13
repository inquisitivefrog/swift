//
//  TestHelpers.swift
//  GroceryAppTests
//
//  Test helpers for Core Data testing
//

import Foundation
import CoreData
@testable import GroceryApp

/// Shared Core Data model instance for all tests to prevent "Multiple NSEntityDescriptions" warnings
private let sharedTestModel: NSManagedObjectModel = {
    // Create a temporary container to extract the model (same way NSPersistentContainer loads it)
    // This ensures we use the exact same model that the app uses
    let tempContainer = NSPersistentContainer(name: "GroceryApp")
    return tempContainer.managedObjectModel
}()

extension PersistenceController {
    /// Create an in-memory Core Data context for testing
    /// Uses a shared model instance to prevent Core Data warnings
    static var test: PersistenceController {
        return PersistenceController(inMemory: true, managedObjectModel: sharedTestModel)
    }
}
