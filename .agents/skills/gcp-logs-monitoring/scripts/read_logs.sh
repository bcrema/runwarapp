#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  read_logs.sh --project PROJECT_ID --filter FILTER [options]

Required:
  --project PROJECT_ID   GCP project id
  --filter FILTER        Cloud Logging filter expression

Options:
  --freshness DURATION   Query freshness window (default: 1h)
  --limit N              Max number of entries (default: 100)
  --order ORDER          asc or desc (default: desc)
  --format FORMAT        gcloud output format (default: table)
  -h, --help             Show this help
EOF
}

PROJECT=""
FILTER=""
FRESHNESS="1h"
LIMIT="100"
ORDER="desc"
FORMAT="table"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="${2:-}"
      shift 2
      ;;
    --filter)
      FILTER="${2:-}"
      shift 2
      ;;
    --freshness)
      FRESHNESS="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --order)
      ORDER="${2:-}"
      shift 2
      ;;
    --format)
      FORMAT="${2:-}"
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

if [[ -z "${PROJECT}" ]]; then
  echo "Error: --project is required." >&2
  usage >&2
  exit 1
fi

if [[ -z "${FILTER}" ]]; then
  echo "Error: --filter is required." >&2
  usage >&2
  exit 1
fi

if [[ "${ORDER}" != "asc" && "${ORDER}" != "desc" ]]; then
  echo "Error: --order must be 'asc' or 'desc'." >&2
  exit 1
fi

gcloud logging read "${FILTER}" \
  --project="${PROJECT}" \
  --freshness="${FRESHNESS}" \
  --limit="${LIMIT}" \
  --order="${ORDER}" \
  --format="${FORMAT}"
