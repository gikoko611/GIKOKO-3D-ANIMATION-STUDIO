# G.I KO KO 3D ANIMATION STUDIO

Unity 6 migration branch for a phone-first 3D creation and animation studio.

## Target device
- Android 10+
- ARMv7 (32-bit) APK
- OpenGL ES compatibility target
- Low-memory mobile preview profile

## Current Unity 6 foundation
- Unity 6000.0.64f1 project scaffold
- Runtime 3D preview with cube, sphere and capsule primitives
- Basic rotate and scale controls
- Local JSON project save
- Android ARMv7 + IL2CPP build configuration
- GitHub Actions build workflow

## Build requirements
This repository uses GitHub Actions; no Android SDK, JDK or Unity Editor installation is required on the phone.

A Unity Personal license is required by the CI build. Run the Unity Personal License Activation File workflow, download its artifact, submit the .alf file at https://license.unity.com/manual, then add the returned license file contents as the repository Actions secret named UNITY_LICENSE. Do not commit license files or passwords.

After setting the secret, run Unity 6 Android ARMv7 APK. The workflow uploads the APK as an artifact.

## Planned modules
1. GLB/GLTF import and export
2. Myanmar 3D asset library
3. PBR material editor
4. Offline background removal model
5. Mesh cleanup and polygon reduction
6. Character skeleton and bone editor
7. Pose and keyframe animation timeline
8. Anime storyboard, audio, subtitles and scene renderer

These modules are roadmap items, not implemented in this foundation build. Advanced rendering and AI generation must be staged carefully for Redmi 9A performance.

Powered By အိုင်ကိုကို
