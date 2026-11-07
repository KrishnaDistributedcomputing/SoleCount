# SoleCount business case

This page is the product decision record for the free app. How the code works is in [TECHNICAL-DESIGN.md](TECHNICAL-DESIGN.md). How a change is made is in [DEVELOPER.md](DEVELOPER.md). The next upload is in [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md).

It is written for Krishna, a solo beginner, so a later choice has a place to live. It is not an ad, and it is not a forecast.

## Status

| | |
|---|---|
| Written | 7 November 2026 |
| Branch | `cursor/ai-adlc-foundation-a2e5` |
| Product decision in force | SoleCount is free. Every feature is unlocked. There is no Pro screen and no paywall. |
| Where that decision lives in code | `SoleCount/FeatureFlags.swift`: `monetizationEnabled = false` |
| App-code baseline | GitHub `main` at `d41209a`, plus `SoleCountTests/IdentityTests.swift` on this branch |
| What this page is not | A description of the approved binary. See the baseline below. |

Labels used here:

- **Decided.** The owner has set this, and the GitHub tree matches it.
- **Implemented.** The behavior is in this GitHub tree.
- **Hypothesis.** A guess to test. It is not a finding about real users.
- **Historical.** An older note. It is not the current plan.
- **Unapproved option.** An idea that must not be built until the owner says yes in a pull request.
- **Illustrative.** A sample number so a rule is easy to read. It is not a target and not a result.

## Baseline: do not treat GitHub as the shipped app

The owner reported that App Store version 1.0, build 2, was approved on 6 November 2026. This environment did not open App Store Connect and did not open the Mac folder `~/Desktop/SoleCount`.

Commits named as Mac-only, and absent here: `740a4a8`, `d99297c`, `90a5e9f`, `e2a3f71`, `2a028c2`, `afd2f8e`, `66a2717`, `bb63397`. Uncommitted Mac work was also reported around signing, the widget, the Fastfile, screenshots, and contact setup.

So a feature listed as **Implemented** below means "present in this GitHub tree." It does not mean "verified inside build 2." Reconcile the Mac folder before you tell anyone, including yourself, that the store build matches this page. The steps are in the release checklist.

`docs/PRIVACY.md` mentions a camera and a "Sole check." The Swift sources and `project.yml` in this tree do not. Which text matches the approved app is unknown.

## 1. Why this app exists

**Decided.** SoleCount helps one person see what their sneakers are doing: how often each pair is worn, what a wear costs, and, if they allow it, how far they walked in that pair. The phone keeps the data. There is no account.

The owner is the first user and the only reviewer. The app stays small enough for one person to understand, test, and ship with the path in [DEVELOPER.md](DEVELOPER.md): say what should change, write a short plan, use a small branch, run checks, read the pull request, and release only with an explicit yes.

StoreKit code is still in the project so a future paid unlock could be switched on. That switch is off. Fastlane reads the off line and skips the in-app purchase. Turning it on is not part of this business case.

## 2. Who it is for, and the job they are doing

These are **hypotheses** about jobs the screens support. They are not interview results, and they are not a market study. No one has been counted.

| Person (hypothesis) | Job they might hire the app to do | What in this GitHub tree serves that job |
|---|---|---|
| The owner, learning iOS | Keep a real app working without a team or a server | One `project.yml`, Make commands, fastlane, and the review path |
| Someone with more than one everyday pair | Log a wear in a tap and see price ÷ wears | `Sneaker.logWear`, `PairTotals.costPerWear` |
| Someone who walks and is curious, not training | See today's steps, and kilometres on the pairs marked worn | Today tab, read-only Health, widget snapshot |
| Someone who wants the story kept | Retire a pair without deleting its numbers | `isRetired`, Hall of Fame copy, send-off screen |
| Someone eyeing a next pair | Hold a wish, then turn it into a real pair | `WishlistItem`, `WishlistMath.bought` |
| Someone who will not make an account | Use the app with nothing to sign in to | No account, no SoleCount server, CloudKit off |

