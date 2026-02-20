#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  read_metrics.sh --project PROJECT_ID --filter FILTER [options]

Required:
  --project PROJECT_ID   GCP project id
  --filter FILTER        Cloud Monitoring filter expression

Options:
  --start UTC_ISO8601    Interval start (default: now-1h)
  --end UTC_ISO8601      Interval end (default: now)
  --limit N              Max number of points/series (default: 200)
  --format FORMAT        gcloud output format (default: table)
  -h, --help             Show this help
EOF
}

iso_now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

iso_one_hour_ago_utc() {
  if date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
    date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ"
  else
    date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

PROJECT=""
FILTER=""
START=""
END=""
LIMIT="200"
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
    --start)
      START="${2:-}"
      shift 2
      ;;
    --end)
      END="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
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

if [[ -z "${END}" ]]; then
  END="$(iso_now_utc)"
fi

if [[ -z "${START}" ]]; then
  START="$(iso_one_hour_ago_utc)"
fi

gcloud monitoring time-series list \
  --project="${PROJECT}" \
  --filter="${FILTER}" \
  --interval-start="${START}" \
  --interval-end="${END}" \
  --limit="${LIMIT}" \
  --format="${FORMAT}"
