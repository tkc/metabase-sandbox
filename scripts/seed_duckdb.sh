#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DUCKDB_DIR="${REPO_ROOT}/duckdb"
DB_FILE="${DUCKDB_DIR}/sample.duckdb"
SEED_SQL="${DUCKDB_DIR}/seed.sql"

if [[ ! -f "${SEED_SQL}" ]]; then
  echo "Seed file not found at ${SEED_SQL}" >&2
  exit 1
fi

mkdir -p "${DUCKDB_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found. Install Docker before running this script." >&2
  exit 1
fi

echo "Seeding DuckDB database at ${DB_FILE}"
docker run --rm \
  -v "${DUCKDB_DIR}:/data" \
  duckdb/duckdb:latest \
  /data/sample.duckdb \
  -c ".read '/data/seed.sql'" \
  >/dev/null

echo "Done. Database stored at ${DB_FILE}"
