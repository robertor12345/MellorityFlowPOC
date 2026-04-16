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
| 6 | Full-screen immersive (animated visuals + mock HR) |
| 7 | Snippets |
| 8 | Hue-style IoT presets |
| 9 | Summary + feedback |
| 10 | Learning loop → another session or home |

## Requirements

- iOS **17+**, Xcode **15+**
- Physical device recommended for **camera**
