#!/bin/bash
# Stop App Store commands with a clear message when the paid membership
# details are not on this Mac yet. Used by `make appstore-setup` and `make deploy`.
# Safe to run again. It never prints the key file itself.
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="fastlane/.env"

# Read one KEY=value from fastlane/.env. Empty if the file or key is missing.
env_value() {
  key="$1"
  if [ ! -f "$ENV_FILE" ]; then
    printf ''
    return 0
  fi
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" || true
}

# A path that starts with ~/ is turned into the home folder. bash 3.2 safe.
expand_home() {
  path="$1"
  prefix=$(printf '%s' '~')
  if [ "${path#"$prefix"/}" != "$path" ]; then
    printf '%s\n' "$HOME/${path#"$prefix"/}"
  else
    printf '%s\n' "$path"
  fi
}

is_placeholder() {
  case "$1" in
    ""|*XXXXXXXXXX*) return 0 ;;
    *) return 1 ;;
  esac
}

TEAM="$(env_value TEAM_ID)"
if is_placeholder "$TEAM"; then
  TEAM="$(grep -E '^DEVELOPMENT_TEAM' Config/Team.xcconfig 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' "' || true)"
fi
KEY_ID="$(env_value ASC_KEY_ID)"
ISSUER="$(env_value ASC_ISSUER_ID)"
KEY_PATH="$(env_value ASC_KEY_PATH)"
if [ -z "$KEY_PATH" ] && ! is_placeholder "$KEY_ID"; then
  KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
fi
KEY_PATH="$(expand_home "$KEY_PATH")"

MISSING=""
if is_placeholder "$TEAM"; then
  MISSING="${MISSING}
  - Team ID"
fi
if is_placeholder "$KEY_ID"; then
  MISSING="${MISSING}
  - API Key ID"
fi
if is_placeholder "$ISSUER"; then
  MISSING="${MISSING}
  - Issuer ID"
fi
if is_placeholder "$KEY_PATH" || [ ! -f "$KEY_PATH" ]; then
  MISSING="${MISSING}
  - .p8 key file (saved outside the project, in your home folder)"
fi

if [ -n "$MISSING" ]; then
  cat <<MSG
Your Apple Developer membership isn't active yet. Run make appstore-setup once Apple emails you.

This Mac is still missing:${MISSING}

You can run SoleCount now, with no membership:
  make test     tests in the iPhone Simulator
  make open     open Xcode, then press Cmd + R

When Apple emails you that the membership is active:
  1. Run: make setup
     Answer the Team ID, Key ID, Issuer ID, and .p8 questions.
  2. Run: make appstore-setup
  3. Run: make deploy
MSG
  exit 1
fi

exit 0
