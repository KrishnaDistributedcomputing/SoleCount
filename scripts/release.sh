#!/bin/bash
# One command for the whole App Store path. Safe to run again.
# Skips records that already exist. Always uploads a new build number,
# because Apple rejects a second upload of the same build.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

bash scripts/prepare_apple.sh
echo ""
bash scripts/doctor.sh
echo ""
echo "Checks passed. Starting the release."
echo "Finished steps are skipped. A new TestFlight build is uploaded, because Apple requires a new build number."
echo ""
fastlane ios ship
