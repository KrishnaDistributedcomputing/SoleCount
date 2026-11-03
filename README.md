# SoleCount

An iPhone app that counts how often you wear each pair of sneakers and shows your cost per wear.

- SwiftUI, SwiftData, Swift Charts, StoreKit 2 (iOS 18+)
- All data stays on the device. No accounts, no tracking.
- Free: 3 pairs. SoleCount Pro (one-time): unlimited pairs + wear history chart.

Privacy policy: [PRIVACY.md](PRIVACY.md)

## Quick start on Mac

**Requirements:** macOS with Xcode 26+ installed. This guide is for beginners.

### 1. Open Terminal
Press `Cmd + Space`, type `Terminal`, and press Return.

### 2. Get the code
```bash
git clone https://github.com/yourusername/SoleCount.git
cd SoleCount
```

### 3. Run setup (one time)
This installs Homebrew, XcodeGen, and fastlane, and asks for your App Store Connect API keys.
```bash
make setup
```

The setup script will:
- Check that Xcode 26+ is installed
- Install Homebrew if needed (may ask for your Mac password)
- Install XcodeGen and fastlane via Homebrew
- Ask for your App Store Connect credentials (Team ID, API Key ID, Issuer ID, and .p8 key file)
- Generate the Xcode project from `project.yml`
- Open the project in Xcode

### 4. Create the app in App Store Connect (one time)
After setup completes, run:
```bash
fastlane setup
```

This creates the bundle ID, app record, sets pricing ($0.99 Pro IAP), and configures privacy settings.

### 5. Run tests
```bash
make test
```

Or press `Cmd + U` in Xcode.

### 6. Deploy to TestFlight and App Store
```bash
make deploy
```

This runs all tests, builds the app, uploads to TestFlight, and submits for App Review (goes live automatically when approved).

**Deploy options:**
- `bash scripts/deploy.sh --beta-only` — stop after TestFlight
- `bash scripts/deploy.sh --setup` — run `fastlane setup` first

### Other commands
- `make open` — Regenerate the Xcode project and open it
- `make clean` — Remove build artifacts

---

## Detailed guides
- [AUTOMATION.md](AUTOMATION.md) — Full fastlane and GitHub Actions setup
- [LAUNCH-GUIDE.md](LAUNCH-GUIDE.md) — First-time App Store submission walkthrough

**Note:** The Xcode project (`SoleCount.xcodeproj`) is generated from `project.yml` by XcodeGen and is not committed to Git. Always edit `project.yml`, not the `.xcodeproj` directly.
