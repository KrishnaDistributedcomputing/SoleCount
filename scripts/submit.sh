#!/bin/bash
# Send the latest TestFlight build to App Review.
# make release uploads the build and stops. Run this after you have tried it.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

bash scripts/prepare_apple.sh
echo ""
bash scripts/doctor.sh
echo ""
echo "Submitting the latest TestFlight build for review."
echo ""
SUBMIT=1 fastlane ios release
