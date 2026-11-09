# G.I KO KO 3D ANIMATION STUDIO

Phone-first 3D modeling, sculpting and animation-film workspace powered by **Godot 4**.

## Target device
- Redmi 9A / Helio G25 class Android phones
- Android 10+
- ARMv7 (32-bit) APK as the required compatibility target
- Godot Compatibility renderer (OpenGL ES 3)
- Low-memory UI and 30 FPS preview target
- GitHub Actions builds; no local PC, Unity Hub, Unity license, Android SDK or JDK installation required on the phone

## Current Godot foundation
- Cyber green / blue / gold studio shell
- 3D viewport and primitive Box / Sphere / Capsule creation
- Sculpt sphere with touch raycast and prototype Standard / Clay / Smooth / Inflate / Move / Flatten / Crease / Mask brush selector
- Adjustable sculpt brush radius and strength; vertex deformation prototype for the sculpt sphere
- GLB / GLTF import and GLB export foundation
- Object focus, rotate, scale, duplicate, delete and reset-transform controls
- Local JSON project save/load for supported primitive and sculpt-sphere object transforms, plus camera-marker and subtitle-cue metadata
- Film Maker starter tools: timeline camera-marker capture, subtitle cue entry and SubRip (SRT) export
- Android ARMv7 export preset
- GitHub Actions workflow on the `godot-migration` branch

## Migration status — important
The current Godot app is a **starter foundation**, not yet feature-complete. A basic transform-keyframe timeline (position, rotation and scale) is now included; character rigging, skeletal animation and IK are not implemented. Sculpting currently edits a low-resolution sphere mesh using a simple radial brush prototype; it does not yet include production remeshing, subdivision, functional vertex masks, brush-stroke interpolation, or persistence of sculpted vertex data. Basic undo/redo history is available during the current session only. The earlier Unity branch contains prototypes for sculpt brushes, a procedural character/scene film-maker, Android TTS, synthetic sound effects and subtitle controls. Those Unity C# features are not automatically portable to Godot and are not yet all implemented in this Godot branch. Keep the Unity branch intact as a reference until each corresponding Godot feature has been rebuilt and checked.

## Full feature roadmap
1. **Sculpt Studio:** Standard, Clay, Smooth, Inflate, Move, Flatten, Crease and Mask brushes; brush size/strength; undo/redo; save/load; subdivision and remesh research.
2. **3D asset pipeline:** GLB/GLTF import/export, material editing, asset library and safe model selection.
3. **Character Studio:** humanoid skeleton, skinning, IK, retargeting and editable animation clips.
4. **Film Maker:** Myanmar scene assets, multi-scene storyboard, camera-marker playback/tracks, full timeline editing and preview. Current camera markers are captured and saved, but not yet interpolated or played back.
5. **Audio & subtitles:** Myanmar/English dialogue, device TTS integration where supported, voice-over, music/SFX tracks and timed subtitle editing. Basic subtitle cues and SRT export are implemented; audio mixing and TTS are not yet implemented.
6. **Video output:** memory-aware frame queue, pause/resume, 480p/720p presets, Android encoder integration and audio/video muxing. MP4 export is not implemented yet.
7. **AI assistance:** optional external image/model/voice providers; API keys remain user-supplied and are never committed.

## Build
Open **Actions → Godot Android ARMv7 APK → Run workflow** on the `godot-migration` branch, or push a change to that branch. The workflow validates the Godot project, exports the Android preset, checks for an ARMv7 native library, and uploads the APK artifact if all steps pass.

The workflow uses a pinned Godot CI container and does not require a Unity license secret. A successful workflow is still required before claiming that an installable APK is ready.

## Compatibility notes
- The project is configured for ARMv7 only to meet the Redmi 9A requirement.
- Google Play distribution generally requires a 64-bit variant as well; this ARMv7 build is intended for direct testing on the specified 32-bit device.
- Godot's Android editor is experimental and touch UI is not fully optimized. Building through GitHub Actions avoids requiring the editor on the phone.
- Heavy sculpt meshes and long video renders must be optimized carefully for the Redmi 9A's limited memory.

Powered By အိုင်ကိုကို
