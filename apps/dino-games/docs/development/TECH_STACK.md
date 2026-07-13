# Technology Stack & Tools

Use this file to list technologies and tools used to build DinoGames, plus their versions. Update the version placeholders as needed (e.g. from Xcode → **Xcode > About Xcode**; Swift from **Build Settings → Swift Language Version**).

---

## Development

| Technology | Version | Notes |
|------------|---------|--------|
| **Swift** | 5.0 | Set in Xcode target Build Settings |
| **SwiftUI** | — | UI framework |
| **Xcode** | _e.g. 16.x / 26.x_ | Check **Xcode → About Xcode** |
| **iOS deployment target** | 26.2 | Set in project; lower if supporting older devices |
| **Core Data** | — | Local persistence (DinoGames.xcdatamodeld) |
| **AVFoundation** | — | Audio playback (m4a), TTS fallback |

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|--------|
| **Cursor** | _your version_ | IDE / AI-assisted editing |
| **sips** | _macOS built-in_ | Image resizing/export (e.g. for @1x/@2x/@3x) |
| **QuickTime Player** | _macOS built-in_ | Recording/exporting m4a audio |
| **Google Gemini** (e.g. Nano) | _your model/version_ | Image generation, research |

---

## Where versions live

- **Xcode / Swift**: Xcode → **About Xcode**; project **Build Settings** → “Swift Language Version”.
- **iOS SDK**: Xcode **Build Settings** → “iOS Deployment Target”.
- **Cursor**: **Cursor → About Cursor** (or Check for Updates).
- **sips**: Terminal `sips --help` or `man sips` (macOS version).
- **QuickTime**: **QuickTime Player → About QuickTime Player** (or System Settings).

---

## For README / portfolio

You can copy a short “Built with” block from here into:

- **docs/README.md** – already has a Technology Stack section; add versions there or link to this file.
- **Repo root README** – if the repo is `dino-games` or `DinoGames`, add a one-line link:  
  `Tech stack & versions: [TECH_STACK.md](DinoGames/TECH_STACK.md)`.

Example one-liner for resumes or interviews:

> Built with Swift 5, SwiftUI, Xcode, Core Data, and AVFoundation; assets prepared with sips and QuickTime; design and copy assisted with Cursor and Google Gemini.
