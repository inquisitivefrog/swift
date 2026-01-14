# Finding Hang Detection Logs

Hang detection logs are stored separately from crash logs. Here's where to find them:

## Method 1: iPhone Settings (On Device)

1. **Settings > Privacy & Security > Analytics & Improvements > Analytics Data**
2. Look for entries with:
   - `hang_` prefix
   - `GroceryShopping` or `GroceryApp` in the name
   - Dates matching January 14, 2026 at 9:47am and 9:43am
3. Tap to view, then copy/paste the content

## Method 2: Xcode Devices Window

1. **Connect iPhone** to Mac
2. **Xcode > Window > Devices and Simulators** (`Shift+Cmd+2`)
3. Select your iPhone
4. Click **"Open Recent Logs"** (or "View Device Logs")
5. Look for logs with:
   - "Hang" in the name
   - Dates: January 14, 2026 at 9:47am and 9:43am
   - "GroceryShopping" or "GroceryApp" in the name

## Method 3: Console App

1. **Open Console.app** (Applications > Utilities > Console)
2. **Connect iPhone**
3. Select your **iPhone** in left sidebar
4. In search box, type: `hang` or `GroceryShopping`
5. Filter by date: January 14, 2026
6. Look for entries around 9:43am and 9:47am

## Method 4: Device Logs Directory

Hang logs might be in:
- `~/Library/Logs/CrashReporter/MobileDevice/[Device Name]/`
- `~/Library/Logs/DiagnosticReports/` (but these are usually crashes)
- Device-specific directories in Xcode's device support folder

## Method 5: Export from iPhone Settings

1. On iPhone: **Settings > Privacy & Security > Analytics & Improvements > Analytics Data**
2. Find the hang logs (should show "Hang" in the name)
3. Tap to open
4. Use **Share** button (if available) to AirDrop/email to Mac
5. Or take screenshots of the log content

## What Hang Logs Look Like

Hang detection logs typically contain:
- **Hang Duration**: How long the app was unresponsive
- **Thread Information**: Which thread hung (usually main thread)
- **Stack Trace**: Where the hang occurred
- **Memory Status**: Memory usage at time of hang
- **Time Stamp**: Exact time of hang

## Key Differences: Hang vs Crash

| Type | Log Location | Exception Type |
|------|-------------|---------------|
| **Crash** | `.ips` files in DiagnosticReports | `EXC_CRASH`, `SIGABRT`, etc. |
| **Hang** | Analytics Data or separate hang logs | `0x8badf00d` (watchdog timeout) |

## Recommended Approach

Since you see them in iPhone Settings:
1. **Go to Settings > Privacy & Security > Analytics & Improvements > Analytics Data**
2. **Find the hang logs** from January 14 at 9:47am and 9:43am
3. **Tap each one** to view the full content
4. **Copy the text** or take screenshots
5. **Share with me** so I can analyze them

The hang logs from today (January 14) are more relevant than the crash logs from January 12, since we've already fixed those crashes. The hang logs will show if there are still memory or performance issues.
