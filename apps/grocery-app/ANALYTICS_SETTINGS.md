# iPhone Analytics Settings Explained

## Settings Location
**Settings > Privacy & Security > Analytics & Improvements**

## What Each Setting Does

### 1. **Share iPhone Analytics**
- **What it does**: Sends diagnostic and usage data to Apple
- **Impact on hang logs**: None - logs are still created and stored locally
- **Recommendation**: Can be on or off - doesn't affect your ability to view logs

### 2. **Share iCloud Analytics**
- **What it does**: Sends iCloud-related analytics to Apple
- **Impact on hang logs**: None - not related to app hang detection
- **Recommendation**: Can be on or off - doesn't affect hang logs

### 3. **Share With App Developers**
- **What it does**: Allows developers (like you, if you have TestFlight or App Store apps) to receive crash/hang reports
- **Impact on hang logs**: None - logs are still created and stored locally
- **Recommendation**: Can be on or off - doesn't affect your ability to view logs locally

## Important: These Settings Don't Block Local Logs

**All three settings only control sharing/sending data to Apple/developers. They do NOT:**
- Prevent logs from being created
- Prevent logs from being stored on your device
- Prevent you from viewing logs in Analytics Data

## How to Access Hang Logs

Regardless of these settings:

1. **Settings > Privacy & Security > Analytics & Improvements > Analytics Data**
2. You'll see all logs there, including:
   - Crash logs (`.ips` files)
   - Hang detection logs
   - Other diagnostic data
3. The logs are stored locally on your device

## For Your Situation

Since you can see:
- Hang logs dated January 14, 2026 at 9:47am and 9:43am
- In "Available Hang Logs" section

This means:
- ✅ Hang detection is working
- ✅ Logs are being created
- ✅ You can access them

The analytics sharing settings don't matter for viewing logs - they only affect whether data is sent to Apple/developers.

## Next Steps

1. Go to **Analytics Data** (regardless of sharing settings)
2. Find the hang logs from January 14
3. Tap to open and view/copy the content
4. Share with me for analysis

The sharing settings are optional and don't affect your ability to diagnose issues locally.
