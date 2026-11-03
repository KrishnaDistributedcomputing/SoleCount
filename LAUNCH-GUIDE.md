# SoleCount: Your 3-Day App Store Launch Guide

*Written for a first-timer on a Mac. Every step is numbered. Do them in order.*

**Your app:** SoleCount (sneaker wear tracker) · **Bundle ID:** `com.krishnav.SoleCount` · **Pro unlock:** `com.krishnav.SoleCount.pro` ($0.99, one-time) · **Code:** <https://github.com/KrishnaDistributedcomputing/SoleCount>

> **Read this first (honest odds).** Two steps are controlled by Apple, not you: **(1)** approving your Apple Developer Program membership and **(2)** reviewing your app. Apple says individual enrollments are usually approved in about 24–48 hours, and 90% of app reviews finish in under 48 hours. But in October 2026 many developers reported multi-week waits in "Waiting for Review" (The Register, 22 Oct 2026). **Realistic odds of being live on the App Store within 3 days: about 1 in 4 to 1 in 3.** Within 7 days: likely. Within 14 days: very likely. You can't control Apple's queue. What you *can* control is being 100% ready, so you never lose time to a rejection. This guide is built around that.

---

## The 3-day plan on one page

| When | What you do | Time it takes you | Waiting on Apple? |
|---|---|---|---|
| **Day 1, first 30 min** | **Enroll in the Apple Developer Program** ($99/yr) as an **Individual**. Do it first, before anything else. | 20–30 min | **Yes**: usually 24–48 h |
| Day 1 | Download the code from GitHub, create the Xcode project, add the files, add the StoreKit test file | 1–2 h | No |
| Day 1 | Fix build errors (table in Step 1.9) and set the 5 key project settings | 30–60 min | No |
| Day 1 | Test in the simulator and on your iPhone with the checklist (Step 1.13) | 1 h | No |
| Day 1 (evening) | Add the app icon. Take screenshots. Paste the store text into a notes file | 1 h | No |
| **Day 2 (once enrolled)** | Sign the **Paid Apps Agreement**, fill in tax + bank, apply for the **Small Business Program** | 30–45 min | Agreement may show "Processing" for a while |
| Day 2 | Create the app record + the $0.99 In-App Purchase in App Store Connect | 1 h | No |
| Day 2 | Fill in metadata, privacy ("Data Not Collected"), age rating | 1 h | No |
| Day 2 | **Archive & upload** from Xcode → TestFlight on your iPhone → test the purchase | 1–2 h | Build processing 5–30 min |
| **Day 2 night or Day 3** | **Submit for Review** (app + In-App Purchase together) | 30 min | **Yes**: usually 1–2 days, sometimes more |
| Day 3+ | Answer App Review fast if they write. Fix and resubmit if rejected. App goes live automatically | — | Yes |

**The two rules that save the most time:**
1. **Enroll in the first hour.** Nothing on Day 2 works without an approved membership.
2. **Submit something perfect the first time.** One rejection costs about 1–2 days. Use the checklists.

---

## Words you'll see (mini dictionary)

