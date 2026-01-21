# Swift Workspace

Applications developed using Swift with help from Cursor

## Projects

### 1. helloworld

   Basic Swift command-line application
  
   - Simple "Hello, World!" output
   - Tested with XCTest
   - Uses Swift Package Manager (SPM)

### 2. ShoppingKart (grocery-app)

   **Portfolio Project**: Native iOS shopping list application
  
   **Status**: ✅ Submitted to App Store for Review
  
   A production-ready iOS app demonstrating modern SwiftUI development, Core Data persistence, and complete App Store submission workflow. Helps users organize grocery shopping by store with intelligent item filtering and category management.
   
   **Technology Stack:**
   - SwiftUI + Core Data
   - Swift Concurrency (async/await)
   - XCTest (Unit + UI tests)
   - Xcode Cloud CI/CD
   
   **Key Features:**
   - Store-based shopping organization (Trader Joe's, Whole Foods, Costco, etc.)
   - Smart item import filtered by preferred stores
   - Category management (Produce, Dairy, Meats, etc.)
   - Shopping list persistence with local-first architecture
   - First-time user onboarding flow
   
   See [apps/grocery-app/README.md](./apps/grocery-app/README.md) for complete documentation and portfolio details.

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

For iOS projects like `ShoppingKart`, open the Xcode project:

```bash
cd apps/grocery-app
open GroceryApp/GroceryApp.xcodeproj
```

Then build and run from Xcode, or use command line:

```bash
cd apps/grocery-app
./ci-cd-commands.sh build    # Build
./ci-cd-commands.sh test     # Run tests
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
│   └── grocery-app/    # ShoppingKart - iOS shopping list app (Portfolio)
└── README.md            # This file
```

