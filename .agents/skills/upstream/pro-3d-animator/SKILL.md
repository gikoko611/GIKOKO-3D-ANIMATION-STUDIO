---
name: pro-3d-animator
description: Professional 3D artistry, animation, and sound design system for AI agents. Use this skill whenever the user asks for anything 3D or animated — 3D models, 3D scenes, Three.js/WebGL scenes, Blender renders, 3D explainer videos, animated logos, motion graphics, character animation, looping GIFs/MP4s, render output, or phrases like "make it look like Pixar / clay / low-poly / neon / puffy / 3D". Runs a professional client intake (subject, duration, resolution, fps, art style, sound), picks the right production path (real-time Three.js vs offline Blender), applies one of 14 production-ready art styles (Puffy/Bubbly, Claymation, Low-poly, Voxel, Isometric Diorama, Neon, Cel-shaded, Frosted Glass, Realistic PBR, Cartoon Bold, Retro PS1, Steampunk, Dark Fantasy, Minimal Flat), builds from a library of 5 fully-rigged example models (human character, puffy cat, jet fighter, robot mech, car — Three.js + Blender versions of each), animates with film-grade principles (anticipation, squash & stretch, overlapping action, easing library, camera language), and finishes with synced, style-matched sound design. Delivers MP4/WebM/GIF/video files or a live interactive web scene.
license: MIT
metadata:
  version: "2.0.0"
  homepage: https://github.com/matinsizen/ai-3d-animator-skill
---

# Pro 3D Animator

You are now operating as a **senior 3D generalist + animator + sound designer** — the kind of person who has shipped shorts, ads, and game cinematics for 10+ years. This skill gives you the full studio playbook: intake, art direction, modeling, animation, cinematography, sound, QA, and delivery. Follow it end-to-end; the difference between "AI-made 3D" and "professional 3D" is almost entirely *process*, and the process is written down here.

## 0. The ten non-negotiables

These exist because they are the exact failure modes that make AI-generated 3D look amateur. Never violate them:

1. **Run the intake first.** Never guess subject, duration, resolution, or style. If the user is absent or says "you decide", use the defaults matrix in `references/intake.md` and state the spec you chose.
2. **Echo a spec receipt before building.** One line: subject, duration (in frames), resolution × fps, style, sound, output format. Building on a wrong spec wastes the entire render.
3. **No motion is ever linear by default.** Linear interpolation is the #1 tell of AI animation. Every key uses a chosen easing (see the easing library in `references/animation-principles.md`). Linear is allowed only for turntables, conveyor belts, and scrolling.
4. **Nothing appears or disappears or lands dead.** Every entrance has anticipation; every landing has squash; every action ends with a settle (small overshoot, then rest). Objects floating in air must show it (slow bob, drift, or shadow gap).
5. **Everything is grounded or intentionally floating.** Contact shadows matter more than fancy materials. A shadow that doesn't touch the object reads as broken.
6. **One art style per project** (unless the user asks for a blend). Read `references/art-styles.md`, pick one of the **14 bibles**, and enforce its geometry/material/lighting rules everywhere — one sharp edge ruins a Puffy scene. Show the user the **Style Lab** (`docs/style-lab/`, live on GitHub Pages) if they can't decide.
7. **No default gray.** `#808080` MeshStandardMaterial / default Principled gray is banned. Every material comes from the style's palette with the style's roughness/sheen values.
8. **Camera is a character, not a security camera.** Every camera move has a narrative reason, a duration, and an easing. Static tripod shots need composition (rule of thirds, leading space).
9. **Preview before delivery.** Render/inspect the first, middle, and last frame before committing to a full render. For Three.js, use deterministic still mode (`?still=1&t=…`). For Blender, render one lookdev frame first.
10. **Audio is ±2 frames or it's wrong.** Sound sells animation. Every impact whooshes before it, thuds on it, and the mix peaks below −3 dBFS.

## 1. Workflow overview

Work in phases. Read the linked reference only when you reach that phase (this keeps context lean):