A notes app or a spreadsheet can compute price ÷ wears. A running app can count miles on running shoes. A closet app can cover a whole wardrobe. A collection app can track what a pair might sell for. SoleCount's bet, as built, is narrower: sneakers you actually wear, cost per wear, optional distance, on the phone, for free.

An older file, [MARKET-ANALYSIS.md](../MARKET-ANALYSIS.md) (3 November 2026), names specific other apps, prices, ratings, and market sizes, and it assumes a $0.99 unlock. Those figures were **not re-checked** for this page. Do not quote them as current facts. The banner on that file says the same thing.

## 3. The problem, in the product's own words

**Implemented** in the store text and the code, not proven by user research:

- Wears are easy to forget, so "what did this pair cost me per wear?" has no number until someone writes the wears down.
- Distance from Apple Health is about the person, not about the shoe, until a wear log splits the day across the pairs that were worn (`HealthAttribution`).
- A pair that is "done" is not the same as a pair that should be deleted. The app retires it and keeps the stats.
- A medical or training claim would be the wrong promise. Copy in the app and in the review notes says SoleCount is not a medical app.

What this tree does **not** claim: that people are unhappy with other apps, that a market of a certain size is waiting, or that anyone has learned the product yet. Those sentences are absent on purpose.

## 4. What is different, tied to this tree

Only differences the code actually has:

| Promise | Evidence in this GitHub tree |
|---|---|
| Free, every feature unlocked | `FeatureFlags.monetizationEnabled` is false. `StoreManager.hasFullAccess` is true in that state. The 3-pair cap runs only if the flag is turned on. |
| No account, data on the phone | SwiftData with `cloudKitDatabase: .none`. No analytics package. Privacy manifests say no tracking and no collected data types. |
| Health is optional and read-only | `toShare: []`. The app still runs if Health is missing. UI test `testFirstLaunchAddPairAndLogWear` launches with Health unavailable. |
| One tap wear, then cost | `logWear` appends a date. Cost is price divided by logged wears plus starting wears. No wears means no cost yet. |
| Distance per shoe, split fairly | A shared day is divided evenly across the pairs worn that day. |
| Offline catalog | Brand and model names are compiled into `ShoeCatalog`. No logo files, no network lookup. |
| A widget that does not read Health | The app writes a small snapshot. The widget reads that snapshot. |
| A CSV the person chooses to share | Settings builds a file and uses the system share sheet. There is no import and no upload. |

**Unknown (Mac copy).** If build 2 has screens this tree does not, this table is incomplete for the store app. If build 2 is missing the widget or the CSV, this table is ahead of the store app.

## 5. Current scope and what is not scheduled

### In the GitHub tree now

**Implemented.** Today (steps, the step-goal streak, a separate logging streak, tip, walk nudge), Collection (add, filter, retire), Stats, Calendar, detail with cost and distance, wishlist, local reminders, CSV export, on-device share card, Shortcuts phrase to log a wear, Home Screen widget, English, iPhone, iOS 18.

The logging streak thanks you for logging wears on consecutive local days. It is not a step goal, not a purchase, and not a notification. Milestones on the card are 3, 7, 14, and 30 days. Those four numbers are a product choice for this screen.

### Explicitly not the current product

**Decided.** A paywall, a price on the download, ads, an account, a server, behavioral analytics, and writing to Apple Health.

**Not in this tree, and not scheduled by this page.** iCloud sync, CSV import, deleting a pair (retire is the removal), iPad layout, a second language, any donation or sponsor UI, a leaderboard, and kudos that require an account.

**Unknown (Mac copy).** Levels, quests, or a weekly challenge may exist only on the Mac. This page has not seen that code. The logging streak here is not that feature.

### Historical scope that is no longer the plan

**Historical.** [MARKET-ANALYSIS.md](../MARKET-ANALYSIS.md) describes a free tier of 3 pairs and a $0.99 Pro unlock, and it says the widget and export were not built yet. The flag is now false, so the 3-pair cap is not applied. This GitHub tree does contain a widget and a CSV export. Use this business case, not that file, for product choices.

