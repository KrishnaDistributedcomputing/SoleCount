# SoleCount — Mac Setup Guide

Complete setup from zero to App Store in **5 steps**. For someone brand new to Mac.

**Time needed:** 30-45 minutes first time.

---

## Never used a Mac? Start here

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

## How to copy and paste commands

Throughout this guide:
1. **Copy:** Hover over any code block and click the copy icon (two squares) in the top-right corner. Or select the text and press `Cmd + C`.
2. **Paste:** Click inside Terminal, press `Cmd + V`, then press `Return` to run it.

---

## Step 1: Open Terminal and get the code

Press `Cmd + Space`, type `Terminal`, press `Return`. Then copy and run this (all three commands at once):

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```

**Why:** Gets a copy of the app's code onto your Mac.

<details>
<summary>What you should see</summary>

```
Cloning into 'SoleCount'...
Receiving objects: 100% ...
```

Your prompt now shows `SoleCount`.
</details>

<details>
<summary>If it fails</summary>

**Popup says "Install command line developer tools"**: Click Install, wait 5-10 minutes, then run the command again.
</details>

---

## Step 2: Run setup and answer the questions

```bash
make setup
```

**Why:** Installs the tools Apple's build needs and saves your App Store keys safely.

### What make setup does, and why SoleCount needs it

`make setup` only runs `scripts/setup_mac.sh`. These are the steps that script actually does, in order. It is safe to run again: if a tool or answer is already there, it keeps it.

1. **Checks Xcode 26**
   - What it does: Looks for Xcode, Apple's app-building program, and checks that it is version 26 or newer.
   - Why SoleCount needs it: Apple only accepts App Store uploads built with Xcode 26. Without it, SoleCount cannot be sent to Apple.

2. **Installs Homebrew if it is missing**
   - What it does: Installs Homebrew, a helper that installs other developer tools. On a new Apple-chip Mac it also tells Terminal where Homebrew lives. It may ask for your Mac password.
   - Why SoleCount needs it: The next step uses Homebrew to install XcodeGen and fastlane.

3. **Installs XcodeGen**
   - What it does: Installs XcodeGen, the tool that builds an Xcode project from a settings file.
   - Why SoleCount needs it: SoleCount's project file (`SoleCount.xcodeproj`) is not stored on GitHub. XcodeGen makes it on your Mac from `project.yml`.

4. **Installs fastlane**
   - What it does: Installs fastlane with Homebrew. Fastlane is written in the Ruby language. This script does not install Ruby packages with bundler, and it does not run `bundle install`. (The project has a `Gemfile` that lists fastlane, but `make setup` uses the Homebrew copy.)
   - Why SoleCount needs it: `make appstore-setup` and `make deploy` use fastlane to set up the $0.99 Pro upgrade, take screenshots, upload to TestFlight, and send the app to App Review.

5. **Creates a private settings file**
   - What it does: Copies `fastlane/.env.example` to `fastlane/.env` if that file is not there yet, and locks it so only your Mac user can read it.
   - Why SoleCount needs it: Your Team ID and API details are saved in that file. It is ignored by Git, so it is never uploaded to the public GitHub repo.

6. **Asks for your Team ID**
   - What it does: Asks for the 10-character Team ID and saves it in `fastlane/.env`. Find it at [developer.apple.com/account](https://developer.apple.com/account) → Membership details.
   - Why SoleCount needs it: It tells Xcode which Apple Developer account is allowed to build SoleCount.

7. **Asks for your API Key ID**
   - What it does: Asks for the 10-character Key ID and saves it. Find it at [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api). Click **+** to make a key if you do not have one.
   - Why SoleCount needs it: Together with the next two items, it lets SoleCount's tools sign in to your Apple account without your Apple ID password.

8. **Asks for your Issuer ID**
   - What it does: Asks for the long Issuer ID shown above the keys table on that same API page, and saves it.
   - Why SoleCount needs it: Apple uses it with the Key ID and the `.p8` file to confirm the login is yours.

9. **Stores the .p8 key outside the project**
   - What it does: Takes the downloaded `AuthKey_XXXXXXXXXX.p8` file (from Downloads, or you drag it into Terminal) and saves it at `~/.appstoreconnect/private_keys/`, which is in your home folder, not inside SoleCount.
   - Why SoleCount needs it: That file is the private half of the API login. Keeping it outside the project means it never goes to the public GitHub.

10. **Asks for your Apple ID email (you can skip this)**
    - What it does: Asks for the email on your Apple ID. Press Return to skip.
    - Why SoleCount needs it: If you fill it in, fastlane can create the App Store listing and the privacy answers for you. If you skip it, you do that once on the Apple website instead.

11. **Writes the Team ID into the Xcode settings**
    - What it does: Puts the Team ID into `Config/Team.xcconfig`.
    - Why SoleCount needs it: When Xcode builds SoleCount, it reads that file to know which developer team to use.

12. **Asks for an App Review phone number and email**
    - What it does: If those two files still contain the placeholder `REPLACE_ME`, it asks for a phone number (with country code) and an email, then saves them.
    - Why SoleCount needs it: Apple requires a person they can contact while they review SoleCount.

13. **Builds the Xcode project**
    - What it does: Runs XcodeGen to create `SoleCount.xcodeproj` from `project.yml`.
    - Why SoleCount needs it: Xcode opens a project file, and that file is created on your Mac rather than downloaded from GitHub.

14. **Downloads the iPhone Simulator if it is missing**
    - What it does: Checks for an iPhone simulator. If none is installed, it downloads the iOS simulator. A simulator is a pretend iPhone that runs on your Mac.
    - Why SoleCount needs it: `make test` and the App Store screenshots run SoleCount in that simulator.

15. **Opens SoleCount in Xcode**
    - What it does: Opens `SoleCount.xcodeproj`.
    - Why SoleCount needs it: You can then run the app in the simulator or on your real iPhone.

---

The script then asks for:

- **Team ID** (10 chars): [developer.apple.com/account](https://developer.apple.com/account) → Membership details
- **API Key ID** (10 chars): [App Store Connect → API](https://appstoreconnect.apple.com/access/integrations/api) → Generate key, copy Key ID
- **Issuer ID** (a long code): Same page, above the keys table
- **.p8 file**: Drag `AuthKey_*.p8` from Downloads into Terminal when prompted
- **Phone & email**: For App Review contact

**Note:** When typing your Mac password, you won't see any characters. That's normal—just type it and press Return.

<details>
<summary>What you should see</summary>

```
==> Checking Xcode
✔ Xcode is ready
==> Checking Homebrew
✔ Homebrew 4.x
...
==> Done!
```

Xcode opens with the project.
</details>

<details>
<summary>If it fails</summary>

**"Xcode is not ready"**: Install Xcode 26+ from App Store, open it once, run `make setup` again.
</details>

---

## Step 3: Create the app in App Store Connect

```bash
make appstore-setup
```

**Why:** Creates the app's listing and the $0.99 upgrade in Apple's system.

<details>
<summary>What you should see</summary>

```
App record: SoleCount: Sneaker Tracker (Apple ID 1234567890)
✅ Setup done.
```
</details>

<details>
<summary>If it fails</summary>

**"App record doesn't exist yet"**: Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com), click Apps → + → New App, use bundle ID `com.krishnav.SoleCount`, then run the command again.
</details>

---

## Step 4: Test the app

```bash
make test
```

**Why:** Catches bugs before Apple's reviewers do, which helps avoid rejection.

The simulator opens, tests run (8-10 minutes).

<details>
<summary>What you should see</summary>

```
Executed 12 tests, with 0 failures
✅ Tests passed!
```
</details>

---

## Step 5: Deploy to TestFlight and App Store

⚠️ This submits your app to the real App Store.

```bash
make deploy
```

**Why:** Builds the app and sends it to Apple for review.

Takes 10-15 minutes. Runs tests → uploads to TestFlight → submits for review.

<details>
<summary>What you should see</summary>

```
==> 1/3 Tests
✅ Tests passed!
==> 2/3 TestFlight upload
✅ Build 1 is on TestFlight.
==> 3/3 App Review
✅ Submitted SoleCount 1.0 (1) for review.
```
</details>

<details>
<summary>If it fails</summary>

**"No valid code signing identity"**: Open the project in Xcode, click the project name, go to Signing & Capabilities, check "Automatically manage signing".
</details>

---

## Get updates later

```bash
git pull && make open
```

---

## Other commands

```bash
make help           # See all commands
make open           # Regenerate and open Xcode project
make clean          # Remove build artifacts
```

---

## If something goes wrong

Copy the error from Terminal (select it with your mouse, press `Cmd + C`), then use this prompt with Claude Code:

```
I'm setting up SoleCount on Mac (beginner). I ran:

