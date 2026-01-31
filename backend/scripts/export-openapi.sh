#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/openapi"
OUTPUT_FILE="${OUTPUT_DIR}/openapi.json"
APP_LOG="${ROOT_DIR}/build/openapi-bootrun.log"

mkdir -p "${OUTPUT_DIR}"
mkdir -p "$(dirname "${APP_LOG}")"

if [[ -z "${JAVA_HOME:-}" ]] && command -v mise >/dev/null 2>&1; then
  if JAVA_HOME="$(mise where java@21.0.2 2>/dev/null)"; then
    export JAVA_HOME
  fi
fi

cleanup() {
  if [[ -n "${BOOT_PID:-}" ]]; then
    kill "${BOOT_PID}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

"${ROOT_DIR}/gradlew" -p "${ROOT_DIR}" bootRun --args="--spring.profiles.active=openapi" > "${APP_LOG}" 2>&1 &
BOOT_PID=$!

echo "Aguardando API em http://localhost:8081/api-docs ..."
for _ in {1..60}; do
  if curl -sf "http://localhost:8081/api-docs" -o "${OUTPUT_FILE}"; then
    echo "OpenAPI exportado em ${OUTPUT_FILE}"
    exit 0
  fi
  sleep 2
done

echo "Falha ao exportar OpenAPI. Veja o log em ${APP_LOG}" >&2
exit 1