## 6. Goals and non-goals

### Goals

**Decided** unless marked otherwise.

1. Keep the app free and usable with no account.
2. Keep wears, photos, and Health numbers on the device.
3. Keep one beginner able to change it through a reviewed pull request and a Mac test before any upload.
4. Learn whether the owner still wants the app after using the real build, before adding scope.

### Non-goals

- Hitting a revenue number. There is no current revenue commitment. See section 8.
- Adding analytics so a dashboard can show retention. That would be a new product decision.
- Marketing campaigns, paid ads, or public launch posts from this document.
- Treating a merged documentation pull request as a release.

## 7. How someone might find it, start, and come back

These are **hypotheses**. None of them has a measured result in the repo.

### Finding the app

The metadata already submitted in git uses the name "SoleCount: Sneaker Tracker" and the keywords in `fastlane/metadata/en-US/keywords.txt`: shoes, steps, km, walk, wear, sneakers, closet, streak, distance, health, retire. **Hypothesis:** those words match how a person searches. **Not known:** whether they rank, or how often the product page is viewed.

The GitHub repository is the source and the public privacy page. It is not, by itself, a plan to recruit customers.

### Starting

**Hypothesis:** a new person can add a pair and log one wear without Health and without an account, and can then say the cost per wear out loud. The UI test on this tree walks that path with sample data in memory. That test is not a substitute for a person on a phone.

**Acceptance for a manual check:** you, or one person you ask, install a build you trust, add one real pair, tap wore today, and tell you the cost without you explaining the formula. If they cannot, the next change is onboarding copy, not a new feature. Decision sits with you after you try it.

### Coming back

**Hypothesis:** the Today tab, the gentle streak, and the widget give a reason to open the app on a later day. **Not known:** whether anyone does.

**Acceptance for a personal log, not an in-app metric:** for 14 days, mark on paper or in a note whether you opened SoleCount. This is a diary. It is not a retention rate. If you opened it fewer days than you hoped, write the hope down first so you are not moving the goal after the fact. An **illustrative** bar, not an approved target: "I hoped to open it on 7 of 14 days." Change the 7 before you start if you want a different bar. Do not put that diary in the repo if it has private details.

## 8. How you would know it is working

No download count, rating, revenue, or retention rate is stored in this repository. Do not fill those in from memory in this file. Read them, when you want them, from App Store Connect or from your own notes, and keep the raw export out of git if it is sensitive.

| Measure | Precise meaning | Where it can come from today | What this repo has |
|---|---|---|---|
| Units | Whatever App Store Connect calls a download or update for this app | App Store Connect, after you sign in | No number |
| Product page views | Apple's count of store-page views | App Store Connect | No number |
| Crashes | Apple's crash reports for a build | App Store Connect / Xcode Organizer | No number |
| Support contacts | Messages you actually receive | The support page's email, or GitHub issues | The page exists. The count is not in git |
| Cost understood | A person states price ÷ wears after one log | A manual session | Not recorded |
| Owner still uses it | Days you chose to open the app | Your private diary | Not recorded |
| GitHub matches the store | The Mac folder and build 2 compared with this tree | The release checklist | Not done |
| In-app retention, funnels, or feature taps | Needs new instrumentation | Not built | Do not invent this |

Suggested measures that need code, such as "percent of people who connected Health," are **not available** and are **not approved**. Adding them means a privacy review, a change to the privacy page, and probably a new App Store privacy answer. Prefer Apple's aggregate store numbers and your own eyes until you explicitly want instrumentation.

## 9. Money and operating cost

### Income under the current model

**Decided.** With `monetizationEnabled` false there is no paid download and no in-app purchase. The app does not show a paywall. Fastlane skips the purchase. **Direct app income is zero** for as long as that flag stays false. That is the model to preserve.

