#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  check_prereqs.sh [--project PROJECT_ID]

Checks:
  - gcloud CLI availability
  - active gcloud account
  - target project configured and accessible
EOF
}

PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Error: gcloud CLI is not installed or not in PATH." >&2
  exit 1
fi

ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n 1 || true)"
if [[ -z "${ACTIVE_ACCOUNT}" ]]; then
  echo "Error: no active gcloud account. Run 'gcloud auth login' first." >&2
  exit 1
fi

if [[ -z "${PROJECT}" ]]; then
  PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
fi

if [[ -z "${PROJECT}" || "${PROJECT}" == "(unset)" ]]; then
  echo "Error: no project configured. Pass --project PROJECT_ID or set a default project." >&2
  exit 1
fi

if ! gcloud projects describe "${PROJECT}" --format='value(projectId)' >/dev/null 2>&1; then
  echo "Error: cannot access project '${PROJECT}'. Check permissions and project id." >&2
  exit 1
fi

echo "OK: authenticated as ${ACTIVE_ACCOUNT}"
echo "OK: project '${PROJECT}' is accessible"
