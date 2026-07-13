
Goal: replace square images of game runners with realistic backgrounds
      with square images of game runners with transparent backgrounds
      that make images look like dinosaur shaped borders.

Example: OLD: Ankylosaur racing using image with white background
         NEW: Ankylosaur racing using image with clear background

Steps:
1. update SETTING in Ankylosaur asset manifest to indicate nothing
   in the background and green color, "00ff00" 
2. use Gemini Nano Banana to generate image with colored background
   dino-racer-ankylosaurus-run-1024-transparent.png
3. use "magick" instead of "sips" to convert green color to transparent
   Note: when image displays on MacOS Desktop, it still looks like
         a white shaded background but when added as imageset to XCode
         it looks different
   magick dino-racer-ankylosaurus-run-1024-transparent.png -resize 80x80 PNG32:dino-racer-ankylosaurus-run-80.png        
   magick dino-racer-ankylosaurus-run-1024-transparent.png -resize 160x160 PNG32:dino-racer-ankylosaurus-run-160.png        
   magick dino-racer-ankylosaurus-run-1024-transparent.png -resize 240x240 PNG32:dino-racer-ankylosaurus-run-240.png        
4. update imageset dino-racer-ankylosaurus-run
5. XCode
   Product/Clean Build Folder
   Product/Build
6. Cursor
   start app Simulator in debug mode 
   xcrun simctl spawn booted defaults write com.inquisitivefrog.DinoGames devUnlockAllGameLevels -bool YES
7. play game Racing Dinosaurs
   select Cretaceous Period
   select Ankylosaurus
   watch race and compare image styles
