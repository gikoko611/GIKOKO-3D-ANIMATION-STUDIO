# G.I KO KO 3D ANIMATION STUDIO

A phone-first 3D asset studio prototype for Android 10+ (ARMv7).

## Current build scope
- 3D viewport with orbit camera and sample primitives
- Add basic mesh objects (box, sphere, capsule)
- Import GLB/GLTF and OBJ assets from device storage
- Export GLB assets
- Simple project save/load as JSON
- Free AI Image-to-3D workflow links (generation is performed by external hosted demos; no paid API key is embedded)
- GitHub Actions Android APK build

## Important free-AI note
The app does not run large image-to-3D models on the Redmi 9A. Open models such as [TripoSR](https://github.com/VAST-AI-Research/TripoSR) can be used through a hosted demo or a separately managed GPU machine. Hosted free demos may have queues, limits, or change availability. The app provides an import workflow for generated GLB/OBJ files; it does not claim unlimited free cloud generation.

## Build
Push to `main` or run the **Android APK** workflow manually. Download the APK from the workflow artifact.

Target: Android 10+, armeabi-v7a (32-bit). The build uses Godot 4 and GitHub Actions.

## Roadmap
Rigging, timeline animation, multi-view reconstruction, texture editing, and video rendering are planned stages, not yet implemented in this initial prototype.

Powered By အိုင်ကိုကို
