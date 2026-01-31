# Match the Pterosaur Game Plan

## Image Set Naming Convention

**Prefix: `ptero-`** (consistent with `dino-` for dinosaurs)

**Image Set Names:**
- `ptero-pterodactyl` (or `ptero-pterodactylus` if you prefer the full scientific name)
- `ptero-pteranodon`
- `ptero-quetzalcoatlus`

## Pterosaurs to Add (5 total)

1. **Pterodactyl** (Pterodactylus)
   - Characteristics: TBD (need suggestions)
   - Image: `ptero-pterodactyl`

2. **Pteranodon**
   - Characteristics: TBD (need suggestions)
   - Image: `ptero-pteranodon`

3. **Quetzalcoatlus**
   - Characteristics: TBD (need suggestions)
   - Image: `ptero-quetzalcoatlus`

4. **Rhamphorhynchus**
   - Characteristics: TBD (need suggestions)
   - Image: `ptero-rhamphorhynchus`

5. **Dimorphodon**
   - Characteristics: TBD (need suggestions)
   - Image: `ptero-dimorphodon`

## Game Structure

This will be a **separate matching game** from "Match the Dinosaur!":
- New game card on the selection screen: "Match the Pterosaur!"
- Uses the same `MatchingGameView` (reusable)
- New `MatchingGameConfig` for pterosaurs
- Separate pool of pterosaurs and characteristics

## Characteristics Ideas

**Pterodactyl:**
- Wings
- Small
- Teeth

**Pteranodon:**
- Wings
- Crest
- No Teeth

**Quetzalcoatlus:**
- Wings
- Big
- Long Neck

## Implementation Steps

1. ✅ Confirm image prefix (`ptero-`)
2. ✅ Add pterosaur data structures (similar to dinosaurs)
3. ✅ Create `MatchingGameConfig` for pterosaurs
4. ✅ Add to `GameSelectionView` as new matching game
5. ⏳ Add intro audio file: `Feedback/game-intro-pterosaur.m4a`
6. ⏳ Add game card image: `game-pterosaur-features` to Assets.xcassets

## Notes

- Pterosaurs are flying reptiles, not dinosaurs (but kids love them!)
- Dinosaur Train is a great reference for kid-friendly pterosaur facts
- All 5 pterosaurs are now included in the plan
