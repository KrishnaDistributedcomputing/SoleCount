# SoleCount

An iPhone app that counts how often you wear each pair of sneakers and shows the cost per wear (price divided by wears).

- SwiftUI, SwiftData, Swift Charts, and StoreKit 2. iOS 18 or newer.
- All data stays on the phone. No account, no tracking, no ads.
- Free: 3 pairs. SoleCount Pro is a one-time $0.99 unlock: unlimited pairs and the wear chart.

Privacy policy: [PRIVACY.md](PRIVACY.md)

## Quick start

You are new to the Mac, and Apple may still be processing the paid Developer membership (up to 48 hours). The full path, with a **Why:** line on every step, is **[docs/MAC-STEP-BY-STEP.md](docs/MAC-STEP-BY-STEP.md)**.

Do this on the Mac. Copy each grey box, click Terminal, press Cmd + V, then press Return.

**A. Get ready**

```bash
cd ~/Desktop && git clone https://github.com/KrishnaDistributedcomputing/SoleCount.git && cd SoleCount
```

**B. Do this now. No Apple membership needed**

```bash
make setup-local
```

```bash
make test
```

```bash
make open
```

Then press Cmd + R in Xcode to run SoleCount in the simulator.

**C. After Apple's welcome email**

Accept the Paid Apps agreement, create an Admin API key, and leave the `.p8` file in Downloads. The few steps Apple still requires by hand are listed in the guide: [what stays manual](docs/MAC-STEP-BY-STEP.md#manual-steps).

```bash
make doctor
```

```bash
make release
```

`make release` is safe to run again. It skips records that already exist, uploads a new build, and submits for review. If it asks you to create the app, use the [New App form](docs/MAC-STEP-BY-STEP.md#new-app-form). The first $0.99 purchase still needs one click on the website: [SoleCount Pro](docs/MAC-STEP-BY-STEP.md#pro-purchase). Check progress with `make status`.

**D. Later updates**

Merge the branch on GitHub, then on the Mac:

```bash
git checkout main && git pull
```

How: [Get the latest updates](docs/MAC-STEP-BY-STEP.md#get-updates).

## Other guides

Use these for extra detail. The step-by-step page above is the one to follow first.

- [docs/MAC-STEP-BY-STEP.md](docs/MAC-STEP-BY-STEP.md) is the ordered setup.
- [AUTOMATION.md](AUTOMATION.md) explains fastlane and GitHub Actions.
- [LAUNCH-GUIDE.md](LAUNCH-GUIDE.md) is the longer launch plan.
- [GUIDE.md](GUIDE.md) is an older build walkthrough.