- **Xcode**: Apple's free app for building iPhone apps. You already have it.
- **Simulator**: a pretend iPhone that runs on your Mac screen.
- **Bundle ID**: your app's unique internal name (`com.krishnav.SoleCount`). It never changes after you publish.
- **Target**: the "thing being built" in Xcode (your app). Settings live under **TARGETS → SoleCount**.
- **Build**: turning your code into an app (**Cmd+B**). **Run**: build and launch it (**Cmd+R**).
- **Archive**: the final, store-ready build you upload to Apple.
- **App Store Connect (ASC)**: the website (<https://appstoreconnect.apple.com>) where you set up your store page, prices, and submissions.
- **TestFlight**: Apple's app for installing test versions on your iPhone before release.
- **In-App Purchase (IAP)**: something people buy inside the app. Yours is **SoleCount Pro**.
- **Non-consumable**: an IAP you buy once and keep forever (not used up, not a subscription).
- **StoreKit**: Apple's code library for purchases. **StoreKit configuration file**: a fake store for testing purchases in Xcode for free.
- **Sandbox**: Apple's test store. Purchases there are free.
- **Restore Purchases**: a button that gives Pro back to someone on a new phone. **Apple requires it.**
- **Metadata**: the store-page text, screenshots, and icon.
- **App Review**: the Apple team that tests your app before it can go live.
- **Guideline 2.1 / 3.1.1 / 4.2**: numbered rules in Apple's *App Review Guidelines*. Rejections quote these numbers.

---

# DAY 1: Enroll, build, test

## Step 1.1: Enroll in the Apple Developer Program (do this NOW)

**Why first:** you can't create the app in App Store Connect, upload a build, or use TestFlight until Apple approves you. This is usually the slowest step.

**Individual or Organization?** Choose **Individual**.
- **Individual**: your legal name ("Krishna Venkataraman") shows as the seller. No company paperwork. Usually approved in about 24–48 hours.
- **Organization**: needs a registered company, a **D-U-N-S number** (a free business ID from Dun & Bradstreet, which takes up to 5 business days plus 2 more for Apple to receive it), a company website, and a work email. It often takes 1–2 weeks. **Not an option for a 3-day launch.** You can switch to an organization later.

**Fastest way: use your iPhone.**
1. On your iPhone, open the **App Store**, search **Apple Developer**, and install Apple's **Apple Developer** app.
2. Open it. Tap **Account** and sign in with the Apple ID you'll use for the business.
3. Tap **Enroll Now** and follow the steps. Use your **exact legal name** as it appears on your ID. Apple says aliases or nicknames delay approval. Two-factor authentication must be on. Don't use a P.O. box address.
4. If asked, scan your photo ID. Pay the fee (**US $99/year**, shown in local currency, about CA$129). This one membership covers **unlimited apps**. You renew yearly, not per app.

**Or use the Mac:** go to <https://developer.apple.com/programs/enroll/> → **Start Your Enrollment** → choose **Individual / Sole Proprietor** → finish and pay.

5. Watch your email (krishnaazure1975@gmail.com or your Apple ID email). You'll get a purchase email, then a **"Welcome to the Apple Developer Program"** email when you're approved.
6. **If there's no confirmation after 24 hours**, use <https://developer.apple.com/contact/> → **Membership and Account** → **Program Enrollment** and give your **Enrollment ID**. Calling is often faster than email.

While you wait, keep going. Everything else on Day 1 works with your free Apple ID.

---

## Step 1.2: Check your Mac setup

1. **Xcode version:** open Xcode → menu **Xcode → About Xcode**. Since **April 28, 2026**, Apple only accepts uploads built with **Xcode 26 or later (iOS 26 SDK or later)**. If you have Xcode 26.x or 27.x, you're fine. If it's older, update it from the Mac App Store.
2. **iOS simulator:** **Xcode → Settings → Components** (sometimes called **Platforms**). Make sure **iOS** shows as installed, not downloading. Wait for it to finish if needed.
3. **Sign in to Xcode:** **Xcode → Settings → Accounts** → **+** → **Apple Account** → sign in. You need this for running on your iPhone. After enrollment is approved, the same account shows a paid team.

---

## Step 1.3: Download the code from GitHub

First check that the code is on GitHub. Open <https://github.com/KrishnaDistributedcomputing/SoleCount> in Safari. You should see a **SoleCount** folder plus `PRIVACY.md`, `README.md`, and other files. If the repo is empty, push it from your Windows PC first.

1. Open **Terminal**: press **Cmd+Space**, type `Terminal`, press **Return**.
2. Copy and paste these lines one at a time, pressing **Return** after each:

```
cd ~/Documents
git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git SoleCount-Code
open SoleCount-Code
```

3. If the Mac asks to install **Command Line Developer Tools**, click **Install**, wait, then run the `git clone` line again.
4. A Finder window opens. Inside is a **SoleCount** folder with 10 `.swift` files plus `PrivacyInfo.xcprivacy`.

> We name the download **SoleCount-Code** so it doesn't clash with the Xcode project you'll make next.

---

## Step 1.4: Create the Xcode project

1. Open **Xcode** → **File → New → Project…**
2. At the top, pick **iOS**, then **App**, then **Next**.
3. Fill in **exactly**:

| Field | Type / choose |
|---|---|
| Product Name | `SoleCount` |
| Team | Your name (Personal Team for now; change it to the paid team after enrollment) |
| Organization Identifier | `com.krishnav` |
| Bundle Identifier (shown, grey) | `com.krishnav.SoleCount` |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Testing System | **None** |
| Storage | **SwiftData** |
| Host in CloudKit | **unchecked** |

4. Click **Next**. Choose **Documents**. Leave **Create Git repository** unchecked, because you already have one on GitHub. Click **Create**.

You now have `~/Documents/SoleCount/SoleCount.xcodeproj`.

---

## Step 1.5: Swap in the real code

1. In Xcode's left sidebar (the **Project navigator**; press **Cmd+1** if hidden), open the yellow **SoleCount** folder.
2. Right-click **ContentView.swift** → **Delete** → **Move to Trash**. Do the same for **Item.swift** and **SoleCountApp.swift**.
3. Go back to the Finder window from Step 1.3 and open the inner **SoleCount** folder.
4. Press **Cmd+A** to select everything: the 10 `.swift` files and `PrivacyInfo.xcprivacy`.
5. **Drag** them onto the yellow **SoleCount** folder in Xcode.
6. In the pop-up:
   - **Copy items if needed** (or **Action: Copy files to destination**): ✅
   - **Add to targets: SoleCount**: ✅
   - Click **Finish**.

Your sidebar should now list: `SoleCountApp.swift`, `Sneaker.swift`, `Helpers.swift`, `SneakerListView.swift`, `AddSneakerView.swift`, `SneakerDetailView.swift`, `WearChartView.swift`, `StoreManager.swift`, `PaywallView.swift`, `SettingsView.swift`, `PrivacyInfo.xcprivacy`, and `Assets.xcassets`.

---

## Step 1.6: Set the 5 key project settings (saves rejections and headaches)

Click the **blue SoleCount project icon** at the very top of the sidebar. In the middle pane, under **TARGETS**, click **SoleCount**.

**A. iPhone only (avoids needing iPad screenshots and iPad review testing)**
1. Open the **General** tab → **Supported Destinations**.
2. If **iPad** is listed, select it and click **–** to remove it. Also remove **Mac (Designed for iPad)** and **Apple Vision (Designed for iPad)** if they're listed. Keep only **iPhone**.

**B. Minimum iOS version**
1. Still in **General**, under **Minimum Deployments**, set **iOS** to **18.0**.
   (New Xcode projects default to the newest iOS. Setting 18.0 lets far more people install your app. All the code works on iOS 18.)

**C. Version and build numbers**
1. Under **Identity**: **Version** = `1.0`, **Build** = `1`.
   (Each upload needs a higher **Build** number: 1, 2, 3…)

**D. In-App Purchase capability**
1. Open the **Signing & Capabilities** tab → click **+ Capability** (top left) → double-click **In-App Purchase**.

**E. Encryption answer (export compliance)**
Apple asks every app whether it uses encryption. SoleCount only uses Apple's built-in HTTPS, which is "exempt". Put the answer in the app so you never get asked again:
1. Open the **Info** tab → under **Custom iOS Target Properties**, hover any row and click the small **+**.
2. Type `App Uses Non-Exempt Encryption` (or the raw key `ITSAppUsesNonExemptEncryption`) and press **Return**.
3. Set **Type** to **Boolean** and **Value** to **NO**.

This is the same as putting this in an Info.plist:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

---

## Step 1.7: Add the StoreKit test file (free fake purchases)

1. In the sidebar, click the yellow **SoleCount** folder.
2. **File → New → File from Template…** → type `storekit` in the filter box → **StoreKit Configuration File** → **Next**.
3. Name: `SoleCount`. Leave **Sync this file with an app in App Store Connect** **unchecked**. Click **Create**.
4. In the file that opens, click **+** (bottom left) → **Add Non-Consumable In-App Purchase**.
5. Fill in:
   - **Reference Name:** `SoleCount Pro`
   - **Product ID:** `com.krishnav.SoleCount.pro` (this must match the code exactly)
   - **Price:** `0.99`
   - **Localization** (double-click the English row): **Display Name** `SoleCount Pro`, **Description** `Unlimited pairs and wear history chart`
6. Press **Cmd+S**.
7. Turn it on: **Product → Scheme → Edit Scheme…** → **Run** (left side) → **Options** tab → **StoreKit Configuration** → choose **SoleCount.storekit** → **Close**.

> The StoreKit file is only for testing in Xcode. It isn't used by TestFlight or the real App Store; those use what you create in App Store Connect on Day 2.

---

## Step 1.8: Build

1. At the top centre of Xcode, click the device menu and choose **iPhone 17 Pro Max** (any iPhone simulator works).
2. Press **Cmd+Shift+K** (Clean Build Folder), then **Cmd+B** (Build).
3. Wait for **Build Succeeded**. Red ⛔ = errors (must fix). Yellow ⚠️ = warnings (usually fine to ignore).

## Step 1.9: Fix build errors: troubleshooting table

Click the ⛔ icon in the left sidebar (**Cmd+5**, the Issue navigator) to see all errors.

| What you see | What to do |
|---|---|
| `Cannot find 'ContentView' in scope` / `'Item'` | An old template file is still there. Delete it (Step 1.5). Only the downloaded `SoleCountApp.swift` should exist. |
| `Invalid redeclaration of 'SoleCountApp'` (or another name) | A file got added twice. Delete the duplicate (Move to Trash). |
| `Cannot find 'StoreManager'` (or `SneakerListView`) `in scope` | That file isn't in the app. Click it → right panel (**Cmd+Option+0**) → **Target Membership** → tick **SoleCount**. If it's missing entirely, drag it in again. |
| Many errors/warnings mentioning **MainActor**, **Sendable**, "concurrency", "actor-isolated" | **Build Settings** tab → search `Swift Language Version` → set **Swift 5**. Then search `Default Actor Isolation` → set **MainActor**. Clean (**Cmd+Shift+K**) and build again. |
| ⚠️ `'purchase(options:)' was deprecated…` | A warning only. Ignore it; the purchase still works and Apple accepts it. |
| `Multiple commands produce … PrivacyInfo.xcprivacy` | There are two PrivacyInfo files. Delete one. |
| `Signing for "SoleCount" requires a development team` | **Signing & Capabilities** → tick **Automatically manage signing** → pick your **Team**. |
| `Failed to register bundle identifier` / "not available" | While on the free Personal Team, change the Bundle Identifier to `com.krishnav.SoleCount2` for testing. After you're enrolled, try `com.krishnav.SoleCount` again; if it's still refused, keep **SoleCount2** everywhere (Xcode + App Store Connect). The product ID `com.krishnav.SoleCount.pro` can stay the same. |
| `The 'In-App Purchase' capability…` error on the Personal Team | Expected on a free account. Remove the capability for now and add it back after enrollment (Step 2.6). |
| App crashes on launch after you edited `Sneaker.swift` | Old test data doesn't match. Delete the app from the simulator (long-press icon → Remove App) and run again. |
| Anything else | Copy the **first** red error's text and paste it to me (Ideabot). Fix errors top to bottom; one root error often causes many others. |

---

## Step 1.10: Run in the simulator

1. Press **Cmd+R** (▶). The simulator opens with SoleCount.
2. You should see **"No sneakers yet"** and an **Add a pair** button.

## Step 1.11: Run on your iPhone

1. Plug the iPhone into the Mac with a cable. Unlock it and tap **Trust**, then enter your passcode.
2. In Xcode's device menu, pick **your iPhone**.
3. On the iPhone: **Settings → Privacy & Security → Developer Mode** (at the bottom) → **On** → **Restart** → after the restart tap **Turn On**. (This option only appears after the phone has been connected to Xcode once.)
4. Press **Cmd+R**.
5. If the iPhone says **Untrusted Developer**: **Settings → General → VPN & Device Management** → your Apple ID → **Trust**. Run again.

> On the free Personal Team, the app stops opening after 7 days; just run it again. This limit goes away once you're enrolled.

## Step 1.12: Get test photos into the simulator

Drag any photo from Finder (for example, a sneaker photo you saved) onto the simulator window. It's saved to the simulator's Photos app, and **Add photo** in SoleCount can then pick it.

## Step 1.13: The test checklist (do every line, on the simulator AND your iPhone)

Tick each box. **If any line fails, fix it before Day 2.** A failed line is exactly how apps get rejected under Guideline 2.1.

**Basics**
- [ ] App opens with no crash. The empty screen shows "No sneakers yet".
- [ ] Tap **+** → fill in a name, brand, price `120`, and a date → **Save**. The pair appears in the list.
- [ ] **Add photo** opens Photos. Pick a photo; it shows on the form and in the list.
- [ ] Tap the pair → **Wore today**. Wears = 1, and cost per wear = $120.00.
- [ ] Tap **Wore them again** → Wears = 2, cost per wear = $60.00.
- [ ] **Undo today's wear** removes one wear.
- [ ] Add a pair with **Set a wear limit** ON. When it reaches the limit, the "Time to retire this pair?" alert appears.
- [ ] **Retire** moves the pair to **Retired**. **Unretire** moves it back.
- [ ] **Delete:** swipe left on a pair in the list → **Delete**. It disappears.

**Free limit (3 pairs)**
- [ ] With 3 pairs saved, tap **+** again. The **SoleCount Pro** screen appears instead of the form.
- [ ] On a pair's screen, the chart says **"Unlock the wear history chart with Pro"** (locked).

**Purchase (uses the StoreKit test file)**
- [ ] The Pro button says **Unlock Pro for $0.99** (not "Loading price…").
- [ ] Tap it → confirm the test purchase. The screen closes.
- [ ] You can now add a 4th pair. The chart shows bars.
- [ ] **Settings** (gear icon) shows **Pro unlocked**.
- [ ] **Cancel test:** start a purchase and tap Cancel. There's no error and Pro stays locked.

**Restore**
- [ ] In Xcode: **Debug → StoreKit → Manage Transactions…** → select the purchase → **Delete** (this pretends it's a new phone). Stop and run again. Pro is locked.
- [ ] While Pro is locked (no purchase), tap **Settings → Restore Purchases**. Expect the message "No previous SoleCount Pro purchase was found…" (correct, nothing to restore).
- [ ] Buy Pro again → tap **Settings → Restore Purchases** → it stays **Pro unlocked** with no error.
- [ ] **Restore Purchases** is visible on **both** the Pro screen and Settings.

**Relaunch (data is saved)**
- [ ] Stop the app in Xcode (■), then open it again from the home screen. All pairs, photos, wears, and the Pro status are still there.
- [ ] On the iPhone: swipe the app away in the app switcher, reopen it, and check the data is still there.

**Links**
- [ ] **Settings → Privacy Policy** opens the GitHub PRIVACY.md page (the repo must stay **public**).
- [ ] **Terms of Use** opens Apple's standard license page. **Support** opens the GitHub Issues page.

**Looks**
- [ ] Turn on Dark Mode (simulator: **Features → Toggle Appearance**, or Cmd+Shift+A). Everything is readable.
- [ ] Rotate isn't needed. Check that big text works: **Settings → Accessibility → Display & Text Size → Larger Text** on the phone, and nothing important is cut off.

> **Important:** in the GitHub repo, open **Settings → General → Features** and make sure **Issues** is ticked, so your Support link works for the reviewer.

## Step 1.14: Save your work to GitHub (optional but smart)

Your Xcode project lives in `~/Documents/SoleCount`. The simplest backup: keep editing code in Xcode, and if you change a file, copy it back into `SoleCount-Code/SoleCount/` and push from Terminal:
```
cd ~/Documents/SoleCount-Code
git add .
git commit -m "Launch fixes"
git push
```

---

## Step 1.15 (Day 1 evening): App icon

Apple needs a **1024 × 1024 pixel PNG with no transparency** (no see-through areas) and square corners; iOS rounds them for you.

1. **Ready-made icon:** this package includes `AppIcon/AppIcon-1024.png` (orange sneaker with tally marks; opaque; exactly 1024×1024). Use it now. You can replace it later with a nicer one.
2. In Xcode's sidebar, click **Assets** (`Assets.xcassets`) → click **AppIcon**.
3. In the right panel (**Cmd+Option+0**), set **iOS** to **Single Size** if it isn't already.
4. Drag `AppIcon-1024.png` from Finder into the **Any Appearance** 1024 slot. (Leave Dark/Tinted empty; that's allowed.)
5. Run the app again. The home screen icon shows your sneaker.

> Making your own: any 1024×1024 PNG works. If you use a design app, export **without transparency**. Xcode 26 also has **Icon Composer** for "Liquid Glass" layered icons, but it's optional; the asset-catalog method above is fine.

## Step 1.16 (Day 1 evening): Screenshots

**Required:** at least 1 (best is 3–5) iPhone screenshot at a **6.9-inch size: 1320 × 2868 pixels** (portrait). Apple automatically scales them down for smaller iPhones. iPad screenshots aren't needed because you made the app iPhone-only in Step 1.6A.

1. In Xcode, choose the **iPhone 17 Pro Max** simulator (its screen is exactly 1320 × 2868) → **Cmd+R**.
2. **Clean status bar (optional, looks pro):** in Terminal, paste:
   ```
   xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   ```
3. Fill the app with nice sample data: 3 pairs with photos, real-looking prices, and several wears each. Buy Pro (StoreKit test) so the chart shows. (To spread wears over months, just tap "Wore them again" a number of times; the chart uses the dates you tapped.)
4. Take these screens with **Cmd+S** in the simulator (files save to your **Desktop**):
   1. The list with 3 pairs (wears + cost per wear)
   2. A pair's detail screen with the big **Wore today** button and stats
   3. The detail screen scrolled to the **wear history chart** (Pro)
   4. The **New Sneaker** form with a photo
   5. The **SoleCount Pro** screen (this also becomes your **IAP review screenshot**)
5. Check the size: click a screenshot on the Desktop → **Cmd+I** → **More Info** should say **1320 × 2868**.

**Screenshot rules (Guideline 2.3, metadata):** show the real app only. No fake features, no other companies' logos (crop out or avoid Nike/Jordan logos in photos you add), and no prices in the image text.

---

# DAY 2: App Store Connect, upload, TestFlight

> Day 2 needs your **approved** membership. Check your email for "Welcome to the Apple Developer Program". Not approved yet? Do Steps 2.1–2.3 as soon as it arrives. Meanwhile, re-run the Day 1 checklist and polish your screenshots.

## Step 2.1: Switch Xcode to your paid team

1. **Xcode → Settings → Accounts** → select your Apple ID. You should now see **Krishna Venkataraman** (without "Personal Team").
2. **TARGETS → SoleCount → Signing & Capabilities** → **Team:** choose **Krishna Venkataraman** (not Personal Team).
3. Set **Bundle Identifier** to `com.krishnav.SoleCount` (if it was SoleCount2). If Xcode says it's unavailable, use `com.krishnav.SoleCount2` and use that same value everywhere below.
4. Make sure **In-App Purchase** is listed under capabilities (add it now if you removed it).

## Step 2.2: Sign the Paid Apps Agreement + tax + bank (required to sell the $0.99 unlock)

Without an **active** Paid Apps Agreement, your In-App Purchase won't load in TestFlight or for the reviewer. The button stays on "Loading price…", which means **instant rejection**.

1. Go to <https://appstoreconnect.apple.com> → sign in.
2. Click **Business** (on some accounts it's **Agreements, Tax, and Banking**).
3. Under **Agreements**, find **Paid Apps** → **View and Agree to Terms** → read and tick → **Agree**. (The Free Apps agreement is already active.)
4. **Tax forms:** click **Add Tax Forms** (or **Set Up Tax Forms**). As an individual in Canada, you'll be guided to the **U.S. W-8BEN** form (for non-US individuals). Answer honestly: country of residence **Canada**, and include your SIN if it's asked for as the foreign tax ID. Canada has a tax treaty with the U.S. that usually lowers U.S. withholding. Apple may also ask for Canadian sales-tax (GST/HST) info; small sellers under CA$30,000 a year usually aren't required to register, and you can mark that you aren't registered. *(This is general info, not tax advice.)*
5. **Bank account:** click **Add Bank Account** → enter your Canadian bank details (transit, institution, and account numbers from a void cheque or your bank app). Choose the account currency (CAD is fine).
6. The status shows **Processing**, then **Active**. It's often same-day, but it can take up to about 24 hours or more. **Don't submit for review until it says Active.** You can still do every other step while it processes.

## Step 2.3: Apply for the Small Business Program (15% instead of 30%)

1. Go to <https://developer.apple.com/app-store/small-business-program/> → **Enroll**.
2. Sign in, confirm you have no other associated developer accounts, and submit.
3. It applies once Apple approves it (sometimes days or weeks). The 15% rate starts **15 days after the end of the Apple fiscal month in which you're approved**. It doesn't block your launch. You qualify because you earned under $1M last year.

> **What you keep at $0.99:** after Apple's 15% you get about **$0.84 per sale** (before income tax; prices and Apple's cut vary a little by country). To net about **$500 a year** you need roughly **600 Pro sales** (600 × $0.84 ≈ $504). Before the Small Business Program kicks in, Apple takes 30%, so it's about $0.69 per sale.

## Step 2.4: Create the app record

1. App Store Connect → **Apps** → **+** (top left) → **New App**.
2. Fill in:
   - **Platforms:** ✅ iOS
   - **Name:** `SoleCount: Sneaker Tracker` (if it's taken, try `SoleCount – Wear Tracker` or `SoleCount Sneaker Log`)
   - **Primary Language:** English (U.S.) (or English (Canada))
   - **Bundle ID:** choose `com.krishnav.SoleCount` from the list. *(Not in the list? Upload a build first (Step 2.10), which registers it automatically, or register it at developer.apple.com → Certificates, IDs & Profiles → Identifiers → + → App IDs → App → Explicit `com.krishnav.SoleCount`.)*
   - **SKU:** `solecount001` (any private code)
   - **User Access:** Full Access
3. Click **Create**.

## Step 2.5: App Information page

Left sidebar → **General → App Information**:
- **Subtitle:** `Cost per wear for every pair`
- **Category:** Primary **Lifestyle**, Secondary **Utilities**
- **Content Rights:** "No, it does not contain, show, or access third-party content." Your users add their own photos; that doesn't count.
- **Age Rating:** click **Set Up Age Ratings** (or Edit) → see Step 2.8.
- **Digital Services Act / EU Trader status** (you may see this under **Business** or App Information): selling a $0.99 unlock means you're probably a "trader". Apple then **shows your address, phone, and email publicly** on EU store pages and verifies them, which can take time. **Fastest choice for a 3-day launch:** in **Pricing and Availability**, leave the **27 EU countries out for now**, and add them later after you've set this up (a P.O. box is allowed for the address).
- Click **Save**.

## Step 2.6: Create the In-App Purchase ($0.99 SoleCount Pro)

1. Left sidebar → **Monetization → In-App Purchases** → **+** (or **Create**).
2. **Type:** **Non-Consumable**. **Reference Name:** `SoleCount Pro`. **Product ID:** `com.krishnav.SoleCount.pro` (must be exact; this can't be changed or reused later). Click **Create**.
3. **Availability:** all countries you sell the app in (match Step 2.9).
4. **Price Schedule** → **Add Pricing** → base country **United States** → **$0.99** → Next. Apple fills in matching prices for other countries automatically (Canada will be a little over CA$1) → **Confirm**.
5. **App Store Localization** → **+** → English (U.S.):
   - **Display Name:** `SoleCount Pro`
   - **Description:** `Unlimited pairs and wear history chart`
6. **Review Information:**
   - **Screenshot:** upload screenshot #5 from Step 1.16 (the SoleCount Pro screen).
   - **Review Notes:** `Non-consumable one-time unlock. Free version tracks up to 3 pairs. Pro unlocks unlimited pairs and the wear history chart. Open the app, add 3 pairs (or tap the gear icon > Unlock Pro) to see the purchase screen. Restore Purchases is on the Pro screen and in Settings.`
7. **Save.** Status should become **Ready to Submit**. If it says **Missing Metadata**, a field above is empty.
8. **Family Sharing** (optional): you can turn it on. It's friendly, but it can't be turned off later. Leave it off if unsure.

> Your **first** In-App Purchase can only be submitted **together with an app version**. You'll attach it in Step 3.1.

## Step 2.7: App Privacy (the "nutrition label")

Left sidebar → **App Privacy**:
1. **Privacy Policy URL:** `https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/PRIVACY.md` → Save.
2. **Data Collection** → **Get Started** → "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app** → Save.
3. Click **Publish**. Your label will read **Data Not Collected**.

Why this is true: SoleCount has no servers, no analytics, no ads, and no login. Everything is stored on the phone with SwiftData. Apple handles the payment itself, so you don't collect it. Your `PrivacyInfo.xcprivacy` already matches this (no tracking, no collected data, UserDefaults reason CA92.1).

## Step 2.8: Age rating questionnaire

**App Information → Age Ratings → Set Up / Edit**. Answer honestly:
- **In-app controls** (Parental Controls, Age Assurance): **none**.
- **Capabilities:** Unrestricted Web Access **No** (the links open Safari, not a browser inside your app). User-Generated Content **No** (photos stay private on the phone and aren't shared). Messaging/Chat **No**. Advertising **No**. **Social media: No.**
- New questions (Shared Location, Dating & Relationships; required from Nov 16, 2026): **No**.
- All content questions (violence, profanity, mature themes, medical, gambling, contests, etc.): **None**.
- Result: **4+**. Click **Done/Save**.

## Step 2.9: Pricing and Availability

1. Left sidebar → **Pricing and Availability**.
2. **Price:** **Free** (USD 0.00). (The money comes from the $0.99 unlock.)
3. **Availability:** all countries, **except** EU countries if you skipped the DSA trader step (Step 2.5). Canada and the US are included.
4. **Save.**

## Step 2.10: Archive and upload from Xcode

1. In Xcode's device menu, choose **Any iOS Device (arm64)**. Archive won't work with a simulator selected.
2. Check **Signing & Capabilities**: **Team** = your paid team; Bundle ID matches App Store Connect.
3. Check **General**: **Version** `1.0`, **Build** `1` (bump the build to `2`, `3`… for every new upload).
4. **Product → Archive.** Wait a few minutes. The **Organizer** window opens with your archive.
5. Click **Distribute App** → **App Store Connect** → **Distribute** (or **Upload**). Accept the defaults: automatic signing, upload symbols. Click **Upload**.
6. Wait for **"Upload Successful"** (or "App … successfully uploaded").
7. In App Store Connect → your app → **TestFlight** tab, the build shows **Processing** for about 5–30 minutes. You'll get an email when it's ready.
8. Because you set `ITSAppUsesNonExemptEncryption = NO`, there's no "Missing Compliance" warning. If you still see one: click it → **None of the algorithms mentioned above** → Save.

**Upload errors you might hit:**

| Error | Fix |
|---|---|
| `Missing required icon` / `Invalid large app icon` | Your icon has transparency or isn't 1024×1024. Use the provided PNG (Step 1.15). |
| `SDK version issue` / built with older SDK | Update Xcode to 26 or later (Step 1.2). |
| `Redundant binary upload` / build already exists | Increase **Build** to the next number, archive again. |
| `No suitable application records were found` | Bundle ID in Xcode ≠ bundle ID chosen in App Store Connect. Make them identical. |
| `Invalid Privacy Manifest` | Make sure `PrivacyInfo.xcprivacy` is in the target (Target Membership ✅) and unchanged. |

## Step 2.11: TestFlight: test the real purchase on your iPhone

**TestFlight purchases use Apple's sandbox. You're never charged.**

1. App Store Connect → **TestFlight** → left side **Internal Testing** → **+** → create a group called `Me` → add yourself (your account is already a user) → enable your build.
2. On your iPhone, install **TestFlight** from the App Store and sign in with the same Apple ID. Accept the email invite or open TestFlight; SoleCount appears → **Install**.
3. **Delete the Xcode-installed copy first** if it's on the phone (long-press → Remove App), so you're testing the real build.
4. Run the **Day 1 checklist** again on this build, especially:
   - [ ] Pro screen shows **Unlock Pro for $0.99** (or your local price). If it's stuck on **"Loading price…"**: Paid Apps Agreement isn't **Active** yet, the product ID doesn't match, or the IAP is still being created. Wait up to an hour after creating the IAP and try again.
   - [ ] Buy → the sandbox sheet says it's a test purchase → Pro unlocks.
   - [ ] Delete the app, reinstall it from TestFlight → **Restore Purchases** → Pro comes back.

**Sandbox tester (only for testing purchases from an Xcode run on your phone *without* the StoreKit file):**
1. App Store Connect → **Users and Access** → **Sandbox** → **Test Accounts** → **+** → use a new email you control (for example, a Gmail "+" address like `krishnaazure1975+sandbox@gmail.com`), a password, and region **Canada** → Create.
2. On the iPhone: **Settings → Developer → Sandbox Apple Account** → sign in with that test account.
3. In Xcode, set **Edit Scheme → Run → Options → StoreKit Configuration** to **None** and run on the phone. Purchases now go through the real sandbox using your App Store Connect product.

You don't strictly need this if TestFlight works. TestFlight is what matters most.

## Step 2.12: Fill in the version page (store listing)

App Store Connect → your app → **iOS App → 1.0 Prepare for Submission**. Paste the text from **"Ready-to-paste App Store copy"** below:
1. **Previews and Screenshots** → **iPhone 6.9" Display** (may be labeled "iPhone with Dynamic Island (large display)") → drag in your 3–5 screenshots.
2. **Promotional Text**, **Description**, **Keywords**, **Support URL**, **Marketing URL** (optional; leave blank).
3. **Version:** 1.0. **Copyright:** `2026 Krishna Venkataraman`.
4. **Build:** click **Add Build** → pick your TestFlight build → **Done**.
5. **App Review Information:**
   - **Sign-in required:** **unchecked** (no login in SoleCount).
   - **Contact:** your first/last name, phone with country code (+1…), and email.
   - **Notes:** paste the review notes below.
6. **Version Release:** **Automatically release this version** (fastest).
7. **Save** (top right).

---

# DAY 3: Submit, respond, release

## Step 3.1: Final pre-submit checklist

- [ ] Paid Apps Agreement = **Active** (Business page).
- [ ] IAP `com.krishnav.SoleCount.pro` = **Ready to Submit**, with a review screenshot.
- [ ] TestFlight build: purchase + restore worked on your iPhone.
- [ ] Screenshots uploaded (6.9"), icon visible on the build.
- [ ] Privacy label published (**Data Not Collected**) + privacy policy URL opens in a private Safari window.
- [ ] GitHub repo is **public**; Issues are enabled (Support URL works).
- [ ] Age rating done (4+). Pricing: Free. Availability set.
- [ ] Review notes pasted, sign-in unchecked, contact info filled in.

## Step 3.2: Attach the In-App Purchase and submit

1. On the **1.0 Prepare for Submission** page, scroll to **In-App Purchases and Subscriptions** → **Select In-App Purchases or Subscriptions** (or **+**) → tick **SoleCount Pro** → **Done**.
   *(This section only appears once a build is attached and the IAP is "Ready to Submit". Don't see it? Remove the build, save, add it again.)*
2. Click **Add for Review** (top right). Fix anything it flags. It lists missing items in red.
3. Click **Submit to App Review** (or open the draft submission and click **Submit**).
4. Status becomes **Waiting for Review** → **In Review** → **Pending Developer Release** / **Ready for Distribution**. You'll get emails at each step.

## Step 3.3: While you wait

- **Keep your phone nearby.** App Review sometimes emails a question. Answering within an hour or so keeps you in the queue.
- Don't upload new builds or edit the submission unless they ask; changing it can put you back at the end of the queue.
- **Expedited review:** after submitting, go to **developer.apple.com/contact → App Review → Request an Expedited Review** (Apple's help page: <https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review/>). Apple says it's for **critical bug fixes** to a live app or apps tied to a **time-sensitive event**. A personal 3-day goal for a brand-new app doesn't really qualify, and asking too often can get future requests ignored. **Save it** for a real emergency, like a crash fix after launch. If you still want to try, be short and honest. Apple decides.

## Step 3.4: If you're rejected: what to do (calmly)

A rejection is normal and fixable. It's not a ban.

1. Open App Store Connect → your app. You'll see a message from App Review (this used to be called **Resolution Center**; it's now the **App Review** messages area on your submission). Read which **guideline number** they cite and the screenshots they attach.
2. Decide which kind it is:
   - **Metadata only** (text/screenshots wrong): fix the text/screenshots → reply → **Resubmit**. No new build needed.
   - **App bug / binary issue**: fix the code → increase **Build** by 1 → Archive → Upload → choose the new build on the version page → reply → **Resubmit**.
   - **Misunderstanding**: reply politely with exact steps or a screen recording.
3. Reply template (copy, edit the bits in [brackets]):

```
Hello App Review team,

Thank you for reviewing SoleCount. Regarding Guideline [2.1]:

[What we changed]: We fixed [the issue you described] in build [1.0 (2]).
[How to verify]: 1) Open SoleCount. 2) Tap the gear icon > Unlock Pro.
3) The price loads and the purchase completes. Restore Purchases is on
the same screen and in Settings.

Please let us know if you need anything else.

Kind regards,
Krishna Venkataraman
```

4. If you strongly disagree after replying, you can **appeal** to the App Review Board (**developer.apple.com/contact → App Review → Appeal an App Rejection**). Use this rarely.

## Step 3.5: Release 🎉

- With **Automatically release**, the app goes live right after approval. It can take up to about 24 hours to appear in App Store search.
- Find your store link: App Store Connect → **App Information** → **View on App Store**.
- **Within the first week:** check **Sales/Trends** for the first Pro purchase. Answer reviews in App Store Connect → **Ratings and Reviews**.
- Remember: your membership renews every year ($99). If it lapses, the app is removed from sale.

---

# Common rejection reasons for an app like SoleCount, and how you're already covered

| Guideline | What gets apps rejected | SoleCount status / what to do |
|---|---|---|
| **3.1.1 In-App Purchase** | Unlocking features without Apple's IAP; **no Restore Purchases button**; mentioning other ways to pay | ✅ The code uses StoreKit 2 for Pro. ✅ **Restore Purchases already exists in two places**: `PaywallView.swift` ("Restore Purchases" button calling `store.restore()`, which uses `AppStore.sync()`) and `SettingsView.swift`. **No code change needed.** Never mention PayPal/website payments. |
| **2.1 App Completeness** | Crashes; IAP that won't load for the reviewer; placeholder text; broken links | Run the full checklist on TestFlight. **#1 risk: Paid Apps Agreement not Active → price never loads.** Make sure GitHub links work and the repo is public. |
| **4.2 Minimum Functionality** | Apps that are too simple, a website wrapper, or a template | SoleCount has real features: photos, wear logging, cost per wear, wear limits/retire, charts, a local database. In the description, clearly explain the value. Don't remove features to save time. |
| **2.3 Accurate Metadata** | Screenshots that aren't the real app; keywords with brand names (Nike, Jordan, Adidas); description promises features that don't exist; mentioning "Android" | Use real simulator screenshots. The keywords below contain **no brand names**. The description only lists features that exist. |
| **3.1.2 / clarity of purchase** | Not clear what you get, or that it's one-time | The paywall says "One-time purchase. No subscription.", shows the price from StoreKit, and lists features. ✅ |
| **5.1.1 Privacy** | Missing or broken privacy policy URL; label doesn't match the app | URL in app + App Store Connect. Label = Data Not Collected, which matches the code. ✅ |
| **2.1 (info needed)** | Reviewer can't find the paid feature | Review notes tell them exactly where to tap. ✅ |
| **Trademark (5.2)** | Using logos or brand names in the icon, name, or screenshots | Your icon is a generic sneaker. Avoid branded photos in screenshots. |

### Optional code polish (not required for approval)

- **Delete is swipe-only.** This is fine for review. The list footer already tells free users "Swipe left on a pair to delete it." A delete button on the detail screen can come in v1.1.
- **No edit screen** for a pair yet. That's acceptable for v1.0. Don't mention editing in the description.
- The `product.purchase()` deprecation **warning** is harmless and doesn't affect approval.

---

# Ready-to-paste App Store copy

**App Name** (30 max), 26 characters:
```
SoleCount: Sneaker Tracker
```

**Subtitle** (30 max), 28 characters:
```
Cost per wear for every pair
```

**Promotional Text** (170 max), 128 characters (can be changed anytime without review):
```
Track every pair you own and see what each wear really costs. Tap once a day. No account, no ads, all data stays on your iPhone.
```

**Description** (4000 max):
```
How much did that last pair really cost you? SoleCount turns your sneaker collection into simple numbers: how often you wear each pair and what every wear costs.

TAP ONCE, SEE THE VALUE
• Add a pair with a photo, brand, price and purchase date
• Tap "Wore today" whenever you wear them
• Cost per wear updates instantly (price ÷ wears)
• Undo a tap if you made a mistake

KNOW YOUR ROTATION
• See wears and cost per wear for every pair at a glance
• Set an optional wear limit and get a reminder to retire a worn-out pair
• Keep retired pairs in their own section

PRIVATE BY DESIGN
• No account, no sign-up, no ads, no tracking
• Everything stays on your iPhone

FREE AND SOLECOUNT PRO
SoleCount is free for up to 3 pairs. SoleCount Pro is a one-time purchase (no subscription) that unlocks:
• Unlimited pairs
• A wear history chart for every pair (last 6 months)
Already bought Pro? Use Restore Purchases in Settings.

Made by an independent developer. Questions or ideas? Tap Support in the app's Settings.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/PRIVACY.md
```

**Keywords** (100 max, commas, no spaces needed), 96 characters, no brand names, and no words already in the name or subtitle:
```
shoes,kicks,wear log,cost per wear,collection,rotation,closet,footwear,sneakerhead,outfit,budget
```

**Support URL:**
```
https://github.com/KrishnaDistributedcomputing/SoleCount/issues
```

**Privacy Policy URL:**
```
https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/PRIVACY.md
```

**Category:** Primary **Lifestyle** · Secondary **Utilities**

**Copyright:** `2026 Krishna Venkataraman`

**App Review Notes:**
```
Thank you for reviewing SoleCount.

- No login or account is required. All data is stored only on the device (SwiftData). The app has no servers, analytics, ads or third-party SDKs.
- Free version: track up to 3 pairs of sneakers.
- In-App Purchase: "SoleCount Pro" (com.krishnav.SoleCount.pro), a one-time NON-CONSUMABLE that unlocks unlimited pairs and the wear history chart.
- How to reach the purchase screen: tap the gear icon (top left) > Unlock Pro. Or add 3 pairs with the + button, then tap + again. Or open any pair and tap "Unlock the wear history chart with Pro".
- Restore Purchases is on the Pro screen and in Settings.
- To test the core feature: tap + to add a pair (name and price), open it, and tap "Wore today". Cost per wear updates.
- Photos are chosen with the system photo picker and stay on the device.
- Export compliance: the app uses no encryption beyond Apple's standard OS-provided HTTPS (ITSAppUsesNonExemptEncryption = NO).
```

**In-App Purchase**
- Reference Name: `SoleCount Pro`
- Product ID: `com.krishnav.SoleCount.pro`
- Type: Non-Consumable · Price: **$0.99 USD**
- Display Name (35 max): `SoleCount Pro`
- Description (55 max), 38 characters: `Unlimited pairs and wear history chart`

---

# What's outside your control (and how to maximize speed)

| Risk | Typical time | What you can do |
|---|---|---|
| **Developer Program enrollment** | ~24–48 h for individuals; can be longer if Apple needs ID checks | Enroll first thing on Day 1, on the iPhone app. Use your exact legal name. Call Apple Developer Support after 24–48 h with your Enrollment ID. |
| **Paid Apps Agreement / bank / tax "Processing"** | Hours to ~1 day+ | Do it the minute you're approved. Don't submit until **Active**. |
| **App Review queue** | Apple: 50% < 24 h, 90% < 48 h. Oct 2026 reports: some apps waited weeks | Submit a complete, tested app with clear notes. Reply fast. Don't resubmit unnecessarily. |
| **A rejection** | Adds ~1–2 days per round | Use the checklists and the rejection table. Reply politely and resubmit the same day. |
| **EU trader (DSA) verification** | Can take days | Exclude the EU for launch; add it later. |
| **Small Business Program** | Days to weeks | Doesn't block the launch. Just apply. |

**Realistic timeline:**
- **Best case:** approved on Day 1 night, submitted Day 2 evening, live Day 3–4.
- **Typical case:** live on day 4–7.
- **Slow case** (enrollment delay or review backlog): 1–3 weeks.

---

# Key facts used in this guide (checked November 2026)

- Uploads must be built with **Xcode 26+ / iOS 26 SDK+** since April 28, 2026. (Apple Developer, *Upcoming Requirements*: <https://developer.apple.com/news/upcoming-requirements/>)
- Enrollment: Individual needs legal name + 2FA; Organization needs a legal entity, D-U-N-S, and a website; **US $99/year**; you can enroll via the Apple Developer app. (<https://developer.apple.com/programs/enroll/>, <https://developer.apple.com/help/account/membership/program-enrollment/>)
- D-U-N-S: up to 5 business days + 2 business days for Apple. (<https://developer.apple.com/help/account/membership/D-U-N-S/>)
- App Review: "at least 50% of submissions in less than 24 hours and 90% in less than 48 hours"; new apps with little review history can take longer. (<https://developer.apple.com/distribute/app-review/>, <https://developer.apple.com/help/app-review/after-submitting-for-review/review-status/>)
- Oct 2026 reports of multi-week "Waiting for Review". (The Register, 22 Oct 2026)
- Expedited review is for critical bug fixes or time-sensitive events. (<https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review/>)
- Paid Apps Agreement → tax → banking order. (<https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/>)
- Small Business Program: under $1M proceeds; 15% starts 15 days after the end of the fiscal month of approval. (<https://developer.apple.com/app-store/small-business-program/>)
- Screenshots: 6.9" iPhone 1320×2868 (also 1290×2796 or 1260×2736); 1–10 per size; scaled down automatically. (<https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/>)
- Age ratings: 4+, 9+, 13+, 16+, 18+; social media questions required since Sept 2026; Shared Location and Dating questions from Nov 16, 2026. (<https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/>, <https://developer.apple.com/news/?id=yxkh08us>)
- First IAP is submitted with an app version via "In-App Purchases and Subscriptions" on the version page. (<https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/>)
- `ITSAppUsesNonExemptEncryption = NO` for apps using only exempt encryption (HTTPS). (<https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/>)
- App icon: 1024×1024, opaque, single size. (<https://developer.apple.com/documentation/xcode/configuring-your-app-icon>)
- EU DSA trader status and public contact details. (<https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements>)
- Metadata limits: name 30, subtitle 30, promotional text 170, keywords 100 bytes, description 4000. (<https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/>)

*Stuck at any step? Take a screenshot (**Cmd+Shift+4**, then drag) or copy the error text and send it to me.*
