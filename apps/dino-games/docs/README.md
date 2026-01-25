# 🦕 Dino Games 🦖

A native iOS mobile application designed for children ages 4-6, featuring age-appropriate educational games.

## Overview

Dino Games is a SwiftUI application with Core Data for local storage, providing a safe and engaging gaming experience for young children. The app features colorful, intuitive interfaces and simple gameplay mechanics suitable for preschoolers.

## Technology Stack

Following the patterns from `grocery-app`:
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence (game progress, settings, etc.)
- **Swift Concurrency**: Async/await for smooth performance
- **UserDefaults**: User preferences and app state
- **XCTest**: Unit and UI test coverage

## App Size Considerations

### Download Limits
- **200 MB warning**: Apps over 200MB will prompt users on cellular (iOS 13+)
- **No hard limit**: Users can download larger apps with permission
- **Best practice**: Keep under 200MB for better user experience

### Image Optimization Strategy

Since the app is image-heavy (children can't read), we'll use:

1. **HEIF/HEIC format** for photos/illustrations (30-50% smaller than JPEG)
2. **PNG with optimization** for UI elements with transparency
3. **Asset Catalogs** with @1x, @2x, @3x variants (App Thinning)
4. **Build-time compression** using tools like ImageOptim, pngquant
5. **Vector assets** (PDF/SVG) where possible for icons/illustrations

### Estimated Image Capacity

Assuming optimized images:
- **Small UI elements** (icons, buttons): ~5-20 KB each
- **Game assets** (characters, objects): ~50-200 KB each
- **Background images**: ~100-500 KB each

**Rough estimates:**
- **Conservative** (under 100MB): ~500-1000 images
- **Moderate** (100-200MB): ~1000-2000 images  
- **Large** (200-500MB): ~2000-5000 images

*Note: Actual capacity depends heavily on image complexity, compression, and whether you use vector assets.*

## Features

- **Child-Friendly UI**: Large buttons, bright colors, and simple navigation
- **Educational Games**: Age-appropriate games that promote learning through play
- **Safe Environment**: No ads, in-app purchases, or external links
- **Offline-First**: All content downloaded with app, no backend required
- **Image-Heavy**: Visual-first design for pre-readers

## Project Status

🚧 **Planning Phase** - Brainstorming game ideas and architecture

## Design Philosophy

**Sound & Touch, NOT Read & Write**

This app is designed for pre-literate children (ages 4-6). The entire interface is built on:
- ✅ **Sound**: Spoken instructions, audio feedback, spoken dinosaur names
- ✅ **Touch**: Tap interactions, large touch targets, visual feedback
- ❌ **NOT Reading**: Minimal text, no written instructions
- ❌ **NOT Writing**: No text input required

Every design decision must answer: "Can a 4-year-old who can't read use this?"

## Design Guidelines

- Use large, touch-friendly buttons (minimum 44x44 points)
- Keep colors bright and cheerful
- Use simple, clear visual instructions
- **All instructions are spoken** (no text-only instructions)
- Provide immediate visual AND audio feedback
- Avoid text-heavy screens
- Use images, emojis, and icons to aid understanding
- Icon-based navigation (not text menus)
- Visual feedback for all interactions
- Audio feedback for all actions

See `DESIGN_PHILOSOPHY.md` for complete design guidelines.
