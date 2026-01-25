# Matching Game Logic Review: Matching Dinosaurs to Characteristics

*This review is specific to the "Match the Dinosaur!" matching game (dino-features).*

## Current Game Data

### Dinosaurs (3 total):
1. **T-Rex** (id: 1)
   - Characteristics: Teeth (id: 1), Footprints (id: 2)
   - `characteristicIds: [1, 2]`

2. **Triceratops** (id: 2)
   - Characteristics: Eggs (id: 3), Skin (id: 4)
   - `characteristicIds: [3, 4]`

3. **Stegosaurus** (id: 3)
   - Characteristics: Spikes (id: 5)
   - `characteristicIds: [5]`

### Characteristics (5 total):
1. **Teeth** (id: 1) → belongs to T-Rex (dinosaurId: 1)
2. **Footprints** (id: 2) → belongs to T-Rex (dinosaurId: 1)
3. **Eggs** (id: 3) → belongs to Triceratops (dinosaurId: 2)
4. **Skin** (id: 4) → belongs to Triceratops (dinosaurId: 2)
5. **Spikes** (id: 5) → belongs to Stegosaurus (dinosaurId: 3)

## Current Matching Logic

### Flow:
1. **User taps dinosaur** → `handleDinosaurTap()`
   - Checks if dinosaur is fully matched (all characteristics matched)
   - If same dinosaur tapped again → deselects (no audio)
   - Plays dinosaur name audio
   - Sets `selectedDinosaur`
   - Resets `selectedCharacteristic`

2. **User taps characteristic** → `handleCharacteristicTap()`
   - Checks if characteristic is already matched
   - If same characteristic tapped again → deselects (no audio)
   - Sets `selectedCharacteristic`
   - Plays characteristic name audio
   - Waits 1.2 seconds, then calls `checkMatch()`

3. **Match check** → `checkMatch()`
   - Compares: `characteristic.dinosaurId == dinosaur.id`
   - If match:
     - Shows "Great match!" feedback
     - Plays "great-match" audio
     - Adds `MatchedPair(dinosaurId, characteristicId)` to `matchedPairs` set
     - Checks if game complete: `matchedPairs.count == dinosaurs.count` (3 matches)
     - If complete → shows success, plays "success-all-matches", returns to home
     - If not complete → resets selections after 1.5 seconds
   - If no match:
     - Shows "Try again!" feedback
     - Plays "try-again" audio
     - Adds failed attempt to `failedAttempts` set (shows red X)
     - Resets selections after 2.0 seconds
     - Clears failed attempt indicator after 3.0 seconds total

## Potential Issues & Questions

### 1. **Game Completion Logic**
**Current**: Game completes when `matchedPairs.count == dinosaurs.count` (3 matches)

**Issue**: This assumes each dinosaur has exactly 1 characteristic that needs matching. But:
- T-Rex has 2 characteristics (Teeth, Footprints)
- Triceratops has 2 characteristics (Eggs, Skin)
- Stegosaurus has 1 characteristic (Spikes)

**Question**: What should the win condition be?
- **Option A**: Match all 5 characteristics (one for each characteristic)
- **Option B**: Match 3 pairs (one characteristic per dinosaur)
- **Option C**: Match all characteristics for each dinosaur (all 5 matches)

### 2. **Dinosaur Selection Blocking**
**Current**: `handleDinosaurTap()` blocks selection if:
```swift
let matchedCount = matchedPairs.filter { $0.dinosaurId == dinosaur.id }.count
guard matchedCount < dinosaurCharacteristics.count else { return }
```

**Issue**: This prevents selecting a dinosaur once ALL its characteristics are matched. But if a dinosaur has 2 characteristics, you can still select it after 1 match.

**Question**: Should dinosaurs be selectable after all their characteristics are matched? Or should they be permanently disabled?

### 3. **Characteristic Reuse**
**Current**: Characteristics can only be matched once (checked in `handleCharacteristicTap()`)

**Question**: Is this correct? Or can the same characteristic (e.g., "Teeth") belong to multiple dinosaurs?

### 4. **Match Validation**
**Current**: Simple check: `characteristic.dinosaurId == dinosaur.id`

**Question**: Is this correct? The data shows:
- Teeth → T-Rex only
- Footprints → T-Rex only
- Eggs → Triceratops only
- Skin → Triceratops only
- Spikes → Stegosaurus only

This seems correct, but want to confirm the intended game design.

## Recommended Clarifications

1. **Win Condition**: How many matches are needed to win?
   - All 5 characteristics matched?
   - One match per dinosaur (3 total)?
   - Something else?

2. **Multiple Characteristics per Dinosaur**: 
   - Should players match ALL characteristics for each dinosaur?
   - Or just one characteristic per dinosaur?

3. **Visual Feedback**:
   - Should matched dinosaurs show all their matched characteristics?
   - Should matched characteristics be visually distinct?

4. **Game Progression**:
   - Can players continue after matching one characteristic per dinosaur?
   - Or must they match all characteristics?

## Current Behavior Summary

✅ **What Works**:
- Prevents selecting already-matched characteristics
- Prevents selecting fully-matched dinosaurs (all characteristics matched)
- Shows visual feedback (green checkmark for matches, red X for failures)
- Plays appropriate audio feedback
- Tracks specific matched pairs correctly

⚠️ **Potential Issues**:
- Game completion might trigger too early (after 3 matches instead of 5)
- Dinosaur blocking logic might be confusing (can still select after 1 of 2 matches)

---

**Please review and let me know:**
1. What should the win condition be?
2. Should dinosaurs be selectable after partial matches?
3. Is the current matching logic correct for your game design?
