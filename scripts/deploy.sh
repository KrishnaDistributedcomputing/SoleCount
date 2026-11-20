#!/bin/bash
# Tests, then TestFlight, then the store listing.
# This does not send the app to App Review. `make submit` does that.
# The command that does setup plus this upload is: make release
#
# Options:
#   bash scripts/deploy.sh --beta-only    stop after TestFlight
#   bash scripts/deploy.sh --setup        refresh the App Store records first
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

bash "$(dirname "$0")/prepare_apple.sh"
# App Store upload needs the paid membership. Stop here with a plain message if it is not ready.
bash "$(dirname "$0")/require_apple.sh"

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
step "3/3 Store listing";      fastlane ios release
printf "\n\033[1;32mUpload finished.\033[0m The build is on TestFlight. Review starts after: make submit\n"
