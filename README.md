# Mellority Flow POC

**iPhone demo** of the Mellority user journey: onboarding → personalisation → capture → AI processing → immersive session → snippets → IoT (mock) → summary → learning loop.

- **Brand:** cream / chocolate brown / gold (`BrandTheme`), aligned with Mellority logo asset.
- **Integrations:** All **simulated** (no real Sign in with Apple/Google, no HealthKit calls, Hue is UI-only). Camera and photo library use real pickers when you grant system permission.

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
| 1 | Welcome → Auth choice → Email sign up / log in |
| 2 | Permissions (toggles) |
| 3 | Mood goals, genres, tempo, source toggles |
| 4 | Start session → photo (library or camera) |
| 5 | Processing animation |
| 6 | Full-screen immersive (ethereal layers, **leaf breeze** animation, **streaming ambient** MP3 + on-device HF sine, mock HR) |
| 7 | Snippets |
| 8 | Hue-style IoT presets |
| 9 | Summary + feedback |
| 10 | Learning loop → another session or home |

## Immersive session — audio & visuals

- **Leaves:** `LeafBreezeLayer` animates SF Symbol leaves drifting with wind-like motion and gold gradients.
- **Streaming bed:** `AVPlayer` loads **[SoundHelix example MP3](https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3)** over HTTPS (orchestral ambient demo; see SoundHelix project terms). Loops until you leave the screen.
- **High frequency:** A quiet **~9.2 kHz sine** is synthesized with `AVAudioEngine` + `AVAudioSourceNode` (not streamed — avoids CDN hotlink blocks). It adds a subtle “air” layer; use the **speaker** button to mute.
- **Why not only a remote HF file?** Many royalty-free CDNs return **403** to app user-agents; bundling a separate MP3 would work but duplicates licensing in-repo. The split (streamed bed + local HF) matches the brief.

## Requirements

- iOS **17+**, Xcode **15+**
- Physical device recommended for **camera**
- **Network** required on first immersive session for the streamed MP3 (then cached by the system).
