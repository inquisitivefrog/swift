# Land games (L1–4) test checklist

Shipping land games only. Check off as covered.

## All 12 games — baseline
- [x] Audio contract + bundle resolution (`LandDinosaurGameAudioFilesXCTests`)
- [x] Picker card image (`UnifiedGameMediaContractXCTests`)
- [x] Catalog placement L1–4 (`LandDinosaurGameCatalogXCTests`)
- [x] Victory success image (`LandDinosaurVictoryAssetsXCTests`)
- [x] Progress category = land (`LandDinosaurGameCatalogXCTests`)
- [x] Image + text + audio triad per gameplay moment (`LandGameDisplayMomentXCTests`)
- [x] Ordered-touch feedback audio (`OrderedTouchFeedbackAudioXCTests`) — pick-first + slow-response clips
- [x] Comparison negative cases (`ComparisonGameNegativeXCTests`) — near-equal, asymmetric mismatch, too-small-to-see

## Level 1
- [x] Weigh the Dinosaur — mechanic (`LandDinosaurMechanicCatalogXCTests`)
- [x] Which Dino Is Taller — mechanic
- [x] Dino Puzzle — config + art

## Level 2
- [x] Name That Dinosaur — production config + silhouettes
- [x] Racing Dinosaurs — config + progress id
- [x] Dino Ages — placement + period art

## Level 3
- [x] Dino Footprints — dedicated file (`DinoFootprintsAssetsXCTests`)
- [x] Dino Flora — plants + success art
- [x] Dino Eggs — rounds + clade assets

## Level 4
- [x] Dino Matrix — config + level 4
- [x] Dino Diets — diet audio + success art (`DinoDietsXCTests` + victory assets)
- [x] Dino Smile — config + level 4

## Shared victory
- [x] `crowd-cheering` resolves in bundle

## Victory sequence (shared module)
- [x] `StandardVictorySequence` unit tests (`StandardVictorySequenceXCTests`) — same style as air/sea catalog tests
- [x] UI skip-splash → category picker (`LandVictorySequenceUITests`)
