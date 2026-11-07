#!/usr/bin/env bash
# Fast checks that run on Linux and on a Mac. They do not build the app.
# Xcode and the simulator stay in `make test` (see docs/DEVELOPER.md).
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)

FAILS=0

ok() { printf 'ok   %s\n' "$1"; }

bad() {
  printf 'FAIL %s\n' "$1" >&2
  if [ -n "${2:-}" ]; then
    printf '     %s\n' "$2" >&2
  fi
  FAILS=$((FAILS + 1))
}

require_contains() {
  local file="$1" text="$2" label="$3"
  if [ ! -f "$file" ]; then
    bad "$label" "Missing file: $file"
    return
  fi
  if grep -F -q -- "$text" "$file"; then
    ok "$label"
  else
    bad "$label" "Expected this text in $file: $text"
  fi
}

require_file_text() {
  local file="$1" expected="$2" label="$3" actual
  if [ ! -f "$file" ]; then
    bad "$label" "Missing file: $file"
    return
  fi
  actual=$(tr -d '[:space:]' < "$file")
  if [ "$actual" = "$expected" ]; then
    ok "$label"
  else
    bad "$label" "Expected $expected in $file"
  fi
}

require_absent() {
  local file="$1" text="$2" label="$3"
  if [ ! -f "$file" ]; then
    bad "$label" "Missing file: $file"
    return
  fi
  if grep -F -q -- "$text" "$file"; then
    bad "$label" "Found unwanted text in $file: $text"
  else
    ok "$label"
  fi
}

# Print matching paths and return 1 when a tracked secret is present.
check_tracked_secrets() {
  local root="$1" file base failed=0
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    base=$(basename "$file")
    case "$file" in
      *.env.example) continue ;;
    esac
    case "$base" in
      *.p8 | *.p12 | *.cer | *.mobileprovision | *.pem | AuthKey_* | .env)
        printf 'tracked secret file: %s\n' "$file" >&2
        failed=1
        ;;
    esac
  done < <(git -C "$root" ls-files)

  local code
  set +e
  git -C "$root" grep -I -n -E -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' >/dev/null
  code=$?
  set -e
  if [ "$code" -eq 0 ]; then
    printf 'tracked file contains a private key block\n' >&2
    git -C "$root" grep -I -n -E -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' >&2 || true
    failed=1
  elif [ "$code" -gt 1 ]; then
    printf 'git grep failed while scanning %s\n' "$root" >&2
    failed=1
  fi

  return "$failed"
}

