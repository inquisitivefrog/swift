# Xcode CLI Commands for CI/CD

This document provides command-line equivalents for common Xcode Product menu actions.

## Quick Start

**Recommended: Use the convenience script**
```bash
cd /Users/tim/Documents/workspace/swift/apps/grocery-app
./ci-cd-commands.sh test  # Runs tests on simulator (iPhone 16e) by default
```

**Key Features:**
- ✅ **Automatic device detection** - Finds available simulators and devices
- ✅ **Safe defaults** - Uses simulator by default (prevents hangs when device disconnected)
- ✅ **Simplified format** - Uses `id=...` instead of verbose platform strings
- ✅ **Environment variables** - `USE_SIMULATOR=1`, `USE_DEVICE=1`, `DESTINATION_OVERRIDE`
- ✅ **Automatic fallback** - Falls back to simulator if device unavailable

## Quick Reference

| Xcode Action | CLI Command |
|-------------|-------------|
| **Product > Clean Build Folder** | `./ci-cd-commands.sh clean` |
| **Product > Build** | `./ci-cd-commands.sh build` |
| **Product > Test** | `./ci-cd-commands.sh test` |
| **Product > Run** | Build first, then use `xcrun simctl` to launch |

**Note:** The `ci-cd-commands.sh` script automatically detects available devices/simulators. By default, it uses the simulator (iPhone 16e) for safety when devices might be disconnected.

## Detailed Commands

### 1. Clean Build Folder

```bash
cd /Users/tim/Documents/workspace/swift/apps/grocery-app
xcodebuild clean \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Debug
```

### 2. Build

**Using simplified `id=` format (recommended):**
```bash
cd /Users/tim/Documents/workspace/swift/apps/grocery-app
xcodebuild build \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Debug \
  -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B'  # iPhone 16e simulator
```

**Using legacy format:**
```bash
xcodebuild build \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16e'
```

**For Release builds:**
```bash
xcodebuild build \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Release \
  -destination 'generic/platform=iOS'
```

### 3. Run Tests

**Using simplified `id=` format (recommended):**
```bash
cd /Users/tim/Documents/workspace/swift/apps/grocery-app
xcodebuild test \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Debug \
  -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B' \
  -testPlan GroceryApp
```

**Run only unit tests:**
```bash
xcodebuild test \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B' \
  -only-testing:GroceryAppTests
```

**Run only UI tests:**
```bash
xcodebuild test \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B' \
  -only-testing:GroceryAppUITests
```

**For physical device (when connected):**
```bash
xcodebuild test \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -destination 'id=00008110-000A150C1E23A01E' \
  -testPlan GroceryApp
```

### 4. Build and Archive (for App Store)

```bash
xcodebuild archive \
  -project GroceryApp/GroceryApp.xcodeproj \
  -scheme GroceryApp \
  -configuration Release \
  -archivePath ./build/GroceryApp.xcarchive \
  -destination 'generic/platform=iOS'
```

## Using the CI/CD Script

A convenience script is provided: `ci-cd-commands.sh` that automatically detects available devices and simulators.

### Basic Usage

```bash
# Make it executable (if not already)
chmod +x ci-cd-commands.sh

# Clean
./ci-cd-commands.sh clean

# Build
./ci-cd-commands.sh build

# Test (defaults to simulator - iPhone 16e)
./ci-cd-commands.sh test

# All (clean + build + test)
./ci-cd-commands.sh all

# Help
./ci-cd-commands.sh help
```

### Environment Variables

The script supports several environment variables for customization:

#### `USE_SIMULATOR=1`
Force simulator usage (default behavior - safer when device might be disconnected):
```bash
USE_SIMULATOR=1 ./ci-cd-commands.sh test
```

#### `USE_DEVICE=1`
Try to use physical device (will fall back to simulator if device is unavailable):
```bash
USE_DEVICE=1 ./ci-cd-commands.sh test
```

#### `DESTINATION_OVERRIDE`
Override destination with specific device/simulator ID:
```bash
# Use iPhone 16e simulator
DESTINATION_OVERRIDE="id=B9FBB080-6DFB-419E-93D1-C407A735356B" ./ci-cd-commands.sh test

# Use physical iPhone (when connected)
DESTINATION_OVERRIDE="id=00008110-000A150C1E23A01E" ./ci-cd-commands.sh test
```

### Default Behavior

- **Default**: Uses simulator (iPhone 16e) - safe when device is disconnected
- **Device Detection**: Only attempts device if `USE_DEVICE=1` is set
- **Automatic Fallback**: Falls back to simulator if device is unavailable
- **Device Verification**: Verifies device is actually available before using it

