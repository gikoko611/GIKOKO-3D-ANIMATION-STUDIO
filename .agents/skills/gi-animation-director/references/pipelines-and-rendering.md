# Production Pipelines and Rendering

Choose the simplest pipeline that meets the brief. Keep rendering deterministic and process one scene at a time.

## A — Lightweight 2D
Generate SVG, Canvas or Pillow frames with reusable character rigs and layered backgrounds. Render numbered frames or short clips. Assemble narration, music and subtitles with FFmpeg.

## B — Browser 3D with Three.js
Use Three.js for procedural geometry, materials, lights, camera and time-based animation. Reuse GLB/GLTF assets. Prefer instancing, low-poly meshes, texture atlases and level-of-detail. Capture deterministic frames in a browser; Playwright may automate capture on hosted runners.

## C — Blender headless
Use Blender Python (bpy) to create/import meshes, rigs, materials, lights, cameras and keyframes. Run headless on GitHub Actions or a suitable workstation. Use FFmpeg for final muxing, subtitles and compression.

## D — Stickman / procedural 2D
Define a joint graph and pose keyframes. Interpolate joints with easing; calculate limbs from joint coordinates rather than guessed line endpoints. Add IK for planted feet and reaching hands. Render with SVG, Canvas or Pillow.

## E — Motion Canvas / Remotion / GSAP
Use Motion Canvas for code-authored explanatory scenes, Remotion for React-based video composition and GSAP for browser timelines. Pin package versions and test browser dependencies on the hosted runner.

## F — External generative video
Use only when the user explicitly selects a provider and approves model, duration, resolution and credit/cost usage. Free tiers can be rate-limited or discontinued. A coding skill does not itself generate AI video.

## Redmi 9A execution policy
The target phone is Android 10 with ARMv7/32-bit userspace and limited RAM. Use it for prompts, code editing, lightweight SVG/Canvas previews and job dispatch. Run heavy Blender rendering, browser capture and long encodes on GitHub Actions hosted runners. Do not assume CUDA, desktop GPU features, ARM64-only binaries or local Blender availability.

## Render budget
- Render a short low-resolution proof first.
- Render scene-by-scene; do not buffer a full film in memory.
- Use image sequences for recoverable long renders.
- Set FPS, dimensions, duration and bitrate explicitly.
- Approximate total bitrate in kb/s as target MB × 8192 ÷ duration seconds; reserve some bitrate for audio.
- Prefer H.264 MP4 with yuv420p for broad playback compatibility.
- Keep generated videos and large intermediates out of Git history; upload them as Actions artifacts.

## Current repository capability note
The current workflow installs FFmpeg and Pillow and calls animation_pipeline/render_2d.py. Its style input does not yet select separate Blender, Three.js or stickman renderers. Treat those pipelines as production guidance until matching code and CI tests exist. Never claim a renderer is implemented merely because this skill describes it.
