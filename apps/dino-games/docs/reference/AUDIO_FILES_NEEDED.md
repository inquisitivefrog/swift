# Audio Files Needed for Matching Game

## Design Philosophy
Audio files provide gameplay clues for children who can't read yet. This supports the "Sound & Touch, NOT Read & Write" design principle.

## Current Status
- ✅ Audio system implemented and working
- ✅ Falls back to TTS if audio files missing
- ⏳ Need to record/add audio files for new dinosaurs and characteristics

## Audio Files Needed

### Dinosaurs (12 total):
1. ✅ T-Rex - `Dinosaurs/t-rex.m4a` (exists)
2. ✅ Triceratops - `Dinosaurs/triceratops.m4a` (exists)
3. ✅ Stegosaurus - `Dinosaurs/stegosaurus.m4a` (exists)
4. ⏳ Velociraptor - `Dinosaurs/velociraptor.m4a` (needed)
5. ⏳ Therizinosaurus - `Dinosaurs/therizinosaurus.m4a` (needed)
6. ⏳ Spinosaurus - `Dinosaurs/spinosaurus.m4a` (needed)
7. ⏳ Apatosaurus - `Dinosaurs/apatosaurus.m4a` (needed)
8. ⏳ Ankylosaurus - `Dinosaurs/ankylosaurus.m4a` (needed)
9. ⏳ Corythosaurus - `Dinosaurs/corythosaurus.m4a` (needed)
10. ⏳ Parasaurolophus - `Dinosaurs/parasaurolophus.m4a` (needed)
11. ⏳ Iguanodon - `Dinosaurs/iguanodon.m4a` (needed)
12. ⏳ Troodon - `Dinosaurs/troodon.m4a` (needed)

### Characteristics (13 total):
**Existing (5):**
1. ✅ Teeth - `Characteristics/teeth.m4a` (exists)
2. ✅ Footprints - `Characteristics/footprints.m4a` (exists)
3. ✅ Eggs - `Characteristics/eggs.m4a` (exists)
4. ✅ Skin - `Characteristics/skin.m4a` (exists)
5. ✅ Spikes - `Characteristics/spikes.m4a` (exists)

**New (10):**
6. ⏳ Claws - `Characteristics/claws.m4a` (needed - Velociraptor)
7. ⏳ Fast - `Characteristics/fast.m4a` (needed - Velociraptor)
8. ⏳ Long Claws - `Characteristics/long-claws.m4a` (needed - Therizinosaurus)
9. ⏳ Feathers - `Characteristics/feathers.m4a` (needed - Therizinosaurus)
10. ⏳ Sail - `Characteristics/sail.m4a` (needed - Spinosaurus)
11. ⏳ Swims - `Characteristics/swims.m4a` (needed - Spinosaurus)
12. ⏳ Long Neck - `Characteristics/long-neck.m4a` (needed - Apatosaurus)
13. ⏳ Big - `Characteristics/big.m4a` (needed - Apatosaurus)
14. ⏳ Armor - `Characteristics/armor.m4a` (needed - Ankylosaurus)
15. ⏳ Club Tail - `Characteristics/club-tail.m4a` (needed - Ankylosaurus)
16. ⏳ Crest - `Characteristics/crest.m4a` (needed - Corythosaurus)
17. ⏳ Duck Bill - `Characteristics/duck-bill.m4a` (needed - Corythosaurus)
18. ⏳ Long Crest - `Characteristics/long-crest.m4a` (needed - Parasaurolophus)
19. ⏳ Duck Bill - `Characteristics/duck-bill.m4a` (needed - Parasaurolophus - note: shared with Corythosaurus)
20. ⏳ Thumb Spikes - `Characteristics/thumb-spikes.m4a` (needed - Iguanodon)
21. ⏳ Smart - `Characteristics/smart.m4a` (needed - Troodon)
22. ⏳ Big Eyes - `Characteristics/big-eyes.m4a` (needed - Troodon)

### Feedback Audio (existing):
- ✅ `Feedback/great-match.m4a` (exists)
- ✅ `Feedback/try-again.m4a` (exists)
- ✅ `Feedback/success-all-matches.m4a` (exists)
- ✅ `Feedback/sorry-game-over.m4a` (exists)
- ✅ `Feedback/welcome-to-dino-games.m4a` (exists)

## Recording Guidelines
- Use MacOS Settings/Sound/Input at halfway or higher
- Record in quiet environment
- Speak clearly and at consistent volume
- Save as `.m4a` format
- Place in appropriate folder: `Assets/Audio/Dinosaurs/` or `Assets/Audio/Characteristics/`

## Next Steps
1. Record dinosaur name audio files (9 new: Velociraptor, Therizinosaurus, Spinosaurus, Apatosaurus, Ankylosaurus, Corythosaurus, Parasaurolophus, Iguanodon, Troodon)
2. Record characteristic name audio files (17 new: Claws, Fast, Long Claws, Feathers, Sail, Swims, Long Neck, Big, Armor, Club Tail, Crest, Duck Bill, Long Crest, Thumb Spikes, Smart, Big Eyes)
   - Note: "Duck Bill" is shared by Corythosaurus and Parasaurolophus, so only one recording needed
3. Add to Xcode project as folder references
4. Test playback

---

**Note**: The game will work with TTS fallback, but recorded audio provides better experience for children.
