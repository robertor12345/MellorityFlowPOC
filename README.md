# Mellority Flow POC

**iPhone demo** of a simplified Mellority journey: open the app → **Start Session** (no login) → optional sign-in → **optional integration slides** (after a successful sign-in, with per-feature **Connect** / **Skip** and **Skip all**) → **Camera** or **Quick Start** → **mood** → fast session load (**under ~5s**) with subtle AI lines → **immersive** space with real-time adaptation → **insight** (simple, visual) → **unlock deeper features** (health sync, IoT, personalisation, snippets + memory, “replay your calm”).

- **Brand:** cream / chocolate brown / gold (`BrandTheme`), aligned with Mellority logo asset. Typography: **SF** with **rounded** design app-wide for a simple modern look.
- **Integrations:** All **simulated** except **Camera** and **photo library** (real pickers when you grant permission). Optional sign-in is mock.

## Run

```bash
cd MellorityFlowPOC
xcodegen generate
open MellorityFlowPOC.xcodeproj
```

Set your **Development Team**, pick an **iPhone**, build and run.

## Flow map

| Step | Screen |
|------|--------|
| 1 | **Home** — “Start Session”; **Sign in (optional)** in a sheet |
| 1b | **Post–sign-in slides** (only if user continues sign-in) — Health, **IoT** (Philips Hue stock image from Wikimedia Commons, CC BY 2.0), personalisation, snippets + memory, replay; mock **Connect** / **Skip**; **Skip all** or **Continue** to home |
| 2 | **Entry mode** — **Camera** (photo) or **Quick Start** (skip to mood) |
| 3 | **Mood select** |
| 4 | **Starting session** — progress + rotating subtle AI lines (&lt; ~5s) |
| 5 | **Immersive** — **royalty-free nature video** (Mixkit) + **meditation-style** audio, mock HR; collapsed **Session options** menu (home lights sync · share to social); **End session** → insight |
| 6 | **Insight** — minimal visual calm ring + mood; **Replay your calm** teaser |
| 7 | **Unlock features** — health sync, IoT, personalisation, snippets + memory; another session or sign-in |

Soft **fade-in** animations (`FadeInTitle`, `FadeInLine`, `ScreenFadeIn`) run on each step for navigation copy.

## Immersive session — audio & visuals

- **Nature video (royalty-free):** Full-screen **AVPlayerLayer** uses an **`AVQueuePlayer`** that plays four **[Mixkit](https://mixkit.co/free-stock-video/nature/)** clips in order (forest lake → park → meadow → water), then **re-queues** the same set so the compilation **loops until the session ends** (muted; music is separate). Jumps between *different* files may show a brief decode gap; within a single file, the pipeline is continuous. Licensed under the **[Mixkit Stock Video Free License](https://mixkit.co/license/#videoFree)**.
- **Meditation audio:** **`AVPlayerLooper`** + **`AVQueuePlayer`** loops **[CC0 calm music](https://opengameart.org/content/calm-music)** (`song_2.mp3` by [Morsi](https://opengameart.org/users/morsi), hosted on OpenGameArt) with **gapless** repeats until `AmbientAudioSession.stop()`. Use the **speaker** button to mute. For offline or another file, point `AmbientAudioSession.streamURL` at `Bundle.main.url(forResource:withExtension:)` instead.
- **Session options (bottom):** Collapsible **`SessionBottomConfigMenu`** — mock **home lighting sync** toggle (Philips Hue / HomeKit–style, no real bridge) and **Share visuals** via the system share sheet (text placeholder; no screen capture in POC).
- **Optional legacy canvas:** Procedural layers from `NatureSessionImagery.swift` are **not** shown during immersive anymore (video replaces them); file kept if you want to reuse elsewhere.

## Requirements

- iOS **17+**, Xcode **15+**
- Physical device recommended for **camera**
- **Network** required on first immersive session for **streamed nature video** and **streamed MP3** (AVFoundation may cache segments afterward).