StoreKit and the product id `com.krishnav.SoleCount.pro` remain in the tree so the old unlock could return. `fastlane/iap.json` still says `0.99` for that unused product. Those lines are not a price customers pay today.

### The old $500 figure

**Historical, unresolved, not a commitment.** [MARKET-ANALYSIS.md](../MARKET-ANALYSIS.md) aimed at about $500 a year from a $0.99 unlock. That page's arithmetic assumed paid sales. Under the later all-free decision, app sales and the in-app purchase cannot produce that $500. Do not treat $500 as a goal, a forecast, or a failure if it is not reached. If you still want a money goal later, write a new one in a pull request and say where the money would come from. This page does not set that goal.

### Unapproved ways money could exist later

None of these are decided. None are implemented. Do not add a button, a link, or a StoreKit change for them in a drive-by edit.

| Idea | Status | What would have to be true first |
|---|---|---|
| Turn `monetizationEnabled` back on and charge for the existing product id | **Unapproved option** | You say yes. The paywall shows the live StoreKit price, Restore Purchases, and the privacy and terms links. A separate reviewed pull request. |
| A tip, donation, or "buy me a coffee" link | **Unapproved option** | You say yes. Check Apple's rules for that kind of link before any code. |
| A sponsor or a paid mention | **Unapproved option** | You say yes. The privacy page would have to stay honest about what the app collects. Today it collects nothing to sell. |
| Ads | **Unapproved option**, and a poor fit | You say yes. Ads conflict with the current "no ads, no tracking" promise. Default is no. |

### Costs

Amounts you have not shown this repo are not filled in.

| Cost | What it is | Figure used here |
|---|---|---|
| Apple Developer Program | Annual membership Apple charges to ship to the App Store | Apple publishes the fee. Confirm the current amount and your receipt on your Apple account. This page does not copy a receipt. |
| Your time | Review, Mac testing, support email | Not priced |
| Mac and Xcode | Already how you build | Not priced |
| GitHub Actions | Linux checks are the cheap ones. A macOS run compiles and tests. Public-repo billing follows GitHub's current price list | Not converted to money here. Early November 2026 runs that finished tests took roughly 10 to 14 minutes of a macOS runner (for example Actions run `41822364146`, about 14 minutes). That is a duration, not a bill. |
| Support | Reading mail and issues | The support page has a contact. Volume is unknown. |
| Marketing spend | Ads, creators, tools | **Not approved.** This case assumes $0 of paid marketing until you decide otherwise. |

There is no profit forecast. Zero app income minus whatever you confirm Apple and GitHub charge you is the honest current picture.

## 10. Small tests, and when to stop or continue

Each test is something you can do without a new SDK. "Continue" means write the next issue. "Stop" means do not add scope yet. "Change the question" means the test was the wrong test, not that the app failed.

| # | Test | How | Continue if | Stop or change the question if |
|---|---|---|---|---|
| 1 | Mac folder versus GitHub | Release checklist commands, saved outside the repo | You can name what build 2 contains | You still cannot tell. Do not ship a "bug fix" for a screen you have not seen. |
| 2 | First real pair | You add one pair on a build you trust and log one wear | You can state the cost without looking up the formula | The screen confuses you. Next pull request is copy or layout, after `make test` on the Mac. |
| 3 | Health off still feels complete | Use the app for a day with Health denied | Wears and cost still make sense | You expected distance and the empty state did not say why. Fix the empty state before new badges. |
| 4 | Store page, weekly | Read App Store Connect once a week. Write the numbers in a private note | You understand views, units, and crashes for that build | You are tempted to add analytics inside the app. That is a separate decision, default no. |
| 5 | One other person | Ask one person to try the build. No survey form in the app | They finish add + wore today, or they point at one stuck step | You need a crowd before you know the one stuck step. You do not. |
| 6 | Diary of opening the app | 14 days, private | You met the bar you wrote down **before** day 1 | You did not. Decide whether Today, the widget, or reminders are the next issue. Do not add a paywall to "fix" this. |

