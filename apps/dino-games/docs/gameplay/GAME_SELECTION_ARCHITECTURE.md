# Game Selection Architecture

## Decision: Split data, share UI

- **Data:** Game lists are split by category into separate catalog files. Each category (Dinosaur, Pterosaur, Marine Reptile) has its own catalog that defines which games appear and in what order.
- **UI:** A single `GameSelectionView` is used for all categories. It takes a `GameCategory` and gets its list from the catalogs. The same layout, cards, transition, and sheet flow apply everywhere.

## Benefits

- **Scalability:** Adding games or new categories (e.g. Ichthyosaur, Mosasaur, Plesiosaur) is done by editing or adding a catalog file, not one giant view.
- **Maintainability:** Each catalog is a small, focused list. The view stays generic and does not grow with the number of games.
- **Consistency:** One UI ensures the same behavior and look across Land, Air, and Sea (and future subcategories).

## Files

| File | Role |
|------|------|
| `GameSelectionView.swift` | Shared UI: receives `category`, shows `GameCatalog.games(for: category)`, one `ForEach`, same sheets/transition. |
| `GameCatalog.swift` | Dispatcher: `games(for: GameCategory) -> [GameType]` returns the list for the selected category. |
| `DinosaurGameCatalog.swift` | Games for Land (e.g. Match the Dinosaur, Weigh, Find Mama, …). |
| `PterosaurGameCatalog.swift` | Games for Air (e.g. Match the Pterosaur, …). |
| `MarineReptileGameCatalog.swift` | Games for Sea (empty until marine reptile games exist). |

Future: additional catalog files (e.g. `IchthyosaurGameCatalog`, `MosasaurGameCatalog`, `PlesiosaurGameCatalog`) and an extended `GameCategory` or subcategory model can be added without changing the shared `GameSelectionView`.

## Data flow

1. User taps a category on the cover (Dinosaurs / Pterosaurs / Marine Reptiles).
2. `CategorySelectionView` navigates to `GameSelectionView(category: selectedCategory)`.
3. `GameSelectionView` computes `gamesForCategory = GameCatalog.games(for: category)`.
4. One `ForEach(gamesForCategory)` renders `GameCard` for each game.
5. Tapping a card still sets `selectedGame`, plays transition audio, and presents the same sheet flow as before.
