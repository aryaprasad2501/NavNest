# NavNest — NavBloom High-Quality Tree Assets Specification

This directory holds individual high-quality graphical assets (sprites / illustrations / 3D renders) for NavBloom tree species and growth stages.

## Asset Architecture & Resolution Specifications

- **Format:** Transparent 32-bit PNG (`.png`) or WebP (`.webp`) with alpha transparency.
- **Recommended Resolution:** `512x512 px` or `1024x1024 px` (square aspect ratio).
- **Anchor Point:** Base of the trunk / roots at bottom-center of the canvas (`x: 50%, y: 92%`).
- **Color Profile:** sRGB.

## Naming Conventions per Species & Stage

NavNest automatically resolves and loads assets matching the following standard naming schema:

### 1. Cherry Blossom (Sakura)
- `cherryBlossom_stage_1.png` — Planted Seed
- `cherryBlossom_stage_2.png` — Sprout
- `cherryBlossom_stage_3.png` — Sapling
- `cherryBlossom_stage_4.png` — Young Tree
- `cherryBlossom_stage_5.png` — Full Bloom

### 2. Mountain Pine
- `mountainPine_stage_1.png`
- `mountainPine_stage_2.png`
- `mountainPine_stage_3.png`
- `mountainPine_stage_4.png`
- `mountainPine_stage_5.png`

### 3. Ancient Oak
- `ancientOak_stage_1.png`
- `ancientOak_stage_2.png`
- `ancientOak_stage_3.png`
- `ancientOak_stage_4.png`
- `ancientOak_stage_5.png`

### 4. River Willow
- `riverWillow_stage_1.png`
- `riverWillow_stage_2.png`
- `riverWillow_stage_3.png`
- `riverWillow_stage_4.png`
- `riverWillow_stage_5.png`

### 5. Golden Ginkgo
- `goldenGinkgo_stage_1.png`
- `goldenGinkgo_stage_2.png`
- `goldenGinkgo_stage_3.png`
- `goldenGinkgo_stage_4.png`
- `goldenGinkgo_stage_5.png`

### 6. Bonsai Juniper
- `bonsaiJuniper_stage_1.png`
- `bonsaiJuniper_stage_2.png`
- `bonsaiJuniper_stage_3.png`
- `bonsaiJuniper_stage_4.png`
- `bonsaiJuniper_stage_5.png`

### 7. Withered Tree (Forest Signature Mechanic)
- `withered_tree.png` — Leafless, crooked trunk with parched earth (used when giving up focus sessions).

## Fallback Mechanism
If an asset file is not yet present in this directory, NavNest automatically renders the procedural multi-layered botanical vector geometry. When an asset file is placed in this directory, NavNest seamlessly detects and displays the high-quality sprite.