**Illustrative** store-page rule, not approved: "If I still cannot tell views from units after two weekly reads, I will learn App Store Connect before I change keywords." That sentence is a study plan, not a growth target.

## 11. Risks and constraints

| Risk | Why it is real here | What to do |
|---|---|---|
| GitHub and build 2 differ | Mac commits are not in this clone | Reconcile before the next upload. Do not delete the Mac folder to force a match. |
| Privacy text and code differ | Camera / sole check versus no camera key in `project.yml` | After reconciliation, make the public privacy page match the binary you shipped. |
| Free means no sales income | Flag is false on purpose | Do not quietly turn the flag on. A money change is its own pull request. |
| Old market note misleads | [MARKET-ANALYSIS.md](../MARKET-ANALYSIS.md) still talks about $0.99 and missing widget | Read this page for decisions. The old file is history. |
| No in-app analytics | Privacy choice | Use store aggregates and manual checks. Do not add a tracker to "see if it works." |
| macOS CI costs minutes | The test job uses a macOS runner | Docs-only pull requests skip that job. Do not start a release from a red or cancelled test. |
| One person is the team | You review and you ship | Keep changes small. `make check` is not `make test`. |
| Health or reminder permission denied | The app must still work | The code already continues. Test that path on a phone before you depend on it in a store screenshot. |
| Accidental submit | Release button text used to sound like App Review | `make submit` is the review command. The GitHub button does not set `SUBMIT=1`. |

Constraints that stay: iPhone, iOS 18, English, offline-first, no third-party packages, public GitHub repo so secrets stay out.

## 12. Roadmap, in the order that respects the gates

Each phase ends with you. An assistant can prepare a branch. You merge. You decide whether anything is uploaded.

| Phase | Work | Gate before the next phase |
|---|---|---|
| 0. Baseline | Compare the Mac folder with GitHub. Write down what build 2 contains. | You can say which features on this page are in the approved app. No TestFlight from this docs pull request. |
| 1. Tell the truth in public | If privacy text, screenshots, or the store description disagree with that build, fix the words in a pull request. | `make check`. On a Mac, `make test` if code changed. You read the diff. |
| 2. Learn without new code | Tests 2 through 6 in section 10, on a build you trust. | You have notes. You do not need a metric inside the app. |
| 3. One small product change | The single stuck step from those notes, if any. Issue, short plan, branch, tests, your review. | Same gates as [DEVELOPER.md](DEVELOPER.md). Update [TECHNICAL-DESIGN.md](TECHNICAL-DESIGN.md) if behavior changes. Update this page if the free promise or the job changes. |
| 4. A later version | Only after phase 2. Still free, unless you open the money decision below. | You run `make release` only when you want a new build. You run `make submit` only after you have tried that build. |

**Not on this roadmap:** donations, sponsors, ads, or turning monetization on.

## 13. Open decisions

| Decision | Current answer | Who can change it |
|---|---|---|
| Is the app free, with every feature unlocked? | **Yes. Decided.** | You, in a pull request that shows the flag, the paywall rules, and the privacy text |
| Is about $500 a year a goal? | **No current commitment.** Historical only | You, and only together with a source of money |
| Any donation, sponsor, or tip? | **No. Unapproved.** | You, before any link or button exists |
| In-app analytics? | **No.** Not in the tree | You, and only with a privacy-page change |
| Does this page describe build 2? | **Unknown** until phase 0 | The Mac comparison |
| Paid marketing? | **No budget is approved here** | You |
| Delete a pair, or only retire? | Retire is what the screens do | A normal feature pull request |
| Shared feather mark on About | **Proposed** elsewhere, not started. The launcher stays the app icon | A separate visual change. Not this page |

## 14. How to keep this page honest

Update it in the same pull request when you change the free flag, the promise on the store page, or which job the app is for. Leave **Historical** notes historical. Do not paste download counts, mail, or diary notes into git. Do not add a price that customers do not pay.
