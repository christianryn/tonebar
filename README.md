# ToneBar

Open-source macOS menu bar audio equalizer using **Core Audio Taps** (no virtual audio driver).

## Features (planned)

- **All system audio** — EQ everything playing on your Mac
- **Per application** — pick one app (e.g. Spotify); only that app is EQ'd
- Menu bar UI with graphic EQ and presets

## Requirements

- macOS **14.2** or later (Sonoma+)
- **Xcode 15+** to build (full Xcode from the Mac App Store)
- Permission: **System Settings → Privacy & Security → Screen & System Audio Recording**

## Build

```bash
git clone git@github.com:christianryn/tonebar.git
cd tonebar
open ToneBar.xcodeproj   # available after Xcode project is added
```

> **Note:** The Xcode project is being added incrementally. Check commits on `main` for the latest scaffold.

## Development status

Early setup — repository created; app implementation in progress.

## License

MIT — see [LICENSE](LICENSE).
