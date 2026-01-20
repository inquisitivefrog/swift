
% cd /Users/tim/Documents/workspace/swift/apps/grocery-app/GroceryApp 

# Basic Pipeline Test
% xcodebuild -scheme GroceryApp -destination 'platform=iOS Simulator,name=iPhone 15' clean build test 

# Simple Test
% xcodebuild -project GroceryApp.xcodeproj -scheme GroceryApp -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build-for-testing 2>&1 | grep -A 5 -i "error\|warning"