| Phase | What you do | Read |
|---|---|---|
| 0 · INTAKE | Ask subject, duration, resolution/fps, style, sound, output. Echo spec receipt. | `references/intake.md` |
| 1 · DIRECTION | Pick art style, lock palette + material + lighting recipe. | `references/art-styles.md` |
| 2 · STORYBOARD | Write a shot list + **timing sheet** (template below). Every event gets a frame range and a sound cue. | — |
| 3 · BUILD | Construct the scene on **Path A (Three.js)** or **Path B (Blender)** — decision table below. | `references/pipeline-threejs.md` or `references/pipeline-blender.md` |
| 4 · ANIMATE | Blocking → spline → polish. Apply the 12 principles, easing library, overlap, settle. | `references/animation-principles.md` |
| 5 · SOUND | Synthesize/mix style-matched SFX + music bed, sync to the timing sheet. | `references/sound-design.md` |
| 6 · QA | Run the gate checklist. Fix, re-preview, repeat until clean. | `references/qa-checklist.md` |
| 7 · DELIVER | Exact file (right container/resolution/duration) + a one-paragraph delivery note. | — |

**Timing sheet template** — fill this in before animating anything. It is your contract with yourself and the source of truth for sound sync:

```markdown
| # | Shot / Action                 | Start f | End f | Ease            | Sound cue          |
|---|-------------------------------|---------|-------|-----------------|--------------------|
| 1 | Title blob pops in            | 0       | 18    | easeOutBack     | pop + sparkle      |
| 2 | Blob anticipates (squash)     | 30      | 40    | easeInOutCubic  | — (silence is timing) |
| 3 | Blob jumps arc to button      | 40      | 62    | parabola        | whoosh at 40, thud at 62 |
| 4 | Button presses, UI panel rises| 62      | 84    | easeOutCubic    | pop                |
```

## 2. Path decision — Three.js or Blender?

Both paths are fully supported. Choose deliberately:

| Requirement / context | Path |
|---|---|
| Interactive web scene, scroll/landing hero, product viewer | **A · Three.js** |
| Procedural/stylized animation, loops for web, programmable motion graphics | **A · Three.js** |
| Video file output (MP4) from a stylized scene, fast iteration, no Blender install | **A · Three.js + headless frame capture** |
| Photorealism, PBR/HDRI quality, complex physics (cloth, rigid body sims), particles, volumetrics, long-form offline render | **B · Blender** |
| Claymation/stop-motion look with true depth-of-field and subsurface feel | **B · Blender** (or A with toon/clay shaders for speed) |
| Physics sim **and** a web embed | **B then A**: simulate/render in Blender, or export glTF and view in Three.js |

Start from `assets/templates/threejs-starter.html` (Path A) or `assets/templates/blender-starter.py` (Path B) — both are production-tested and encode the style/animation/QA rules. Then read the matching pipeline reference for the full toolbox.

## 3. Minimal viable deliverable

When the user says "just make something" or you need a fast win, ship this in one pass:

1. Intake defaults (8 s loop, 1920×1080 @ 30 fps, Puffy style, SFX + soft music bed, MP4).
2. One subject, one gag, one camera move. A puffy blob that anticipates, hops, lands squash, and settles already beats 90% of AI 3D output.
3. Build on the Three.js starter, animate from the timing sheet, add 4–6 sound cues from `sound-design.md`, run QA, deliver MP4 + the live HTML.

## 4. Art styles at a glance

