# Audio, Post-production and Delivery QA

## Audio plan
For every scene list dialogue, ambience, Foley, spot effects and music cues separately. Use original or properly licensed audio. Keep dialogue intelligible and duck music beneath speech.

## Voice and dialogue
Give each character a stable voice ID and pronunciation guide. Record language, accent preference, emotion, pace and delivery. Align narration and dialogue to storyboard timing. Check current TTS/API pricing and limits before use; never hard-code API keys into source or workflow files.

## Sound design
Use sound to clarify who moved, what collided and where. Use silence and room tone intentionally. Avoid clipping, leave headroom and keep music, dialogue and effects separate until final mix.

## FFmpeg finishing
1. Concatenate rendered scene clips in storyboard order.
2. Add narration, dialogue, ambience, music and effects.
3. Burn or mux subtitles according to delivery requirements.
4. Scale/crop to requested aspect ratio and dimensions.
5. Encode H.264 video and AAC audio with explicit bitrate, pixel format and frame rate.
6. Probe the final file and record metadata.

## Final QA
- MP4 exists and is non-empty.
- Video stream, codec, dimensions, FPS and duration match the brief.
- Audio stream exists when requested; no clipping or silent dialogue.
- Subtitles are synchronized and Myanmar Unicode glyphs render correctly.
- No missing assets, black frames, flicker, broken rigs or unintended camera jumps.
- Character identity, costume, palette and screen direction remain consistent.
- File size meets the requested limit.
- Preview/contact sheet and render log are available.
- GitHub Actions artifact exists and its URL is reported accurately.

## Delivery bundle
Provide MP4, storyboard, scene manifest, character bible, preview/contact sheet and render log as workflow artifacts. Keep large outputs out of the repository. Report exact output specs and known limitations.
