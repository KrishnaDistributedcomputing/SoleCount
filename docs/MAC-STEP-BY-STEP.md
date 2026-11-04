# SoleCount on a Mac, step by step

One path, in order. You are new to the Mac. Apple is still processing the paid Developer membership (up to 48 hours). You can build and run SoleCount today. You upload it after Apple's welcome email.

Do every command on the Mac. Copy a grey box by hovering and clicking the copy icon (two squares), or select the text and press Cmd + C. Click inside Terminal, press Cmd + V, then press Return.

<a id="contents"></a>

## 0. Contents

- [ ] [1. Mac basics](#mac-basics)
- [ ] [2. Get the code](#get-the-code)
- [ ] [3. Set up with no Apple membership](#setup-local)
- [ ] [4. Run the tests](#make-test)
- [ ] [5. Run the app](#run-the-app)
- [ ] [6. The steps that stay manual](#manual-steps)
- [ ] [7. make doctor, then make release](#make-release)
- [ ] [8. Get later updates](#get-updates)
- [ ] [9. Troubleshooting](#troubleshooting)
- [ ] [10. Ask Claude Code](#claude-code)
- [ ] [11. Command cheat sheet](#cheat-sheet)

<a id="part-a"></a>

## Part A: Get ready (one time)

<a id="mac-basics"></a>

### 1. Mac basics

**1. Open this page in Safari.** Click the compass icon in the Dock (the row of icons at the bottom of the screen). Click the address bar, type `github.com/KrishnaDistributedcomputing/SoleCount`, and press Return.

**Why:** You copy commands from this page. A Mac cannot paste text that was copied on a Windows PC.

**2. Open Terminal.** Hold the Cmd key (⌘, next to the space bar) and press the space bar. Type `Terminal` and press Return. A window with a blinking cursor opens.

**Why:** Terminal is where you type instructions. SoleCount's setup tools run there.

**3. Copy a command.** Hover over a grey box and click the copy icon, or drag across the text and press Cmd + C.

**Why:** One wrong character can make a command fail.

**4. Paste and run it.** Click inside Terminal, press Cmd + V, then press Return.

**Why:** Pasting only puts the text in. Return tells the Mac to run it.

**5. Wait.** When the blinking cursor comes back on a new line, the command is finished. If the Mac asks for your password, type it and press Return. Nothing appears while you type. That is normal.

**Why:** Each command builds on the one before it. The password check is macOS asking permission to install tools. The characters stay hidden for security.

Press Cmd + Tab to switch between Safari and Terminal. In Finder, press Cmd + Shift + . to show folders whose names start with a dot. Press it again to hide them.

<a id="get-the-code"></a>

### 2. Get the code

If you do not have a SoleCount folder yet:

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```

**Why:** This downloads SoleCount onto the Desktop and moves into that folder. Later commands only work inside it.

The first time you use `git`, a window may say **Install command line developer tools**. Click **Install**, wait, then run the command again.

**Why:** Those tools include `git`. The Mac does not include them until you install them.

If the folder is already there, update it instead of cloning again:

```bash
cd ~/Desktop/SoleCount && git pull
```

**Why:** `git pull` downloads the newest saved copy of the branch you are on.

This guide may still be on the branch `cursor/setup-without-apple-043d` and not yet on `main`. If `git pull` on `main` does not show these steps, switch to that branch:

```bash
git checkout cursor/setup-without-apple-043d && git pull
```

**Why:** `git checkout` switches which copy of the project this folder is using. After the branch is merged into `main`, go back with `git checkout main && git pull`.

To throw away a broken copy and start over, only if you have not saved notes inside that folder:

```bash
cd ~/Desktop && rm -rf SoleCount
```

Then run the clone command again.

**Why:** `rm -rf` deletes that folder. The `.p8` key is stored outside it, in your home folder, so this does not delete the key.

<a id="part-b"></a>

## Part B: Do now, no Apple membership needed

You do not have a Team ID, Key ID, Issuer ID, or `.p8` file yet. You do not need them for this part.

<a id="setup-local"></a>

### 3. Set up the Mac

```bash
make setup-local
```

**Why:** This installs the tools, creates the Xcode project, downloads the iPhone Simulator if it is missing, and opens Xcode. It skips every Apple question.

`make setup-local` only runs `scripts/setup_mac.sh --no-apple`. These are the steps, in order:

1. **Checks Xcode 26.** Xcode is Apple's app-building program. Apple only accepts uploads built with Xcode 26, so SoleCount cannot be sent to the App Store with an older Xcode. Skip: no.
2. **Installs Homebrew if it is missing.** Homebrew installs other developer tools. On a new Apple-chip Mac it also tells Terminal where Homebrew lives. It may ask for your Mac password. Skip: no.
3. **Installs XcodeGen.** XcodeGen builds `SoleCount.xcodeproj` from `project.yml`. That project file is not stored on GitHub, so it has to be made on your Mac. Skip: no.
4. **Installs fastlane with Homebrew.** Fastlane is a Ruby tool. This script does not run `bundle install`. Later, `make appstore-setup` and `make deploy` use fastlane. Skip: no.
5. **Creates `fastlane/.env`.** This is a private settings file. Git ignores it, so it is never uploaded to the public GitHub. A blank file is fine today. Skip: no.
6. **Skips the Apple questions when nothing is saved yet.** Team ID, API Key ID, Issuer ID, the `.p8` file, Apple ID email, and the App Review phone and email. `make setup` does this by itself if those answers are missing. After Apple's email, `make release` finds a `.p8` file in Downloads and asks only for what is still blank. Skip: yes, until Apple's email.
7. **Leaves the Team ID blank** in `Config/Team.xcconfig`. The simulator does not need a Team ID. Skip: yes.
8. **Builds `SoleCount.xcodeproj`.** Xcode opens that file. Skip: no.
9. **Downloads the iPhone Simulator if none is installed, then opens Xcode.** A simulator is a pretend iPhone on your Mac. `make test` and Cmd + R use it. Skip: no.

When it finishes, it lists the skipped Apple items and tells you to run `make test`, then press Cmd + R.

<a id="make-test"></a>

### 4. Run the tests

```bash
make test
```

**Why:** This runs SoleCount's tests in the iPhone Simulator. No Team ID is required. It catches bugs before Apple's reviewers do.

The command prints `Running tests in the iPhone Simulator. No Apple Team ID is needed.` Then fastlane runs the unit tests and the UI tests. The screenshot test is skipped. The usual simulator name is `iPhone 17 Pro Max`. It can take about 10 minutes. A passing run ends with the tests passed.

<a id="run-the-app"></a>

### 5. Run the app

```bash
make open
```

**Why:** This rebuilds the Xcode project from `project.yml` and opens it.

In Xcode, press Cmd + R.

**Why:** Cmd + R builds SoleCount and shows it in the simulator. The $0.99 purchase can be tried there because the project includes `SoleCount.storekit`, a local pretend store. That is not the real App Store.

Optional: install it on your own iPhone with a free Apple ID.

1. In Xcode, open Settings, then Accounts, and add your Apple ID.
2. Click the SoleCount project, open Signing & Capabilities, and choose your Personal Team.

**Why:** A free Apple ID can put SoleCount on your own phone. That install expires after 7 days. It cannot use the In-App Purchase sandbox, and it cannot upload to TestFlight.

<a id="part-c"></a>

## Part C: After Apple's welcome email

Do the short list below once. Then two commands do the rest.

<a id="manual-steps"></a>
<a id="team-id"></a>
<a id="find-the-p8-file"></a>

### 6. The steps Apple still makes you do by hand

These stay manual because Apple does not let a script do them:

1. Wait for the "Welcome to the Apple Developer Program" email. You already paid.
2. In App Store Connect, open **Business** and accept the **Paid Apps** agreement. Add your bank and tax forms. The $0.99 purchase cannot be sold until this is done.
3. Create an **Admin** API key and download the `.p8` file **once**. Leave that file in **Downloads**. Do not move it into the SoleCount folder. The Key ID is the middle of the file name `AuthKey_<Key ID>.p8`. The Issuer ID is the long code above the keys table.
4. Have your 10-character Team ID ready. It is on [developer.apple.com/account](https://developer.apple.com/account), under **Membership details**. `make release` asks for the Team ID and the Issuer ID once.
5. Optional: your Apple ID email. If you type it when asked, fastlane creates the app record and sends the privacy answers after one 2FA code. If you press Return, you use the website instead. The form is in the section below.
6. The first time only, after the command finishes: on the website, add **SoleCount Pro** to version **1.0** and submit. Apple blocks a script from attaching the first purchase to a review.
7. Wait for review. It usually takes about 1 to 2 days. It can take longer.

**Why:** Everything else (bundle ID, price, age rating, the $0.99 purchase, screenshots, TestFlight, the store text) is already in this package. `make release` runs it and skips steps that are already done.

How to download the key, if you have not done it before:

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com), then **Users and Access**, **Integrations**, **App Store Connect API**, **Team Keys**.
2. If you see **Request Access**, click it and accept the terms.
3. Click **+**. Name it `SoleCount`. Access: **Admin**. Click **Generate**.
4. Copy the Key ID and the Issuer ID. Click **Download API Key**. Apple lets you download it only once.
5. It lands in Downloads. Check with:

```bash
ls ~/Downloads/AuthKey_*.p8
```

**Why:** `make release` finds that file, reads the Key ID from the name, and copies it to `~/.appstoreconnect/private_keys/`. That folder is outside the project, so the key is never uploaded to GitHub.

<a id="make-release"></a>
<a id="make-setup"></a>
<a id="make-deploy"></a>

### 7. Run the checks, then release

```bash
make doctor
```

**Why:** This prints a green and red checklist: Xcode 26, the tools, the key file, and a real call to App Store Connect. Each red line tells you the exact command to run next.

When every required line is green:

```bash
make release
```

**Why:** This is the whole path, and it is safe to run again. It finds the `.p8` file, asks only for answers that are still blank, then:

1. Registers the bundle ID `com.krishnav.SoleCount` and turns on In-App Purchase.
2. Creates the app record if you saved an Apple ID (one 2FA code). If not, it stops and tells you to use the form below.
3. Sets the app price to free, the countries, and the age rating (4+).
4. Creates the $0.99 purchase `com.krishnav.SoleCount.pro` from `fastlane/iap.json`, including the English name and the review screenshot.
5. Takes the 6.9-inch App Store screenshots in the iPhone 17 Pro Max simulator if they are not saved yet. The test uses sample shoes, not your real pairs. Apple scales that size to the other iPhone sizes.
6. Runs the tests.
7. Bumps the build number to one higher than the latest TestFlight build, builds the app, and uploads it.
8. Uploads the name, subtitle, description, keywords, promo text, support URL, privacy URL, category (Lifestyle), and screenshots from `fastlane/metadata`.
9. Submits version 1.0 for review when Apple allows it. The app goes live automatically after approval.

Running it again does not create a second app or a second purchase. It does upload a new build, because Apple rejects a second upload of the same build number.

Check progress any time:

```bash
make status
```

**Why:** This shows the latest TestFlight build and the review state, such as waiting for review.

<a id="new-app-form"></a>

### If make release says the app record does not exist

Apple's API key is not allowed to create the app record. Either add `APPLE_ID=you@example.com` to `fastlane/.env` and run `make release` again (one 2FA code), or fill in this form.

![New App form in App Store Connect. Platforms, Name, Primary Language, Bundle ID, SKU, and User Access are empty, and Create is grey.](images/appstoreconnect-new-app.png)

1. Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com). Click **Apps**, the blue **+**, then **New App**.
2. Platforms: **iOS** only.
3. Name: `SoleCount`. If Apple says that name is taken, use `SoleCount: Sneaker Tracker`.
4. Primary Language: **English (U.S.)**.
5. Bundle ID: `com.krishnav.SoleCount`. If it is missing, run `make release` once so it can register the ID, then refresh this page.
6. SKU: `solecount001`. If fastlane created the app, it used `solecount-ios`. Leave that one alone.
7. User Access: **Full Access**. Click **Create**.

Then run `make release` again.

**Why:** The listing, the purchase, and the installed app must share the bundle ID `com.krishnav.SoleCount`.

<a id="pro-purchase"></a>

### If the command says to add SoleCount Pro for review

`make release` creates the purchase. Apple still wants the **first** one attached on the website:

1. Open SoleCount in App Store Connect.
2. Open **Monetization**, then **In-App Purchases**, then **SoleCount Pro**.
3. Click **Add for Review** and choose iOS version **1.0**.
4. Submit for review.

Also open **App Privacy** and publish **Data Not Collected**, unless the command already did that because you saved your Apple ID. SoleCount keeps every sneaker on the phone. The privacy page is [PRIVACY.md](../PRIVACY.md). The same text is in [docs/privacy.md](privacy.md) for GitHub Pages. The address uploaded to Apple is the GitHub file, which works without Pages.

**Why:** Review looks at the app and the purchase together. After Pro is approved once, later runs of `make release` submit by themselves.

### GitHub button (optional)

After the first `make release` on this Mac has created the app, you can repeat a release from GitHub: **Actions**, **Release**, **Run workflow**. Add these repository secrets (nothing else, and never the key file in the repo):

| Secret | What to paste |
|---|---|
| `ASC_KEY_ID` | The 10-character Key ID |
| `ASC_ISSUER_ID` | The long Issuer ID |
| `ASC_KEY_P8` | The output of `base64 -i ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8` |
| `TEAM_ID` | The 10-character Team ID |
| `REVIEW_PHONE` | Phone for App Review, with country code |
| `REVIEW_EMAIL` | Email for App Review |

**Why:** GitHub cannot type your 2FA code, so it cannot create the app the first time. It can repeat the upload after the Mac has done that once. The full note is in [AUTOMATION.md](../AUTOMATION.md).

<a id="part-d"></a>

## Part D: Keeping up to date and help

<a id="get-updates"></a>

### 8. Get the latest updates

New work is saved on a branch first. `main` is the copy that `git clone` downloads.

**1. Merge on the GitHub website.** Open:

[https://github.com/KrishnaDistributedcomputing/SoleCount/compare/main...cursor/setup-without-apple-043d](https://github.com/KrishnaDistributedcomputing/SoleCount/compare/main...cursor/setup-without-apple-043d)

For a later branch, replace `cursor/setup-without-apple-043d` at the end of that address. Or open the repo page and click the yellow **Compare & pull request** banner when it appears.

Click the green **Create pull request** button, then **Create pull request** again. Wait for the checks. Click **Merge pull request**, then **Confirm merge**.

**Why:** Merging copies the branch into `main`, which is the version everyone gets by default.

**2. Download it on the Mac.** If this folder is still on the branch:

```bash
cd ~/Desktop/SoleCount && git pull
```

After the merge, switch back to `main` and download it:

```bash
git checkout main && git pull
```

**Why:** `git checkout main` switches this folder to the default copy. `git pull` downloads the newest saved version of that copy.

<a id="troubleshooting"></a>

### 9. Troubleshooting

**Mac and Terminal**

- **Password field looks blank.** Type the password and press Return. macOS hides it on purpose.
- **Popup: Install command line developer tools.** Click Install, wait, then run the `git` command again.

**Getting the code**

- **`not a git repository`.** You are not inside the SoleCount folder. Run `cd ~/Desktop/SoleCount`, then try again.
- **`git pull` says your local changes would be overwritten.** Run `git stash`, then `git pull`. `git stash` sets your Mac-only edits aside so the download can finish. Those edits stay in a side pile. You do not need them for normal setup.
- **There isn't anything to compare.** That branch is already in `main`. Skip the merge and run `git checkout main && git pull`.

**Setup**

- **Xcode is not ready.** Install Xcode 26 or newer from the App Store, open it once, then run `make setup-local` again.
- **You skipped a question by mistake.** Run `make setup` again. Saved answers are kept. Blank ones are asked again.

**The .p8 file**

- **The name does not end in `.p8`.** Rename it. Do not edit the inside.
- **You cannot find it.** Run `ls ~/Downloads/AuthKey_*.p8` and `mdfind -name AuthKey_`.
- **You lost the only download.** Revoke that key and generate a new one. Update the Key ID in `make setup`.
- **Never commit it.** Keep it in `~/.appstoreconnect/private_keys/`. The repo is public.

**New App form**

- **The app name you entered is already being used.** Type `SoleCount: Sneaker Tracker`.
- **Bundle ID is not in the list.** Run `make appstore-setup`, then refresh. Or register `com.krishnav.SoleCount` under Certificates, Identifiers & Profiles.
- **Create stays grey.** A required field is empty. Check iOS, the name, English (U.S.), the bundle ID, the SKU, and Full Access.

**Upload**

- **`make doctor` has a red line.** Do the Fix command on that line, then run `make doctor` again.
- **`make release` cannot find the .p8 file.** Leave `AuthKey_*.p8` in Downloads. The name must end in `.p8`, not `.p8.txt`. Then run `make release` again.
- **The app record does not exist yet.** Add your Apple ID when asked, or fill in the New App form above, then run `make release` again.
- **No valid code signing identity.** In Xcode, open Signing & Capabilities and turn on Automatically manage signing. For the simulator you can ignore this. For an upload you need the paid Team ID.

<a id="claude-code"></a>

### 10. Ask Claude Code for help

Copy the error in Terminal: drag across the red lines, then press Cmd + C.

If Claude Code is installed, go to the SoleCount folder and type `claude`. If not, paste the prompt at [claude.ai](https://claude.ai) or into Cursor.

```text
I'm setting up the SoleCount iOS app on my Mac and I'm a beginner to macOS and Terminal. I ran this command:

[PASTE THE COMMAND YOU RAN HERE]

And I got this error:

[PASTE THE ERROR TEXT FROM TERMINAL HERE]

Can you explain what went wrong in simple terms and tell me exactly what command to run to fix it?
```

**Why:** The prompt gives Claude the command and the real error, so the answer matches SoleCount's scripts.

<a id="cheat-sheet"></a>

### 11. Command cheat sheet

| Command | What it does | When to use it |
|---|---|---|
| `make setup-local` | Installs tools, builds the project, opens Xcode. Skips Apple questions. | Now, before the membership is active. |
| `make setup` | Same as setup-local if the Team ID, key, and Issuer ID are missing. If a `.p8` file is already on the Mac, it saves that key and asks for the rest. | First setup, or any time. |
| `make test` | Runs tests in the iPhone Simulator. No Team ID. | After setup, any time. |
| `make open` | Rebuilds the project and opens Xcode. Then press Cmd + R. | When you want to see the app. |
| `make doctor` | Green/red checklist, including a real API call. Each red line has the fix. | After Apple's email, before you release. |
| `make release` | Finds the `.p8` file, then creates the records, tests, uploads a new build, and submits. Skips finished records. | The command to ship. Safe to run again. |
| `make deploy` | Same as `make release`. | Same as `make release`. |
| `make status` | Shows the TestFlight build and the review state. | While you wait for Apple. |
| `make appstore-setup` | Only the App Store records (bundle ID, app, $0.99 purchase). No upload. | When you want the records without a new build. |
| `bash scripts/deploy.sh --beta-only` | Uploads to TestFlight and stops before review. | When you do not want review yet. |
| `make clean` | Deletes build files and the generated Xcode project. | When you want a fresh project. Run `make open` after. |
| `git pull` | Downloads the newest copy of the branch you are on. | When GitHub has newer commits. |
| `git checkout main && git pull` | Switches to `main` and downloads it. | After a branch is merged. |

More detail lives in other files. Read them when you need that topic. Do not follow them instead of this page for the first setup.

- [AUTOMATION.md](../AUTOMATION.md) explains fastlane and GitHub Actions.
- [LAUNCH-GUIDE.md](../LAUNCH-GUIDE.md) is the longer launch plan, including Apple's review wait.
- [GUIDE.md](../GUIDE.md) is an older build walkthrough.
- [PRIVACY.md](../PRIVACY.md) is the privacy policy. SoleCount collects no data.