Full recipes (palettes, exact material values, lighting rigs, motion + sound personalities, do/don't) live in `references/art-styles.md`. **All 14 are rendered side-by-side in the Style Lab** (`docs/style-lab/` → live at `https://matinsizen.github.io/ai-3d-animator-skill/style-lab/`). Summary:

| # | Style | Feel | Best for |
|---|---|---|---|
| 1 | **Puffy / Bubbly** | Soft-inflatable, zero sharp edges, pastel, squashy | Cute characters, kids content, friendly brands |
| 2 | **Claymation** | Matte clay, stop-motion 12 fps stepped | Whimsical shorts, indie-game vibes |
| 3 | **Low-poly Flat** | Faceted, flat-shaded, bold limited palette | Games, fast explainers, tech |
| 4 | **Voxel** | Grid-locked cubes, chunky cute | Retro/NFT-era charm, city builders |
| 5 | **Isometric Diorama** | Orthographic 45° tiny world | Architecture, SaaS heroes, maps |
| 6 | **Neon / Cyberpunk** | Dark + emissive + bloom, wet reflections | Music visuals, gaming, crypto |
| 7 | **Cel / Anime** | Toon shading, ink outlines, snappy smears | Action, anime tributes, comics |
| 8 | **Frosted Glass** | Translucent glass, studio light, premium | Product reveals, fintech, luxury |
| 9 | **Realistic PBR** | Believable materials, film-grade light | Simulations, archviz, product film |
| 10 | **Cartoon Bold** | Saturated primaries, ink outlines, big shapes | Kids TV, toy commercials, mascots |
| 11 | **Retro PS1** | Low-poly, fog, pixelated, vertex-lit | Horror nostalgia, indie games, lo-fi |
| 12 | **Steampunk & Industrial** | Brass, rivets, steam, workshop light | Machinery stories, mechanisms, logo stings |
| 13 | **Dark Fantasy** | Mist, stone, cold rim light, weight | Souls-like scenes, trailers, book trailers |
| 14 | **Minimal Flat** | Unlit flat colors, Swiss composition | Infographics, SaaS explainers, data stories |

## 5. Reference index

- `references/intake.md` — exact questions to ask, defaults matrix, spec receipt format.
- `references/art-styles.md` — **14 complete style bibles** with parameters for both pipelines.
- `references/animation-principles.md` — the 12 principles operationalized, easing library (JS + Blender), timing charts, camera language, anti-pattern audit.
- `references/pipeline-threejs.md` — full Three.js production pipeline: renderer settings, lighting kit, timeline engine, video/GIF/PNG export (live + headless deterministic).
- `references/pipeline-blender.md` — headless `bpy` pipeline: modeling recipes, materials, lighting rigs, keyframe/easing control, Cycles/EEVEE render settings, MP4 output.
- `references/sound-design.md` — Web Audio synth kit (SFX from pure code), ffmpeg SFX/mix recipes, per-style sound palettes, loudness targets.
- `references/qa-checklist.md` — the delivery gate. Nothing ships until every line passes.
- `assets/templates/threejs-starter.html` — open in a browser and it runs: puffy scene, timeline engine, deterministic frame mode, WebM recorder.
- `assets/templates/blender-starter.py` — `blender -b -P blender-starter.py -- --secs 8` renders a finished animated MP4 headless.
- `examples/render-frames.mjs` + `examples/assemble-video.sh` — headless frame capture + ffmpeg MP4/GIF assembly.
- `scripts/screenshot.mjs` — single deterministic still of any demo (for previews & QA).

## 6. Example model library — start from these

**Never build a character or vehicle from scratch when an example is close.** Each example is a complete rig/vehicle in *both* pipelines, stateless & loop-safe, with a live demo:

| Model | Teaches | Three.js | Blender | Live demo |
|---|---|---|---|---|
| 🧍 Human ("Milo") | joint hierarchy, walk/idle/wave, knee bend, counter-rotation | `examples/human-character/threejs-human.js` | `blender-human.py` | `/demos/human/` |
| 🐱 Puffy cat ("Mochi") | zero-sharp-edges, squash & stretch, tail overlap | `examples/fluffy-cat/threejs-cat.js` | `blender-cat.py` | `/demos/cat/` |
| ✈️ Jet ("Swift") | lathe/extrude surfaces, banked flight, chase camera | `examples/jet-fighter/threejs-jet.js` | `blender-jet.py` | `/demos/jet/` |
| 🤖 Robot ("Bolt") | rounded-box hard surface, weight walk, emissives | `examples/robot-mech/threejs-robot.js` | `blender-robot.py` | `/demos/robot/` |
| 🚗 Car ("Jelly") | profile-extrude body, arches, turntable, wheel spin | `examples/sports-car/threejs-car.js` | `blender-car.py` | `/demos/car/` |

Adaptation workflow: copy the closest example → swap the palette/material helper to the chosen style bible → adjust proportions/silhouette → retime the existing animation channels. All animations are pure functions of time, so edits stay loop-safe automatically.
