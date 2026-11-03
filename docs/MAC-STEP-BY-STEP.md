# SoleCount — Complete Mac Setup Guide for Beginners

This guide walks you through every step of setting up SoleCount on your Mac and submitting it to the App Store. No prior Terminal or macOS development experience needed.

**Time needed:** About 30-45 minutes for first-time setup.

---

## Step 1: Open Terminal

**What this does:** Opens the Terminal app, which lets you type commands to control your Mac.

**How to open it:**
1. Press `Cmd + Space` on your keyboard (this opens Spotlight search)
2. Type `Terminal`
3. Press `Return`

A window with white or black text on a colored background will open. This is Terminal.

---

## Step 2: Choose where to put the project

**What this does:** Creates a folder (if needed) and moves into it so the code downloads there.

**Choose ONE of these options:**

### Option A: Put it on your Desktop (easy to find)

**Copy this:**

```bash
cd ~/Desktop
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:** Nothing prints if it works (that's normal!). The prompt line now shows `Desktop` in it.

### Option B: Put it in a Developer folder (organized)

**Copy this:**

```bash
mkdir -p ~/Developer && cd ~/Developer
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:** The command runs silently. The prompt line now shows `Developer` in it.

**Tip:** `mkdir -p` creates the folder if it doesn't exist yet, and `-p` means "don't show an error if it's already there."

---

## Step 3: Download the SoleCount code

**What this does:** Downloads the complete SoleCount project from GitHub to your Mac.

**Copy this:**

```bash
git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**How to copy text from GitHub or this guide:**
- When you hover over a code block in GitHub, a copy button (two overlapping squares) appears in the top-right corner. Click it to copy.
- Alternative: Click and drag your mouse to select the text, then press `Cmd + C` to copy.

**What you should see:**

```
Cloning into 'SoleCount'...
remote: Enumerating objects: ...
remote: Counting objects: ...
Receiving objects: 100% ...
```

**If it fails:**
- **"xcrun: error: invalid active developer path"** or **A popup says "Install command line developer tools"**: This is normal the first time you use `git`. Click **Install** in the popup and wait (takes 5-10 minutes). Then run the `git clone` command again.
- **"command not found: git"**: Install Xcode from the Mac App Store first, open it once, then try again.

---

## Step 4: Enter the SoleCount folder

**What this does:** Moves into the SoleCount project folder so the next commands work on the right files.

**Copy this:**

```bash
cd SoleCount
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:** The prompt line now shows `SoleCount` in it. That means you're inside the project folder.

**If it fails:**
- **"No such file or directory"**: The git clone in Step 3 didn't work. Scroll up in Terminal to see the error from that step.

---

## Step 5: Run the one-time Mac setup

**What this does:** Installs all the tools you need (Homebrew, XcodeGen, fastlane), asks for your Apple Developer credentials, generates the Xcode project, and opens it.

**Copy this:**

```bash
make setup
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:**

The script runs through several steps with colored output:

```
==> Checking Xcode
Xcode 26.0
✔ Xcode is ready

==> Checking Homebrew
✔ Homebrew 4.x.x

==> Installing XcodeGen and fastlane
✔ xcodegen 2.x.x, fastlane installed

==> Your App Store Connect details (see AUTOMATION.md, steps 2-3)
```

**The script will ask you for:**

1. **Team ID** (10 characters, like `A1B2C3D4E5`)
   - Where to find it: Go to [developer.apple.com/account](https://developer.apple.com/account) (sign in with your Apple ID), click **Membership details**, and copy the **Team ID**.

2. **API Key ID** (10 characters, like `ABCD123456`)
   - Where to find it: Go to [App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys](https://appstoreconnect.apple.com/access/integrations/api), click the **+** to generate a key if you haven't yet, then copy the **Key ID**.

3. **Issuer ID** (a long code like `12345678-1234-1234-1234-123456789abc`)
   - Where to find it: Same page as the API Key. It's shown above the keys table. Copy the **Issuer ID**.

4. **The .p8 key file** (a file like `AuthKey_ABCD123456.p8`)
   - Where to find it: When you generated the API Key in App Store Connect, you downloaded a `.p8` file. If it's in your Downloads folder, the script will find it automatically. Otherwise, the script will say:
     ```
     Drag the AuthKey_ABCD123456.p8 file into this window and press Return:
     ```
   - Drag the file from Finder into the Terminal window, then press `Return`.

5. **Phone number for App Review** (like `+1 416 555 0100`)
   - Apple requires a contact number for their review team. Enter it with the country code (e.g., `+1` for USA/Canada).

6. **Email for App Review** (like `you@example.com`)
   - Apple requires a contact email for their review team.

**About typing your Mac password:**
- When the script installs Homebrew (if it's not already installed), you'll see:
  ```
  Password:
  ```
- Type your Mac password and press `Return`. **You won't see any characters as you type** (not even dots or asterisks). This is normal and a security feature. Just type it and press `Return`.

**What happens at the end:**

```
==> Generating SoleCount.xcodeproj
✔ Project generated

