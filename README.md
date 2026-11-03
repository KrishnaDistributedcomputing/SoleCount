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
   **Why:** You copy commands from this page, and copying and pasting is easiest on the same computer, because the Mac can't paste text that was copied on your Windows PC.

2. **Open Terminal.** Hold the Cmd key (⌘, next to the space bar) and press the space bar. In the search box that appears, type `Terminal` and press Return. A window with a blinking cursor opens; that's where commands go.  
   **Why:** Terminal lets you type instructions directly to the Mac, and the setup tools (Xcode, fastlane) are run from it.

3. **Copy a command.** Hover over a grey command box and click the copy icon (two squares) in its top-right corner. Or drag your mouse across the command to highlight it and press Cmd + C.  
   **Why:** Copying avoids typos, since one wrong character can make a command fail.

4. **Paste and run it.** Click inside the Terminal window, press Cmd + V, then press Return.  
   **Why:** Pasting puts the command in Terminal, but nothing happens until you press Return, which tells the Mac to run it.

5. **Wait, then do the next one.** When the blinking cursor comes back on a new line, the command is finished. If it asks for your Mac password, type it and press Return. Nothing shows on screen while you type, and that's normal.  
   **Why:** Each command builds on the one before, so running the next one too early can break things. The password check is macOS confirming you allow installing tools, and the characters are hidden for security.

**Tips:** Press Cmd + Tab to switch between Safari and Terminal. If something goes wrong, take a photo of the screen and ask for help, or use the Claude Code prompt section.

---

### No Apple Developer membership yet? (waiting up to 48 hrs)

You paid, and Apple is still processing it. You can build, test, and run SoleCount on this Mac today. The Team ID, Key ID, Issuer ID, and `.p8` key do not exist until Apple finishes. Full detail: **[Mac setup guide](docs/MAC-STEP-BY-STEP.md#no-apple-developer-membership-yet-waiting-up-to-48-hrs)**.

**Do now, no membership needed**

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```
**Why:** Gets a copy of SoleCount's code onto your Mac.

```bash
make setup-local
```
**Why:** Installs the tools, creates the Xcode project, downloads the iPhone Simulator, and opens Xcode. It does not ask for any Apple membership details.

```bash
make test
```
**Why:** Runs SoleCount in the iPhone Simulator. No Team ID is required, so you can catch bugs before you send the app to Apple.

```bash
make open
```
**Why:** Opens SoleCount in Xcode. Press Cmd + R to run it in the simulator.

To run it on your own iPhone with a free Apple ID: in Xcode open Settings, then Accounts, and add your Apple ID. Click the SoleCount project, open Signing & Capabilities, and choose Personal Team. A free install lasts 7 days. It cannot use the In-App Purchase sandbox or TestFlight. The $0.99 purchase can still be tried in the simulator.

**Do after Apple's welcome email**

Find your Team ID at [developer.apple.com/account](https://developer.apple.com/account) → Membership details. Create the API key and find the downloaded file with **[How to get and find your AuthKey_XXXXXXXXXX.p8 file](docs/MAC-STEP-BY-STEP.md#find-the-p8-file)**.

```bash
make setup
```
**Why:** Saves the Team ID, Key ID, Issuer ID, and `.p8` key so SoleCount can sign in to your Apple account. Press Return only for a question you still do not have. When it asks for the key file, use **[How to get and find your AuthKey_XXXXXXXXXX.p8 file](docs/MAC-STEP-BY-STEP.md#find-the-p8-file)**.

```bash
make appstore-setup
```
**Why:** Registers the bundle ID and sets up the $0.99 upgrade. It needs the `.p8` file from **[How to get and find your AuthKey_XXXXXXXXXX.p8 file](docs/MAC-STEP-BY-STEP.md#find-the-p8-file)**. If it says the app record does not exist yet, fill in **[Create the SoleCount app in App Store Connect (New App form)](docs/MAC-STEP-BY-STEP.md#new-app-form)** before `make deploy`.

```bash
make deploy
```
**Why:** Builds SoleCount and sends it to Apple for review.

If you run those last two commands before the membership is ready, they stop and tell you to wait for Apple's email.

**Get a newer copy of the code**

When a branch such as `cursor/setup-without-apple-043d` should become the normal copy, follow **[Get the latest updates (merge a branch and git pull)](docs/MAC-STEP-BY-STEP.md#get-updates)**. On the Mac, after that merge:

```bash
cd ~/Desktop/SoleCount && git checkout main && git pull
```

**Why:** `git checkout main` switches to the default copy, and `git pull` downloads the merged updates into this folder.

The `.p8` key steps stay in **[How to get and find your AuthKey_XXXXXXXXXX.p8 file](docs/MAC-STEP-BY-STEP.md#find-the-p8-file)**.

### Available commands

- `make setup-local` — Setup while Apple is still processing your membership
- `make setup` — Setup, and type your Team ID and API key when you have them
- `make test` — Run all tests in the iPhone Simulator (no Team ID)
- `make appstore-setup` — Create the App Store listing after Apple's email
- `make deploy` — Full deployment after Apple activates your membership
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
