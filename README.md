# SoleCount

An iPhone app that counts how often you wear each pair of sneakers and shows your cost per wear.

- SwiftUI, SwiftData, Swift Charts, StoreKit 2 (iOS 18+)
- All data stays on the device. No accounts, no tracking.
- Free: 3 pairs. SoleCount Pro (one-time): unlimited pairs + wear history chart.

Privacy policy: [PRIVACY.md](PRIVACY.md)

## 🚀 Quick Start on Mac

**New to Mac?** **[→ 5-step beginner guide](docs/MAC-STEP-BY-STEP.md)** with copy-paste commands.

**Requirements:** macOS with Xcode 26+.

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
make setup
make appstore-setup
make test
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
