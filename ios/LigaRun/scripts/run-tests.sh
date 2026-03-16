#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not available. Run this script on macOS with Xcode 15+ installed."
  exit 0
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not available. Install XcodeGen before running tests."
  exit 1
fi

cd "$(dirname "$0")/.."

PROJECT_PATH=${XCODE_PROJECT_PATH:-LigaRun.xcodeproj}
SCHEME=${XCODE_SCHEME:-LigaRun}
XCODE_DESTINATION=${XCODE_DESTINATION:-}
XCODE_DERIVED_DATA_PATH=${XCODE_DERIVED_DATA_PATH:-$(pwd)/DerivedData}
XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH=${XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH:-$(pwd)/SourcePackages}
XCODE_ONLY_TESTING=${XCODE_ONLY_TESTING:-}
XCODE_SKIP_GENERATE=${XCODE_SKIP_GENERATE:-0}

if [[ -z "${XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION:-}" ]]; then
  if [[ -d "${XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH}/checkouts" ]]; then
    XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION=1
  else
    XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION=0
  fi
fi

mkdir -p \
  "${XCODE_DERIVED_DATA_PATH}" \
  "${XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH}" \
  "$(pwd)/ModuleCache" \
  "$(pwd)/.swiftpm/cache"

export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-$(pwd)/ModuleCache}
export SWIFT_MODULE_CACHE_PATH=${SWIFT_MODULE_CACHE_PATH:-$(pwd)/ModuleCache}
export SWIFTPM_CACHE_PATH=${SWIFTPM_CACHE_PATH:-$(pwd)/.swiftpm/cache}

resolve_destination() {
  local destinations line name os

  destinations=$(xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME}" -showdestinations 2>/dev/null || true)
  while IFS= read -r line; do
    if [[ "${line}" == *"platform:iOS Simulator"* && "${line}" == *"name:iPhone"* && "${line}" == *"OS:"* ]]; then
      name=$(sed -n 's/.*name:\([^,}]*\).*/\1/p' <<< "${line}" | sed 's/^ *//; s/ *$//')
      os=$(sed -n 's/.*OS:\([^,}]*\).*/\1/p' <<< "${line}" | sed 's/^ *//; s/ *$//')
      if [[ -n "${name}" && -n "${os}" ]]; then
        printf 'platform=iOS Simulator,OS=%s,name=%s\n' "${os}" "${name}"
        return 0
      fi
    fi
  done <<< "${destinations}"

  printf '%s\n' 'platform=iOS Simulator,OS=latest,name=iPhone 17'
}

if [[ "${XCODE_SKIP_GENERATE}" != "1" ]]; then
  xcodegen generate
fi

if [[ -z "${XCODE_DESTINATION}" ]]; then
  XCODE_DESTINATION=$(resolve_destination)
fi

cmd=(
  xcodebuild
  -project "${PROJECT_PATH}"
  -scheme "${SCHEME}"
  -destination "${XCODE_DESTINATION}"
  -derivedDataPath "${XCODE_DERIVED_DATA_PATH}"
  -clonedSourcePackagesDirPath "${XCODE_CLONED_SOURCE_PACKAGES_DIR_PATH}"
)

if [[ "${XCODE_DISABLE_AUTOMATIC_PACKAGE_RESOLUTION}" == "1" ]]; then
  cmd+=(-disableAutomaticPackageResolution)
fi

if [[ -n "${XCODE_ONLY_TESTING}" ]]; then
  IFS=',' read -r -a only_testing <<< "${XCODE_ONLY_TESTING}"
  for test_identifier in "${only_testing[@]}"; do
    if [[ "${test_identifier}" == */* ]]; then
      cmd+=("-only-testing:${test_identifier}")
    else
      cmd+=("-only-testing:LigaRunTests/${test_identifier}")
    fi
  done
fi

cmd+=(test)
"${cmd[@]}"
