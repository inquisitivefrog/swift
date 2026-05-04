# Audio Files Setup for Xcode 26.2

## Folder layout (by game type)

Audio is organized by category for easier maintenance as you add more dinosaurs, pterosaurs, and marine reptiles:

| Folder | Contents | Filename prefix |
|--------|----------|------------------|
| **Dinosaurs/** | Dinosaur name clips | `dino-` (e.g. dino-t-rex, dino-triceratops) |
| **Dino-Characteristics/** | Feature audio for Match the Dinosaur | no prefix (teeth, crest, footprints, …) |
| **Ptero-Characteristics/** | Feature audio for Match the Pterosaur | no prefix (wings, small, no-teeth, crest, …) |
| **Pterosaurs/** | Pterosaur name clips | `ptero-` (e.g. ptero-pteranodon, ptero-quetzacoatlus) |
| **Feedback/** | Try again, great match, game over, etc. | no prefix |
| **Games/** | Intros and prompts | no prefix |

**Shared words** (used in both dinosaur and pterosaur games, e.g. crest, teeth, big, long-neck): the app picks the folder from the current game. You can put the same file in both **Dino-Characteristics** and **Ptero-Characteristics** if you want different recordings, or one copy in either folder if the same clip is fine for both.

## Current situation
- Audio files exist at: `DinoGames/DinoGames/Assets/Audio/`
- Xcode 26.2 uses automatic file system synchronization
- Files may need to be explicitly added to bundle resources

## Method 1: Drag and Drop (Easiest for Xcode 26.2)

1. **Open Finder** and navigate to:
   ```
   /Users/tim/Documents/workspace/swift/apps/dino-games/DinoGames/DinoGames/Assets/Audio
   ```

2. **In Xcode**, make sure the Project Navigator is visible (⌘1)

3. **Drag the `Audio` folder** from Finder into Xcode:
   - Drop it inside the `DinoGames` folder (the one with your Swift files)
   - **Important**: When the dialog appears, look for these options:
     - ✅ "Copy items if needed" (check this)
     - ✅ "Add to targets: DinoGames" (check this)
     - Choose **"Create folder references"** (this creates blue folders, not yellow groups)

4. The `Audio` folder should appear as a **blue folder** (not yellow) in Xcode

## Method 2: Using Xcode's Add Files Menu

1. In Xcode Project Navigator, **right-click** on the `DinoGames` folder
2. Select **"Add Files to 'DinoGames'..."**
3. Navigate to: `DinoGames/DinoGames/Assets/`
4. Select the **`Audio`** folder
5. In the dialog that appears:
   - Look for **"Add to targets"** section - make sure **DinoGames** is checked
   - Look for **"Options"** button or triangle - click it to expand
   - You should see options for how to add the folder
   - Select **"Create folder references"** (blue folder icon)

## Method 3: Verify Build Phase (If files still not found)

1. Click on the **blue project icon** at the top of Project Navigator
2. Select the **DinoGames** target (under "TARGETS")
3. Click the **"Build Phases"** tab
4. Expand **"Copy Bundle Resources"**
5. If you don't see the audio files listed:
   - Click the **"+"** button
   - Navigate to `Assets/Audio/` and add the folders
   - Or click **"Add Other..."** → **"Add Files..."** and select the Audio folder

## Verify It Worked

After adding:
1. The `Audio` folder should appear as a **blue folder** in Project Navigator
2. Inside it you should see `Dinosaurs/`, `Dino-Characteristics/`, `Ptero-Characteristics/`, `Pterosaurs/`, `Feedback/`, `Games/` (all blue folders)
3. The `.m4a` files should be visible inside those folders

## If You Still See Issues

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+⌘+K)
2. **Delete Derived Data**: 
   - Xcode → Settings → Locations
   - Click arrow next to Derived Data path
   - Delete the `DinoGames-*` folder
3. **Rebuild**: Product → Build (⌘+B)

## Check Console Output

When you run the app, check the console. You should see:
- ✅ `🔊 Playing audio: Dinosaurs/t-rex.m4a` (success)
- ❌ `⚠️ No audio file found...` (files not in bundle)

If you see the warning, the files aren't in the bundle yet.
