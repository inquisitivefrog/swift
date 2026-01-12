# Swift Workspace

Applications developed using Swift with help from Cursor

## Projects

### 1. helloworld

   Basic Swift command-line application
  
   - Simple "Hello, World!" output
   - Tested with XCTest
   - Uses Swift Package Manager (SPM)

## Getting Started

Each project in the `apps/` directory is a standalone Swift package. Navigate to the project directory and use Swift Package Manager commands:

```bash
cd apps/helloworld
swift build    # Build the project
swift run      # Run the application
swift test     # Run tests
```

## Requirements

- Swift 6.1 or later
- macOS (or Linux with Swift installed)
- Xcode Command Line Tools (on macOS)

## Workspace Structure

```
swift/
├── apps/
│   └── helloworld/      # Hello World application
└── README.md            # This file
```

