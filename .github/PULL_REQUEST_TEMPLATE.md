## What this changes

One or two sentences.

## Plan

Short. Which files, and what you left alone.

## How you will know it works

- [ ] Acceptance criteria from the issue, or written here
- [ ] `make check` (Linux or Mac)
- [ ] `make test` on a Mac when Swift, `project.yml`, or the fastlane lanes change
- [ ] Repo checks workflow
- [ ] iOS workflow, when this pull request changes code or workflows

## Checked

Say which commands you ran, and the result. Say which ones you could not run.

## Left unchanged

- [ ] Bundle ID `com.krishnav.SoleCount` and product ID `com.krishnav.SoleCount.pro`
- [ ] The app stays free and offline. Health stays read-only.
- [ ] Privacy URL, support URL, and marketing URL
- [ ] `make release` still stops before App Review. `make submit` is still the review command.
- [ ] No `.p8`, `AuthKey_*`, `fastlane/.env`, or review phone or email

## Release

This pull request does not upload to TestFlight and does not submit to Apple.
The next upload follows docs/RELEASE-CHECKLIST.md.
