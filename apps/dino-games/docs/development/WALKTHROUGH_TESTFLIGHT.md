# Walkthrough TestFlight build

A **demo / coffee-shop** binary: every catalog game that has a row, skip kid picker audio, and **Exit** on every game so you can start one mechanic and jump to another (dinosaurs vs pterosaurs, weigh vs racing, smile vs matrix).

This is **not** the App Store kids build. Archive **DinoGames-Walkthrough** for Internal TestFlight only. Do not submit that archive for App Store review.

## What it changes

| Shipping (`DinoGames`) | Walkthrough (`DinoGames-Walkthrough`) |
|---|---|
| Home screen name **DinoGames** | **DinoGames Demo** |
| Picker levels **1–4** | Every level that has games (land 5+ included) |
| Guided play + spoken walks | Manual pick; cover/level/game-card audio skipped |
| Finish a game to leave (except Debug flags) | **Exit** on every game cover, including during audio |
| Locks and concept prerequisites | All listed games playable |

Same bundle ID as the store app (`com.inquisitivefrog.DinoGames`). Installing this TestFlight build **replaces** the App Store copy on that device until you delete it and reinstall from the store.

Level 5+ land games may still miss parked art (`future-games` branch). Exit still works; some screens can look incomplete.

## Archive for TestFlight

From `apps/dino-games/DinoGames`:

```bash
xcodebuild -scheme DinoGames-Walkthrough -showdestinations
xcodebuild archive -scheme DinoGames-Walkthrough \
  -destination "generic/platform=iOS" \
  -archivePath ./build/DinoGames-Walkthrough.xcarchive
```

Then Organizer → Distribute App → TestFlight (Internal). Keep the App Store scheme on **DinoGames** / Release.

## Simulator without the scheme

```bash
defaults write com.inquisitivefrog.DinoGames devWalkthrough -bool YES
```

`defaults delete com.inquisitivefrog.DinoGames devWalkthrough` turns it off. Re-launch the app.

## Compile flag

Walkthrough configuration sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DINO_WALKTHROUGH`. Implementation: `DeveloperSessionFlags`, `WalkthroughEarlyExit`, `GameLevel.visibleInGamePicker`.
