#!/bin/bash
# Compile the app, the widget, and the intents for a real iPhone, with signing off.
# This catches Swift errors that the simulator test might not build.
# It does not need an Apple Team ID.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

xcodegen generate

xcodebuild build \
  -project SoleCount.xcodeproj \
  -scheme SoleCount \
  -destination "generic/platform=iOS" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

echo "Device compile finished (signing off)."
