# SoleCount

Read [CLAUDE.md](CLAUDE.md) and [docs/DEVELOPER.md](docs/DEVELOPER.md) before editing. Cursor loads this file. Claude Code loads `CLAUDE.md`. The rules match.

SoleCount is a free, offline iPhone app (SwiftUI, SwiftData, minimum iOS 18). The owner is a beginner and reviews every pull request.

- Keep `FeatureFlags.monetizationEnabled` false. Keep HealthKit read-only. Add no servers, accounts, analytics, ads, or third-party packages.
- Keep the bundle ID `com.krishnav.SoleCount`, the widget ID `com.krishnav.SoleCount.widget`, and the product ID `com.krishnav.SoleCount.pro`.
- Keep the public privacy, support, and marketing URLs. They are checked by `scripts/check_repo.sh`.
- Edit `project.yml`. Do not commit the generated Xcode project.
- Never commit `.env`, `fastlane/.env`, `*.p8`, `AuthKey_*`, certificates, profiles, or review phone and email. Those stay `REPLACE_ME` in git.
- Run `make check`. On a Mac, run `make test` when Swift or the project changes. Say so when you could not run Xcode.
- Open a pull request. Do not merge it. Do not run `make release`, `make submit`, TestFlight, or App Review unless the owner asked for that exact step.
- The Mac folder `~/Desktop/SoleCount` may be ahead of GitHub. Do not delete it, reset it, or pull over it. [docs/RELEASE-CHECKLIST.md](docs/RELEASE-CHECKLIST.md) is the reconciliation path.

Explain changes in plain English.
