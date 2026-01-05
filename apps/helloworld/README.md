# Hello World - Swift

A simple Swift command-line application that prints "Hello, World!".

## Overview

This is a basic Swift command-line tool demonstrating:
- Swift Package Manager (SPM) project structure
- Executable target configuration
- Unit testing with XCTest
- Code organization and separation of concerns

## Requirements

- Swift 6.1 or later
- macOS (or Linux with Swift installed)
- Xcode Command Line Tools (on macOS)

## Installation

No installation required - this is a standalone Swift package.

## Building and Running

### Build the project:
```bash
cd apps/helloworld
swift build
```

This creates an executable at `.build/debug/helloworld`

### Run the application:
```bash
swift run helloworld
```

Or run the built executable directly:
```bash
.build/debug/helloworld
```

Expected output:
```
Hello, World!
```

## Testing

Run the test suite:
```bash
swift test
```

The test suite verifies that the `getGreeting()` function returns the expected "Hello, World!" message.

**Note:** XCTest requires full Xcode installation. If you're using Command Line Tools and get an "XCTest module not found" error, switch to Xcode:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Then run `swift test` again.

## Code Documentation

### `getGreeting() -> String`
Returns a greeting message.

**Returns:** A string containing "Hello, World!"

**Example:**
```swift
let greeting = getGreeting()
print(greeting) // Prints: Hello, World!
```

## Project Structure

```
apps/helloworld/
├── Package.swift              # Swift package configuration
├── README.md                  # This file
├── Sources/
│   ├── main.swift             # Entry point - calls getGreeting() and prints result
│   └── helloworld.swift       # Main logic - contains getGreeting() function
└── Tests/
    └── helloworldTests/
        └── helloworldTests.swift  # Unit tests for the greeting function
```

## Development

### Adding New Features

1. Add functions to `Sources/helloworld.swift`
2. Call them from `Sources/main.swift`
3. Write tests in `Tests/helloworldTests/helloworldTests.swift`

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful function and variable names
- Add documentation comments for public functions
- Keep functions small and focused

## License

ISC

