# SoleCount

An iPhone app that counts how often you wear each pair of sneakers and shows your cost per wear.

- SwiftUI, SwiftData, Swift Charts, StoreKit 2 (iOS 18+)
- All data stays on the device. No accounts, no tracking.
- Free: 3 pairs. SoleCount Pro (one-time): unlimited pairs + wear history chart.

Privacy policy: [PRIVACY.md](PRIVACY.md)

## 🚀 Quick Start on Mac

### Never used a Mac? Start here

Do all of this on the Mac, so you copy and paste on the same computer.

1. **Open this page in Safari.** Click the compass icon in the row of icons at the bottom of the screen (the Dock). That's Safari. Click the address bar at the top, type `github.com/KrishnaDistributedcomputing/SoleCount` and press Return. Scroll down to the steps.

2. **Open Terminal.** Hold the Cmd key (⌘, next to the space bar) and press the space bar. In the search box that appears, type `Terminal` and press Return. A window with a blinking cursor opens; that's where commands go.

3. **Copy a command.** Hover over a grey command box and click the copy icon (two squares) in its top-right corner. Or drag your mouse across the command to highlight it and press Cmd + C.

4. **Paste and run it.** Click inside the Terminal window, press Cmd + V, then press Return.

5. **Wait, then do the next one.** When the blinking cursor comes back on a new line, the command is finished. If it asks for your Mac password, type it and press Return. Nothing shows on screen while you type, and that's normal.

**Tips:** Press Cmd + Tab to switch between Safari and Terminal. If something goes wrong, take a photo of the screen and ask for help, or use the Claude Code prompt section.

---

**New to Mac?** **[→ 5-step beginner guide](docs/MAC-STEP-BY-STEP.md)** with copy-paste commands.

**Requirements:** macOS with Xcode 26+.

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```

```bash
make setup
```

```bash
make appstore-setup
```

```bash
make test
```

```bash
make deploy
```

### Available commands

- `make setup` — One-time Mac setup (Homebrew, XcodeGen, fastlane, API keys, generate project)
- `make test` — Run all tests
- `make deploy` — Full deployment (tests → TestFlight → App Review)
- `make open` — Regenerate the Xcode project and open it
- `make clean` — Remove build artifacts
- `make help` — Show all available commands

**Deploy options:**
- `bash scripts/deploy.sh --beta-only` — Upload to TestFlight only (skip App Review)
- `bash scripts/deploy.sh --setup` — Run `fastlane setup` first, then deploy

---

## Detailed guides
- [AUTOMATION.md](AUTOMATION.md) — Full fastlane and GitHub Actions setup
- [LAUNCH-GUIDE.md](LAUNCH-GUIDE.md) — First-time App Store submission walkthrough

**Note:** The Xcode project (`SoleCount.xcodeproj`) is generated from `project.yml` by XcodeGen and is not committed to Git. Always edit `project.yml`, not the `.xcodeproj` directly.
