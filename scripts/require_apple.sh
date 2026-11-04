#!/bin/bash
# Stop App Store commands with a clear message when the paid membership
# details are not on this Mac yet. Used by make appstore-setup and scripts/deploy.sh.
# Safe to run again. It never prints the key file itself.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
# Path depends on how the script was started, so shellcheck cannot follow it.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

TEAM="$(get_env TEAM_ID)"
if is_placeholder "$TEAM"; then
  TEAM="$(grep -E '^DEVELOPMENT_TEAM' Config/Team.xcconfig 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' "' || true)"
fi
KEY_ID="$(get_env ASC_KEY_ID)"
ISSUER="$(get_env ASC_ISSUER_ID)"
KEY_PATH="$(saved_key_path)"

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
  - .p8 key file (Downloads, or ~/.appstoreconnect/private_keys)"
fi

if [ -n "$MISSING" ]; then
  cat <<MSG
Your Apple Developer membership isn't active yet, or the key is not on this Mac.

This Mac is still missing:${MISSING}

You can run SoleCount now, with no membership:
  make test     tests in the iPhone Simulator
  make open     open Xcode, then press Cmd + R

When Apple emails you that the membership is active:
  1. Create an Admin API key and leave the .p8 file in Downloads.
  2. Run: make doctor
  3. Run: make release
     It finds the .p8 file, reads the Key ID from the file name, and asks for the Team ID and Issuer ID once.
MSG
  exit 1
fi

exit 0
