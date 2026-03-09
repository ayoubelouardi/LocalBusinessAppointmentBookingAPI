#!/usr/bin/env bash

set -euo pipefail

# This script asserts that privileged or sensitive operations MUST NOT succeed
# when called without valid credentials. If any request returns a 2xx success
# status the script exits with failure so the team can treat that as a bug.

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admin12345}"
PYTHON_BIN="${PYTHON_BIN:-./venv/bin/python}"

if [ ! -x "${PYTHON_BIN}" ]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  else
    echo "Error: no usable Python interpreter found."
    exit 1
  fi
fi

echo "== Security assertion curl test (expect failures) =="
echo "Base URL: ${BASE_URL}"

LAST_BODY=""
LAST_CODE=""

call_api() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  local auth="${4:-}"
  local body_file
  body_file="$(mktemp)"

  if [ -n "${data}" ] && [ -n "${auth}" ]; then
    LAST_CODE="$(curl -sS -u "${auth}" -X "${method}" "${url}" -H "Content-Type: application/json" -d "${data}" -o "${body_file}" -w "%{http_code}")"
  elif [ -n "${data}" ]; then
    LAST_CODE="$(curl -sS -X "${method}" "${url}" -H "Content-Type: application/json" -d "${data}" -o "${body_file}" -w "%{http_code}")"
  elif [ -n "${auth}" ]; then
    LAST_CODE="$(curl -sS -u "${auth}" -X "${method}" "${url}" -o "${body_file}" -w "%{http_code}")"
  else
    LAST_CODE="$(curl -sS -X "${method}" "${url}" -o "${body_file}" -w "%{http_code}")"
  fi

  LAST_BODY="$(<"${body_file}")"
  rm -f "${body_file}"
}

expect_not_success() {
  local context="$1"
  # If the last code indicates success (2xx) treat it as a bug and fail.
  if [[ "${LAST_CODE}" =~ ^2 ]]; then
    echo "BUG: ${context} unexpectedly succeeded"
    echo "HTTP ${LAST_CODE}"
    echo "Body: ${LAST_BODY}"
    exit 1
  else
    echo "OK (failed as expected): ${context} -> ${LAST_CODE}"
  fi
}

echo
echo "[A] Wrong credentials should be rejected (admin:wrongpass)"
call_api "POST" "${BASE_URL}/api/business-profiles/" '{"name":"X","address":"X","phone":"1","email":"x@x","opening_time":"09:00:00","closing_time":"17:00:00"}' "${ADMIN_USER}:wrongpass"
expect_not_success "Create business profile with wrong credentials"

echo
echo "[B] Unauthenticated creation of business profile must be rejected"
call_api "POST" "${BASE_URL}/api/business-profiles/" '{"name":"X","address":"X","phone":"1","email":"x@x","opening_time":"09:00:00","closing_time":"17:00:00"}'
expect_not_success "Create business profile without auth"

echo
echo "[C] Listing services without auth must NOT be allowed (should fail)"
call_api "GET" "${BASE_URL}/api/services/"
expect_not_success "List services without auth"

echo
echo "[D] Availability endpoint should require auth and fail without it"
call_api "GET" "${BASE_URL}/api/availability/?date=2026-03-20"
expect_not_success "Availability without auth"

echo
echo "[E] Creating a booking without auth must be forbidden"
call_api "POST" "${BASE_URL}/api/bookings/" '{"service":1,"customer_name":"Bad","customer_email":"bad@example.com","appointment_date":"2026-03-20","start_time":"10:00:00","status":"pending"}'
expect_not_success "Create booking without auth"

echo
echo "[F] Modifying a service with invalid credentials must be rejected"
call_api "PATCH" "${BASE_URL}/api/services/1/" '{"price":"99.00"}' "${ADMIN_USER}:badpass"
expect_not_success "Update service with bad credentials"

echo
echo "[G] Schedule endpoint must require admin auth (reject anonymous)"
call_api "GET" "${BASE_URL}/api/schedule/?date=2026-03-20"
expect_not_success "Schedule without auth"

echo
echo "All security assertion checks finished. If any of the checks above reported a BUG, fix the API so the operation is rejected."