### Finding Device/Simulator IDs

To find available device and simulator IDs:
```bash
xcodebuild -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -showdestinations
```

This will list all available destinations with their IDs.

## Finding Your Scheme and Destination

### List available schemes:
```bash
xcodebuild -list -project GroceryApp/GroceryApp.xcodeproj
```

### List all available destinations (recommended):
```bash
xcodebuild -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -showdestinations
```

This shows all devices and simulators with their IDs in the format:
```
{ platform:iOS Simulator, arch:arm64, id:B9FBB080-6DFB-419E-93D1-C407A735356B, OS:18.6, name:iPhone 16e }
{ platform:iOS, arch:arm64, id:00008110-000A150C1E23A01E, name:Timothy's iPhone }
```

### List available simulators:
```bash
xcrun simctl list devices available
```

### Destination Format

**Simplified format (recommended):**
- `'id=B9FBB080-6DFB-419E-93D1-C407A735356B'` - iPhone 16e simulator
- `'id=00008110-000A150C1E23A01E'` - Physical iPhone

**Legacy format (still supported):**
- `'platform=iOS Simulator,name=iPhone 16e'`
- `'platform=iOS Simulator,name=iPhone 16'`
- `'platform=iOS Simulator,name=iPhone 17'`
- `'generic/platform=iOS'` (for device builds)

## CI/CD Integration Examples

### Using the CI/CD Script (Recommended)

The `ci-cd-commands.sh` script automatically handles device detection and is ideal for CI/CD:

```yaml
# GitHub Actions example
name: iOS CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Build and Test
        run: |
          cd apps/grocery-app
          chmod +x ci-cd-commands.sh
          ./ci-cd-commands.sh all
```

### Direct xcodebuild Commands

If you prefer direct commands:

#### GitHub Actions

```yaml
name: iOS CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Build
        run: |
          cd apps/grocery-app
          xcodebuild build -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B'
      - name: Test
        run: |
          cd apps/grocery-app
          xcodebuild test -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B' -testPlan GroceryApp
```

#### GitLab CI

```yaml
build:
  stage: build
  script:
    - cd apps/grocery-app
    - xcodebuild clean -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp
    - xcodebuild build -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B'
  artifacts:
    paths:
      - apps/grocery-app/build/

test:
  stage: test
  script:
    - cd apps/grocery-app
    - xcodebuild test -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -destination 'id=B9FBB080-6DFB-419E-93D1-C407A735356B' -testPlan GroceryApp
```

## Optional: Pretty Output

Install `xcpretty` for cleaner output:

```bash
gem install xcpretty
```

Then pipe commands through it:
```bash
xcodebuild build ... | xcpretty
```

## Troubleshooting

### "Scheme not found"
- Verify scheme name: `xcodebuild -list -project GroceryApp/GroceryApp.xcodeproj`
- Ensure scheme is shared (in Xcode: Product > Scheme > Manage Schemes > check "Shared")

### "Destination not found"
- List all destinations: `xcodebuild -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -showdestinations`
- Use the `id=` format with the exact ID from the list
- Boot simulator first if needed: `xcrun simctl boot "iPhone 16e"`

### Device Unavailable or Locked
- **Default behavior**: Script uses simulator automatically (iPhone 16e)
- **Force simulator**: `USE_SIMULATOR=1 ./ci-cd-commands.sh test`
- **Try device**: `USE_DEVICE=1 ./ci-cd-commands.sh test` (falls back to simulator if unavailable)
- **Device locked**: Unlock your iPhone and ensure it's connected via USB or Wi-Fi
- **Device disconnected**: Script automatically falls back to simulator

### Script Hangs When Device Disconnected
- The script now defaults to simulator to prevent this
- If it still tries device, use: `USE_SIMULATOR=1 ./ci-cd-commands.sh test`
- Or set override: `DESTINATION_OVERRIDE="id=B9FBB080-6DFB-419E-93D1-C407A735356B" ./ci-cd-commands.sh test`

### Build errors
- Clean first: `./ci-cd-commands.sh clean` or `xcodebuild clean ...`
- Check Xcode version: `xcodebuild -version`
- Verify deployment target matches your Xcode version

### Finding Device/Simulator IDs
```bash
# List all available destinations with IDs
xcodebuild -project GroceryApp/GroceryApp.xcodeproj -scheme GroceryApp -showdestinations

# Look for lines like:
# { platform:iOS Simulator, id:B9FBB080-6DFB-419E-93D1-C407A735356B, name:iPhone 16e }
# { platform:iOS, id:00008110-000A150C1E23A01E, name:Timothy's iPhone }
```
