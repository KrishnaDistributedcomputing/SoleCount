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

## No Apple Developer membership yet? (waiting up to 48 hrs)

You already paid, and Apple's email can take up to 48 hours. Until that email arrives you have no Team ID, no Key ID, no Issuer ID, and no `.p8` key. You can still set up, test, and run SoleCount.

### Do now, no membership needed

**1. Get the code**

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```

**Why:** Gets a copy of SoleCount's code onto your Mac.

**2. Set up the Mac without Apple questions**

```bash
make setup-local
```

**Why:** Installs Homebrew, XcodeGen, and fastlane, creates the Xcode project, downloads the iPhone Simulator, and opens Xcode. It skips every Apple question.

If you run `make setup` instead, press Return on each Apple question. The script prints what it skipped.

**3. Run the tests**

```bash
make test
```

**Why:** Runs SoleCount in the iPhone Simulator. No Team ID is required. This catches bugs before Apple's reviewers do.

**4. Run the app**

```bash
make open
```

Xcode opens. Press Cmd + R.

**Why:** Cmd + R builds SoleCount and shows it in the simulator on your Mac.

**5. Optional: your own iPhone, with a free Apple ID**

In Xcode, open the Settings menu, then Accounts, and add your Apple ID. Click the SoleCount project in the left sidebar, open Signing & Capabilities, and choose Personal Team.

**Why:** A free Apple ID can install SoleCount on your own phone. The free install expires after 7 days. It cannot use the In-App Purchase sandbox, and it cannot upload to TestFlight. You can still try the $0.99 purchase inside the simulator.

### Do after Apple's welcome email

**1. Copy your Team ID**

Open [developer.apple.com/account](https://developer.apple.com/account), then Membership details. Copy the 10-character Team ID.

**Why:** SoleCount's upload tools need this to show Apple which developer account is yours.

**2. Create the App Store Connect API key, then find the file**

Follow **[How to get and find your AuthKey_XXXXXXXXXX.p8 file](#find-the-p8-file)** below. Do that before `make setup`. Apple lets you download the file only once.

**Why:** The Key ID, Issuer ID, and `.p8` file let SoleCount sign in to your Apple account without your Apple ID password.

**3. Save those answers on your Mac**

```bash
make setup
```

Answer the questions this time. Press Return only if you still do not have that one item.

**Why:** Writes the Team ID into the project and saves the API key outside the project folder.

**4. Create the App Store listing**

```bash
make appstore-setup
```

**Why:** Registers the bundle ID `com.krishnav.SoleCount` and, after the app exists, sets up the $0.99 upgrade. Apple does not let the API key create the app record by itself. If the command stops and says the app record does not exist yet, fill in the New App form in the next section before you deploy.

<a id="new-app-form"></a>

## Create the SoleCount app in App Store Connect (New App form)

Do this only after Apple emails you that the paid membership is active. You need it before `make deploy`. If SoleCount is already in the Apps list, skip this form.

This is the empty form. Yours should look the same before you type:

![New App form in App Store Connect. Platforms, Name, Primary Language, Bundle ID, SKU, and User Access are empty, and Create is grey.](images/appstoreconnect-new-app.png)

**0. Open the form**

In Safari, open [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com). Click **Apps**. Click the blue **+** next to Apps, then **New App**.

**Why:** This creates the App Store record for SoleCount. The paid membership has to be active, or the + button will not let you add an iOS app.

**1. Platforms**

Tick **iOS** only. Leave macOS, tvOS, and visionOS unticked.

**Why:** SoleCount is an iPhone app.

**2. Name**

Type `SoleCount`. The number under the box must stay at 30 or less. This is the name people see on the App Store. If Apple says the name is already being used, type `SoleCount: Sneaker Tracker` instead. You can change the name later, before the app is released.

**Why:** This is the public name of this app. The project file `fastlane/metadata/en-US/name.txt` already says `SoleCount: Sneaker Tracker`, which is the name fastlane uses if it creates the record for you.

**3. Primary Language**

Choose **English (U.S.)**.

**Why:** SoleCount's App Store text is written in that language.

**4. Bundle ID**

Pick `com.krishnav.SoleCount` in the dropdown. It must match `project.yml` and `fastlane/Fastfile` exactly. Those files both use `com.krishnav.SoleCount`.

**Why:** Apple ties the installed app, the $0.99 upgrade, and this listing to that one ID. A different ID would be a different app.

If `com.krishnav.SoleCount` is not in the list, register it, then come back:

1. Click the **Certificates, Identifiers & Profiles** link under the Bundle ID menu.
2. Click **Identifiers**, then the **+** button.
3. Choose **App IDs**, then **App**. Continue.
4. Description: `SoleCount`.
5. Bundle ID: choose **Explicit** and type `com.krishnav.SoleCount`.
6. If **In-App Purchase** is in the capability list, tick it. On a new App ID it is already on.
7. Click **Continue**, then **Register**.
8. Go back to the New App form and refresh the page. The bundle ID should now be in the menu.

`make appstore-setup` can do this bundle-ID step for you. It calls fastlane, which uses your API key to register `com.krishnav.SoleCount` if it is missing. The script says In-App Purchase is on by default for that new ID. It does not fill in this website form. Refresh the form after that command if the ID was missing.

That same command does **not** create this New App record with the API key. Apple blocks that. Two things can happen:

- You left Apple ID blank in `fastlane/.env`. The command stops and tells you to fill in this form. Its example name is `SoleCount: Sneaker Tracker` and its example SKU is `solecount-ios`. Use the values in this section instead. `solecount001` is fine.
- You put your Apple ID email in `fastlane/.env`. Fastlane signs in as you, asks for a verification code, and creates the app itself. The name it sends is the text in `fastlane/metadata/en-US/name.txt` (`SoleCount: Sneaker Tracker`). The SKU it sends is `solecount-ios`. If the Apps list already shows SoleCount, do not fill this form again.

**5. SKU**

Type `solecount001`.

**Why:** SKU is a private ID. Only you see it. It can be any text that you have not used before, and you cannot change it later. SoleCount's tools find the app by the bundle ID, not by this SKU, so `solecount001` matches this app. If fastlane created the app for you, it stored `solecount-ios` instead. Leave that one alone.

**6. User Access**

Choose **Full Access**.

**Why:** You are the only developer. Full Access means every person on your Apple team can see SoleCount. Limited Access is for a big team that should hide the app from some members.

**7. Click Create**

Create stays grey until every box above is filled. After it turns blue, click **Create**.

**Why:** This saves the SoleCount record so the later upload has somewhere to go.

What to do on the next screens, still before `make deploy`:

- The $0.99 upgrade is an in-app purchase with the product ID `com.krishnav.SoleCount.pro`. In the app's sidebar, open **Monetization**, then **In-App Purchases**. `make appstore-setup` creates that purchase when the app record already exists. The first time, Apple requires that purchase to be attached to version 1.0 before you submit. In the purchase, choose **Add for Review** and select iOS version 1.0.
- Screenshots and the privacy answers still have to be filled in. `make deploy` uploads screenshots and the description. Privacy is set on the app's **App Privacy** page: SoleCount does not collect data.
- Then run `make deploy`. That builds SoleCount and sends version 1.0 to Apple. Do not submit until the Pro purchase is attached to that version.

**If something goes wrong**

- **"The app name you entered is already being used."** Someone else already took `SoleCount`. Type `SoleCount: Sneaker Tracker` instead. That name is still under 30 characters.
- **"Bundle ID not in the list."** It has not been registered yet. Use the Certificates, Identifiers & Profiles steps above, or run `make appstore-setup` so the API key registers `com.krishnav.SoleCount`, then refresh this form.
- **Create stays grey.** A required field is empty. Check iOS, the name, English (U.S.), the bundle ID, the SKU, and Full Access.

**6. Send the app to Apple**

```bash
make deploy
```

**Why:** Builds SoleCount and sends it to Apple for review. Run this only after the New App record exists and the $0.99 purchase is attached to version 1.0.

If you run `make appstore-setup` or `make deploy` before the membership details are saved, they stop with: "Your Apple Developer membership isn't active yet. Run make appstore-setup once Apple emails you."

---

<a id="get-updates"></a>

## Get the latest updates (merge a branch and git pull)

New SoleCount changes are saved on a branch first. A branch is a separate copy of the project. `main` is the copy that `git clone` downloads. These steps put a finished branch into `main`, then download that copy onto your Mac.

**1. Merge the branch on the GitHub website**

Open this page in Safari:

[https://github.com/KrishnaDistributedcomputing/SoleCount/compare/main...cursor/setup-without-apple-043d](https://github.com/KrishnaDistributedcomputing/SoleCount/compare/main...cursor/setup-without-apple-043d)

For a later branch, replace `cursor/setup-without-apple-043d` at the end of that address with the new branch name. Or open [the SoleCount page](https://github.com/KrishnaDistributedcomputing/SoleCount) and click the yellow **Compare & pull request** banner when GitHub shows one.

Click the green **Create pull request** button. On the next page, click **Create pull request** again. Wait until the checks finish. Then click **Merge pull request**, and click **Confirm merge**.

**Why:** `main` is the version everyone gets by default, including a new `git clone`. New work stays on a branch until this merge copies it into `main`.

**2. Download that update on the Mac**

If you already switched this folder to the update branch, download the latest commit of that branch:

```bash
cd ~/Desktop/SoleCount && git pull
```

**Why:** `git pull` downloads the newest saved copy of the branch you are on and puts it in this SoleCount folder.

After the GitHub merge, switch back to `main` and download it:

```bash
git checkout main && git pull
```

**Why:** `git checkout main` switches this folder from the side branch back to `main`. The second command, `git pull`, then downloads the merged `main` from GitHub onto your Mac. Your next `make setup-local`, `make test`, or `make open` uses that copy.

**If something goes wrong**

- **"There isn't anything to compare."** GitHub is saying this branch is already in `main`. You can skip the merge and run `git checkout main && git pull` on the Mac.
- **`git pull` says "Your local changes would be overwritten."** You edited a file on the Mac, and the download would replace that edit. Run `git stash`, then `git pull`. `git stash` sets your Mac-only edits aside so the download can finish. The project files match GitHub after that. Your stashed edits are not deleted. They sit in a side pile, and you do not need them for SoleCount's normal setup.
- **"not a git repository."** Terminal is not inside the SoleCount folder. Run `cd ~/Desktop/SoleCount` first, then run the `git` command again.

---

<a id="find-the-p8-file"></a>

## How to get and find your AuthKey_XXXXXXXXXX.p8 file

This is the private key file SoleCount uses to sign in to Apple. You can create it only after Apple emails you that the paid membership is active. Do these steps in Safari and Terminal on the Mac.

The file name looks like `AuthKey_ABC123DEFG.p8`. The letters after `AuthKey_` are your Key ID. Setup asks for that Key ID, for the Issuer ID, and then for this file.

### A. Create the key

**1. Sign in to App Store Connect**

Open [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com) in Safari and sign in with the Apple ID that paid for the developer membership.

**Why:** This is Apple's site for your app. SoleCount's upload tools use the same account.

**2. Open the API keys page**

Click **Users and Access**. Open the **Integrations** tab. Click **App Store Connect API**. Stay on **Team Keys**.

**Why:** This is the only page that can make the key `make setup` asks for.

**3. The first time, request access**

If you see **Request Access**, click it and accept the terms. You only do this once.

**Why:** Apple hides the key list until you accept those terms. SoleCount cannot get a key before that.

**4. Generate the key**

Click the **+** button (**Generate API Key**). Name it `SoleCount`. For Access, choose **App Manager** (or **Admin**). Click **Generate**.

**Why:** App Manager is enough for SoleCount to upload builds and set up the $0.99 upgrade. Admin also works.

**5. Copy the Key ID and the Issuer ID**

The Key ID is the 10-character code in the keys list, such as `ABC123DEFG`. The Issuer ID is the long code shown above the table. Write both down.

**Why:** `make setup` asks for both. The Key ID is also the middle of the file name.

**6. Download the key**

On that key's row, click **Download API Key**. Apple lets you download this file **only once**. If you close the download, you cannot get the same file again.

**Why:** The download is `AuthKey_` plus your Key ID plus `.p8`. That file is what lets SoleCount sign in. Setup will copy it out of Downloads. It must not stay inside the SoleCount project folder.

### B. Find the file on the Mac

Safari saves the download in your Downloads folder.

**1. Look in Finder**

Click the Finder icon in the Dock. It is the blue and white face. In the left sidebar, click **Downloads**. Or, with Finder in front, press Cmd + Option + L.

**Why:** You need to see the file so you can drag it into Terminal when setup asks for it.

**2. Or search with Spotlight**

Press Cmd + Space, type `AuthKey`, and press Return.

**Why:** Spotlight finds the file even if it did not land in Downloads.

**3. Or list it in Terminal**

```bash
ls ~/Downloads/AuthKey_*.p8
```

**Why:** This prints the exact file name in Downloads, which is the name setup expects.

**4. Or search the whole Mac**

```bash
mdfind -name AuthKey_
```

**Why:** This searches every folder, not only Downloads, and prints the full path.

**5. Give that path to setup**

When `make setup` says to drag the `.p8` file into Terminal, drag it from Finder into the Terminal window and press Return. Dragging pastes the full path.

Or type the path yourself. Replace the X's with your Key ID:

```bash
~/Downloads/AuthKey_XXXXXXXXXX.p8
```

**Why:** Setup copies the file to a safe folder. A wrong path means SoleCount cannot sign in later.

**6. Check that setup stored it outside the project**

```bash
ls ~/.appstoreconnect/private_keys/
```

**Why:** You should see `AuthKey_` and your Key ID and `.p8`. That folder is in your home folder, not inside SoleCount, so the key is never uploaded to the public GitHub. Folders whose names start with a dot are hidden in Finder. In Finder, press Cmd + Shift + . to show them. Press it again to hide them.

### C. If something goes wrong

**1. Safari opened it as text, or the name looks wrong**

The name must end in `.p8`, like `AuthKey_ABC123DEFG.p8`. If Safari saved it as `.p8.txt` or showed the text in a window, go back to Downloads and rename it so it ends in `.p8` only. Do not edit the text inside the file.

**Why:** Setup looks for a `.p8` file. A renamed file will not match, and SoleCount cannot use a damaged key.

**2. You downloaded it on the Windows PC**

AirDrop does not work from a Windows PC. Put the file on the Mac with iCloud Drive, a USB stick, or an email to yourself, then save the attachment on the Mac. The file is secret. After it is on the Mac, delete the email and delete the copy on the USB stick.

**Why:** `make setup` can only see files that are on this Mac. Leaving extra copies around makes it easier for someone else to get the key.

**3. You lost the file**

Apple will not let you download the same key again. In App Store Connect, on that key's row, revoke it. Then click **+** and generate a new one. Download the new file immediately and write down the new Key ID. The Issuer ID above the table does not change.

**Why:** SoleCount needs one working `.p8` file. A revoked key cannot sign in.

**4. Do not put the file in the SoleCount folder or on GitHub**

The SoleCount repository is public. Never copy the `.p8` file into the project folder, and never commit it. The file `.gitignore` already ignores names that start with `AuthKey_`, which blocks an accidental commit, but do not rely on that as the only protection. Leave the file in `~/.appstoreconnect/private_keys/`.

**Why:** Anyone who can read the public GitHub page could copy a key that was committed, and then act as you on App Store Connect.

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

While Apple is still processing your membership, use this. It skips every Apple question:

```bash
make setup-local
```

**Why:** Installs the tools, creates the project, downloads the simulator, and opens Xcode. SoleCount can run with no Team ID.

When Apple has emailed you, use this instead and answer the questions:

```bash
make setup
```

**Why:** Same tool install, and it saves your Team ID, Key ID, Issuer ID, and `.p8` key. Press Return to skip any question you still do not have.

### What make setup does, and why SoleCount needs it

`make setup` and `make setup-local` only run `scripts/setup_mac.sh`. These are the steps that script actually does, in order. It is safe to run again: if a tool or answer is already there, it keeps it. Steps marked "Skip for now: Yes" are the Apple membership questions. `make setup-local` skips all of them. The simulator still works.

1. **Checks Xcode 26**
   - What it does: Looks for Xcode, Apple's app-building program, and checks that it is version 26 or newer.
   - Why SoleCount needs it: Apple only accepts App Store uploads built with Xcode 26. Without it, SoleCount cannot be sent to Apple.
   - Skip for now: No.

2. **Installs Homebrew if it is missing**
   - What it does: Installs Homebrew, a helper that installs other developer tools. On a new Apple-chip Mac it also tells Terminal where Homebrew lives. It may ask for your Mac password.
   - Why SoleCount needs it: The next step uses Homebrew to install XcodeGen and fastlane.
   - Skip for now: No.

3. **Installs XcodeGen**
   - What it does: Installs XcodeGen, the tool that builds an Xcode project from a settings file.
   - Why SoleCount needs it: SoleCount's project file (`SoleCount.xcodeproj`) is not stored on GitHub. XcodeGen makes it on your Mac from `project.yml`.
   - Skip for now: No.

4. **Installs fastlane**
   - What it does: Installs fastlane with Homebrew. Fastlane is written in the Ruby language. This script does not install Ruby packages with bundler, and it does not run `bundle install`. (The project has a `Gemfile` that lists fastlane, but `make setup` uses the Homebrew copy.)
   - Why SoleCount needs it: Later, `make appstore-setup` and `make deploy` use fastlane for the $0.99 upgrade, screenshots, TestFlight, and App Review. You do not need fastlane to run the simulator today.
   - Skip for now: No. The script installs it now so it is ready after Apple's email.

5. **Creates a private settings file**
   - What it does: Copies `fastlane/.env.example` to `fastlane/.env` if that file is not there yet, and locks it so only your Mac user can read it.
   - Why SoleCount needs it: Your Team ID and API details will be saved in that file later. It is ignored by Git, so it is never uploaded to the public GitHub repo. A blank file is fine today.
   - Skip for now: No. Creating the blank file is not the same as filling in Apple's details.

6. **Asks for your Team ID**
   - What it does: Asks for the 10-character Team ID and saves it in `fastlane/.env`. Find it at [developer.apple.com/account](https://developer.apple.com/account) → Membership details, after Apple's email.
   - Why SoleCount needs it: It tells Xcode which paid Apple Developer account is allowed to upload SoleCount.
   - Skip for now: Yes. Press Return, or run `make setup-local`. The simulator does not need a Team ID.

7. **Asks for your API Key ID**
   - What it does: Asks for the 10-character Key ID and saves it. Find it at [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api), after the membership is active.
   - Why SoleCount needs it: Together with the next two items, it lets SoleCount's tools sign in to your Apple account without your Apple ID password.
   - Skip for now: Yes.

8. **Asks for your Issuer ID**
   - What it does: Asks for the long Issuer ID shown above the keys table on that same API page, and saves it.
   - Why SoleCount needs it: Apple uses it with the Key ID and the `.p8` file to confirm the login is yours.
   - Skip for now: Yes.

9. **Stores the .p8 key outside the project**
   - What it does: Takes the downloaded `AuthKey_` file (from Downloads, or you drag it into Terminal) and saves it at `~/.appstoreconnect/private_keys/`, which is in your home folder, not inside SoleCount.
   - Why SoleCount needs it: That file is the private half of the API login. Keeping it outside the project means it never goes to the public GitHub.
   - Skip for now: Yes. You cannot download this file until the membership is active. When you can, follow [How to get and find your AuthKey_XXXXXXXXXX.p8 file](#find-the-p8-file).

10. **Asks for your Apple ID email**
    - What it does: Asks for the email on your Apple ID. Press Return to skip.
    - Why SoleCount needs it: If you fill it in later, fastlane can create the App Store listing and the privacy answers for you. If you skip it, you do that once on the Apple website instead.
    - Skip for now: Yes.

11. **Writes the Team ID into the Xcode settings**
    - What it does: Puts the Team ID into `Config/Team.xcconfig` when you have one. If you skipped it, the line stays blank.
    - Why SoleCount needs it: When you later upload SoleCount, Xcode reads that file to know which developer team to use. A blank line is what the simulator build uses.
    - Skip for now: Yes.

12. **Asks for an App Review phone number and email**
    - What it does: If those two files still contain the placeholder `REPLACE_ME`, it asks for a phone number (with country code) and an email, then saves them.
    - Why SoleCount needs it: Apple requires a person they can contact while they review SoleCount.
    - Skip for now: Yes.

13. **Builds the Xcode project**
    - What it does: Runs XcodeGen to create `SoleCount.xcodeproj` from `project.yml`.
    - Why SoleCount needs it: Xcode opens a project file, and that file is created on your Mac rather than downloaded from GitHub.
    - Skip for now: No.

14. **Downloads the iPhone Simulator if it is missing**
    - What it does: Checks for an iPhone simulator. If none is installed, it downloads the iOS simulator. A simulator is a pretend iPhone that runs on your Mac.
    - Why SoleCount needs it: `make test` and pressing Cmd + R run SoleCount in that simulator, with no Team ID.
    - Skip for now: No.

15. **Opens SoleCount in Xcode**
    - What it does: Opens `SoleCount.xcodeproj`.
    - Why SoleCount needs it: You can then press Cmd + R to run the app in the simulator, or on your iPhone with a free Personal Team.
    - Skip for now: No.

---

If you run `make setup` before Apple's email, press Return to skip each of these:

- **Team ID** (10 characters): [developer.apple.com/account](https://developer.apple.com/account) → Membership details
- **API Key ID** (10 characters): [App Store Connect → API](https://appstoreconnect.apple.com/access/integrations/api)
- **Issuer ID** (a long code): Same page, above the keys table
- **.p8 file**: See [How to get and find your AuthKey_XXXXXXXXXX.p8 file](#find-the-p8-file). Drag the file into Terminal, or press Return to skip
- **Phone and email**: For App Review. Press Return to skip

`make setup-local` skips that whole list for you.

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
