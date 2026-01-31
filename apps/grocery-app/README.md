# ShoppingKart

A native iOS shopping list application that helps users organize grocery shopping by store. Built with SwiftUI and Core Data, demonstrating modern iOS development practices and full App Store submission workflow.

## 📱 App Store

**Status**: Submitted for Review

[Download on the App Store](https://apps.apple.com/app/shoppingkart/id[APP_ID]) *(Link will be available after App Store approval)*

## ✨ Key Features

- **Store-Based Organization**: Organize shopping lists by store (Trader Joe's, Whole Foods, Costco, etc.)
- **Category Management**: Browse items by category (Produce, Dairy, Meats, etc.)
- **Smart Item Import**: Pre-loaded grocery items filtered by your preferred stores
- **Shopping List Persistence**: Save and manage multiple shopping lists locally
- **First-Time User Experience**: Guided setup for store selection and initial data import
- **Local-First Architecture**: All data stored locally using Core Data with iCloud backup support

## 🛠️ Technical Stack

- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence with relationship management
- **Swift Concurrency**: Async/await for background operations
- **UserDefaults**: User preferences and app state management
- **XCTest**: Comprehensive unit and UI test coverage

## 🏗️ Architecture Highlights

- **MVVM Pattern**: Clean separation of concerns
- **Service Layer**: Dedicated services for data operations (CategoryService, StoreService, ImportService)
- **NavigationStack**: Modern SwiftUI navigation with proper state management
- **Asynchronous Operations**: Non-blocking UI with proper error handling
- **Test Coverage**: Unit tests for business logic and UI tests for user flows

## 📊 Development Process

This project demonstrates:

- **Full iOS Development Lifecycle**: From concept to App Store submission
- **Iterative Design**: User feedback-driven feature development
- **Modern Development Practices**: SwiftUI, Core Data, async/await
- **Quality Assurance**: Comprehensive test suite (unit + UI tests)
- **App Store Compliance**: Privacy policy, export compliance, age rating, content rights
- **CI/CD Ready**: Xcode Cloud integration and automated testing

## 🧪 Testing

The project includes:

- **Unit Tests**: Business logic, data services, and Core Data operations
- **UI Tests**: Complete user flows including first-time setup, navigation, and data management
- **Performance Tests**: App launch time and operation performance
- **Asset Verification**: App icon and image asset validation

Run tests:
```bash
./ci-cd-commands.sh test
```

## 📁 Project Structure

```
GroceryApp/
├── GroceryApp/              # Main app source
│   ├── Views/               # SwiftUI views
│   ├── Services/            # Business logic services
│   ├── Models/              # Core Data models
│   └── Assets.xcassets/     # App icons and images
├── GroceryAppTests/         # Unit tests
├── GroceryAppUITests/       # UI tests
└── docs/                    # Project documentation
```

## 🚀 Getting Started

### Requirements

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- iPhone device or simulator for testing

### Build & Run

```bash
# Run tests
./ci-cd-commands.sh test

# Build
./ci-cd-commands.sh build

# See all commands
./ci-cd-commands.sh help
```

Or open `GroceryApp/GroceryApp.xcodeproj` in Xcode.

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

- **[Architecture](./docs/ARCHITECTURE.md)**: App architecture and design decisions
- **[Testing](./docs/TEST_PATTERNS_GUIDE.md)**: Test patterns and examples
- **[Distribution](./docs/DISTRIBUTION.md)**: App Store and TestFlight setup
- **[Import Data](./docs/IMPORT_DATA_README.md)**: How to update grocery items
- **[Categories](./docs/CATEGORIES.md)**: Category structure and organization
- **[Stores](./docs/STORES.md)**: Store management system

## 🎯 Portfolio Highlights

This project showcases:

- ✅ **Production-Ready Code**: Clean, maintainable Swift code following best practices
- ✅ **User Experience Design**: Intuitive navigation and thoughtful onboarding flow
- ✅ **Data Management**: Complex Core Data relationships with efficient queries
- ✅ **Testing Discipline**: Comprehensive test coverage ensuring reliability
- ✅ **App Store Expertise**: Complete submission process including compliance and metadata
- ✅ **Modern iOS Development**: SwiftUI, async/await, and latest iOS features

## 📄 License

This project is a portfolio demonstration piece.

## 👤 Developer

Built as a portfolio project to demonstrate iOS development capabilities and modern development workflows.---**Note**: This app is designed for personal use and portfolio demonstration. Store names are used for organizational purposes only and are not affiliated with or endorsed by the respective retailers.
