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

Find the Team ID, create the API key, and find the `.p8` file. Steps: [Team ID](docs/MAC-STEP-BY-STEP.md#team-id) and [AuthKey .p8 file](docs/MAC-STEP-BY-STEP.md#find-the-p8-file).

```bash
make setup
```

```bash
make appstore-setup
```

If that command says the app record does not exist yet, fill in the [New App form](docs/MAC-STEP-BY-STEP.md#new-app-form). Attach the $0.99 purchase to version 1.0, then:

```bash
make deploy
```

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
