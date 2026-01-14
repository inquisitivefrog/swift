#!/usr/bin/env bash 
# set -x
#
# CI/CD Script for GroceryApp
# Command-line equivalents of Xcode Product menu actions
#
# Usage:
#   ./ci-cd-commands.sh clean    # Clean Build Folder
#   ./ci-cd-commands.sh build    # Build
#   ./ci-cd-commands.sh test     # Run Tests
#   ./ci-cd-commands.sh run      # Build and Run (simulator)
#   ./ci-cd-commands.sh all       # Clean, Build, and Test

set -e  # Exit on error

# Project configuration
PROJECT_PATH="GroceryApp/GroceryApp.xcodeproj"
SCHEME="GroceryApp"
CONFIGURATION="Debug"  # or "Release" for production builds

# Manual override options:
#   DESTINATION_OVERRIDE="id=DEVICE_ID" - Use specific device/simulator by ID
#   Example: DESTINATION_OVERRIDE="id=B9FBB080-6DFB-419E-93D1-C407A735356B" (iOS Simulator for iPhone 16e)
#   Example: DESTINATION_OVERRIDE="id=00008110-000A150C1E23A01E" (My Personal iPhone)
#   USE_SIMULATOR=1 - Force simulator (default behavior - safer when device might be disconnected)
#   USE_DEVICE=1 - Try to use physical device (will fall back to simulator if unavailable)

# Function: Auto-detect best available destination
detect_destination() {
    # Check for manual override first
    if [ -n "$DESTINATION_OVERRIDE" ]; then
        # If override is just an ID (starts with id= or is just a UUID), use it directly
        if echo "$DESTINATION_OVERRIDE" | grep -qE "^id=" || echo "$DESTINATION_OVERRIDE" | grep -qE "^[0-9A-F-]{8}-[0-9A-F-]{4}-[0-9A-F-]{4}-[0-9A-F-]{4}-[0-9A-F-]{12}$"; then
            # Normalize to id= format
            local override_id=$(echo "$DESTINATION_OVERRIDE" | sed -E 's/^id=//')
            echo "id=$override_id"
            return 0
        else
            # Full destination format provided (e.g., from command line)
            echo "$DESTINATION_OVERRIDE"
            return 0
        fi
    fi
    
    # Check if simulator is forced
    if [ "${USE_SIMULATOR:-0}" = "1" ]; then
        # Force simulator - skip device detection
        :
    elif [ "${USE_DEVICE:-0}" = "1" ]; then
        # Explicitly requested to use device - try to find and verify it's available
        local destinations_output=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showdestinations 2>/dev/null)
        local physical_line=$(echo "$destinations_output" | \
            grep -E "platform:iOS.*id:[0-9A-F-]+.*name:" | \
            grep -v "Simulator" | \
            grep -v "placeholder" | \
            head -1)
        
        if [ -n "$physical_line" ]; then
            local device_id=$(echo "$physical_line" | sed -E 's/.*id:([0-9A-F-]+).*/\1/')
            if [ -n "$device_id" ] && [ "$device_id" != "dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder" ]; then
                # Verify device is actually available by trying a quick operation
                # This will fail fast if device is disconnected
                if xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "id=$device_id" -showdestinations 2>&1 | grep -q "id=$device_id"; then
                    echo "id=$device_id"
                    return 0
                else
                    # Device not actually available, fall through to simulator
                    echo -e "${YELLOW}Device $device_id not available, using simulator${NC}" >&2
                fi
            fi
        fi
    fi
    # Default: use simulator (safer when device might be disconnected)
    
    # Fall back to simulators - try iPhone 16e first (user's preference), then iPhone 16, then iPhone 17
    for iphone_model in "iPhone 16e" "iPhone 16" "iPhone 17"; do
        local simulator_line=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -showdestinations 2>/dev/null | \
            grep -E "platform:iOS Simulator.*name:$iphone_model" | \
            head -1)
        
        if [ -n "$simulator_line" ]; then
            local sim_id=$(echo "$simulator_line" | sed -E 's/.*id:([0-9A-F-]+).*/\1/')
            if [ -n "$sim_id" ]; then
                echo "id=$sim_id"
                return 0
            fi
        fi
    done
    
    # Last resort: use iPhone 16e ID directly (B9FBB080-6DFB-419E-93D1-C407A735356B)
    echo "id=B9FBB080-6DFB-419E-93D1-C407A735356B"
}

