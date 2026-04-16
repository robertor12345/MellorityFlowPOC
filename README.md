# Mellority Flow POC

**iPhone demo** of a simplified Mellority journey: open the app → **Start Session** (no login) → optional sign-in → **Camera** or **Quick Start** → **mood** → fast session load (**under ~5s**) with subtle AI lines → **immersive** space with real-time adaptation → **insight** (simple, visual) → **unlock deeper features** (health sync, IoT, personalisation, snippets + memory, “replay your calm”).

- **Brand:** cream / chocolate brown / gold (`BrandTheme`), aligned with Mellority logo asset.
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
| 2 | **Entry mode** — **Camera** (photo) or **Quick Start** (skip to mood) |
| 3 | **Mood select** |
| 4 | **Starting session** — progress + rotating subtle AI lines (&lt; ~5s) |
| 5 | **Immersive** — ethereal layers, leaf breeze, streaming **meditation-style** calm audio, mock HR; **End session** → insight |
| 6 | **Insight** — minimal visual calm ring + mood; **Replay your calm** teaser |
| 7 | **Unlock features** — health sync, IoT, personalisation, snippets + memory; another session or sign-in |

Soft **fade-in** animations (`FadeInTitle`, `FadeInLine`, `ScreenFadeIn`) run on each step for navigation copy.

## Immersive session — audio & visuals

- **Nature imagery:** `NatureSessionImagery` stacks sky/mist, tinted light orbs, **mountain** silhouettes, animated **water** bands, subtle drifting symbols (water, waves, mountains, trees, leaves, clouds), and `LeafBreezeLayer` for gold **leaf** motion.
- **Streaming bed:** `AVPlayer` loops **[CC0 calm music](https://opengameart.org/content/calm-music)** (`song_2.mp3` by [Morsi](https://opengameart.org/users/morsi), hosted on OpenGameArt). Meditation / relaxation vibe. Use the **speaker** button to mute. For offline or a different track, add an MP3 to the target and point `AmbientAudioSession.streamURL` at `Bundle.main.url(forResource:withExtension:)` instead.

## Requirements

- iOS **17+**, Xcode **15+**
- Physical device recommended for **camera**
- **Network** required on first immersive session for the streamed MP3 (then cached by the system).
