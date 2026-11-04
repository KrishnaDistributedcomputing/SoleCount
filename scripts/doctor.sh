#!/bin/bash
# Preflight checklist. Green means ready. Red means stop, with the exact fix.
# Exits 1 if any required item is red. Safe to run again. Never prints the key.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
# Path depends on how the script was started, so shellcheck cannot follow it.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

FAIL=0

pass() { printf '\033[1;32m✔ %s\033[0m\n' "$1"; }
bad() {
  printf '\033[1;31m✖ %s\033[0m\n' "$1"
  printf '  Fix: %s\n' "$2"
  FAIL=1
}
warn() {
  printf '\033[1;33m! %s\033[0m\n' "$1"
  printf '  Note: %s\n' "$2"
}

echo "SoleCount doctor"
echo ""

if ! command -v xcodebuild >/dev/null 2>&1; then
  bad "Xcode is not installed" "Install Xcode 26 from the Mac App Store, open it once, then run: make setup-local"
else
  xv="$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}' | cut -d. -f1)"
  if [ "${xv:-0}" -ge 26 ]; then
    pass "Xcode $(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')"
  else
    bad "Xcode 26 or newer is required (uploads are rejected without it)" "Update Xcode from the Mac App Store, then run: make doctor"
  fi
fi

if xcode-select -p >/dev/null 2>&1; then
  pass "Xcode command line tools are selected"
else
  bad "Xcode command line tools are not selected" "Run: xcode-select --install"
fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew is installed"
else
  bad "Homebrew is missing" "Run: make setup-local"
fi

if command -v xcodegen >/dev/null 2>&1; then
  pass "XcodeGen is installed"
else
  bad "XcodeGen is missing" "Run: make setup-local"
fi

if command -v fastlane >/dev/null 2>&1; then
  pass "fastlane is installed"
else
  bad "fastlane is missing" "Run: make setup-local"
fi

if command -v ruby >/dev/null 2>&1; then
  pass "Ruby is installed (it comes with Xcode)"
else
  bad "Ruby is missing" "Open Xcode once, then run: xcode-select --install"
fi

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [ -n "$branch" ]; then
  pass "Git branch is ${branch}"
else
  bad "This folder is not a git checkout" "Clone the repo again. See the Mac guide, step 2."
fi
if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
  warn "This folder has uncommitted edits" "make release does not commit them. Never commit a .p8 file or fastlane/.env."
fi

if [ -f "$ENV_FILE" ]; then
  pass "fastlane/.env exists (private, not committed)"
else
  bad "fastlane/.env is missing" "Run: make setup-local"
fi

team="$(get_env TEAM_ID)"
if is_placeholder "$team"; then
  team="$(grep -E '^DEVELOPMENT_TEAM' Config/Team.xcconfig 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' "' || true)"
fi
case "$team" in
  [A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9])
    pass "Team ID is saved"
    ;;
  "")
    bad "Team ID is blank" "After Apple's email, run: make release   (it asks once)"
    ;;
  *)
    bad "Team ID must be 10 letters or numbers" "Run: make release   and type the Team ID from Membership details"
    ;;
esac

key_id="$(get_env ASC_KEY_ID)"
if is_placeholder "$key_id"; then
  bad "API Key ID is blank" "Download AuthKey_*.p8 into Downloads, then run: make release"
else
  pass "API Key ID is saved"
fi

issuer="$(get_env ASC_ISSUER_ID)"
if is_placeholder "$issuer"; then
  bad "Issuer ID is blank" "Copy it from App Store Connect > Users and Access > Integrations, then run: make release"
else
  pass "Issuer ID is saved"
fi

key_path="$(saved_key_path)"
if [ -f "$key_path" ] && [ -r "$key_path" ]; then
  if grep -q "PRIVATE KEY" "$key_path"; then
    pass "API key file is readable ($(basename "$key_path"))"
  else
    bad "The .p8 file is not a private key" "Download it again from App Store Connect. Do not edit the inside. Then run: make release"
  fi
else
  bad "API key file is missing or not readable" "Leave AuthKey_*.p8 in Downloads, then run: make release"