[paste the command here]

Error:

[paste the error here]

What's wrong and how do I fix it?
```

Open Claude Code: type `claude` in Terminal (inside the SoleCount folder), or paste the prompt at [claude.ai](https://claude.ai).

---

## Complete command list

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
make setup
make appstore-setup
make test
make deploy
```

Done! 🎉

For more details: [AUTOMATION.md](../AUTOMATION.md) • [LAUNCH-GUIDE.md](../LAUNCH-GUIDE.md)

---

## Other helpful commands

### Open the Xcode project

If you closed Xcode and want to open it again:

```bash
make open
```

### Clean build artifacts

If you want to start fresh (removes build cache and generated project):

```bash
make clean
```

Then run `make open` to regenerate the project.

### See all available commands

```bash
make help
```

---

## If something goes wrong: copy this prompt into Claude Code

If you hit an error and don't know how to fix it, you can get help from Claude Code (an AI coding assistant that runs in your Terminal).

### How to copy an error from Terminal

1. **Select the error text** with your mouse (click and drag over the red error lines)
2. Press `Cmd + C` to copy

### Open Claude Code and ask for help

If Claude Code is installed (type `claude` in Terminal), use this prompt. If not, paste this into the Claude chat in your browser or IDE.

**Copy this prompt template:**

```
I'm setting up the SoleCount iOS app on my Mac and I'm a beginner to macOS and Terminal. I ran this command:

[PASTE THE COMMAND YOU RAN HERE, like: make setup]

And I got this error:

[PASTE THE ERROR TEXT FROM TERMINAL HERE]

Can you explain what went wrong in simple terms and tell me exactly what command to run to fix it?
```

**How to use it:**

1. Copy the template above
2. Replace `[PASTE THE COMMAND YOU RAN HERE]` with the command that failed (like `make setup` or `git clone ...`)
3. Replace `[PASTE THE ERROR TEXT FROM TERMINAL HERE]` with the error you copied from Terminal
4. If you have Claude Code installed:
   - Open Terminal in the SoleCount folder (`cd ~/Desktop/SoleCount` or wherever you put it)
   - Type `claude` and press `Return`
   - Paste the filled-in prompt and press `Return`
5. If you don't have Claude Code:
   - Paste the filled-in prompt into the Claude chat at [claude.ai](https://claude.ai) or in Cursor IDE

Claude Code will read your project files and tell you how to fix the issue.

---

## Quick reference: All setup commands in order

Once you're comfortable, here's the complete flow:

```bash
cd ~/Desktop
git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git
cd SoleCount
make setup
make appstore-setup
make test
make deploy
```

That's it! 🎉

For more details, see:
- [AUTOMATION.md](../AUTOMATION.md) — fastlane and GitHub Actions explained
- [LAUNCH-GUIDE.md](../LAUNCH-GUIDE.md) — Complete App Store submission walkthrough
