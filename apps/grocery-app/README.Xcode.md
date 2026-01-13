
Deployment to iPhone
--------------------
1. Open Xcode and open the project:
   File → Open → Navigate to /Users/tim/Documents/workspace/swift/apps/grocery-app/GroceryApp/GroceryApp.xcodeproj
2. Connect your iPhone 13
   a. Connect via USB
   b. Unlock your iPhone
   c. If prompted, tap "Trust This Computer"
3. Verify signing 
   a. Select the "GroceryApp" project in the navigator
   b. Select the "GroceryApp" target
   c. Go to "Signing & Capabilities"
   d. Ensure "Automatically manage signing" is checked
   e. Select your Team
4. Select your iPhone as the build destination
   a. At the top toolbar, click the device selector (next to Play/Stop)
   b. Choose your iPhone 13 from the list
   c. “Preparing Editor Functionality” banner is Xcode finishing setup 
      (indexing/building module caches). It’s normal the first time you 
      open a project or after an Xcode update. Usually you just wait 1–3 
      minutes and it clears; then the device picker will update.
   d. Window → Devices and Simulators… → verify your iPhone shows 
      as “Connected”. If it’s “Preparing” or “Unavailable,” wait or replug.
   e. Disable Auto-Lock in Settings/Display & Brightness
   f. Enable Developer Mode in Settings/Privacy & Security (requires a reboot)
5. Build and run
   a. Click the Play button (▶️) or press Cmd+R
   b. Xcode will build, install, and launch the app on your phone
6. Trust the developer (first time only)
   a. On your iPhone: Settings → General → VPN & Device Management
   b. Tap your Apple ID under "Developer App"
   c. Tap "Trust [Your Apple ID]"
7. Build Errors
   a. if you see any signing errors after the reboot, go to:
      Xcode → Settings → Apple Accounts
      Make sure your Apple ID is signed in
      Then try building again


