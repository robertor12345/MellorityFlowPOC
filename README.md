# Mellority Flow

**iPhone** journey: open the app → **Start Session** (no login) → optional sign-in → **optional integration slides** (after a successful sign-in, with per-feature **Connect** / **Skip** and **Skip all**) → **Camera** or **Quick Start** → **mood** → fast session load with subtle AI lines → **immersive** space with real-time adaptation → **insight** (simple, visual) → **unlock deeper features** (health sync, IoT, personalisation, snippets + memory, “replay your calm”).

- **Brand:** cream / chocolate brown / gold (`BrandTheme`), aligned with Mellority logo asset. Typography: **SF** with **rounded** design app-wide for a simple modern look.
- **Integrations:** Camera and photo library use real system pickers when you grant permission. Optional sign-in and integration connect flows store choices in-app until backend sync is wired.

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
| 1b | **Post–sign-in slides** (only if user continues sign-in) — Health, **IoT** (Philips Hue stock image from Wikimedia Commons, CC BY 2.0), personalisation, snippets + memory, replay; **Connect** / **Skip**; **Skip all** or **Continue** to home |
| 2 | **Entry mode** — **Camera** (photo) or **Quick Start** (skip to mood) |
| 3 | **Mood select** |
| 4 | **Starting session** — progress + rotating subtle AI lines |
| 5 | **Immersive** — **royalty-free nature video** (Mixkit) + **meditation-style** audio, session heart-rate display; collapsed **Session options** menu (home lights sync · share to social); **End session** → insight |
| 6 | **Insight** — minimal visual calm ring + mood; **Replay your calm** teaser |
| 7 | **Unlock features** — health sync, IoT, personalisation, snippets + memory; another session or sign-in |

Soft **fade-in** animations (`FadeInTitle`, `FadeInLine`, `ScreenFadeIn`) run on each step for navigation copy.

## Immersive session — audio & visuals

- **Nature video (royalty-free):** Full-screen **AVPlayerLayer** uses an **`AVQueuePlayer`** that plays four **[Mixkit](https://mixkit.co/free-stock-video/nature/)** clips in order (forest lake → park → meadow → water), then **re-queues** the same set so the compilation **loops until the session ends** (muted; music is separate). Jumps between *different* files may show a brief decode gap; within a single file, the pipeline is continuous. Licensed under the **[Mixkit Stock Video Free License](https://mixkit.co/license/#videoFree)**.
- **Meditation audio:** **`AVPlayerLooper`** + **`AVQueuePlayer`** loops **[CC0 calm music](https://opengameart.org/content/calm-music)** (`song_2.mp3` by [Morsi](https://opengameart.org/users/morsi), hosted on OpenGameArt) with **gapless** repeats until `AmbientAudioSession.stop()`. Use the **speaker** button to mute. For bundled offline playback, swap in `Bundle.main.url(forResource:withExtension:)` from `AmbientAudioSession.startFresh(photoAnchored:)`/`startFresh(streamURL:)` callers.
- **Session options (bottom):** Collapsible **`SessionBottomConfigMenu`** — **home lighting sync** toggle (Philips Hue / HomeKit–style) and **Share visuals** via the system share sheet (session summary text).
- **Optional legacy canvas:** Procedural layers from `NatureSessionImagery.swift` are **not** shown during immersive anymore (video replaces them); file kept if you want to reuse elsewhere.

## Requirements

- iOS **17+**, Xcode **15+**
- Physical device recommended for **camera**
- **Network** required on first immersive session for **streamed nature video** and **streamed MP3** (AVFoundation may cache segments afterward).

## Listening discovery — retro clip streams

Calibration uses **six different** streamed snippets (sock-hop diner / malt-shop / jazz combos / country-western), all **Kevin MacLeod** instrumentals streamed from **[incompetech.com](https://incompetech.com)** MP3 URLs defined in **`DiscoveryFlowPOC.snippetAudioStreamURLs`**. Listed on incompetech under **Creative Commons BY** ([license](https://creativecommons.org/licenses/by/4.0/)) — **credit in shipping builds:** *Kevin MacLeod ([incompetech.com](https://incompetech.com))* in About / credits alongside any other licensors.

Per clip, **`AmbientAudioSession.startFresh(streamURL:)`** runs the loop for about **30 s** until the rider taps or the timer advances; if incompetech fails to load once, playback falls back to the same **CC0** `song_2.mp3` calm loop.

**Swapping cues:** Replace URLs in **`DiscoveryModels.swift`** (array length drives `snippetCount`) or bundle MP3/M4A and pass `Bundle.main.url(…)`. Other cleared sources with vintage / ~1950s flavour you can audition (read each site's licence before shipping):

| Source | Notes |
|--------|--------|
| **[Silverman Sound — Gramophone Vintage](https://silvermansound.com/royalty-free-vintage-music)** | Dedicated vintage collection; cites **Creative Commons BY 4.0** on catalogue pages |
| **[Pixabay Music](https://pixabay.com/music/)** (search “50s”, “retro”, “sock hop”, “big band”) | **Pixabay licence** permits use without attribution ([summary](https://pixabay.com/service/license-summary/)); good for prototyping |
| **[Free Music Archive](https://freemusicarchive.org)** filtered by licence | Often **BY** variants — credit per track |

Paid subscription libraries (**Motion Array**, **Epidemic Sound**, etc.) have separate terms; do not treat their tracks as interchangeable with incompetech-hosted files without complying with those agreements.
