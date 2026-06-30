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
- [x] Config smoke build (`LandDinosaurMechanicCatalogXCTests`) — all 12 configs instantiate

## Level 1
- [x] Weigh the Dinosaur — `WeighTheDinosaurXCTests` (+ `LandDinosaurWeighCatalogXCTests`)
- [x] Which Dino Is Taller — `WhichDinoIsTallerXCTests` (+ `LandDinosaurHeightCatalogXCTests`)
- [x] Dino Puzzle — `DinoPuzzleXCTests`

## Level 2
- [x] Name That Dinosaur — `NameThatDinosaurXCTests`
- [x] Racing Dinosaurs — `LandDinosaurRacingXCTests`
- [x] Dino Ages — `DinoAgesCatalogXCTests`

## Level 3
- [x] Dino Footprints — `DinoFootprintsXCTests` (+ `DinoFootprintsAssetsXCTests`)
- [x] Dino Flora — `DinoFloraXCTests`
- [x] Dino Eggs — `DinoEggsCatalogXCTests`

## Level 4
- [x] Dino Matrix — `DinoMatrixCatalogXCTests`
- [x] Dino Diets — `DinoDietsXCTests`
- [x] Dino Smile — `DinoSmileXCTests`

## Shared victory
- [x] `crowd-cheering` resolves in bundle

## Victory sequence (shared module)
- [x] `StandardVictorySequence` unit tests (`StandardVictorySequenceXCTests`) — same style as air/sea catalog tests
- [x] UI skip-splash → category picker (`LandVictorySequenceUITests`)
