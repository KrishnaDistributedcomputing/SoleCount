#!/bin/bash
# The one deploy command:  bash scripts/deploy.sh
#   1. runs every test         (fastlane test)
#   2. uploads to TestFlight   (fastlane beta)
#   3. submits to App Review   (fastlane release; goes live automatically when approved)
#
# Options:
#   bash scripts/deploy.sh --beta-only    stop after TestFlight
#   bash scripts/deploy.sh --setup        run the one-time App Store Connect setup first
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f fastlane/.env ] && [ -z "${ASC_KEY_ID:-}" ]; then
  echo "fastlane/.env not found. Run: bash scripts/setup_mac.sh."; exit 1
fi

RUN_SETUP=0; BETA_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --setup) RUN_SETUP=1 ;;
    --beta-only) BETA_ONLY=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

step() { printf "\n\033[1;34m==> %s\033[0m\n" "$1"; }

[ "$RUN_SETUP" = 1 ] && { step "One-time App Store Connect setup"; fastlane ios setup; }
step "1/3 Tests";             fastlane ios test
step "2/3 TestFlight upload"; fastlane ios beta
if [ "$BETA_ONLY" = 1 ]; then echo "Stopped after TestFlight (--beta-only)."; exit 0; fi
step "3/3 App Review";        fastlane ios release
printf "\n\033[1;32mAll done.\033[0m Check https://appstoreconnect.apple.com for review status.\n"
