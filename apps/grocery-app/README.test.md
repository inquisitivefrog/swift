
% cd /Users/tim/Documents/workspace/swift/apps/grocery-app/GroceryApp 

# Basic Pipeline Test
% xcodebuild -scheme GroceryApp -destination 'platform=iOS Simulator,name=iPhone 15' clean build test 

# Simple Test
% xcodebuild -project GroceryApp.xcodeproj -scheme GroceryApp -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build-for-testing 2>&1 | grep -A 5 -i "error\|warning"

# My iPhone 13
% xcodebuild -project GroceryApp.xcodeproj -scheme GroceryApp -sdk iphoneos -destination 'platform=iOS,id=00008110-000A150C1E23A01E' test
