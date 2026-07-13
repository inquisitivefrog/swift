# Proof of Concept (POC) Testing Guide

## What We're Testing

This POC implements a **simplified Matching Game** to validate core game mechanics before building the full app.

## POC Goals

1. ✅ **Tap Interactions** - Can children easily tap and select items?
2. ✅ **Selection State** - Does visual feedback work (highlighting, scaling)?
3. ✅ **Matching Logic** - Does the game correctly identify matches?
4. ✅ **Audio Feedback** - Does text-to-speech work for spoken names?
5. ✅ **Visual Feedback** - Do success/error messages display correctly?
6. ✅ **Game Completion** - Does the game detect when all matches are found?

## Current Implementation

### Matching Game POC
- **Location**: `DinoGames/Views/MatchingGameView.swift`
- **Data**: 3 dinosaurs, 5 characteristics (using emojis - no image assets needed)
- **Interaction**: Tap dinosaur → tap characteristic → see if they match
- **Audio**: Text-to-speech speaks dinosaur and characteristic names
- **Visual**: Color-coded feedback (blue = selected, green = matched)

## How to Test

1. **Build and run** the app on iPhone 17 simulator
2. **Tap a dinosaur** (left side) - should:
   - Highlight in blue
   - Scale up slightly
   - Speak the dinosaur name
3. **Tap a characteristic** (right side) - should:
   - Highlight in blue
   - Scale up slightly
   - Speak the characteristic name
   - Check if it matches the selected dinosaur
4. **If match**: 
   - Both items turn green
   - Success message appears
   - "Great match!" spoken
5. **If no match**:
   - Orange "Try again" message
   - Both selections reset after 1.5 seconds
6. **Complete game**: When all 3 dinosaurs are matched, celebration message appears

## What to Observe

### ✅ Should Work Well
- Large touch targets (180x80 points)
- Clear visual feedback (colors, scaling)
- Audio feedback on every tap
- Simple, intuitive interaction

### ⚠️ Potential Issues to Watch For
- **Audio overlap**: If tapping quickly, multiple speech utterances might overlap
- **Visual clarity**: Are the colors distinct enough?
- **Touch accuracy**: Are the buttons large enough for small fingers?
- **Feedback timing**: Is 1.5 seconds the right delay for "try again"?

## Next Steps After POC Validation

If this POC works well, we can:

1. **Add more dinosaurs** - Expand from 3 to 10+
2. **Add line drawing** - Draw lines connecting matched pairs (even across rows)
3. **Add real images** - Replace emojis with actual dinosaur illustrations
4. **Re-record audio files** - Current recordings are too quiet (see `AUDIO_RECORDING_NOTES.md`)
5. **Add game selection** - Create a menu to choose between different games
6. **Add progress tracking** - Save game progress using Core Data

## Known Issues

- **Audio Volume**: Recorded audio files are too quiet. Need to re-record at higher volume levels. See `AUDIO_RECORDING_NOTES.md` for details.

## Other POCs to Consider

After validating the matching game, we could test:

1. **Name That Dinosaur (Visual)** - Show image, tap correct name from 3-4 options
2. **Where's Waldo** - Grid-based touch detection for finding hidden dinosaurs
3. **Sound Matching** - Play sound, tap which dinosaur made it

## Notes

- This POC uses **emojis** instead of images to test mechanics quickly
- Uses **text-to-speech** instead of pre-recorded audio for rapid prototyping
- **No Core Data** needed for this POC (game state is in-memory)
- All game logic is self-contained in `MatchingGameView.swift`
