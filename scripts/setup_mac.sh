#!/bin/bash
# SoleCount one-time Mac setup. Run from the project folder:
#   bash scripts/setup_mac.sh
#   bash scripts/setup_mac.sh --no-apple
# Safe to run again. It never uploads your key anywhere and never puts it in the project folder.
# Apple questions can be skipped (press Return, or pass --no-apple) while the
# paid Developer membership is still being processed. Tools, the Xcode project,
# the simulator, and Xcode itself still run.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"
# Path depends on how the script was started, so shellcheck cannot follow it.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

SKIP_APPLE=0
for arg in "$@"; do
  case "$arg" in
    --no-apple) SKIP_APPLE=1 ;;
    *) echo "Unknown option: $arg"; echo "Use: bash scripts/setup_mac.sh [--no-apple]"; exit 1 ;;
  esac
done

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; }
ok()  { printf "\033[1;32m✔ %s\033[0m\n" "$1"; }

SKIPPED_LABELS=""
NEED_APPLE=0
remember_skip() {
  SKIPPED_LABELS="${SKIPPED_LABELS}
  - $1"
}
remember_apple_skip() {
  remember_skip "$1"
  NEED_APPLE=1
}

# 1. Xcode
say "Checking Xcode"
if ! xcode-select -p >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  echo "Xcode is not ready. Install Xcode 26 from the Mac App Store, open it once, then run this again."
  exit 1
fi
xcodebuild -version | head -1
XV=$(xcodebuild -version | head -1 | awk '{print $2}' | cut -d. -f1)
if [ "${XV:-0}" -lt 26 ]; then echo "Apple requires Xcode 26 or newer for uploads. Please update Xcode."; exit 1; fi
ok "Xcode is ready"

# 2. Homebrew
say "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew (it may ask for your Mac password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # The line we append must stay literal. It is read later by zsh, not by this script.
    # shellcheck disable=SC2016
    grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

# 3. XcodeGen + fastlane
say "Installing XcodeGen and fastlane"
brew list xcodegen >/dev/null 2>&1 || brew install xcodegen
brew list fastlane >/dev/null 2>&1 || brew install fastlane
brew upgrade xcodegen fastlane 2>/dev/null || true
ok "xcodegen $(xcodegen --version 2>/dev/null | awk '{print $NF}'), fastlane installed"

# 4. Your App Store Connect details -> fastlane/.env (git-ignored)
ensure_env_file

# No Terminal (for example a script) cannot answer questions. Skip them.
if [ "$SKIP_APPLE" != 1 ] && [ ! -t 0 ]; then
  echo "No Terminal to type in. Skipping the Apple questions."
  SKIP_APPLE=1
fi

# A downloaded key is named AuthKey_<Key ID>.p8. Remember it without asking.
current_key="$(get_env ASC_KEY_ID)"
saved_copy="$HOME/.appstoreconnect/private_keys/AuthKey_${current_key}.p8"
if ! is_placeholder "$current_key" && [ -f "$saved_copy" ]; then
  echo "API key ${current_key} is already saved outside the project."
elif found_p8="$(find_newest_authkey)"; [ -n "$found_p8" ]; then
  echo "Found $(basename "$found_p8")."
  echo "The Key ID is the middle of that file name. Saving a copy outside the project."
  adopt_authkey "$found_p8" >/dev/null
fi

# Nothing to ask yet: do the local setup and stop, same as make setup-local.
if [ "$SKIP_APPLE" != 1 ]; then
  team_now="$(get_env TEAM_ID)"
  key_now="$(get_env ASC_KEY_ID)"
  issuer_now="$(get_env ASC_ISSUER_ID)"
  if is_placeholder "$team_now" && is_placeholder "$key_now" && is_placeholder "$issuer_now"; then
    echo "No Apple membership details on this Mac yet."
    echo "Continuing with local setup (same as make setup-local)."
    echo "After Apple's email, leave the .p8 file in Downloads and run: make release"
    SKIP_APPLE=1
  fi
fi

say "Apple Developer questions"
if [ "$SKIP_APPLE" = 1 ]; then
  echo "Skipping every Apple question."
  echo "That is fine while Apple is still processing your membership (up to 48 hours)."
else
  echo "If Apple is still processing your membership (up to 48 hours), press Return on each question."
  echo "Tools, the Xcode project, the iPhone Simulator, and Xcode still get set up."
fi

ask() {
  key="$1"
  question="$2"
  needed_later="${3:-}"
  current="$(get_env "$key")"
  if ! is_placeholder "$current"; then
    echo "$question: $current (kept)"
    return 0
  fi
  if [ "$SKIP_APPLE" = 1 ]; then
    echo "$question: skipped"
    if [ "$needed_later" = "later" ]; then
      remember_apple_skip "$question"
    else
      remember_skip "$question"
    fi
    return 0
  fi
  answer=""
  read -r -p "$question (press Return to skip): " answer || answer=""
  if [ -z "$answer" ]; then
    echo "Skipped."
    if [ "$needed_later" = "later" ]; then
      remember_apple_skip "$question"
    else
      remember_skip "$question"
    fi
    return 0
  fi
  set_env "$key" "$answer"
}

ask TEAM_ID "Team ID (10 characters, developer.apple.com/account > Membership details)" later
ask ASC_KEY_ID "API Key ID (10 characters)" later
ask ASC_ISSUER_ID "Issuer ID (long code above the keys table)" later

# Move the .p8 key to a safe place outside the project, only when we have a Key ID.
KEY_ID="$(get_env ASC_KEY_ID)"
if is_placeholder "$KEY_ID"; then
  echo "Skipped the .p8 key file (no Key ID yet)."
  remember_apple_skip "the .p8 key file"
