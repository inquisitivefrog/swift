# Development conventions

Best practices for working on Dino Games. Agent rules in `.cursor/rules/` mirror these for AI-assisted editing.

## Audio UX

**Audio must complete before user input is re-enabled.** Every game that plays instruction or feedback audio should lock touch input until playback finishes (or is explicitly cancelled).

## Testing

Follow existing patterns in `DinoGamesTests/` before adding infrastructure:

- `@testable import DinoGames`
- Unit XCTests for catalogs, configs, mechanics, and asset contracts
- `@MainActor` only when testing main-actor APIs (e.g. speech)
- **No** custom launch hooks, debug HUDs, or UI test host views unless the project already uses them

**Land display moments:** `LandGameDisplayMomentXCTests` asserts every shipping moment has image, display text, and audio. Add new moments there when a land game shows image + label + narration together.

**Ordered-touch games** (Ages, Flora, Smile, Diets, Eggs): use `OrderedTouchFeedback` for early-second-column taps and slow-success praise. `OrderedTouchFeedbackAudioXCTests` verifies clips exist.

**Comparison games** (Weigh, Who Is Taller): decision rules live in `GameLogic/ComparisonGameLogic.swift`. `ComparisonGameNegativeXCTests` covers near-equal and mismatch cases.

UI tests: keep smoke-level only (skip splash → category picker). Prefer unit tests for victory and game logic.

## Flora naming

Plant instance = `(pack, formation, taxon)`. Registry: `dinoFloraPlants` in `Data/LandGameDisplayMoment.swift`.

| Asset | Pattern |
|-------|---------|
| Images | `{pack}-flora-{formation}-{taxon}-habitat` / `-seeds` |
| Audio | `Audio/{Pack}-Flora/{FormationFolder}/{pack}-flora-{formation}-{taxon}.m4a` |
| Audio key | Same as filename stem (e.g. `dino-flora-morrison-cycad`) |
| Formation folder | Underscores (`Lance_Hell_Creek`); slug uses hyphens (`lance-hell-creek`) |
| Hints | `Audio/{Pack}-Flora/hints/{pack}-hint-{concept}.m4a` |

Add plants to the registry first; CI audio contract tests must pass.

## CLI / Xcode

Before running shell commands, verify syntax (`<tool> help`, `man`, or `--help`). macOS and Xcode updates change flags often.

After macOS or Xcode upgrades, re-verify simulator destinations:

```bash
xcrun simctl list devices available
xcodebuild -scheme DinoGames -showdestinations
```

See [README.xcodebuild.md](README.xcodebuild.md) for build and test commands.

## Documentation

- Human docs: `apps/dino-games/docs/` (this tree)
- Authoring notes: colocated `README.*` under `json/` and `images/`
- Agent rules: `.cursor/rules/` (not for interview review)

Do not add markdown to `DinoGames/DinoGames/` (app source). Put project docs in `docs/`.

## Scope discipline

Shipping land games = 12 (levels 1–4). Additional games exist in code but are gated. Parked features are intentional, not debt — document them in gameplay docs rather than deleting.
