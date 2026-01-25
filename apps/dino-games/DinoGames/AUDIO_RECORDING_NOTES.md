# Audio Recording Notes

## Volume Level Issue

**Problem**: Recorded audio files are too quiet compared to text-to-speech.

**Observation**: 
- Test Audio button (TTS) is very loud at maximum Mac volume
- Recorded `.m4a` files are barely audible even at maximum Mac volume
- Code sets `AVAudioPlayer.volume = 1.0` (maximum), so issue is in source recordings

## Solution Required

**Action Needed**: Re-record all audio files at higher volume levels.

### Recording Guidelines

1. **Input Level**: Record at higher input volume/gain during recording
2. **Normalization**: Use audio editing software to normalize/amplify recordings
3. **Target Level**: Match the volume of text-to-speech output
4. **Test**: Compare recorded files to TTS output before finalizing

### Files to Re-record

All files in `Assets/Audio/`:
- **Dinosaurs**: `t-rex.m4a`, `triceratops.m4a`, `stegosaurus.m4a`
- **Characteristics**: `teeth.m4a`, `footprints.m4a`, `eggs.m4a`, `skin.m4a`, `spikes.m4a`
- **Feedback**: `great-match.m4a`, `try-again.m4a`

### Tools for Volume Adjustment

**Option 1: Re-record with higher input**
- Use QuickTime Player or Voice Memos
- Increase Mac input volume before recording
- Speak closer to microphone

**Option 2: Amplify existing recordings**
- Use Audacity (free) to amplify existing files
- Normalize to -3dB to -6dB peak level
- Export as `.m4a` format

**Option 3: Use audio editing software**
- GarageBand, Audacity, or similar
- Apply gain/amplification to existing files
- Normalize all files to consistent level

## Current Status

- ✅ Audio files are in bundle and playing correctly
- ✅ Code is set to maximum volume (1.0)
- ⚠️ Source recordings are too quiet
- 📝 **TODO**: Re-record or amplify all audio files

## Testing After Re-recording

1. Replace files in `Assets/Audio/` folders
2. Clean build and test
3. Compare volume to TTS output
4. Adjust if needed

---

**Created**: 2026-01-23
**Issue**: Recorded audio too quiet compared to TTS
**Status**: Pending re-recording/amplification
