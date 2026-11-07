# Changing SoleCount

This page is for the next change, after the Mac is set up. First-time setup stays in [START-HERE.md](START-HERE.md). How the app is put together stays in [TECHNICAL-DESIGN.md](TECHNICAL-DESIGN.md). The next App Store upload stays in [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md).

SoleCount is a free iPhone app. SwiftUI, SwiftData, and the Xcode project are generated from `project.yml`. You are the reviewer. An assistant can write the branch. You decide when it merges, and you decide when it ships.

## The path

1. **Say what you want.** Open a GitHub issue with the Change or Bug form. Write how you will know it works. Those sentences are the acceptance criteria.
2. **Write a short plan.** A few lines in the pull request: which files change, and what stays as it is.
3. **Use a small branch.** One change. The branch name can look like `cursor/short-name-a2e5`.
4. **Run the checks.** `make check` on Linux or a Mac. `make test` on a Mac when the change touches Swift, `project.yml`, or fastlane behavior.
5. **Read the pull request.** You merge it when the checks match the acceptance criteria. The assistant does not merge it for you.
6. **Release only when you say so.** TestFlight and App Review are a separate decision. Use the release checklist. A merged pull request is not an upload.

When the change alters a model, a formula, a permission, navigation, or a release lane, update [TECHNICAL-DESIGN.md](TECHNICAL-DESIGN.md) in the same pull request. The maintenance rules are at the end of that page.

## Commands

| Command | Where | What it does |
|---|---|---|
| `make check` | Linux or Mac | Identity, secrets, and the release entry points. No Xcode. |
| `make test` | Mac | Unit tests and UI tests in the iPhone Simulator. |
| `make open` | Mac | Regenerates the Xcode project and opens it. |
| `make doctor` | Mac | Green and red checklist before an upload. |
| `make release` | Mac | Records, tests, TestFlight, and the store listing. Stops before App Review. |
| `make submit` | Mac | Sends the latest TestFlight build to App Review. |

Run commands from the SoleCount folder. `make check` is the one a cloud assistant can run. `make test` needs Xcode on a Mac.

## Rules that stay true

- The app is free. `FeatureFlags.monetizationEnabled` stays `false`.
- The bundle ID stays `com.krishnav.SoleCount`. The widget ID stays `com.krishnav.SoleCount.widget`. The product ID stays `com.krishnav.SoleCount.pro`.
- Data stays on the iPhone. Health is read-only. The app still works when Health is off.
- Edit `project.yml`. The `.xcodeproj` is generated. Do not commit it.
- Keep the `.p8` key in `~/.appstoreconnect/private_keys/`. Keep answers in `fastlane/.env`. The review phone and email in git stay `REPLACE_ME`.
- Explain the change in plain English.

## Claude Code and Cursor

Both tools follow the same rules.

- Claude Code loads [CLAUDE.md](../CLAUDE.md).
- Cursor loads [AGENTS.md](../AGENTS.md), `CLAUDE.md`, and `.cursor/rules/solecount.mdc`.

Ask for one small change, the acceptance criteria, and a pull request. Ask the assistant to run `make check` and to say when it could not run `make test`. The model can be Claude or Grok. The rules are the same either way.

Paste a real error when something fails. Leave out the `.p8` file, `fastlane/.env`, and your Apple ID password.

## What GitHub runs

| Check | Runner | When it runs | What it proves |
|---|---|---|---|
| Repo checks | Linux (`ubuntu-latest`) | Pull requests, pushes to `main`, pushes to `cursor/**` | The shell checks in `scripts/check_repo.sh`, including a small self-test |
| iOS, Build and test | macOS (`macos-26`, Xcode 26) | Pull requests into `main`, and every push to `main` | Device compile with signing off, then `fastlane ios test` |
| iOS, TestFlight / App Store | macOS | A `v*` tag, or the manual iOS button | The existing upload job. It does not run on a pull request |
| Release | macOS | The manual Release button only | `fastlane ios ship` when the submit box is ticked, otherwise setup, test, and TestFlight |
| Screenshots | macOS | The manual Screenshots button only | Simulator screenshots |

A pull request that only changes guides, images, issue templates, the Cursor rule, `guard.yml`, or `scripts/check_repo.sh` skips the macOS job. Repo checks still run. A push to a `cursor/**` branch starts Repo checks and does not start the macOS runner. Open the pull request to build. After you merge, a push to `main` runs the macOS build again.

A newer push to the same pull request cancels the older macOS run. A Release run is not cancelled.

macOS minutes cost more than Linux minutes. That is why a cursor branch push and its pull request no longer each start a Mac.

## What a Linux assistant can prove

`make check` can pass or fail here. It does not compile Swift. It does not boot a simulator. A green Repo checks job is not a green iOS build. Say that in the pull request when the Mac run has not finished.

## Later, if you want it

These are recommendations. They are not part of this setup.

- Run `make test` on your Mac for this branch and keep the result.
- After you trust the macOS job, you can require it in branch protection. This setup does not change branch protection.
- Pin the GitHub Action versions to commit SHAs.
- Teach the Release button to call `make submit` only when you want that. Today the button does not set `SUBMIT=1`, so it does not send the app to App Review. Turning that on is a release-behavior change, so it waits for its own reviewed pull request.
- Compare the public privacy page with the binary Apple approved. See the release checklist.
