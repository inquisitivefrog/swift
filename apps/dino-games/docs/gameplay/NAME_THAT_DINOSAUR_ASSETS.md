# Name that Dinosaur! — Asset changes

The game formerly titled **"Guess the Dinosaur!"** is now **"Name that Dinosaur!"** (identify by silhouette). A future, more sophisticated **"Guess the Dinosaur!"** game can be added later.

## What you need to change

### 1. Image set (required)

The game card image is keyed by id **`name-that-dinosaur`**, so the app looks for an imageset named **`game-name-that-dinosaur`**.

- In Xcode, the imageset must be named **`game-name-that-dinosaur.imageset`**.
- You can leave the image filenames inside as-is; the imageset name is what the code uses. Use caption **"Name That Dinosaur!"** in the image if you add text.

### 2. Audio (optional)

- **Transition (when the player taps the game card):**  
  The app now uses **`Games/name-that-dinosaur`** for the transition clip.  
  - If you add **`name-that-dinosaur.m4a`** in **`Assets/Audio/Games/`**, that file will play.  
  - If you don’t add it, TTS will say “name that dinosaur” as a fallback.  
  - You can also keep using the old phrase by adding a copy of **`can-you-name-the-dinosaur.m4a`** and naming it **`name-that-dinosaur.m4a`**.

- **Intro when the game screen appears:**  
  Still uses **`can-you-name-the-dinosaur`** (same file as before). No change needed unless you want a new intro clip.

## Summary

| Item | Action |
|------|--------|
| **Image set** | Use **`game-name-that-dinosaur.imageset`** (id is `name-that-dinosaur` so image name is `game-name-that-dinosaur`). |
| **Transition audio** | Optional: add **`Games/name-that-dinosaur.m4a`** for a dedicated “Name that Dinosaur!” transition; otherwise TTS is used. |
| **Intro audio** | No change; **`can-you-name-the-dinosaur.m4a`** is still used. |