check_identity() {
  local privacy support terms marketing bundle product team
  privacy="https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/PRIVACY.md"
  support="https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/SUPPORT.md"
  terms="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
  marketing="https://github.com/KrishnaDistributedcomputing/SoleCount"
  bundle="com.krishnav.SoleCount"
  product="com.krishnav.SoleCount.pro"

  require_contains "SoleCount/FeatureFlags.swift" "static let monetizationEnabled = false" "The app stays free"
  require_absent "SoleCount/FeatureFlags.swift" "monetizationEnabled = true" "The free flag is not turned on in source"
  require_contains "SoleCount/StoreManager.swift" "static let proProductID = \"$product\"" "Product ID stays $product"
  require_contains "fastlane/iap.json" "\"product_id\": \"$product\"" "fastlane IAP product ID stays $product"
  require_contains "project.yml" "PRODUCT_BUNDLE_IDENTIFIER: $bundle" "App bundle ID stays $bundle"
  require_contains "project.yml" "PRODUCT_BUNDLE_IDENTIFIER: $bundle.widget" "Widget bundle ID stays $bundle.widget"
  require_contains "project.yml" "MARKETING_VERSION: \"1.0\"" "Marketing version stays 1.0"
  require_contains "project.yml" "CURRENT_PROJECT_VERSION: \"1\"" "Committed build number stays 1 (fastlane picks the next TestFlight number)"
  require_contains "fastlane/Fastfile" "APP_IDENTIFIER = \"$bundle\"" "Fastlane app identifier stays $bundle"
  require_contains "fastlane/Appfile" "app_identifier(\"$bundle\")" "Appfile identifier stays $bundle"
  require_contains "SoleCount/SettingsView.swift" "$privacy" "In-app privacy link"
  require_contains "SoleCount/SettingsView.swift" "$support" "In-app support link"
  require_contains "SoleCount/SettingsView.swift" "$terms" "In-app terms link"
  require_contains "SoleCountTests/IdentityTests.swift" "$privacy" "Identity test covers the privacy link"
  require_contains "SoleCountTests/IdentityTests.swift" "$support" "Identity test covers the support link"
  require_file_text "fastlane/metadata/en-US/privacy_url.txt" "$privacy" "App Store privacy URL"
  require_file_text "fastlane/metadata/en-US/support_url.txt" "$support" "App Store support URL"
  require_file_text "fastlane/metadata/en-US/marketing_url.txt" "$marketing" "App Store marketing URL"
  require_contains "SoleCount/SoleCount.entitlements" "group.$bundle" "App App Group"
  require_contains "SoleCountWidget/SoleCountWidget.entitlements" "group.$bundle" "Widget App Group"
  require_contains "Shared/WidgetSnapshot.swift" "group.$bundle" "Widget snapshot suite name"
  require_contains "SoleCount/HealthKitActivityReader.swift" "toShare: []" "HealthKit requests no write types"
  require_absent "project.yml" "NSHealthUpdateUsageDescription" "The app does not declare Health write access"

  if git grep -n 'toShare:' -- '*.swift' | grep -v 'toShare: \[\]'; then
    bad "HealthKit share list" "Every toShare: list stays empty"
  else
    ok "No other HealthKit share list"
  fi

  if git grep -n 'NSHealthUpdateUsageDescription' -- '*.swift' '*.plist' 'project.yml' '*.xcprivacy' '*.entitlements' '*.json' >/dev/null; then
    bad "Health write usage string" "A Health write purpose string is present. SoleCount only reads Health."
  else
    ok "No Health write usage string"
  fi

  team=$(sed -n 's/^DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*//p' Config/Team.xcconfig | head -1 | tr -d ' "')
  if [ -z "$team" ]; then
    ok "Team ID stays blank in git"
  else
    bad "Team ID stays blank in git" "Config/Team.xcconfig has a Team ID. Keep it in fastlane/.env on the Mac."
  fi

  require_file_text "fastlane/metadata/review_information/phone_number.txt" "REPLACE_ME" "Review phone stays out of git"
  require_file_text "fastlane/metadata/review_information/email_address.txt" "REPLACE_ME" "Review email stays out of git"

  if git ls-files -- 'SoleCount/Info.plist' '*.xcodeproj/*' 'Package.swift' 'Podfile' 'Cartfile' | grep -q .; then
    bad "Generated project or package manifest is tracked" "Edit project.yml. SoleCount does not add package managers."
    git ls-files -- 'SoleCount/Info.plist' '*.xcodeproj/*' 'Package.swift' 'Podfile' 'Cartfile' >&2 || true
  else
    ok "No generated Xcode project or package manifest"
  fi

  require_contains "fastlane/Fastfile" "lane :ship do" "fastlane ship lane still exists"
  require_contains "fastlane/Fastfile" "lane :test do" "fastlane test lane still exists"
  require_contains "fastlane/Fastfile" 'wants_submit = ENV["SUBMIT"] == "1"' "App Review still waits for SUBMIT=1"
  require_contains "scripts/release.sh" "fastlane ios ship" "make release still runs fastlane ship"
  require_contains "scripts/submit.sh" "SUBMIT=1 fastlane ios release" "make submit is still the review command"
  require_contains "Makefile" "bash scripts/release.sh" "make release still calls scripts/release.sh"
  require_contains "Makefile" "bash scripts/submit.sh" "make submit still calls scripts/submit.sh"

  require_contains ".github/workflows/ios.yml" "runs-on: macos-26" "iOS workflow still uses the macOS runner"
  require_contains ".github/workflows/release.yml" "runs-on: macos-26" "Release workflow still uses the macOS runner"
  require_contains ".github/workflows/screenshots.yml" "runs-on: macos-26" "Screenshots workflow still uses the macOS runner"
  require_contains ".github/workflows/ios.yml" "startsWith(github.ref, 'refs/tags/v') || github.event_name == 'workflow_dispatch'" "TestFlight stays off pull requests"
  require_contains ".github/workflows/release.yml" "workflow_dispatch:" "Release stays a manual workflow"
  require_contains ".github/workflows/release.yml" "fastlane ios ship" "Manual release still runs fastlane ship"
  require_contains ".github/workflows/release.yml" "cancel-in-progress: false" "A release run is not cancelled by a newer push"
  require_absent ".github/workflows/ios.yml" 'branches: [main, "cursor/**"]' "cursor branch pushes do not start the macOS runner"
  require_absent ".github/workflows/ios.yml" "SUBMIT=1" "The iOS workflow does not submit to App Review"
  require_absent ".github/workflows/release.yml" "SUBMIT=1" "The Release workflow does not submit to App Review"
  require_contains ".github/workflows/guard.yml" "runs-on: ubuntu-latest" "Repo checks stay on the cheap Linux runner"
  require_contains ".github/workflows/guard.yml" 'cursor/**' "cursor branch pushes still get the Linux checks"
}

