# CosmicWeather App Icon Design Specification

## Design Concept: "Liquid Planet"

A minimalist sphere with premium liquid glass aesthetics, capturing the essence of planetary atmospheres.

---

## Visual Elements

### Primary Shape
- **Perfect circle** with subtle 3D depth
- **Corner radius**: Standard iOS icon shape (superellipse applied automatically)

### Background
- **Deep space gradient**: From `#0D1B2A` (top-left) to `#1B263B` (bottom-right)
- **Subtle vignette**: Darker edges for depth

### Central Planet Sphere
- **Size**: 60% of icon width, centered
- **Gradient**: 
  - Top-left (light): `#4169E1` (Royal Blue)
  - Center: `#1E90FF` (Dodger Blue)  
  - Bottom-right (shadow): `#0D47A1` (Dark Blue)

### Glass/Liquid Effect
- **Highlight arc**: White-to-transparent gradient on top-left quadrant (opacity 40%)
- **Inner shadow**: Subtle dark crescent on bottom-right (opacity 15%)
- **Outer glow**: Soft blue halo (`#4169E1` at 30% opacity, blur 20px)

### Atmospheric Ring (Optional)
- **Thin ellipse**: Tilted 15-20 degrees
- **Gradient stroke**: White (50% opacity) fading to transparent
- **Position**: Slightly below center of sphere

### Stars (Subtle)
- 3-5 tiny white dots in upper corners
- Variable opacity (30-60%)
- Size: 1-2px

---

## Color Palette

| Element | Hex | Usage |
|---------|-----|-------|
| Deep Space | `#0D1B2A` | Background base |
| Navy | `#1B263B` | Background gradient end |
| Royal Blue | `#4169E1` | Planet primary |
| Dodger Blue | `#1E90FF` | Planet highlight |
| Dark Blue | `#0D47A1` | Planet shadow |
| White | `#FFFFFF` | Highlights, stars |

---

## Size Specifications

| Platform | Size (px) |
|----------|-----------|
| iPhone App | 60x60 @2x, @3x |
| iPad App | 76x76 @2x |
| App Store | 1024x1024 |
| Spotlight | 40x40 @2x, @3x |
| Settings | 29x29 @2x, @3x |

---

## Figma/Sketch Construction Guide

```
Layer Stack (bottom to top):
1. Background Rectangle (fill: gradient)
2. Vignette Overlay (radial gradient, multiply)
3. Star Dots (white circles, opacity 40%)
4. Planet Glow (circle, blur 20, opacity 30%)
5. Planet Base (circle, gradient fill)
6. Planet Shadow (arc shape, dark blue, opacity 15%)
7. Planet Highlight (arc shape, white, opacity 40%)
8. Ring (ellipse stroke, gradient, optional)
```

---

## Assets to Generate

1. `AppIcon-1024.png` - App Store
2. `AppIcon-60@2x.png` - iPhone
3. `AppIcon-60@3x.png` - iPhone
4. `AppIcon-76@2x.png` - iPad
5. `AppIcon-83.5@2x.png` - iPad Pro
6. `AppIcon-40@2x.png` - Spotlight
7. `AppIcon-40@3x.png` - Spotlight
8. `AppIcon-29@2x.png` - Settings
9. `AppIcon-29@3x.png` - Settings
10. `AppIcon-20@2x.png` - Notification
11. `AppIcon-20@3x.png` - Notification

---

## Mood Reference

- Apple Weather app icon (gradient sphere)
- Lumy app (liquid glass aesthetics)
- iOS 18 style (depth, soft shadows)
- Minimal, no text, instantly recognizable
