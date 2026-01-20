# Swift Development Overview for GroceryApp

## Development Stack

### 1. **Swift** - The Programming Language
- **What it is**: Apple's modern programming language for iOS, macOS, watchOS, and tvOS
- **Version**: Swift 6.x (latest)
- **Used for**: All application code, business logic, data models, services

### 2. **Xcode** - Apple's Integrated Development Environment (IDE)
- **What it is**: The official IDE for developing Apple platform applications
- **Used for**:
  - Project management
  - Building and compiling
  - Running on simulators/devices
  - Interface Builder (though GroceryApp uses SwiftUI, not Interface Builder)
  - Debugging
  - Source control integration
- **Key Features**:
  - Build system
  - Simulator management
  - Device deployment
  - Code signing
  - App Store submission

### 3. **Cursor** - AI-Powered Code Editor
- **What it is**: A code editor (based on VS Code) with AI assistance
- **Used for**: 
  - Writing and editing code
  - AI-assisted development (like our conversation!)
  - File management
  - Git integration
- **Note**: Cursor is the editor you're using right now. It's great for writing code, but Xcode is still needed for:
  - Building iOS apps
  - Running on simulators/devices
  - Managing Xcode projects
  - App Store deployment

### 4. **XCTest** - Testing Framework
- **What it is**: Apple's built-in testing framework (bundled with Xcode)
- **Used for**:
  - Unit tests (testing individual functions/classes)
  - UI tests (testing user interactions)
  - Performance tests
- **In GroceryApp**:
  - `GroceryAppTests` target: Unit tests for services (CategoryService, StoreService, etc.)
  - `GroceryAppUITests` target: UI tests for user interactions
  - All tests use `XCTestCase` and `XCTAssert*` functions

### 5. **Linter** - Code Quality Tool
- **What it is**: A tool that analyzes code for errors, style issues, and potential bugs
- **In this project**: 
  - **SourceKit** (built into Xcode/Swift compiler) - provides real-time diagnostics
  - When I run `read_lints`, I'm checking for compiler errors and warnings
  - This is **bundled** with Xcode, not a separate tool
- **Optional tools** (not currently used):
  - **SwiftLint**: Third-party style checker (can be added if needed)
  - **swift-format**: Official Swift formatting tool

### 6. **Core Data** - Data Persistence Framework
- **What it is**: Apple's object graph and persistence framework
- **Used for**: Storing all app data locally on the device
- **In GroceryApp**:
  - **Data Model**: `GroceryApp.xcdatamodeld` - defines entities (Category, GroceryItem, ShoppingListItem, Store)
  - **Entities**:
    - `Category`: Grocery categories (Produce, Dairy, etc.)
    - `GroceryItem`: Individual grocery items
    - `ShoppingListItem`: Items in active shopping list
    - `Store`: Store information
  - **PersistenceController**: Manages the Core Data stack
  - **Storage**: SQLite database (automatically created by Core Data)
  - **Location**: Data stored in app's sandbox on device

## Development Workflow

### Typical Development Cycle:

1. **Write Code** (in Cursor or Xcode)
   - Swift files for business logic
   - SwiftUI views for UI
   - Core Data models

2. **Build** (in Xcode)
   - `Product > Build` or `Cmd+B`
   - Compiles Swift code
   - Validates Core Data model
   - Checks for errors

3. **Test** (in Xcode)
   - `Product > Test` or `Cmd+U`
   - Runs XCTest unit tests
   - Runs UI tests
   - Reports pass/fail

4. **Run** (in Xcode)
   - `Product > Run` or `Cmd+R`
   - Builds app
   - Launches on simulator or device
   - Attaches debugger

5. **Debug** (in Xcode)
   - Set breakpoints
   - Inspect variables
   - View console output

## Project Structure

```
GroceryApp/
├── GroceryApp/                    # Main app target
│   ├── GroceryAppApp.swift        # App entry point
│   ├── Models/                    # Core Data models
│   │   ├── Category+CoreDataClass.swift
│   │   ├── GroceryItem+CoreDataClass.swift
│   │   └── ...
│   ├── Views/                     # SwiftUI views
│   │   ├── MainTabView.swift
│   │   ├── ShoppingListView.swift
│   │   └── ...
│   ├── Services/                  # Business logic
│   │   ├── CategoryService.swift
│   │   ├── StoreService.swift
│   │   └── ...
│   ├── Persistence.swift          # Core Data setup
│   └── Assets.xcassets/           # Images, colors
├── GroceryAppTests/               # Unit tests
│   ├── CategoryServiceTests.swift
│   └── ...
├── GroceryAppUITests/             # UI tests
│   └── GroceryAppUITests.swift
└── GroceryApp.xcodeproj/          # Xcode project file
```

## Key Technologies Summary

| Technology | Purpose | Bundled or Separate? |
|-----------|---------|---------------------|
| **Swift** | Programming language | Bundled with Xcode |
| **Xcode** | IDE and build system | Separate (free from App Store) |
| **XCTest** | Testing framework | Bundled with Xcode |
| **Core Data** | Data persistence | Bundled with iOS SDK |
| **SwiftUI** | UI framework | Bundled with iOS SDK |
| **SourceKit** | Linter/compiler | Bundled with Xcode |
| **Cursor** | Code editor | Separate (third-party) |

## Command Line Equivalents

All Xcode actions can be run from command line using `xcodebuild`:

- **Build**: `xcodebuild build -project ... -scheme ...`
- **Test**: `xcodebuild test -project ... -scheme ...`
- **Clean**: `xcodebuild clean -project ... -scheme ...`

See `CLI_COMMANDS.md` for detailed commands.

## Data Persistence Details

### Core Data Stack:
1. **NSManagedObjectModel**: Defines data structure (entities, attributes, relationships)
2. **NSPersistentStoreCoordinator**: Manages SQLite database
3. **NSManagedObjectContext**: In-memory workspace for objects
4. **NSPersistentContainer**: Wraps everything together

### In GroceryApp:
- **Model File**: `GroceryApp.xcdatamodeld/GroceryApp.xcdatamodel/contents`
- **Entities**: Defined in Xcode's Core Data Model Editor
- **Swift Classes**: Auto-generated from model (Category+CoreDataClass.swift, etc.)
- **Storage**: SQLite database in app's Documents directory
- **Threading**: Uses background contexts for heavy operations

## Testing Strategy

### Unit Tests (GroceryAppTests):
- Test individual services in isolation
- Use in-memory Core Data stores
- Fast execution
- Examples: CategoryService, StoreService, ShoppingListService

### UI Tests (GroceryAppUITests):
- Test user interactions
- Launch app in simulator
- Interact with UI elements
- Slower but more comprehensive

## Development Best Practices

1. **Write tests first** (TDD) or alongside code
2. **Use Core Data for local persistence**
3. **Keep business logic in Services** (MVS architecture)
4. **Use SwiftUI for UI** (declarative, modern)
5. **Test on real devices** before release
6. **Use version control** (Git) for all code

## Next Steps for Learning

1. **Swift Language**: [swift.org](https://swift.org)
2. **SwiftUI**: Apple's official tutorials
3. **Core Data**: Apple's Core Data Programming Guide
4. **XCTest**: Apple's Testing documentation
5. **Xcode**: Apple's Xcode User Guide
