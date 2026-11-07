# Before the next upload

Read this before `make release`, `make submit`, the GitHub Release button, or a version tag. Those commands talk to Apple. This page does not run them.

Version 1.0 is already approved. The next upload needs a new build number. Apple rejects a second upload of the same build.

## Do this on the Mac before anything else

The shipping copy may be `~/Desktop/SoleCount`. It may hold commits and uncommitted files that GitHub does not have. This environment did not open that Mac, and it did not change that folder.

Leave the folder where it is. Do not follow the delete steps in [START-HERE.md](START-HERE.md) until the commands below are saved. Do not `git pull` over that folder yet. Do not `git reset`, and do not force-push.

In Terminal, from that folder:

```bash
cd ~/Desktop/SoleCount
git status
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git log --oneline -30
git stash list
```

Copy the output somewhere outside the repo. Then:

```bash
git fetch origin
git log --oneline HEAD..origin/main
git log --oneline origin/main..HEAD
```

- The first `git log` lists GitHub commits that the Mac folder does not have.
- The second `git log` lists Mac commits that GitHub does not have.

If the second list has commits, push them to a new branch name. Do not push them onto `main`.

```bash
git push -u origin HEAD:cursor/mac-baseline-reconcile
```

Open a pull request from that branch. Read the diff before you merge it. If `git status` shows a `.p8` file, `AuthKey_*`, or `fastlane/.env`, leave those untracked. They stay on the Mac.

Uncommitted signing, widget, Fastfile, screenshot, or contact edits belong in that comparison too. Commit only the files you mean to keep, on that new branch, after you have read them. Keep real phone numbers and email addresses in `fastlane/.env` or in GitHub secrets.

After that pull request is merged, update the Mac folder with `git checkout main && git pull`.

## What was reported, and what GitHub showed

Inspected on 7 November 2026. This is a record of that inspection, not a live App Store lookup.

**Reported approved build.** SoleCount 1.0, build 2, approved on 6 November 2026. This environment did not sign in to App Store Connect, so it did not confirm that build.

**GitHub `main` at the inspection.** Commit `d41209a` (4 November 2026), "Update privacy policy regarding camera and feedback". `project.yml` says marketing version `1.0` and committed build number `1`. fastlane ignores that committed build number at upload time. It asks App Store Connect for the latest TestFlight build and adds one. A later `make release` therefore uploads a new build. It does not rebuild build 2.

**The two commits after the last finished test run** (`d9c6685`, `d41209a`) change only `docs/PRIVACY.md`.

**GitHub Actions.** The last run that finished the test job successfully was the merge of pull request 7, commit `e71eeb7`. The two later runs on `main` (docs only) ended **cancelled**, with no test step recorded. They are not a pass, and they are not a test failure.

**Open pull requests at the inspection.** None. Pull requests 1 through 7 are merged. This change does not copy them in again.

**Branch `cursor/setup-without-apple-043d` on GitHub.** It points at `8707a16`, which is already inside `main` through pull request 7. A Mac branch can reuse that name and still contain different commits.

**Reported Mac-only commits.** These were named as local work on `~/Desktop/SoleCount`, branch `cursor/setup-without-apple-043d`. They are not in this GitHub clone, and they were not on any GitHub branch when this page was written:

- Feature commits: `740a4a8`, `d99297c`, `90a5e9f`, `e2a3f71`, `2a028c2`, `afd2f8e`
- Docs commits: `66a2717`, `bb63397`

Uncommitted Mac work was also reported: signing, widget, Fastfile, screenshots, and contact setup. Treat that report as real until the Terminal output says otherwise. Do not assume GitHub matches the approved app.

## Known difference inside GitHub itself

`fastlane/metadata/en-US/privacy_url.txt` and the in-app privacy link both open `docs/PRIVACY.md`. That page mentions the camera and a "Sole check". The Swift sources and `project.yml` on this GitHub `main` have the photo library picker and do not mention a camera permission or a Sole check. The root `PRIVACY.md` does not mention the camera.

The approved binary was not inspected here. Leave both privacy pages as they are until the Mac comparison shows which text matches the app Apple approved.

The public URLs stay:

- Privacy: `https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/PRIVACY.md`
- Support: `https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/SUPPORT.md`
- Marketing: `https://github.com/KrishnaDistributedcomputing/SoleCount`

## Upload checklist

Use this only after the Mac comparison is merged or you have written down that there was nothing to merge.

- [ ] You have the Terminal output from the Mac folder.
- [ ] Mac-only commits are on GitHub in a reviewed pull request, or you recorded that the second `git log` was empty.
- [ ] `main` is the commit you want Apple to build.
- [ ] `make check` passed.
- [ ] `make test` passed on the Mac.
- [ ] `make doctor` ends with "All required checks passed."
- [ ] The `.p8` file is in `~/.appstoreconnect/private_keys/`, not in the project folder.
- [ ] `fastlane/.env` is on the Mac only. GitHub secrets hold the same Key ID, Issuer ID, encoded key, Team ID, review phone, and review email if you use the Release button.
- [ ] You tried the current App Store build and you know what this upload changes.
- [ ] Run `make release` on the Mac. It uploads a **new** TestFlight build and the store listing. It stops before App Review.
- [ ] Install that build from the TestFlight app and use it on your iPhone.
- [ ] When it looks right, run `make submit`.
- [ ] After that version is actually released on the App Store, put that release instant in `SoleCount/ReleaseManifest.json` under the marketing version. Use an ISO-8601 time with a timezone, from the App Store release record. Leave `releasedAt` null until then. Do not write the approval time, the time Xcode compiled the app, or the time a phone installed it. The 6 November 2026 approval email is not that value. About reads this file and does not invent a date.

`make release` calls `fastlane ios ship`. `make submit` sets `SUBMIT=1` and calls `fastlane ios release`. That split is the current release setup. This checklist does not change it.

The GitHub Release button defaults the submit box to on, then runs `fastlane ios ship` or the TestFlight steps. It does not set `SUBMIT=1`. With the lanes as they are today, that button does not send the app to App Review. Use `make submit` on the Mac when you want review. A later pull request can wire the button to `SUBMIT=1` after you agree, because that would change how a release ships.

`bash scripts/deploy.sh --beta-only` stops after TestFlight and skips the store-listing upload. The full `bash scripts/deploy.sh` uploads the listing and still waits for `make submit` before review.

## What this checklist does not do

It does not merge a pull request, change branch protection, upload a build, or submit to Apple. It does not prove the approved binary matches `d41209a` or the Mac commits. It does not replace [START-HERE.md](START-HERE.md) for a brand-new Mac that has no local SoleCount folder.
