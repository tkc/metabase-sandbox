#!/usr/bin/env bash
set -euo pipefail

MB_SITE_URL="${MB_SITE_URL:-http://localhost:3000}"
MB_EMAIL="${MB_EMAIL:-}"
MB_PASSWORD="${MB_PASSWORD:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DUCKDB_FILE="${REPO_ROOT}/duckdb/sample.duckdb"

if [[ ! -f "${DUCKDB_FILE}" ]]; then
  echo "DuckDB database not found at ${DUCKDB_FILE}" >&2
  echo "Run ./scripts/seed_duckdb.sh to create it before bootstrapping Metabase content." >&2
  exit 1
fi

if [[ -z "${MB_EMAIL}" || -z "${MB_PASSWORD}" ]]; then
  cat <<'EOF' >&2
Missing credentials.
Export MB_EMAIL and MB_PASSWORD for an existing Metabase admin user, for example:

  export MB_EMAIL="you@example.com"
  export MB_PASSWORD="supersecret"

Then re-run this script.
EOF
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run this script. Install jq and retry." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to run this script." >&2
  exit 1
fi

echo "Logging in to Metabase at ${MB_SITE_URL}"
SESSION_TOKEN="$(curl -sS -X POST "${MB_SITE_URL}/api/session" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"${MB_EMAIL}\", \"password\": \"${MB_PASSWORD}\"}" | jq -r '.id')"

if [[ "${SESSION_TOKEN}" == "null" || -z "${SESSION_TOKEN}" ]]; then
  echo "Failed to obtain session token. Check credentials and Metabase status." >&2
  exit 1
fi

AUTH_HEADER="X-Metabase-Session: ${SESSION_TOKEN}"

ensure_database() {
  local name="$1"
  local payload="$2"

  local existing_id
  existing_id="$(curl -sS "${MB_SITE_URL}/api/database" \
    -H "${AUTH_HEADER}" \
    | jq ".data[] | select(.name == \"${name}\") | .id")"

  if [[ -n "${existing_id}" ]]; then
    echo "Database \"${name}\" already exists with id ${existing_id}"
    echo "${existing_id}"
    return 0
  fi

  echo "Creating database \"${name}\""
  curl -sS -X POST "${MB_SITE_URL}/api/database" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    | jq '.id'
}

DUCKDB_PAYLOAD="$(cat <<'JSON'
{
  "name": "Sample Sales",
  "engine": "duckdb",
  "details": {
    "db": "/app/duckdb/sample.duckdb"
  },
  "is_full_sync": true,
  "is_on_demand": false,
  "schedules": {
    "metadata_sync": {"schedule_type": "hourly"},
    "cache_field_values": {"schedule_type": "daily"}
  }
}
JSON
)"

DB_ID="$(ensure_database "Sample Sales" "${DUCKDB_PAYLOAD}")"

if [[ "${DB_ID}" == "null" || -z "${DB_ID}" ]]; then
  echo "Unable to create or find the Sample Sales database." >&2
  exit 1
fi

echo "Using database id ${DB_ID}"

create_card() {
  local name="$1"
  local description="$2"
  local sql="$3"
  local visualization_settings="$4"

  local existing_id
  existing_id="$(curl -sS "${MB_SITE_URL}/api/card" \
    -H "${AUTH_HEADER}" \
    | jq ".data[] | select(.name == \"${name}\" and .database_id == ${DB_ID}) | .id")"

  if [[ -n "${existing_id}" ]]; then
    echo "Card \"${name}\" already exists with id ${existing_id}"
    echo "${existing_id}"
    return 0
  fi

  curl -sS -X POST "${MB_SITE_URL}/api/card" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg name "${name}" \
      --arg description "${description}" \
      --arg sql "${sql}" \
      --argjson viz "${visualization_settings}" \
      --argjson db_id "${DB_ID}" \
      '{
        name: $name,
        description: $description,
        display: "area",
        collection_id: null,
        database_id: $db_id,
        dataset_query: {
          type: "native",
          native: {
            query: $sql,
            "template-tags": {}
          },
          database: $db_id
        },
        visualization_settings: $viz
      }')" \
    | jq '.id'
}

