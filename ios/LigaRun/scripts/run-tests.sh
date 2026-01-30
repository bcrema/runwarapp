#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not available. Run this script on macOS with Xcode 15+ installed."
  exit 0
fi

cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild -scheme LigaRun -destination "platform=iOS Simulator,name=iPhone 15" test
