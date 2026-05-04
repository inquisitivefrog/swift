# Fix Duplicate Audio Files in Copy Bundle Resources

## Problem
Audio files appear twice in Copy Bundle Resources:
1. Individual files (added separately)
2. Audio/ folder reference (includes all files)

This causes duplicate file errors during build.

## Solution

### Step 1: Remove Individual File References
1. In Xcode, go to **Build Phases** → **Copy Bundle Resources**
2. Find all individual `.m4a` files listed (not in a folder)
3. Select them all
4. Press **Delete** or click the **-** button
5. Choose **Remove** (not "Move to Trash" - we want to keep the files)

### Step 2: Verify Audio/ Folder Reference
1. In Copy Bundle Resources, you should see:
   - `Audio/` (blue folder reference)
   - Inside it: `Characteristics/`, `Dinosaurs/`, `Feedback/` (all blue folders)
   - The `.m4a` files should be inside those folders

### Step 3: Clean Build
1. Product → Clean Build Folder (Shift+⌘+K)
2. Product → Build (⌘+B)

## Expected Result
- Only `Audio/` folder reference in Copy Bundle Resources
- No individual `.m4a` files listed separately
- No duplicate file errors
- All audio files accessible via `Audio/` path structure

## Verification
After fixing, the console should show:
- `✅ Found at path: Audio/Dinosaurs/t-rex` (or similar)
- No duplicate file build errors
