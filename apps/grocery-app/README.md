# Grocery Shopping App

A native iOS mobile application for managing grocery shopping lists on iPhone.

## Features

- **Master List**: Maintain a comprehensive list of all grocery items
- **Shopping List**: Create active shopping lists from master list items
- **Check-off Items**: Mark items as found/selected during shopping
- **Local Storage**: All data stored locally on iPhone using Core Data
- **iCloud Backup**: Automatic backup via iPhone iCloud backup

## Technology

- SwiftUI for user interface
- Core Data for data persistence
- Xcode for development
- iOS 17.0+ (target to be confirmed)

## Project Status

✅ **Functional** - Ready for personal use and portfolio demonstration

See [docs/PROJECT_DESCRIPTION.md](./docs/PROJECT_DESCRIPTION.md) for detailed project specifications.

## Documentation

All documentation is organized in the [`docs/`](./docs/) directory:

- **Getting Started**: [docs/CLI_COMMANDS.md](./docs/CLI_COMMANDS.md) - Command-line build/test commands
- **Architecture**: [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) - App architecture overview
- **Testing**: [docs/TEST_PATTERNS_GUIDE.md](./docs/TEST_PATTERNS_GUIDE.md) - Test patterns and examples
- **Distribution**: [docs/DISTRIBUTION.md](./docs/DISTRIBUTION.md) - TestFlight and App Store setup
- **Import Data**: [docs/IMPORT_DATA_README.md](./docs/IMPORT_DATA_README.md) - How to update grocery items

See the [`docs/`](./docs/) directory for complete documentation.

## Getting Started

This project is an Xcode project with SwiftUI and Core Data.

The project name is **GroceryShopping** (Product Name in Xcode).

Quick start:
```bash
# Run tests
./ci-cd-commands.sh test

# Build
./ci-cd-commands.sh build

# See all commands
./ci-cd-commands.sh help
```

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- iPhone device or simulator for testing

