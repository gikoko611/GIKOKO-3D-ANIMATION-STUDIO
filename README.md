# G.I KO KO 3D ANIMATION STUDIO

Unity 6 phone-first 3D modeling and animation-film workspace.

## Device target
- Android 10+
- ARMv7 (32-bit) APK for Redmi 9A / Helio G25 class devices
- IL2CPP, Gamma color space, low-memory 30 FPS preview
- GitHub Actions build; no local Android SDK, JDK or Unity Editor required on the phone

## Implemented foundation in this branch
- Sculpt workspace retained: Standard, Clay, Smooth, Inflate, Move, Flatten, Crease and Mask brush prototypes
- Primitive sculpt bases and local sculpt JSON save
- Film Maker tabs: Scene, Character, Timeline and Export
- Procedural Myanmar scene blockouts: ground, teak-style house, pagoda, tree and road
- Procedural humanoid blockout and basic Idle / Walk / Run / Talk / Fight motion previews
- 5-minute / 10-minute project-duration selection and short interactive motion preview
- Local film-project JSON save
- Unity 6 Android ARMv7 IL2CPP build configuration and launcher icon assignment

## Important implementation boundary
The Film Maker tab is an early runtime foundation, not yet a complete production animation editor. Character blockouts are procedural primitives, motion clips are simple transform animation, and the timeline currently previews a short loop while storing the selected target film duration. The Export tab is a render-plan/status screen only: **runtime MP4 encoding, audio mixing, subtitles, real GLB/GLTF import/export, skeletal retargeting, keyframe editing, scene sequencing, and resumable frame rendering are not implemented yet**. Do not treat the 5/10-minute selector as proof that a 5/10-minute MP4 can already be exported.

## Planned next stages
1. Real GLB/GLTF asset pipeline and Myanmar asset library
2. Proper character skeletons, skinning, retargeting and editable keyframes
3. Multi-scene storyboard, camera tracks and timeline sequencing
4. Dialogue, voice-over, music, SFX and subtitle tracks
5. Chunked runtime render queue with pause/resume and memory-aware frame scheduling
6. Android MediaCodec / FFmpeg-based MP4 encoding and final audio/video mux
7. Optional free-cloud rendering and AI-assisted story/voice workflows

## GitHub Actions build
The repository uses Unity 6 version `6000.0.64f1` and GameCI. A Unity Personal license is required by the CI build. Run the Unity Personal License Activation File workflow, download its artifact, submit the `.alf` file at https://license.unity.com/manual, then add the returned license file contents as the repository Actions secret named `UNITY_LICENSE`. Never commit license files or passwords.

After adding the secret, run **Unity 6 Android ARMv7 APK**. The workflow should upload `GI-KO-KO-3D-ANIMATION-STUDIO-ARMv7.apk` as an artifact if compilation and packaging succeed.

Powered By အိုင်ကိုကို
