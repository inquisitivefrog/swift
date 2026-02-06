# Dinosaur assets: name, text, imageset (dino-), Audio/Dinosaurs

All games use the same land-dinosaur pool from `MatchingGameConfigs.allDinosaurs` (plus Weigh/Toothache/Racing/Wacky subsets). Speech uses the dinosaur **name** as the spoken key; audio is resolved via `SpeechManager` → `Dinosaurs/<slug>.m4a`. The bundle actually uses **dino-** prefixed files under `Assets/Audio/Dinosaurs/`.

| Dinosaur name | Text (spoken key) | Imageset (dino-) | Audio in Audio/Dinosaurs |
|---------------|-------------------|------------------|---------------------------|
| T-Rex | T-Rex | dino-trex | ✅ dino-t-rex.m4a |
| Triceratops | Triceratops | dino-triceratops | ✅ dino-triceratops.m4a |
| Stegosaurus | Stegosaurus | dino-stegosaurus | ✅ dino-stegosaurus.m4a |
| Velociraptor | Velociraptor | dino-velociraptor | ✅ dino-velociraptor.m4a |
| Therizinosaurus | Therizinosaurus | dino-therizinosaurus | ✅ dino-therizinosaurus.m4a |
| Spinosaurus | Spinosaurus | dino-spinosaurus | ✅ dino-spinosaurus.m4a |
| Apatosaurus | Apatosaurus | dino-apatosaurus | ✅ dino-apatosaurus.m4a |
| Ankylosaurus | Ankylosaurus | dino-ankylosaurus | ✅ dino-ankylosaurus.m4a |
| Corythosaurus | Corythosaurus | dino-corythosaurus | ✅ dino-corythosaurus.m4a |
| Parasaurolophus | Parasaurolophus | dino-parasaurolophus | ✅ dino-parasaurolophus.m4a |
| Iguanodon | Iguanodon | dino-iguanodon | ✅ dino-iguanodon.m4a |
| Troodon | Troodon | dino-troodon | ✅ dino-troodon.m4a |

**Where each is used**

- **Matching (land), Guess, Racing**: all 12 (T-Rex … Troodon).
- **Weigh**: Velociraptor, Troodon, Parasaurolophus, Corythosaurus, Iguanodon, Therizinosaurus, Stegosaurus, Ankylosaurus, Spinosaurus, T-Rex, Triceratops, Apatosaurus.
- **Toothache**: subset of the 12 (grumpy/tooth images use grumpy-* / tooth-*).
- **Wacky**: same 12 plus **Diplodocus** and **Pachycephalosaurus**; Wacky uses **wacky-** imagesets (e.g. wacky-trex, wacky-diplodocus), not dino-*. Audio for Diplodocus / Pachycephalosaurus is mapped to `Dinosaurs/diplodocus` and `Dinosaurs/pachycephalosaurus`; there are no `dino-diplodocus.m4a` or `dino-pachycephalosaurus.m4a` in Audio/Dinosaurs currently.

**Audio path vs file name**

- Code maps names to paths like `Dinosaurs/t-rex`, `Dinosaurs/triceratops`, etc. (no `dino-` in path).
- Bundle has `Assets/Audio/Dinosaurs/dino-<name>.m4a` (e.g. dino-t-rex.m4a, dino-triceratops.m4a). Bundle search tries multiple path forms and the filename; if playback works, the table’s “Audio in Audio/Dinosaurs” reflects the files that exist under that folder.

**Imagesets in Assets.xcassets**

- All 12 have a matching **dino-&lt;name&gt;.imageset** (e.g. dino-trex, dino-triceratops, dino-stegosaurus, dino-velociraptor, dino-therizinosaurus, dino-spinosaurus, dino-apatosaurus, dino-ankylosaurus, dino-corythosaurus, dino-parasaurolophus, dino-iguanodon, dino-troodon).
- **T-Rex** imageset is `dino-trex`; audio file is `dino-t-rex.m4a` (hyphen in audio name).
