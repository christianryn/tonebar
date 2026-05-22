# Contributing

## Prerequisites

- macOS 14.2+
- Xcode 15+ (not Command Line Tools alone — `xcodebuild` needs full Xcode)
- GitHub CLI optional for releases/issues

## Build & run

1. Clone the repo and open the Xcode project.
2. Build the `ToneBar` scheme (⌘B) and run (⌘R).
3. On first run, grant **Screen & System Audio Recording** when prompted.

## Testing both EQ modes

1. **All system audio** — play audio from two apps; both should be EQ'd when enabled.
2. **Selected app** — pick one app in the UI; only that app's audio should change; the other app plays unchanged.

## Reporting issues

Include: macOS version, output device (built-in / USB / Bluetooth), EQ mode, and steps to reproduce.
