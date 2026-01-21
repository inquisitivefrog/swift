# Distribution Guide

This guide walks you through preparing your ShoppingKart app for TestFlight and App Store distribution.

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Sign up at [developer.apple.com](https://developer.apple.com)
   - Enables TestFlight and App Store distribution

2. **Xcode Configuration**
   - Open `GroceryApp.xcodeproj` in Xcode
   - Go to **Signing & Capabilities** tab
   - Select your **Team** (your Apple Developer account)
   - Xcode will automatically manage certificates and provisioning profiles

## Step 1: Find Your Team ID

1. Open **Xcode** > **Preferences** (or **Settings** on newer versions)
2. Go to **Accounts** tab
3. Select your Apple ID
4. Click **View Details**
5. Copy your **Team ID** (looks like `ABC123DEF4`)

## Step 2: Configure ExportOptions.plist

1. Open `ExportOptions.plist` in the project root
2. Replace `YOUR_TEAM_ID` with your actual Team ID from Step 1
3. Save the file

```xml
<key>teamID</key>
<string>ABC123DEF4</string>  <!-- Replace with your Team ID -->
```

## Step 3: Create Archive

Using the CLI script:
```bash
./ci-cd-commands.sh archive
```

Or using Xcode:
1. Select **Any iOS Device** as the destination
2. **Product** > **Archive**
3. Wait for archive to complete

The archive will be created at: `./build/GroceryApp.xcarchive`

## Step 4: Export Archive

Using the CLI script:
```bash
./ci-cd-commands.sh export
```

Or using Xcode:
1. **Window** > **Organizer** (or **Product** > **Archive** if archive just completed)
2. Select your archive
3. Click **Distribute App**
4. Choose **App Store Connect**
5. Follow the wizard

The exported `.ipa` file will be at: `./build/export/GroceryApp.ipa`

## Step 5: Upload to App Store Connect

### Option A: Using Xcode Organizer (Recommended)
1. **Window** > **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Choose **App Store Connect** > **Upload**
5. Follow the wizard

### Option B: Using Transporter App
1. Download **Transporter** from the Mac App Store
2. Drag your `.ipa` file into Transporter
3. Click **Deliver**

### Option C: Using Command Line (altool)
```bash
xcrun altool --upload-app \
  --type ios \
  --file ./build/export/GroceryApp.ipa \
  --username your-apple-id@email.com \
  --password @keychain:Application-Specific-Password
```

## Step 6: Set Up App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** > **+** (Create App)
3. Fill in:
   - **Platform**: iOS
   - **Name**: ShoppingKart (or your preferred name)
   - **Primary Language**: English
   - **Bundle ID**: `com.inquisitivefrog.GroceryShopping`
   - **SKU**: A unique identifier (e.g., `grocery-app-001`)
4. Click **Create**

## Step 7: TestFlight Setup

1. In App Store Connect, go to your app
2. Click **TestFlight** tab
3. Wait for processing (10-30 minutes after upload)
4. Add testers:
   - **Internal Testing**: Up to 100 testers (immediate access)
   - **External Testing**: Up to 10,000 testers (requires App Review)

### Adding Internal Testers
1. Go to **Users and Access** in App Store Connect
2. Add team members as **App Manager** or **Admin**
3. They'll automatically have access to internal builds

### Adding External Testers
1. Go to **TestFlight** > **External Testing**
2. Click **+** to create a new group
3. Add testers by email
4. Select a build
5. Submit for Beta App Review (first time only)

## Step 8: App Store Submission (When Ready)

1. Complete App Store listing:
   - **App Information**: Name, subtitle, category, etc.
   - **Pricing and Availability**: Free or paid, countries
   - **App Privacy**: Privacy policy URL (required)
   - **Version Information**: What's new, screenshots, description
   - **App Review Information**: Contact info, demo account (if needed)

2. Submit for Review:
   - Go to **App Store** tab
   - Click **+ Version** or **Submit for Review**
   - Answer export compliance questions
   - Submit

3. Wait for Review:
   - Typically 1-3 days
   - You'll receive email notifications

## Troubleshooting

### Archive Fails: "No signing certificate found"
- Make sure your Apple Developer account is added in Xcode
- Check **Signing & Capabilities** tab has a valid Team selected
- Xcode should automatically create certificates

### Export Fails: "Invalid Team ID"
- Double-check `ExportOptions.plist` has the correct Team ID
- Team ID is different from your Apple ID email

### Upload Fails: "Invalid Bundle ID"
- Make sure the Bundle ID in Xcode matches App Store Connect
- Bundle ID: `com.inquisitivefrog.GroceryShopping`

### TestFlight Build Not Processing
- Wait 10-30 minutes after upload
- Check email for processing errors
- Verify the build is valid in App Store Connect

## Additional Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Quick Reference

```bash
# Full distribution workflow
./ci-cd-commands.sh clean    # Clean build
./ci-cd-commands.sh archive  # Create archive
./ci-cd-commands.sh export   # Export for App Store
# Then upload via Xcode Organizer or Transporter
```