fi

phone_file=""
email_file=""
if [ -f fastlane/metadata/review_information/phone_number.txt ]; then
  phone_file="$(tr -d '\r' < fastlane/metadata/review_information/phone_number.txt)"
fi
if [ -f fastlane/metadata/review_information/email_address.txt ]; then
  email_file="$(tr -d '\r' < fastlane/metadata/review_information/email_address.txt)"
fi
if ! is_placeholder "$phone_file" || ! is_placeholder "$(get_env REVIEW_PHONE)"; then
  pass "App Review phone is saved"
else
  bad "App Review phone is still a placeholder" "Run: make release   and type the phone with the country code"
fi
if ! is_placeholder "$email_file" || ! is_placeholder "$(get_env REVIEW_EMAIL)"; then
  pass "App Review email is saved"
else
  bad "App Review email is still a placeholder" "Run: make release   and type the email Apple can use"
fi

apple_id="$(get_env APPLE_ID)"
if is_placeholder "$apple_id"; then
  warn "Apple ID email is blank" "Optional. Without it, you create the app record and App Privacy on the website. With it, make release asks for one 2FA code."
else
  pass "Apple ID email is saved for the one-time login steps"
fi

if ls fastlane/screenshots/en-US/*.png >/dev/null 2>&1; then
  pass "App Store screenshots are already saved"
else
  warn "App Store screenshots are not saved yet" "make release takes the 6.9-inch set in the iPhone 17 Pro Max simulator, using sample shoes."
fi

can_call_api=0
if ! is_placeholder "$key_id" && ! is_placeholder "$issuer" && [ -f "$key_path" ] && [ -r "$key_path" ]; then
  can_call_api=1
fi

if [ "$can_call_api" -eq 1 ] && command -v ruby >/dev/null 2>&1; then
  export ASC_KEY_ID="$key_id"
  export ASC_ISSUER_ID="$issuer"
  export ASC_KEY_PATH="$key_path"
  export APP_IDENTIFIER="com.krishnav.SoleCount"
  set +e
  api_out="$(ruby fastlane/asc_api.rb status 2>&1)"
  api_code=$?
  set +e
  printf '%s\n' "$api_out" | while IFS= read -r line; do
    [ -n "$line" ] && printf '  %s\n' "$line"
  done
  case "$api_code" in
    0)
      pass "App Store Connect accepted the API key"
      ;;
    2)
      pass "App Store Connect accepted the API key"
      if is_placeholder "$apple_id"; then
        bad "The app record does not exist yet" "Add APPLE_ID=you@example.com to fastlane/.env and run make release (one 2FA code), or create the app on the website. The Mac guide has the form."
      else
        warn "The app record does not exist yet" "make release will ask for a 2FA code once and create it."
      fi
      ;;
    *)
      bad "The API key was rejected" "Check the Key ID, Issuer ID, and .p8 file. Accept the Paid Apps agreement, tax, and bank. Then run: make doctor"
      ;;
  esac
  if printf '%s\n' "$api_out" | grep -q "IAP: not created"; then
    warn "The \$0.99 purchase is not created yet" "make release creates com.krishnav.SoleCount.pro from fastlane/iap.json."
  fi
  if printf '%s\n' "$api_out" | grep -q "Bundle ID com.krishnav.SoleCount: not registered"; then
    warn "The bundle ID is not registered yet" "make release registers com.krishnav.SoleCount and turns on In-App Purchase."
  fi
fi

echo ""
echo "Still manual, because Apple does not allow a script to do them:"
echo "  - Pay for the membership and wait for the welcome email"
echo "  - Accept the Paid Apps agreement, tax, and bank"
echo "  - Create the API key and download the .p8 file once"
echo "  - Type a 2FA code if you saved an Apple ID"
echo "  - The first time only: add SoleCount Pro to version 1.0 on the website"
echo "  - Wait for Apple's review (about 1 to 2 days, sometimes longer)"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "All required checks passed. Next: make release"
  exit 0
fi
echo "Fix every red item, then run make doctor again."
exit 1