prepare_fixture() {
  local root="$1"
  mkdir -p "$root"
  git -C "$root" init -q
  git -C "$root" config user.email check@example.com
  git -C "$root" config user.name check
  git -C "$root" config commit.gpgsign false
}

commit_fixture() {
  local root="$1"
  git -C "$root" add -- .
  git -C "$root" commit -q --no-gpg-sign -m fixture
}

self_test() {
  local tmp root
  tmp=$(mktemp -d)
  # shellcheck disable=SC2064
  trap 'rm -rf "'"$tmp"'"' EXIT

  expect_rejected() {
    local label="$1" root="$2" output
    if output=$(check_tracked_secrets "$root" 2>&1); then
      printf 'self-test failed: %s was allowed\n%s\n' "$label" "$output" >&2
      return 1
    fi
  }

  root="$tmp/secret-name"
  prepare_fixture "$root"
  printf 'not-a-real-key\n' > "$root/AuthKey_TEST.p8"
  commit_fixture "$root"
  expect_rejected "a tracked AuthKey file" "$root"

  root="$tmp/env-file"
  prepare_fixture "$root"
  mkdir -p "$root/fastlane"
  printf 'TEAM_ID=SECRET\n' > "$root/fastlane/.env"
  commit_fixture "$root"
  expect_rejected "fastlane/.env" "$root"

  root="$tmp/pem"
  prepare_fixture "$root"
  # Assemble the header so this script does not contain a real key block.
  kind="PRIVATE KEY"
  printf '%s\n' "-----BEGIN ${kind}-----" 'ABC' "-----END ${kind}-----" > "$root/notes.txt"
  commit_fixture "$root"
  expect_rejected "a private key block" "$root"

  root="$tmp/safe"
  prepare_fixture "$root"
  mkdir -p "$root/fastlane"
  printf 'example\n' > "$root/.env.example"
  printf 'example\n' > "$root/fastlane/.env.example"
  printf 'raw.include?("BEGIN PRIVATE KEY")\n' > "$root/asc_api.rb"
  commit_fixture "$root"
  if ! output=$(check_tracked_secrets "$root" 2>&1); then
    printf 'self-test failed: the safe examples were rejected\n%s\n' "$output" >&2
    return 1
  fi

  trap - EXIT
  rm -rf "$tmp"
  printf 'self-test passed\n'
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit 0
fi

printf 'SoleCount repo checks\n'
check_identity
if ! check_tracked_secrets "$ROOT"; then
  bad "Secret scan" "A secret file or private key block is tracked. Keys belong in ~/.appstoreconnect/private_keys/. Answers belong in fastlane/.env."
else
  ok "No tracked secret files or private key blocks"
fi

if [ "$FAILS" -gt 0 ]; then
  printf '\n%s repo check(s) failed.\n' "$FAILS" >&2
  exit 1
fi

printf '\nRepo checks passed.\n'
