# SoleCount

An iPhone app that counts how often you wear each pair of sneakers and shows your cost per wear.

- SwiftUI, SwiftData, Swift Charts, StoreKit 2 (iOS 18+)
- All data stays on the device. No accounts, no tracking.
- Free: 3 pairs. SoleCount Pro (one-time): unlimited pairs + wear history chart.

Privacy policy: [PRIVACY.md](PRIVACY.md)

## 🚀 Quick Start on Mac

**New to macOS and Terminal?** Follow the complete step-by-step guide with copy-paste instructions: **[Mac Setup Guide for Beginners →](docs/MAC-STEP-BY-STEP.md)**

**Requirements:** macOS with Xcode 26+ installed.

### For experienced developers

```bash
# 1. Get the code
git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git
cd SoleCount

# 2. One-time setup (installs tools, asks for API keys, generates project)
make setup

# 3. Create app in App Store Connect
make appstore-setup

# 4. Run tests
make test

# 5. Deploy (tests → TestFlight → App Review)
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
