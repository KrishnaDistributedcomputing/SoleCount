#!/bin/bash
# Find the API key and ask only for the Apple answers that are still blank.
# Safe to run again. It never prints the key file and never puts it in the project.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
# Path depends on how the script was started, so shellcheck cannot follow it.
# shellcheck disable=SC1091
source "$(dirname "$0")/lib.sh"

ensure_env_file

current_key="$(get_env ASC_KEY_ID)"
saved="$HOME/.appstoreconnect/private_keys/AuthKey_${current_key}.p8"
if ! is_placeholder "$current_key" && [ -f "$saved" ]; then
  echo "API key ${current_key} is already saved outside the project."
  set_env ASC_KEY_PATH "$saved" >/dev/null || true
else
  found="$(find_newest_authkey)"
  if [ -n "$found" ]; then
    echo "Found $(basename "$found")."
    echo "The Key ID is the middle of that file name. Copying it outside the project so it is never committed."
    adopt_authkey "$found" >/dev/null
  else
    echo "No AuthKey_*.p8 file in Downloads yet."
  fi
fi

prompt_env() {
  key="$1"
  question="$2"
  current="$(get_env "$key")"
  if ! is_placeholder "$current"; then
    echo "${question}: kept"
    return 0
  fi
  if [ ! -t 0 ]; then
    echo "${question}: skipped (no Terminal to type in)"
    return 0
  fi
  answer=""
  read -r -p "${question} (press Return to skip): " answer || answer=""
  if [ -z "$answer" ]; then
    echo "Skipped."
    return 0
  fi
  set_env "$key" "$answer"
}

prompt_env TEAM_ID "Team ID (10 characters, developer.apple.com/account > Membership details)"
prompt_env ASC_ISSUER_ID "Issuer ID (the long code above the keys table)"
prompt_env APPLE_ID "Apple ID email, optional, for the one-time app record and privacy answers"
prompt_env REVIEW_PHONE "Phone number for App Review, with country code"
prompt_env REVIEW_EMAIL "Email for App Review"

team="$(get_env TEAM_ID)"
case "$team" in
  [A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9])
    /usr/bin/sed -i '' "s|^DEVELOPMENT_TEAM *=.*|DEVELOPMENT_TEAM = ${team}|" Config/Team.xcconfig
    ;;
esac

write_review_file() {
  env_key="$1"
  file="$2"
  value="$(get_env "$env_key")"
  if is_placeholder "$value"; then
    return 0
  fi
  printf '%s\n' "$value" > "fastlane/metadata/review_information/${file}.txt"
}

write_review_file REVIEW_PHONE phone_number
write_review_file REVIEW_EMAIL email_address
