#!/bin/bash
# Show the TestFlight build and the App Store review state. Never prints the key.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
# Path depends on how the script was started, so shellcheck cannot follow it.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

key_id="$(get_env ASC_KEY_ID)"
issuer="$(get_env ASC_ISSUER_ID)"
key_path="$(saved_key_path)"
if is_placeholder "$key_id" || is_placeholder "$issuer" || [ ! -f "$key_path" ]; then
  echo "Apple details are not on this Mac yet, so there is no review status."
  echo "You can still run the app: make test, then make open."
  echo "After Apple's email: make release"
  exit 1
fi

export ASC_KEY_ID="$key_id"
export ASC_ISSUER_ID="$issuer"
export ASC_KEY_PATH="$key_path"
export APP_IDENTIFIER="com.krishnav.SoleCount"
ruby fastlane/asc_api.rb status
