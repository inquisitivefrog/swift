# Walkthrough TestFlight build

A **demo / coffee-shop / interview** binary: free navigation between games — no forced guided completion order — skip kid picker audio, and **Exit** on every game so you can start one mechanic and jump to another (dinosaurs vs pterosaurs, weigh vs racing, smile vs matrix).

This is **not** the App Store kids build. Archive **DinoGames-Walkthrough** for Internal TestFlight only. Do not submit that archive for App Store review — it's also permanently ineligible for one: a build uploaded via "TestFlight Internal Only" can never later be attached to an App Store version (see [`architecture/APP_SIZE_AND_RELEASE_STRATEGY.md`](../architecture/APP_SIZE_AND_RELEASE_STRATEGY.md)).

## What it changes

| Shipping (`DinoGames`) | Walkthrough (`DinoGames-Walkthrough`) |
|---|---|
| Home screen name **DinoGames** | **DinoGames Demo** |
| Picker levels **1–4** | Same **1–4** — see note below, this does *not* expand |
| Guided play + spoken walks | Manual pick; cover/level/game-card audio skipped |
| Finish a game to leave (except Debug flags) | **Exit** on every game cover, including during audio |
| Must complete a category's 12 games in order before free browsing unlocks | Free navigation from the start (`DeveloperSessionFlags.manualGameSelection`) |

Same bundle ID as the store app (`com.inquisitivefrog.DinoGames`). Installing this TestFlight build **replaces** the App Store copy on that device until you delete it and reinstall from the store. TestFlight and the App Store track your access to builds independently, though — deleting one and reinstalling the other via TestFlight works fine any time, since uninstalling doesn't affect your internal-tester access.

**Levels 5+ are deliberately NOT exposed, even here.** An earlier version of this build (`1.0.2 (8)`) tried expanding the picker to every level with games (`DeveloperSessionFlags.showAllCatalogLevels`), and crashed immediately on selecting Land: several of Land's level 5–10 games (`DinoToolsGameConfigs.dinoTools`, `GuessGameConfigs.dinoBones`, confirmed via on-device crash traces) `fatalError()` when their round builder can't find enough creatures with the required art, because that art is parked on `future-games` (see `CLAUDE.md`). The walkthrough's actual goal — free navigation without forced completion order — doesn't need extra levels, so `GameLevel.visibleInGamePicker` stays a flat 1–4 constant for every build, walkthrough included. Don't re-attempt the expansion without first fixing every parked game to skip gracefully (the way `PterosaurGameCatalog`'s level 4 already does via `if let matrix = PteroMatrixGameConfigs.makePteroMatrix()`) instead of crashing.

## Archive for TestFlight

From `apps/dino-games/DinoGames`:

```bash
xcodebuild -scheme DinoGames-Walkthrough -showdestinations
xcodebuild archive -scheme DinoGames-Walkthrough \
  -destination "generic/platform=iOS" \
  -archivePath ./build/DinoGames-Walkthrough.xcarchive
```

Then Organizer → Distribute App → **TestFlight Internal Only** (not "App Store Connect" — that's the tile that would make this build eligible for review). Keep the App Store scheme on **DinoGames** / Release, its own separate build number lineage.

**Status (2026-09-17):** `xcshareddata/xcschemes/` was empty until this date — only the `Walkthrough` build configuration existed, so `xcodebuild archive -scheme DinoGames-Walkthrough` failed with "does not contain a scheme." Added shared `DinoGames.xcscheme` (Release, restores the implicit default scheme Xcode had been synthesizing) and `DinoGames-Walkthrough.xcscheme` (Walkthrough config for all actions). Both are committed now, so this should not recur.

After archiving, `open ./build/DinoGames-Walkthrough.xcarchive` registers it with Xcode's Organizer if it isn't already showing there (a CLI-built archive at a custom path isn't auto-discovered otherwise).

## TestFlight tester groups: keep the demo build from getting shadowed (2026-09-17)

Internal testing groups default to **"Enable automatic distribution" checked** when created. That means the original/default internal group auto-receives *every* successfully processed build — including production builds uploaded via the "App Store Connect" method for an actual App Store submission (e.g. `1.0.2 (11)`), even though that upload was never meant for TestFlight. Since the TestFlight app shows only **one current build per tester per app** (resolved across *all* their group memberships, not one entry per group), a newer production build landing in a group you're still in will silently override the demo build as what's offered to you — even if the demo build is explicitly assigned to a different group you're also in.

**Symptom:** a demo build (e.g. `1.0.2 (10)`) that worked fine suddenly shows as "already tested" / isn't offered for install, right after a newer build (e.g. `1.0.2 (11)`) is uploaded for an unrelated purpose.

**Fix, one-time setup:**
1. Create a separate internal testing group dedicated to interview/demo builds (e.g. "Interview Demo"), and **uncheck "Enable automatic distribution"** during creation.
2. Add yourself as a tester to that group only.
3. Explicitly assign the demo build (pick it by build number, not "latest") to that group.

**If the cycle repeats anyway** (a newer production build shadows the demo build again): you're probably still a member of the original/default group too. Remove yourself from that group, leaving membership only in the demo group, then reload TestFlight's content on-device (pull-to-refresh the Apps list, or force-quit and relaunch TestFlight) to pick up the change.

## Simulator without the scheme

```bash
defaults write com.inquisitivefrog.DinoGames devWalkthrough -bool YES
```

`defaults delete com.inquisitivefrog.DinoGames devWalkthrough` turns it off. Re-launch the app.

## Compile flag

Walkthrough configuration sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DINO_WALKTHROUGH`. Implementation: `DeveloperSessionFlags`, `WalkthroughEarlyExit`, `GameLevel.visibleInGamePicker`.