else
  KEY_DIR="$HOME/.appstoreconnect/private_keys"
  KEY_DEST="$KEY_DIR/AuthKey_${KEY_ID}.p8"
  mkdir -p "$KEY_DIR"
  chmod 700 "$HOME/.appstoreconnect" "$KEY_DIR"
  if [ -f "$KEY_DEST" ]; then
    chmod 600 "$KEY_DEST"
    set_env ASC_KEY_PATH "$KEY_DEST"
    ok "API key already stored at $KEY_DEST (outside the project, never committed)"
  elif [ "$SKIP_APPLE" = 1 ]; then
    echo "Skipped the .p8 key file."
    remember_apple_skip "the .p8 key file"
  elif [ -f "$HOME/Downloads/AuthKey_${KEY_ID}.p8" ]; then
    mv "$HOME/Downloads/AuthKey_${KEY_ID}.p8" "$KEY_DEST"
    chmod 600 "$KEY_DEST"
    set_env ASC_KEY_PATH "$KEY_DEST"
    ok "API key stored at $KEY_DEST (outside the project, never committed)"
  else
    KEY_SRC=""
    read -r -p "Drag the AuthKey_${KEY_ID}.p8 file here and press Return (or press Return alone to skip): " KEY_SRC || KEY_SRC=""
    KEY_SRC="${KEY_SRC%\"}"
    KEY_SRC="${KEY_SRC#\"}"
    KEY_SRC="${KEY_SRC//\\ / }"
    if [ -z "$KEY_SRC" ]; then
      echo "Skipped the .p8 key file."
      remember_apple_skip "the .p8 key file"
    else
      KEY_SRC="$(printf '%s' "$KEY_SRC" | xargs)"
      if [ ! -f "$KEY_SRC" ]; then
        echo "Could not find that file. Skipping the .p8 key for now."
        remember_apple_skip "the .p8 key file"
      else
        cp "$KEY_SRC" "$KEY_DEST"
        chmod 600 "$KEY_DEST"
        set_env ASC_KEY_PATH "$KEY_DEST"
        ok "API key stored at $KEY_DEST (outside the project, never committed)"
      fi
    fi
  fi
fi

ask APPLE_ID "Apple ID email (optional, for creating the app listing)"

# Team ID into the Xcode settings file (not a secret). Leave it blank for simulator-only.
TEAM="$(get_env TEAM_ID)"
if is_placeholder "$TEAM"; then
  /usr/bin/sed -i '' 's|^DEVELOPMENT_TEAM *=.*|DEVELOPMENT_TEAM =|' "$ROOT/Config/Team.xcconfig"
  echo "No Team ID saved. The iPhone Simulator does not need one."
else
  /usr/bin/sed -i '' "s|^DEVELOPMENT_TEAM *=.*|DEVELOPMENT_TEAM = ${TEAM}|" "$ROOT/Config/Team.xcconfig"
  ok "Team ID ${TEAM} saved in Config/Team.xcconfig"
fi

# App Review contact. Leave the placeholder in place when skipped, so the next run asks again.
RI="$ROOT/fastlane/metadata/review_information"
if grep -q REPLACE_ME "$RI/phone_number.txt"; then
  if [ "$SKIP_APPLE" = 1 ]; then
    echo "Skipped the App Review phone number."
    remember_skip "App Review phone number"
  else
    PHONE=""
    read -r -p "Phone number for App Review, with country code (press Return to skip): " PHONE || PHONE=""
    if [ -z "$PHONE" ]; then
      echo "Skipped."
      remember_skip "App Review phone number"
    else
      printf '%s\n' "$PHONE" > "$RI/phone_number.txt"
    fi
  fi
fi
if grep -q REPLACE_ME "$RI/email_address.txt"; then
  if [ "$SKIP_APPLE" = 1 ]; then
    echo "Skipped the App Review email."
    remember_skip "App Review email"
  else
    EMAIL=""
    read -r -p "Email for App Review (press Return to skip): " EMAIL || EMAIL=""
    if [ -z "$EMAIL" ]; then
      echo "Skipped."
      remember_skip "App Review email"
    else
      printf '%s\n' "$EMAIL" > "$RI/email_address.txt"
    fi
  fi
fi
if ! grep -q REPLACE_ME "$RI/phone_number.txt" && ! grep -q REPLACE_ME "$RI/email_address.txt"; then
  ok "App Review contact saved"
fi

# 5. Generate the Xcode project and open it
say "Generating SoleCount.xcodeproj"
xcodegen generate
ok "Project generated"

# Pre-download the Simulator runtime if missing (needed for tests and screenshots)
xcrun simctl list devices available | grep -q "iPhone" || xcodebuild -downloadPlatform iOS || true

open SoleCount.xcodeproj
say "Done!"

if [ "$NEED_APPLE" = 1 ]; then
  cat <<MSG
These Apple items were skipped:${SKIPPED_LABELS}

You do not need them to run SoleCount in the iPhone Simulator.

Do this now:
  make test     run the tests in the simulator
  In Xcode, press Cmd + R to run the app

Your Apple Developer membership isn't active yet.
After Apple emails you, leave the .p8 file in Downloads and run: make release
MSG
elif [ -n "$SKIPPED_LABELS" ]; then
  cat <<MSG
These optional items were skipped:${SKIPPED_LABELS}

Next steps:
  make doctor     see what is still missing
  make release    the rest of the App Store path
MSG
else
  cat <<MSG
Next steps:
  make doctor     see what is still missing
  make release    the rest of the App Store path
MSG
fi
