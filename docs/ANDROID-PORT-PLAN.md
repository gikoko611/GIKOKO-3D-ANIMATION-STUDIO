# AniCraft Android Port Plan

## Constraints
- Android 10 / API 29 minimum; ARMv7 armeabi-v7a is required.
- Native Android interface; no WebView wrapper.
- Offline-first local editing, project storage, preview and export.
- Network only for optional updates or explicitly remote services.

## Milestones
1. Native Android foundation: drawing surface, touch input, frame list, undo, local draft save and PNG export.
2. Editing model: normalized canvas coordinates, layers, frame duration/FPS, onion-skin preview, selection and transforms.
3. Portable engine audit: separate AniCraft platform-independent geometry/document/command/render crates from desktop-only eframe, rfd, OS audio and GPU integrations.
4. Android engine bridge: build only audited portable Rust crates for armv7-linux-androideabi; expose a narrow JNI interface; keep Android UI in Kotlin.
5. Format and export parity: project import/export, PNG sequence, GIF/APNG/WebP where selected portable crates pass Android tests.
6. Compatibility and performance: low-memory safeguards, bounded undo history, background rendering, Android 10 device verification, signed release build.

## Not claimed in the first APK
XFL/FLA compatibility, plugin runtime, advanced text/font handling, audio playback, GPU rendering and all desktop panels require separate porting and validation.

## Acceptance checks
- APK targets Android 10+ and contains ARMv7 native libraries when required.
- Installs on Redmi 9A class devices.
- Drawing, frame navigation, save and PNG export work without network.
- No WebView is used.
