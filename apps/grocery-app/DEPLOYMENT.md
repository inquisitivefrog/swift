# Deploying GroceryApp to iPhone

## Prerequisites

1. **Apple Developer Account** (Free or Paid)
   - Free account: Limited to 7 days, requires re-signing weekly
   - Paid account ($99/year): Full access, no expiration

2. **Physical iPhone** connected via USB cable

3. **Xcode** installed and updated

## Step-by-Step Instructions

### Step 1: Connect Your iPhone

1. Connect your iPhone to your Mac using a USB cable
2. Unlock your iPhone
3. On your iPhone, if prompted, tap **"Trust This Computer"** and enter your passcode

### Step 2: Configure Signing & Capabilities in Xcode

1. Open the project in Xcode: `GroceryApp.xcodeproj`
2. In the Project Navigator (left sidebar), click on **"GroceryApp"** (the blue project icon at the top)
3. Select the **"GroceryApp"** target (under "TARGETS")
4. Click on the **"Signing & Capabilities"** tab
5. Under **"Signing"**:
   - Check **"Automatically manage signing"**
   - Xcode will automatically create provisioning profiles
   - Select your **Team** from the dropdown
     - If you don't see your team, click **"Add Account..."** and sign in with your Apple ID
   - The **Bundle Identifier** should be: `com.inquisitivefrog.GroceryShopping`
     - If it shows an error, you may need to change it to something unique (e.g., `com.inquisitivefrog.GroceryShopping.YourName`)

### Step 3: Select Your iPhone as the Build Destination

1. At the top of Xcode, next to the Play/Stop buttons, you'll see a device selector
2. Click the device dropdown (it probably says "iPhone 16" or similar simulator)
3. Select your connected iPhone from the list
   - It will show as something like: **"Tim's iPhone"** or **"iPhone (iOS 18.x)"**

### Step 4: Build and Run

1. Click the **Play button** (▶️) in the top-left of Xcode, or press **Cmd+R**
2. Xcode will:
   - Build the app
   - Install it on your iPhone
   - Launch it automatically

### Step 5: Trust the Developer on iPhone (First Time Only)

If this is the first time installing an app from this developer:

1. On your iPhone, go to **Settings** → **General** → **VPN & Device Management** (or **"Profiles & Device Management"**)
2. Under **"Developer App"**, you'll see your Apple ID
3. Tap on it
4. Tap **"Trust [Your Apple ID]"**
5. Confirm by tapping **"Trust"**

The app should now launch on your iPhone!

## Troubleshooting

### "No devices found"
- Make sure your iPhone is unlocked
- Try unplugging and replugging the USB cable
- Check that you tapped "Trust This Computer" on your iPhone
- Try a different USB cable or USB port

### "Signing requires a development team"
- Make sure you're signed in to Xcode with your Apple ID
- Go to **Xcode** → **Settings** (or **Preferences**) → **Accounts**
- Click the **"+"** button and add your Apple ID
- Select your account and click **"Download Manual Profiles"**

### "Bundle identifier is already in use"
- Change the Bundle Identifier in **Signing & Capabilities** to something unique
- For example: `com.inquisitivefrog.GroceryShopping.YourName`

### "Provisioning profile doesn't match"
- In **Signing & Capabilities**, uncheck and re-check **"Automatically manage signing"**
- Clean build folder: **Product** → **Clean Build Folder** (Shift+Cmd+K)
- Try building again

### App crashes immediately
- Check the Xcode console for error messages
- Make sure you trusted the developer (Step 5 above)
- Try deleting the app from your iPhone and reinstalling

## Free vs Paid Apple Developer Account

### Free Account (Personal Team)
- ✅ Can install on your own devices
- ✅ 7-day signing certificate (app expires after 7 days)
- ❌ Must re-sign weekly
- ❌ Cannot distribute to App Store
- ❌ Limited to 3 apps per device

### Paid Account ($99/year)
- ✅ Can install on your own devices
- ✅ 1-year signing certificate
- ✅ Can distribute to App Store
- ✅ Can create TestFlight builds
- ✅ No app limit

## Next Steps

Once installed, the app will:
- Store data locally on your iPhone
- Be backed up via iCloud (if iCloud Backup is enabled)
- Work offline (no internet required)

If you want to update the app:
1. Make changes in Xcode
2. Click the Play button again (Cmd+R)
3. Xcode will rebuild and reinstall automatically

