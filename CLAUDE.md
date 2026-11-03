# SoleCount — project guide for Claude Code

## What this app is
SoleCount is an iPhone app that tracks how often I wear each pair of sneakers
and shows the cost per wear (price ÷ number of wears).

## Tech rules (always follow)
- SwiftUI + SwiftData + Swift Charts + StoreKit 2. Minimum iOS 18.
- No servers, no accounts, no analytics, no ads, no third-party SDKs or packages.
- All data stays on the device. Do not add networking code.
- One main type per file. Keep files short and readable.
- Use @Observable (not ObservableObject). Use NavigationStack.
- Build must compile with zero errors before you say you are done.
- Explain every change in plain English. I am a beginner.
- Do not rename the bundle ID or the product ID.

## Files
- SoleCountApp.swift — app entry, creates StoreManager + SwiftData container
- Sneaker.swift — @Model: name, brand, price, purchaseDate, createdAt,
  photoData (external storage), wearDates [Date], isRetired, wearLimit Int?
- SneakerListView.swift — list (In rotation / Retired), add button, free limit
- AddSneakerView.swift — form with PhotosPicker, price, date, wear limit
- SneakerDetailView.swift — stats, big "Wore today" button, undo, retire, chart
- WearChartView.swift — bar chart of wears per month (last 6 months)
- StoreManager.swift — StoreKit 2, one non-consumable
- PaywallView.swift — Pro screen with Buy + Restore Purchases + links
- SettingsView.swift — Pro status, Restore Purchases, privacy policy, version
- Helpers.swift — currency formatting, photo shrinking, SneakerPhoto, StatCard
- PrivacyInfo.xcprivacy — no tracking, no data collected, UserDefaults CA92.1

## Business rules
- Free: up to 3 pairs (StoreManager.freePairLimit). Chart is Pro only.
- Pro: one-time non-consumable, product ID `com.krishnav.SoleCount.pro`, $0.99.
- Paywall must always show: price from StoreKit (displayPrice), Restore Purchases,
  Privacy Policy and Terms links. Never hard-code the price in text.

## App Store rules to respect
- No claims we can't back up. No fake reviews prompts. No "free" if it isn't.
- Restore Purchases must stay visible in Settings and the paywall.
- If you add any new "required reason" API (UserDefaults, file timestamps,
  disk space, system boot time), update PrivacyInfo.xcprivacy.

## Testing
- Local purchases use SoleCount.storekit (Scheme > Run > Options > StoreKit Configuration).
- Test on the iPhone 17 simulator and on my real iPhone.

## Project generation and deployment
- The Xcode project is generated from `project.yml` (XcodeGen). Edit project.yml, not the .xcodeproj.
- Deployment is automated with fastlane (`fastlane/Fastfile`) and GitHub Actions (`.github/workflows/ios.yml`). See AUTOMATION.md.
- Never commit `*.p8`, `fastlane/.env`, or any key. The repo is public.
