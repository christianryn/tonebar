# ToneBar

Open-source macOS menu bar audio equalizer using **Core Audio Taps** (no virtual audio driver).

## Features

- **All system audio** — EQ everything playing on your Mac
- **Per application** — pick one app (e.g. Spotify); only that app is EQ'd
- 10-band graphic EQ with output gain
- Menu bar UI (no Dock icon)

## Requirements

- macOS **14.2** or later (Sonoma+)
- **Xcode 15+** from the Mac App Store (Command Line Tools alone are not enough)
- Permission: **System Settings → Privacy & Security → Screen & System Audio Recording**

## Build & run

```bash
git clone git@github.com:christianryn/tonebar.git
cd tonebar
open ToneBar.xcodeproj
```

In Xcode:

1. Select the **ToneBar** scheme and your Mac as the destination.
2. Set your **Signing Team** under Target → Signing & Capabilities (for local run).
3. Press **⌘R** to build and run.
4. Click the **waveform** icon in the menu bar and enable EQ.

If `xcodebuild` fails with “requires Xcode”, point the active developer directory at full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Project layout

```
ToneBar/
├── App/          # SwiftUI menu bar UI
├── Audio/        # CATap, pipeline, process list
├── EQ/           # AVAudioUnitEQ + presets
└── Resources/    # Assets
```

## Development status

**v0.1** — Xcode scaffold with CATap capture pipeline and menu bar UI. Audio path may need tuning on your machine; report issues with macOS version and output device.

## License

MIT — see [LICENSE](LICENSE).
