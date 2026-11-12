# AniCraft Studio for Android

Native Android-first 2D drawing and frame-animation project targeting Android 10+ and ARMv7 (armeabi-v7a). This is not a WebView wrapper.

## Current native MVP
- Native Android drawing surface with touch input
- Brush colors, eraser, undo and clear
- Multi-frame timeline (add/select frames)
- Save a draft project to app-private storage
- Export the current frame as a 1080x1080 PNG to Pictures/AniCraft
- Core editing works offline; no account or API key required

## AniCraft upstream integration
The upstream AniCraft application is a Rust/egui desktop app. Its existing workspace is not currently an Android-native UI or a drop-in Android library. This repository separates the native Android interface from the future portable-engine integration. The original source and its MIT/Apache-2.0 notices must be retained when portable crates are vendored or adapted. Feature parity with desktop AniCraft is not claimed in this starter milestone.

## Build
GitHub Actions builds a debug APK for ARMv7. Download the AniCraft-Android-ARMv7 artifact from the workflow run.

Target: Android 10 (API 29) and later. Native UI and local drawing/export are offline-first.

Powered By အိုင်ကိုကို