MONTHLY_REVENUE_SQL=$'SELECT date_trunc(\'month\', o.order_date) AS month,\n       SUM(oi.quantity * oi.unit_price) AS revenue\nFROM sales.orders o\nJOIN sales.order_items oi ON oi.order_id = o.order_id\nGROUP BY 1\nORDER BY 1;'
MONTHLY_REVENUE_VIZ='{"graph.dimensions":["month"],"graph.metrics":["revenue"],"graph.show_goal":false,"graph.colors":["#509EE3"]}'

TOP_CUSTOMERS_SQL=$'SELECT c.first_name || \' \' || c.last_name AS customer,\n       SUM(oi.quantity * oi.unit_price) AS revenue\nFROM sales.customers c\nJOIN sales.orders o ON o.customer_id = c.customer_id\nJOIN sales.order_items oi ON oi.order_id = o.order_id\nGROUP BY 1\nORDER BY revenue DESC\nLIMIT 5;'
TOP_CUSTOMERS_VIZ='{"graph.dimensions":["customer"],"graph.metrics":["revenue"],"graph.show_values":true,"graph.colors":["#7FD1B9"]}'

CARD_REVENUE_ID="$(create_card "Monthly Revenue" "Revenue per month based on order totals." "${MONTHLY_REVENUE_SQL}" "${MONTHLY_REVENUE_VIZ}")"
CARD_CUSTOMERS_ID="$(create_card "Top Customers" "Top customers by revenue." "${TOP_CUSTOMERS_SQL}" "${TOP_CUSTOMERS_VIZ}")"

if [[ "${CARD_REVENUE_ID}" == "null" || -z "${CARD_REVENUE_ID}" ]]; then
  echo "Failed to ensure Monthly Revenue card." >&2
  exit 1
fi

if [[ "${CARD_CUSTOMERS_ID}" == "null" || -z "${CARD_CUSTOMERS_ID}" ]]; then
  echo "Failed to ensure Top Customers card." >&2
  exit 1
fi

ensure_dashboard() {
  local name="$1"
  local description="$2"

  local existing_id
  existing_id="$(curl -sS "${MB_SITE_URL}/api/dashboard" \
    -H "${AUTH_HEADER}" \
    | jq ".data[] | select(.name == \"${name}\") | .id")"

  if [[ -n "${existing_id}" ]]; then
    echo "Dashboard \"${name}\" already exists with id ${existing_id}"
    echo "${existing_id}"
    return 0
  fi

  curl -sS -X POST "${MB_SITE_URL}/api/dashboard" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg name "${name}" \
      --arg description "${description}" \
      '{name: $name, description: $description, collection_id: null}')" \
    | jq '.id'
}

DASHBOARD_ID="$(ensure_dashboard "Sales Overview" "Key metrics for the sample sales dataset.")"

if [[ "${DASHBOARD_ID}" == "null" || -z "${DASHBOARD_ID}" ]]; then
  echo "Failed to ensure Sales Overview dashboard." >&2
  exit 1
fi

add_card_to_dashboard() {
  local dashboard_id="$1"
  local card_id="$2"
  local col="$3"
  local row="$4"
  local size_x="$5"
  local size_y="$6"
  local viz_settings="$7"

  local exists
  exists="$(curl -sS "${MB_SITE_URL}/api/dashboard/${dashboard_id}" \
    -H "${AUTH_HEADER}" \
    | jq ".ordered_cards[] | select(.card_id == ${card_id}) | .id")"

  if [[ -n "${exists}" ]]; then
    echo "Card ${card_id} already placed on dashboard ${dashboard_id}"
    return 0
  fi

  curl -sS -X POST "${MB_SITE_URL}/api/dashboard/${dashboard_id}/cards" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --argjson card_id "${card_id}" \
      --argjson col "${col}" \
      --argjson row "${row}" \
      --argjson size_x "${size_x}" \
      --argjson size_y "${size_y}" \
      --argjson viz "${viz_settings}" \
      '{cardId: $card_id, row: $row, col: $col, sizeX: $size_x, sizeY: $size_y, parameter_mappings: [], visualization_settings: $viz}')" \
    > /dev/null
}

add_card_to_dashboard "${DASHBOARD_ID}" "${CARD_REVENUE_ID}" 0 0 12 8 "${MONTHLY_REVENUE_VIZ}"
add_card_to_dashboard "${DASHBOARD_ID}" "${CARD_CUSTOMERS_ID}" 12 0 12 8 "${TOP_CUSTOMERS_VIZ}"

echo
echo "Metabase sample environment is ready."
echo "Dashboard \"Sales Overview\" should now contain two starter cards."
