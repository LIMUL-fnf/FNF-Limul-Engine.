# Changelog

All notable changes to FNF Limul Engine are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.1] - 2026-11-22

Mobile/tablet release. Desktop builds keep the same save format and include the V-Sync and crash
fixes that never shipped in a public build before.

### Added
- Android (arm64) target: landscape phones and tablets with V-Slice-style touch controls - tap and
  hold anywhere on the four note lanes, plus an on-screen pause button.
- On-screen menu navigation pad (left/down/up/right, back, accept) so every keyboard-driven menu
  works on touch screens.
- Touch Controls toggle in Options → Gameplay (on by default; desktop builds ignore it).
- `buildAndroid` CI job that compiles, signs and uploads the release APK.
- Custom Lime boot template that applies the V-Sync option before the window is created.

### Changed
- Engine version is now 1.0.1 in the main menu, `project.xml` and README.
- Mobile builds ship arm64 only; mods, Lua and video cutscenes stay desktop-only (same
  `project.xml` gates as before). Shaders keep loading from `assets/shaders/` on all platforms.
- Main menu version text sits above the touch controls on mobile layouts.

### Fixed
- The V-Sync option was saved but never applied (Lime only reads it when the window is created);
  the custom boot template now applies it at startup.
- Crashing when an input press hit a strum with no animation assigned.
- Android compilation of the mod shader lookup, mod chart finder and Freeplay BPM preview
  (`MODS_ALLOWED` code paths that previously assumed a desktop target).

## [1.0.0] - 2026-11-17

First Limul Engine release. Base: Psych Engine 0.6.3, with code and behaviour backported from
Psych Engine 1.0.4 and features inspired by FPS Plus, Codename Engine, Forever Engine and JS Engine.

### Added
- Hybrid engine tree: Psych 0.6.3 base + Psych 1.0.4 backports + V-Slice (Funkin' 0.8.x) support.
- V-Slice Freeplay screen: album cards, star ratings, ranks, letter filter and per-week styles.
- FPS Plus inspired options: FPS counter with GC memory readout, Background Dim, camera bop,
  combo-break display and simplified popups.
- Codename Engine inspired advanced FPS counter (F3): draw/update FPS, state, song, difficulty,
  BPM, step and stage.
- Forever Engine inspired global note skins and note splash skins.
- Psych 1.0.4 inspired style options: score, time bar, health bar, watermark, botplay text,
  strum-lit and health icon styles; smooth health; rating types; MS counter; opponent note
  alpha and splashes; crossfade modes and limits.
- Note load controls: `maxNotesOnScreen`, `maxNoteSplashesPerSecond`, dynamic spawn time.
- JS Engine inspired Game Renderer settings: target FPS, FPS unlock, bitrate, encoder, quality
  and lossless mode.
- Psych 1.0.x / V-Slice chart auto-conversion at load time (`Song.convertFromPsychV1`).
- Linux and macOS build targets (Lime `linux` / `mac`) with CI jobs for all three desktop platforms.
- Credits screen entries for the FPS Plus, Codename Engine and Forever Engine teams.
- `example_mods/` skeleton mod and `modsList.txt`-based mod loading.
- Portable Haxe 4.3.7 toolchain with pinned haxelibs in `_tools/` for static typechecks.

### Changed
- Freeplay uses the V-Slice layout exclusively; the legacy Freeplay fallback was removed.
- Video playback stays Windows/web-only (hxCodec 2.5.1 has no Linux/macOS native binaries);
  Linux and macOS builds use the screenshot game renderer instead of ffmpeg capture.
- FPS counter refresh throttled to ~20 Hz instead of every frame.
- Sprite-atlas loading is memoized and path lookups are cached (`Paths`).
- Health icon file-name resolution and Freeplay icon lookups cached per week folder.
- All engine-side changes target `source/`; generated/export files are never hand-edited.

### Fixed
- Health icons with N-frame sheets (2 or 3 frames) no longer sliced as hardcoded 2-frame strips.
- Credits rows without shipped icon art fall back to text instead of loading a missing image.
- Crash dumps resolve next to the executable with a working-directory fallback, so macOS/Linux
  launches from Finder or desktop launchers still produce a log; a failed write never throws.

### Performance
- Gameplay note walks in `PlayState.update()` and `keyShit()` no longer allocate closures;
  the hold-note scan is skipped entirely when the chart has no player sustains and no Lua scripts.
- `parseKeys()` reuses boolean buffers and cached control field names.
- Crossfade and limo stage particle cleanup use indexed loops instead of `forEach` closures.
- `MusicBeatState` writes the fullscreen flag to save data only when it actually changes.
- FPS counter keeps a 1 s frame window with a read cursor and periodic compaction instead of an
  `Array.shift()` (O(n) memmove) on every frame.
- Freeplay caches song keys, ranks and the selected row's rating; BPM digits use a lookup table
  instead of `Math.pow`; row lerp/clip values are hoisted out of the per-row loop.
- Story mode rewrites the week score only when it changes and walks lock icons without closures.
- Main menu re-centers entries only when the window width changes.
- `IconBounce` reuses shared scale arrays instead of allocating per beat.
- Incremental GC cadence (minor/major) and memory checks in `Main`.
