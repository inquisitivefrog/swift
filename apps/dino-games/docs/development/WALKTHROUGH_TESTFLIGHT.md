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

## Simulator without the scheme

```bash
defaults write com.inquisitivefrog.DinoGames devWalkthrough -bool YES
```

`defaults delete com.inquisitivefrog.DinoGames devWalkthrough` turns it off. Re-launch the app.

## Compile flag

Walkthrough configuration sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DINO_WALKTHROUGH`. Implementation: `DeveloperSessionFlags`, `WalkthroughEarlyExit`, `GameLevel.visibleInGamePicker`.
