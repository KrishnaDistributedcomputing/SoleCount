#!/bin/bash
# SoleCount one-time Mac setup. Run from the project folder:
#   bash scripts/setup_mac.sh
# Safe to run again. It never uploads your key anywhere and never puts it in the project folder.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

say() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; }
ok()  { printf "\033[1;32m✔ %s\033[0m\n" "$1"; }

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
ENV_FILE="$ROOT/fastlane/.env"
[ -f "$ENV_FILE" ] || cp "$ROOT/fastlane/.env.example" "$ENV_FILE"
chmod 600 "$ENV_FILE"

get_env() { grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- || true; }
set_env() {
  local key="$1" value="$2"
  if grep -qE "^$key=" "$ENV_FILE"; then
    /usr/bin/sed -i '' "s|^$key=.*|$key=$value|" "$ENV_FILE"
  else
    echo "$key=$value" >> "$ENV_FILE"
  fi
}
ask() { # ask KEY "Question" [optional]
  local key="$1" question="$2" current; current="$(get_env "$key")"
  if [ -n "$current" ] && [[ "$current" != *XXXXXXXXXX* ]]; then echo "$question: $current (kept)"; return; fi
  local answer; read -r -p "$question: " answer
  if [ -z "$answer" ] && [ "${3:-}" != "optional" ]; then echo "This one is required."; ask "$@"; return; fi
  set_env "$key" "$answer"
}

say "Your App Store Connect details (see AUTOMATION.md, steps 2-3)"
ask TEAM_ID "Team ID (10 characters, developer.apple.com/account > Membership details)"
ask ASC_KEY_ID "API Key ID (10 characters)"
ask ASC_ISSUER_ID "Issuer ID (long code above the keys table)"

# Move the .p8 key to a safe place outside the project
KEY_ID="$(get_env ASC_KEY_ID)"
KEY_DIR="$HOME/.appstoreconnect/private_keys"
KEY_DEST="$KEY_DIR/AuthKey_${KEY_ID}.p8"
mkdir -p "$KEY_DIR"; chmod 700 "$HOME/.appstoreconnect" "$KEY_DIR"
if [ ! -f "$KEY_DEST" ]; then
  if [ -f "$HOME/Downloads/AuthKey_${KEY_ID}.p8" ]; then
    mv "$HOME/Downloads/AuthKey_${KEY_ID}.p8" "$KEY_DEST"
  else
    read -r -p "Drag the AuthKey_${KEY_ID}.p8 file into this window and press Return: " KEY_SRC
    KEY_SRC="${KEY_SRC%\"}"; KEY_SRC="${KEY_SRC#\"}"; KEY_SRC="${KEY_SRC//\\ / }"; KEY_SRC="$(echo "$KEY_SRC" | xargs)"
    cp "$KEY_SRC" "$KEY_DEST"
  fi
fi
chmod 600 "$KEY_DEST"
set_env ASC_KEY_PATH "$KEY_DEST"
ok "API key stored at $KEY_DEST (outside the project, never committed)"

ask APPLE_ID "Apple ID email (optional: lets fastlane create the app record + privacy answers; press Return to skip)" optional

# Team ID into the Xcode settings file (not a secret)
TEAM="$(get_env TEAM_ID)"
/usr/bin/sed -i '' "s|^DEVELOPMENT_TEAM =.*|DEVELOPMENT_TEAM = $TEAM|" "$ROOT/Config/Team.xcconfig"
ok "Team ID $TEAM saved in Config/Team.xcconfig"

# App Review contact (required by Apple)
RI="$ROOT/fastlane/metadata/review_information"
if grep -q REPLACE_ME "$RI/phone_number.txt"; then
  read -r -p "Phone number for App Review, with country code (e.g. +1 416 555 0100): " PHONE
  echo "$PHONE" > "$RI/phone_number.txt"
fi
if grep -q REPLACE_ME "$RI/email_address.txt"; then
  read -r -p "Email for App Review: " EMAIL
  echo "$EMAIL" > "$RI/email_address.txt"
fi
ok "App Review contact saved"

# 5. Generate the Xcode project and open it
say "Generating SoleCount.xcodeproj"
xcodegen generate
ok "Project generated"

# Pre-download the Simulator runtime if missing (needed for tests and screenshots)
xcrun simctl list devices available | grep -q "iPhone" || xcodebuild -downloadPlatform iOS || true

open SoleCount.xcodeproj
say "Done!"
cat <<MSG
Next steps:
  1) First time only:   fastlane setup       (creates the App Store Connect pieces)
  2) Every release:     bash scripts/deploy.sh  (tests -> TestFlight -> App Review)
MSG
