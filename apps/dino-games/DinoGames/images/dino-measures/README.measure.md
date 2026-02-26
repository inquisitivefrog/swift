
Begin with dinosaur centered on 1024x1024 pixel image
ie. pass JSON file to Google Gemini Nano Banana for image generation

Convert to 340x340 pixel image to match Paleontologist on ladder
% sips -Z 340 measure-dino-{slug}-1024.png --out measure-dino-{slug}-340.png

Convert to 
% sips -c 340 140 measure-dino-{slug}-340.png

Create imageset in Xcode as dino-games/DinoGames/DinoGames/Assets.xcassets/Dinosaur-Measures/measure-dino-{slug}
Add 340x140 image to imageset as 1x

If image crops dinosaur, let it go for now.
