# How to Copy and Share Hang Detection Logs

Since Xcode prevents direct export, here's how to copy the log content:

## Step-by-Step Process

### 1. Identify the Logs to Analyze

Look for `GroceryApp-<timestamp>.ips` files with timestamps from:
- **Today** (when hang detection triggered)
- **2 days ago** (when you had several hangs)

### 2. Open the Log in Xcode

1. **Click once** on a `GroceryApp-<timestamp>.ips` file to highlight it
2. **Double-click** or press **Enter** to open it in a separate window
3. The log will open in Xcode's editor

### 3. What to Copy

The log is a JSON file. Focus on these key sections:

#### **A. Crash Info Section** (Most Important)
Look for and copy:
- `"exception"` field
- `"exceptionSubtype"` field (look for `0x8badf00d` = hang)
- `"terminationReason"` field
- `"triggeredByThread"` field

#### **B. Memory Status Section**
Look for and copy:
- `"memoryStatus"` object
- `"pressureStatus"` value (2 = memory pressure)
- Memory usage numbers

#### **C. Thread Information** (The Hanging Thread)
Look for:
- Thread 0 (main thread) - most common for UI hangs
- The thread that has `"triggeredByThread": true` or similar
- Copy the stack trace for that thread

#### **D. Stack Trace** (Shows Where It Hung)
Look for:
- `"frames"` array in the hanging thread
- Function names and line numbers
- Look for GroceryApp-specific functions

### 4. Quick Copy Method

**Option 1: Copy Entire Log**
- In the opened log window: `Cmd+A` (select all)
- `Cmd+C` (copy)
- Paste into a text file or share directly

**Option 2: Copy Key Sections**
- Scroll to find the sections mentioned above
- Select and copy each section
- Paste them in order

### 5. What to Share

**Minimum needed:**
1. The `"crashInfo"` section
2. The `"memoryStatus"` section  
3. The stack trace from the hanging thread (usually thread 0)

**Ideal (if possible):**
- The entire log file content
- I can parse through it to find the relevant parts

## Example: What a Hang Log Looks Like

```json
{
  "crashInfo" : {
    "exception" : "EXC_CRASH (SIGKILL)",
    "exceptionSubtype" : "0x8badf00d",
    "terminationReason" : "Namespace HANG, Code 0x8badf00d",
    "triggeredByThread" : 0
  },
  "memoryStatus" : {
    "compressorSize" : 12345,
    "compressions" : 100,
    "decompressions" : 50,
    "pageSize" : 16384,
    "pressureStatus" : 2
  },
  "threads" : [
    {
      "threadNumber" : 0,
      "frames" : [
        {
          "imageOffset" : 123456,
          "symbol" : "GroceryApp.ShoppingListView.body.getter",
          "symbolLocation" : 123
        }
      ]
    }
  ]
}
```

## Quick Checklist

For each GroceryApp log from today and 2 days ago:

- [ ] Open the log file in Xcode
- [ ] Copy the entire content (`Cmd+A`, `Cmd+C`)
- [ ] Paste into a text file or share directly
- [ ] Note the timestamp from the filename

## Alternative: Save as Text File

If you can't paste directly:
1. Open the log in Xcode
2. `Cmd+A` to select all
3. `Cmd+C` to copy
4. Open TextEdit or any text editor
5. `Cmd+V` to paste
6. Save as `.txt` file
7. Share the file path

## What I'll Do With the Logs

Once I have the log content, I'll:
1. Parse the JSON structure
2. Identify the exception type (hang vs crash)
3. Analyze memory status
4. Find the stack trace showing where it hung
5. Map stack trace to your code
6. Identify the root cause
7. Suggest fixes

## Priority Order

Start with:
1. **Most recent** GroceryApp log (today)
2. **Logs from 2 days ago** (when you had several hangs)
3. Any other recent GroceryApp logs

You don't need to copy all logs at once - start with the most recent one and we can work through them.
