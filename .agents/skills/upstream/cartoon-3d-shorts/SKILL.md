---
name: cartoon-3d-short
description: Make a ~55-70 s vertical cartoon story short in the "2D characters in a colourful, realistic 3D world" style (flat bean-head cartoon cards with plum ink outlines, straight 2-bone IK limbs, realistic 3D architectural world with constant-width black ink lines, high-chroma sun-kissed lighting, S-curve contrast + split-toned colour grade, bokeh depth-of-field backgrounds, continuous gliding cameras, and 5-beat physical cutaway demonstrations), rendered with three.js / WebGL2 inside Remotion.
---

# Cartoon 3D Story Short (Three.js / WebGL2 + Remotion — Upgraded Lighting, Contrast, Saturation & Realistic 3D World Building)

## Upgraded Production Look Values (Lighting, Contrast, Color Saturation & Realistic 3D World Building)

1. **High-Chroma Sun-Kissed Lighting & Stylized Shadows (`lights.ts` + `shade.ts`)**:
   - **Day (`LIGHTS.day`)**: Camera-relative sun (`az: 75°`, `el: 48°`), warm golden-white key `lit: [1.58, 1.50, 1.33]`, saturated cobalt-slate shade `shade: [0.48, 0.47, 0.58]`, cool shadow lift `lift: [0.04, 0.05, 0.10]`, world albedo saturation boost `uSat: 1.26`, Blinn-Phong metallic specular highlight (`pow(ndh, 20.0) * specK`), and golden rim bounce (`pow(1.0 - dot(N, V), 2.6)`). Sky gradient: `#3373cc` zenith -> `#4f8cdb` -> `#6a9fe0` -> `#9cbfea` -> `#b8d0ec` horizon.
   - **Storm / Winter (`LIGHTS.storm`)**: Overcast slate-blue key `lit: [0.95, 1.00, 1.08]`, deep steel-blue shade `shade: [0.42, 0.48, 0.64]`, horizon fog `#adc0d6` (`28 -> 240 m`), slanting rain + `fxSplash` water crowns.
   - **Golden Hour (`LIGHTS.golden`)**: Backlit low sun (`az: 6°`, `el: 7°`), blazing amber key `lit: [1.52, 0.82, 0.36]`, stylized violet-blue shadows (`shade: [0.28, 0.27, 0.52]`, facade `#444380`), warm horizon `#ffd08a` -> `#f7ae78` -> `#e8967c` -> `#8a6f8a` zenith, sun disc `#ffcf9e` + exponential crepuscular bloom.

2. **High-Contrast S-Curve & 1.26x–1.40x Color Saturation Grade (`grade.ts`)**:
   - Monotone cubic Hermite 7-knot tone curves (`GRADE_DAY2`, `GRADE_GOLDEN2`, `GRADE_STORM`) paired with a display-referred S-curve (`mix(col, col*col*(3.0 - 2.0*col), 0.24)`), Rec.709 luminance-preserving saturation boost (`1.26x` day, `1.34x` golden hour), 3-way shadow/mid/highlight split-toning, and elliptical vignette (`vig: [0.14, 0.45]`).

3. **Realistic 3D Architectural & Structural World Building (`build.ts` + `world.ts` + `paint.ts`)**:
   - **No Congestion or Floating Random Props**: Every background is purpose-built with clear sightlines (`sightLines()` culler in `build.ts`) and open architectural framing.
   - **True Blueprint Structural Geometry**: Multi-tier lattice bays with double St. Andrew's X-bracing, K-trusses, gusset plates, real inclined switchback staircases inside piers (with individual horizontal step treads, risers, twin steel channel stringers, and brass handrails), and inclined double-deck hydraulic elevator tracks.
   - **Open Observation Galleries**: Platform decks use open arched colonnades, overhead lattice spandrels, and waist-high baluster guardrails (never solid walls blocking the camera), so the 3D city skyline, river, bridges, and volumetric multi-lobe 3D trees remain visible in soft bokeh Depth-of-Field behind the characters.

4. **2-Pass FBO Post-Processing (`ink.ts` + `lensblur.ts` + `Bridge.tsx`)**:
   - **Pass 1**: Renders world geometry into MRT attachments (`COLOR_ATTACHMENT0` = Two-Tone Lit Color + CoC; `COLOR_ATTACHMENT1` = View-Space Normal + Linear Depth). Character cards and effect sprites live on layer `NOINK`.
   - **Pass 2**: Computes constant-screen-width `#030303` black ink outlines (`widthNear: 5.1 px` at `6 m` -> `widthFar: 3.3 px` at `90 m`) from signed 2nd-difference depth jumps (`depthLo: 0.01`) and normal creases (`angleLo: 35°`), then blurs the background and its ink lines together via Golden-Angle Vogel-disk thin-lens Depth-of-Field (`cInf: 12–16 px` on CU/MS, `0 px` on wides).

5. **Stickman Character Rig & Full-Stage Physical Cutaway Demonstrations (`toon.ts` + `cast.ts` + `story.ts`)**:
   - Bean heads (`H/W = 0.94`, superellipse crown `1.75` / jaw `2.3`, radial `shadedFill` crescent, variable-width `#241726` `inkRing`), straight 2-bone IK stick arms and legs (`solveIK([shoulder, elbow, hand])` — never curved noodle arms!), planted cycloid walk cycle (zero foot sliding), 3-phase linear girder painting cycle, and shaped 4-frame blinks every `1.45 s`.
   - Scientific explanations use distinct, full-frame physical cutaway and analogy scenes (`drawMacroBrushPainting`, `drawVisual1_ParchmentWarningScroll`, `drawVisual2_MicroScratchCanyonZoom`, `drawVisual3_SubsurfaceXRayScanner`, `drawVisual4_ScraperFractureReveal`, `drawScientificCutaway3D`) with zero repeated diagrams and zero floating sci-fi HUD boxes.
