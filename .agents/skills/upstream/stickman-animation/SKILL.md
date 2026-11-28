---
name: stickman-animation
description: >
  Make a code-drawn 2D/3D stickman/stick-figure animation (explainer,
  story short, gag, or "what if" clip) from a script or idea, as a seekable HTML
  file plus 30 FPS MP4/GIF exports. Includes 2-bone IK character rigging (rig.js),
  camera grammar (camera.js), non-linear easing (easing.js), toon effects (effects.js),
  and short-form audience retention rules.
license: MIT
---

# Stickman Animation Skill (`animation-skill-main`)

Generate deterministic, studio-grade 2D/3D stick-figure animations (`1080×1920` vertical 9:16 at `30.0 FPS`). Renders via HTML5 Canvas + WebGL2 / Three.js with zero bundle step, captures deterministic frames via headless Chromium (`window.seekToFrame(f)`), and stitches to MP4 using `ffmpeg`.

## The 10-Step Production Pipeline

1. **Interpret & Infer Parameters**: `1080×1920` (9:16 vertical), `30.0 FPS`, deterministic frame seeking.
2. **Beat Sheet & Short-Form Retention Formula**:
   - **Hook (`0–3s`)**: Immediate visual action + paradox stated as fact.
   - **Setup & Escalation**: Visual change or camera reframe every `1.5–2.5s` (A-B-A-C shot alternation).
   - **The Turn / Science**: 5 distinct, non-repeating physical cutaway or analogy demonstrations (never repeat the same diagram twice).
   - **Climax & Payoff**: Emotional/ironic reversal and grand crane pull-back.
3. **Decompose into Shots (`story.json` / `timeline.js`)**: Every shot defines camera `pos`, `look`, `fov`, `focusDist`, `dofStrength`, and actor poses.
4. **Assemble Assets (`library/js/rig.js`)**:
   - **Hard Rule**: Always use straight 2-bone articulated stick limbs (`solveIK([shoulder, elbow, hand])` and `solveIK([hip, knee, foot])`) — never curved noodle arms.
   - **Planted Cycloid Locomotion**: Stance foot remains locked to the 3D ground coordinate while the swing foot follows a world-space cycloid arc (`zero foot skating`).
   - **3-Phase Painting Kinematics**: (1) Dip brush into 3D chrome bucket (`0.00..0.16`), (2) Linear vertical up-stroke along the 3D girder (`0.16..0.58`), (3) Linear vertical down-stroke (`0.58..1.00`) with wrist rotation and bristle splay reversal.
5. **Render Storyboard Keyframes (`scripts/capture_frames.mjs`)**.
6. **Self-Check Storyboard (`references/11-ship-gates.md`)**: Silhouette readability, rule-of-thirds eye placement, unobstructed sightlines.
7. **Animate with Non-Linear Easing (`library/js/easing.js`)**: Symmetric `smootherstep` (`glide`) for camera moves, `power2Out` for decelerations, 7-frame sign-flipping impact kicks for slams/snaps.
8. **Capture Frames & Stitch (`scripts/stitch.mjs`)**: True 30.0 FPS un-quantized capture (zero stuck or frozen frames).
9. **Final QA on Contact Sheet (`scripts/contact_sheet.py`)**.
10. **Deliver**: Seekable `.html` studio player + `1080×1920` H.264 `.mp4`.
