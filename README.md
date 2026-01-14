# Swift Workspace

Applications developed using Swift with help from Cursor

## Projects

### 1. helloworld

   Basic Swift command-line application
  
   - Simple "Hello, World!" output
   - Tested with XCTest
   - Uses Swift Package Manager (SPM)

### 2. grocery-app

   Native iOS grocery shopping application for iPhone
  
   - **Master List Management**: Comprehensive grocery item database organized by categories
   - **Shopping Lists**: Create and manage active shopping lists
   - **Store Organization**: Organize shopping by store with preferred store assignments
   - **Save/Load Lists**: Save shopping lists for recurring shopping trips
   - **Check-off Items**: Mark items as purchased during shopping
   - **Landing Page**: Welcome screen with first-time user instructions
   - **Local Storage**: All data stored locally using Core Data
   - **Memory Optimized**: Cached computed properties to prevent memory issues
   
   **Technology Stack:**
   - SwiftUI for user interface
   - Core Data for data persistence
   - Model-View-Service (MVS) architecture
   - Unit tests with XCTest
   
   **Key Features:**
   - Import common grocery items with category and store assignments
   - Shop by category or by store
   - Clear checked items after shopping
   - Settings for managing stores, categories, and data
   - Completion celebration when all shopping is done
   
   See [apps/grocery-app/README.md](./apps/grocery-app/README.md) for more details.

## Getting Started

### Command-Line Projects (SPM)

For Swift Package Manager projects like `helloworld`, navigate to the project directory:

```bash
cd apps/helloworld
swift build    # Build the project
swift run      # Run the application
swift test     # Run tests
```

### iOS Projects (Xcode)

For iOS projects like `grocery-app`, open the Xcode project:

```bash
cd apps/grocery-app
open GroceryApp/GroceryApp.xcodeproj
```

Then build and run from Xcode, or use command line:

```bash
xcodebuild -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Requirements

- Swift 6.1 or later
- macOS (or Linux with Swift installed)
- Xcode Command Line Tools (on macOS)

## Workspace Structure

```
swift/
├── apps/
│   ├── helloworld/      # Hello World command-line application
│   └── grocery-app/    # iOS Grocery Shopping application
└── README.md            # This file
```

