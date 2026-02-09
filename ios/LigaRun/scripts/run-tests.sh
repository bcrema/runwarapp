#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not available. Run this script on macOS with Xcode 15+ installed."
  exit 0
fi

cd "$(dirname "$0")/.."

xcodegen generate
XCODE_DESTINATION=${XCODE_DESTINATION:-platform=iOS Simulator,OS=latest,name=iPhone 15}
xcodebuild -scheme LigaRun -destination "${XCODE_DESTINATION}" test