DESTINATION=$(detect_destination)

# Debug: Show detected destination
if [ "${DEBUG:-0}" = "1" ]; then
    echo "Detected destination: $DESTINATION"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function: Clean Build Folder
clean() {
    echo -e "${YELLOW}Cleaning build folder...${NC}"
    xcodebuild clean \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        | xcpretty || true
    echo -e "${GREEN}✓ Clean complete${NC}"
}

# Function: Build
build() {
    echo -e "${YELLOW}Building project...${NC}"
    xcodebuild build \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        | xcpretty || xcodebuild build \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -destination "$DESTINATION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

# Function: Run Tests
test() {
    echo -e "${YELLOW}Running tests on: $DESTINATION${NC}"
    local temp_log=$(mktemp)
    
    # Check if destination is a physical device and might be unavailable
    # Note: We can't easily distinguish device vs simulator from just ID, so we'll detect issues at runtime
    echo -e "${YELLOW}Using destination: $DESTINATION${NC}"
    echo -e "${YELLOW}Note: If device is locked/disconnected, use: USE_SIMULATOR=1 ./ci-cd-commands.sh test${NC}"
    
    # Run tests and capture output
    # Note: xcpretty can hang after tests complete, so we skip it for tests
    # Output is still captured in temp_log for error checking
    echo -e "${YELLOW}Running tests...${NC}"
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        -testPlan GroceryApp \
        2>&1 | tee "$temp_log" || true
    
    # Check for device availability issues
    if grep -qE "device is locked|destination is not ready|Waiting for the destination|Unlock.*iPhone" "$temp_log" 2>/dev/null; then
        echo -e "${RED}✗ Device unavailable (locked or disconnected)${NC}"
        echo -e "${YELLOW}Tip: Use 'USE_SIMULATOR=1 ./ci-cd-commands.sh test' to use simulator instead${NC}"
        rm -f "$temp_log"
        exit 1
    fi
    
    # Check for test failures
    if grep -qE "Test Suite.*failed|BUILD FAILED|failed \(" "$temp_log" 2>/dev/null; then
        echo -e "${RED}✗ Tests failed${NC}"
        rm -f "$temp_log"
        exit 1
    else
        echo -e "${GREEN}✓ Tests passed${NC}"
        rm -f "$temp_log"
    fi
}

# Function: Build and Run (simulator)
run() {
    echo -e "${YELLOW}Building and running...${NC}"
    xcodebuild build \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful, launching simulator...${NC}"
        # Note: To actually launch the app, you'd need xcrun simctl or open the built app
        echo "Use 'xcrun simctl boot <device-id>' and 'xcrun simctl install' to run"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

# Function: All (clean, build, test)
all() {
    clean
    build
    test
}

# Main script logic
case "${1:-help}" in
    clean)
        clean
        ;;
    build)
        build
        ;;
    test)
        test
        ;;
    run)
        run
        ;;
    all)
        all
        ;;
    help|--help|-h)
        echo "CI/CD Commands for GroceryApp"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  clean    Clean build folder (Product > Clean Build Folder)"
        echo "  build    Build the project (Product > Build)"
        echo "  test     Run all tests (Product > Test)"
        echo "  run      Build and prepare to run (Product > Run)"
        echo "  all      Clean, build, and test"
        echo ""
        echo "Examples:"
        echo "  $0 clean"
        echo "  $0 build"
        echo "  $0 test"
        echo "  $0 all"
        echo ""
        echo "Environment Variables:"
        echo "  USE_SIMULATOR=1    Force simulator (default behavior - safer)"
        echo "  USE_DEVICE=1       Try to use physical device (falls back to simulator if unavailable)"
        echo "  DESTINATION_OVERRIDE  Override destination (e.g., 'id=B9FBB080-6DFB-419E-93D1-C407A735356B')"
        echo ""
        echo "Examples with environment variables:"
        echo "  $0 test    # Default: uses simulator (iPhone 16e)"
        echo "  USE_DEVICE=1 $0 test    # Try to use physical device"
        echo "  DESTINATION_OVERRIDE='id=B9FBB080-6DFB-419E-93D1-C407A735356B' $0 test  # Use specific device/simulator"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
