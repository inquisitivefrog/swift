# Matching Game Design Logic

## Current Implementation

### Game Setup:
- **3 Dinosaurs**: T-Rex, Triceratops, Stegosaurus
- **5 Characteristics**: Teeth, Footprints, Eggs, Skin, Spikes
- **Matching Rules**: Each characteristic belongs to exactly one dinosaur

### Current Win Condition:
- **Win**: When `matchedPairs.count == dinosaurs.count` (3 matches)
- This means: Match ONE characteristic per dinosaur = win
- **Note**: There are 5 total characteristics, but only 3 matches needed

### Failed Attempts:
- **Current**: NO limit on failed guesses
- Failed attempts show red X mark (visual feedback only)
- Players can keep trying indefinitely until they win
- Failed attempts don't block or end the game

## Questions About Design:

### 1. Win Condition:
**Current**: 3 matches (one per dinosaur)
- T-Rex: Match Teeth OR Footprints (either one)
- Triceratops: Match Eggs OR Skin (either one)  
- Stegosaurus: Match Spikes (only option)

**Alternative**: 5 matches (all characteristics)
- Must match ALL characteristics for each dinosaur
- More challenging, more educational

**Which do you prefer?**

### 2. Failed Guess Limit:
**Current**: Unlimited failed attempts

**Option A**: No limit (current) - players keep trying
**Option B**: Limit to 2 failed attempts per pair, then game ends
**Option C**: Limit total failed attempts (e.g., 5 total failures = game over)
**Option D**: Something else?

**Do you want to add a failed guess limit?**

### 3. Game Flow:
- Should players be able to match multiple characteristics per dinosaur?
- Or is one match per dinosaur enough?

---

**Current Status**: 
- ✅ 3 matches = win
- ✅ Unlimited failed attempts allowed
- ✅ Visual feedback for failures (red X)
- ⚠️ No game-over condition for too many failures

**What would you like to change?**
