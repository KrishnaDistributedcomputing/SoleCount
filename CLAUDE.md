# SoleCount — project guide for Claude Code

## What this app is
SoleCount is a free iPhone app that tracks how often I wear each pair of sneakers,
shows the cost per wear (price ÷ number of wears), and can read Apple Health
steps and walking distance so each pair shows kilometres. It is not a medical app.

## Tech rules (always follow)
- SwiftUI + SwiftData + Swift Charts + HealthKit (read only) + StoreKit 2 kept behind a flag. Minimum iOS 18.
- No servers, no accounts, no analytics, no ads, no third-party SDKs or packages.
- All data stays on the device. Do not add networking code.
- One main type per file. Keep files short and readable.
- Use @Observable (not ObservableObject). Use NavigationStack.
- Build must compile with zero errors before you say you are done.
- Explain every change in plain English. I am a beginner.
- Do not rename the bundle ID or the product ID.

## Files
- SoleCountApp.swift — app entry, StoreManager, Health, motivation, SwiftData
- FeatureFlags.swift — `monetizationEnabled = false` (Fastlane reads this line)
- Sneaker.swift — @Model: name, brand, type, price, photos, wear dates, cached km
- ShoeCatalog.swift — offline brands, types, and model suggestions
- SneakerListView.swift — collection, filters, Hall of Fame, Add a pair
- AddSneakerView.swift — form, brand and type, PhotosPicker, price, date
- SneakerDetailView.swift — stats, Wore Today, km, charts
- TodayView.swift — step rings, streak, tip, Walk now
- WearChartView.swift — bar chart of wears per month
- StoreManager.swift — StoreKit 2, unused while the flag is false
- PaywallView.swift — kept for the flag; not shown while the app is free
- SettingsView.swift — goals, reminders, CSV, privacy, version
- PrivacyInfo.xcprivacy — no tracking, no data collected, UserDefaults CA92.1

## Business rules
- The app is free. `FeatureFlags.monetizationEnabled` is false. Do not show a paywall.
- StoreKit code stays in the project. The product ID is still `com.krishnav.SoleCount.pro`. Do not rename it.
- If that flag is turned back on, the paywall must show the StoreKit price, Restore Purchases, and the Privacy and Terms links. Never hard-code the price.
- HealthKit is read-only (step count and walking/running distance). Never write to Health. The app must work if Health is unavailable or denied.
- Health numbers stay on the device. No iCloud, no ads, no analytics.

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
- Deployment is automated with fastlane (`fastlane/Fastfile`) and GitHub Actions (`.github/workflows/ios.yml` and `.github/workflows/release.yml`). The human setup page is `docs/START-HERE.md`.
- Never commit `*.p8`, `fastlane/.env`, or any key. The repo is public.