==> Done!
Next steps:
  1) First time only:   fastlane setup       (creates the App Store Connect pieces)
  2) Every release:     bash scripts/deploy.sh  (tests -> TestFlight -> App Review)
```

Then Xcode opens with the SoleCount project.

**If it fails:**
- **"Xcode is not ready"**: Install Xcode 26 or newer from the Mac App Store, open it once (accept the license), then run `make setup` again.
- **"Homebrew ... command not found"**: The Homebrew install failed. Run: `brew --version` to check. If still missing, go to [brew.sh](https://brew.sh) and follow the install instructions, then run `make setup` again.
- **"API key file not found"**: The script couldn't find your `.p8` file. Make sure you downloaded it from App Store Connect, then run `make setup` again and drag the file into Terminal when asked.

---

## Step 6: Create the app in App Store Connect

**What this does:** Uses fastlane to create the app bundle ID, app record, set the Pro unlock pricing to $0.99, and configure privacy settings in App Store Connect.

**Copy this:**

```bash
make appstore-setup
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:**

```
[✔] 🚀
[21:30:15]: ------------------------------
[21:30:15]: --- Step: default_platform ---
[21:30:15]: ------------------------------
...
[21:30:25]: App record: SoleCount: Sneaker Tracker (Apple ID 1234567890)
[21:30:30]: ✅ Setup done. Next: bash scripts/deploy.sh
```

**If it fails:**
- **"The App Store Connect app record doesn't exist yet"**: The script will print instructions. You need to either:
  - **Option A (easiest)**: Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com), click **Apps** → **+** → **New App**, fill in the form (use bundle ID `com.krishnav.SoleCount`), then run `make appstore-setup` again.
  - **Option B**: Add `APPLE_ID=you@example.com` to the file `fastlane/.env` (your Apple ID email), then run `make appstore-setup` again. It will prompt for your password and a 2FA code.

---

## Step 7: Run the tests

**What this does:** Builds the app and runs all unit tests and UI tests in the iPhone simulator to make sure everything works.

**Copy this:**

```bash
make test
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:**

The iPhone simulator launches, the app opens, tests run automatically, and you see:

```
[21:35:10]: ------------------------------
[21:35:10]: --- Step: run_tests ---
[21:35:10]: ------------------------------
...
Test Suite 'All tests' passed at ...
	 Executed 12 tests, with 0 failures (0 unexpected) in 8.234 (8.567) seconds
...
[21:35:45]: ✅ Tests passed!
```

**If it fails:**
- **"Test Suite 'SomeTestName' failed"**: Read the failure message above that line. It shows which test broke. Copy the error (see "If something goes wrong" section below) and use the Claude Code prompt.
- **Simulator doesn't open**: Make sure you accepted the Xcode license. Open Xcode, go to **Xcode menu** → **Preferences** → **Locations**, and make sure **Command Line Tools** is set to Xcode 26 or newer.

---

## Step 8: Deploy to TestFlight and App Store

**What this does:** Runs all tests again, builds a production version of the app, uploads it to TestFlight (for beta testing), and submits it to Apple for App Review (goes live automatically when approved).

**⚠️ Important:** This uploads your app to the real App Store. Make sure you've tested it first (Step 7).

**Copy this:**

```bash
make deploy
```

**Paste and run:**
- Click inside the Terminal window
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:**

```
==> 1/3 Tests
[21:40:10]: ✅ Tests passed!

==> 2/3 TestFlight upload
...
[21:50:25]: ✅ Build 1 is on TestFlight.

==> 3/3 App Review
...
[21:52:10]: ✅ Submitted SoleCount 1.0 (1) for review. It goes live automatically when approved.

All done. Check https://appstoreconnect.apple.com for review status.
```

**The whole process takes 10-15 minutes.**

**If it fails:**
- **"Missing ASC_KEY_ID, ASC_ISSUER_ID"**: The API key setup from Step 5 is incomplete. Run `make setup` again.
- **"No valid code signing identity found"**: This is an Xcode signing issue. Open the project in Xcode, click the project name at the top left, go to **Signing & Capabilities**, and make sure **Automatically manage signing** is checked and your Team is selected.
- **"App Review submission failed"**: Read the error carefully. Common causes: missing screenshots, missing privacy policy URL, or the In-App Purchase (Pro unlock) hasn't been approved yet. See LAUNCH-GUIDE.md for details.

**Deploy options if you want more control:**

- Upload to TestFlight only (skip App Review):
  ```bash
  bash scripts/deploy.sh --beta-only
  ```

---

## Step 9: Get updates later

**What this does:** Downloads the latest changes from GitHub if the code is updated.

**Copy this:**

```bash
git pull
```

**Paste and run:**
- Click inside the Terminal window (make sure you're in the `SoleCount` folder)
- Press `Cmd + V` to paste
- Press `Return` to run it

**What you should see:**

- If there are updates:
  ```
  Updating abc1234..def5678
  Fast-forward
   README.md | 10 ++++++++--
   1 file changed, 8 insertions(+), 2 deletions(-)
  ```

- If you're already up to date:
  ```
  Already up to date.
  ```

After pulling updates, regenerate the Xcode project:

```bash
make open
```

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
