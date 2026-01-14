# Extracting Hang Detection Data from iPhone

Hang detection data can help diagnose memory crashes. Here are several ways to extract it:

## Method 1: Xcode Devices Window (Easiest)

1. **Connect your iPhone** to your Mac
2. **Open Xcode**
3. **Window > Devices and Simulators** (or `Shift+Cmd+2`)
4. Select your iPhone from the left sidebar
5. Click **"View Device Logs"** button
6. Look for entries with:
   - "Hang" in the name
   - "GroceryApp" in the name
   - Recent timestamps (today and 2 days ago)
7. **Right-click** on a log and select **"Export Log..."**
8. Save it to a location you can access

## Method 2: Console App (macOS)

1. **Open Console.app** (Applications > Utilities > Console)
2. **Connect your iPhone**
3. In the left sidebar, select your **iPhone** under "Devices"
4. In the search box, type: `GroceryApp` or `hang`
5. Look for entries with timestamps matching when hangs occurred
6. **File > Export** to save the log

## Method 3: iPhone Settings (On Device)

1. On your iPhone: **Settings > Privacy & Security > Analytics & Improvements > Analytics Data**
2. Scroll to find entries starting with:
   - `GroceryApp-`
   - `hang_`
   - Recent dates
3. **Tap** on an entry to view details
4. **Tap and hold** to copy the text, or take screenshots
5. Share via AirDrop, email, or Messages to your Mac

## Method 4: Command Line (if device is connected)

```bash
# List all crash/hang logs for your device
xcrun simctl diagnose 2>/dev/null || echo "For physical devices, use Xcode Devices window"

# Or check system logs
log show --predicate 'process == "GroceryApp"' --last 1d --style syslog > ~/Desktop/groceryapp_logs.txt
```

## Method 5: Xcode Organizer

1. **Xcode > Window > Organizer** (or `Shift+Cmd+9`)
2. Click **"Crashes"** tab
3. Look for GroceryApp entries
4. Click to view details
5. **Right-click > Export** to save

## What to Look For

Hang detection logs typically contain:
- **Memory pressure warnings**
- **Thread information** (which thread hung)
- **Stack traces** (where the hang occurred)
- **Memory usage** at time of hang
- **Time duration** of the hang

## After Extracting

Once you have the log files:
1. Save them to your Desktop or a folder you can access
2. Share the file path or contents with me
3. I can analyze them to identify:
   - Memory leaks
   - Threading issues
   - Performance bottlenecks
   - Core Data problems

## Quick Check: Current Memory Issues

The memory optimizations we made earlier (caching computed properties) should have helped. If hangs are still occurring, the logs will show:
- What operations were running when the hang occurred
- Memory usage patterns
- Any specific views or functions causing issues

## Recommended: Method 1 (Xcode Devices Window)

This is usually the easiest and most reliable method. The logs will be in a format I can easily read and analyze.
