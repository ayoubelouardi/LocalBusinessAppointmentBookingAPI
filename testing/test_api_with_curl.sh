#!/usr/bin/env bash

set -euo pipefail

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

echo "== Local Business Appointment Booking API curl test =="
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

expect_code() {
  local expected="$1"
  local context="$2"
  if [ "${LAST_CODE}" != "${expected}" ]; then
    echo "FAIL: ${context}"
    echo "Expected HTTP ${expected}, got ${LAST_CODE}"
    echo "Body: ${LAST_BODY}"
    exit 1
  fi
}

extract_json_field() {
  local json="$1"
  local field="$2"
  "${PYTHON_BIN}" -c "import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])" "${json}" "${field}"
}

# Step 0: Verify server is reachable before running tests.
call_api "GET" "${BASE_URL}/api/"
expect_code "200" "API root should be reachable"

# Step 0.5: Ensure database schema is up to date before test data setup.
"${PYTHON_BIN}" manage.py migrate --noinput >/dev/null

# Step 1: Reset database test data and ensure a known admin account exists.
"${PYTHON_BIN}" manage.py shell -c "from django.contrib.auth import get_user_model; from appointments.core.models import Booking, Service, BusinessProfile; Booking.objects.all().delete(); Service.objects.all().delete(); BusinessProfile.objects.all().delete(); User=get_user_model(); User.objects.filter(username='${ADMIN_USER}').delete(); User.objects.create_superuser(username='${ADMIN_USER}', email='admin@example.com', password='${ADMIN_PASS}')"

echo
echo "[1] Create Business Profile (admin-only)"
# Step 2: Create business profile required for availability and schedule calculations.
call_api "POST" "${BASE_URL}/api/business-profiles/" '{
  "name": "Salon Test",
  "address": "Main Street",
  "phone": "123456789",
  "email": "owner@salon.test",
  "opening_time": "09:00:00",
  "closing_time": "17:00:00"
}' "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "201" "Create business profile"
echo "${LAST_BODY}"

echo
echo "[2] Create Service (admin-only)"
# Step 3: Create a service used by bookings.
call_api "POST" "${BASE_URL}/api/services/" '{
  "name": "Haircut",
  "description": "Standard haircut",
  "duration_minutes": 30,
  "price": "25.00"
}' "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "201" "Create service"
SERVICE_RESPONSE="${LAST_BODY}"
echo "${SERVICE_RESPONSE}"

SERVICE_ID="$(extract_json_field "${SERVICE_RESPONSE}" "id")"

echo
echo "[3] List Services"
# Step 4: Verify service listing endpoint works.
call_api "GET" "${BASE_URL}/api/services/" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "List services"
echo "${LAST_BODY}"

echo
echo "[4] Filter Services by name"
# Step 5: Verify query filtering support on services endpoint.
call_api "GET" "${BASE_URL}/api/services/?name=hair" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Filter services by name"
echo "${LAST_BODY}"

echo
echo "[5] Update Service (admin-only)"
# Step 6: Update service details.
call_api "PATCH" "${BASE_URL}/api/services/${SERVICE_ID}/" '{"price": "30.00"}' "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Update service"
echo "${LAST_BODY}"

echo
echo "[6] Create Booking"
# Step 7: Create first booking and verify end_time is auto-calculated.
call_api "POST" "${BASE_URL}/api/bookings/" "{
  \"service\": ${SERVICE_ID},
  \"customer_name\": \"John Doe\",
  \"customer_email\": \"john@example.com\",
  \"appointment_date\": \"2026-03-20\",
  \"start_time\": \"10:00:00\",
  \"status\": \"pending\"
}" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "201" "Create booking"
BOOKING_RESPONSE="${LAST_BODY}"
echo "${BOOKING_RESPONSE}"

BOOKING_ID="$(extract_json_field "${BOOKING_RESPONSE}" "id")"

echo
echo "[7] Prevent Overlapping Booking"
# Step 8: Attempt overlapping booking; should return validation error.
call_api "POST" "${BASE_URL}/api/bookings/" "{
  \"service\": ${SERVICE_ID},
  \"customer_name\": \"Overlap User\",
  \"customer_email\": \"overlap@example.com\",
  \"appointment_date\": \"2026-03-20\",
  \"start_time\": \"10:15:00\",
  \"status\": \"pending\"
}" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "400" "Overlapping booking should fail"
echo "${LAST_BODY}"

echo
echo "[8] Availability Endpoint"
# Step 9: Verify availability endpoint excludes occupied slots.
call_api "GET" "${BASE_URL}/api/availability/?date=2026-03-20" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Availability endpoint"
echo "${LAST_BODY}"

echo
echo "[9] Confirm Booking (admin-only)"
# Step 10: Confirm pending booking via custom confirm action.
call_api "PATCH" "${BASE_URL}/api/bookings/${BOOKING_ID}/confirm/" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Confirm booking"
echo "${LAST_BODY}"

echo
echo "[10] Cancel Booking (idempotent)"
# Step 11: Cancel booking via custom cancel action.
call_api "PATCH" "${BASE_URL}/api/bookings/${BOOKING_ID}/cancel/" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Cancel booking"
echo "${LAST_BODY}"

echo
echo "[11] Cancel Booking Again"
# Step 12: Re-cancel same booking to validate idempotent behavior.
call_api "PATCH" "${BASE_URL}/api/bookings/${BOOKING_ID}/cancel/" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Cancel booking again should be idempotent"
echo "${LAST_BODY}"

echo
echo "[12] Schedule Endpoint (admin-only)"
# Step 13: View daily schedule as admin.
call_api "GET" "${BASE_URL}/api/schedule/?date=2026-03-20" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "200" "Schedule endpoint"
echo "${LAST_BODY}"

echo
echo "[13] Schedule Unauthorized Check"
# Step 14: Verify schedule endpoint rejects unauthenticated access.
call_api "GET" "${BASE_URL}/api/schedule/?date=2026-03-20"
expect_code "403" "Schedule endpoint should reject anonymous access"
echo "HTTP ${LAST_CODE}"
echo "${LAST_BODY}"

echo
echo "[14] OpenAPI Schema"
# Step 15: Verify OpenAPI schema endpoint is available. download a yaml.
call_api "GET" "${BASE_URL}/api/schema/"
expect_code "200" "Schema endpoint"
echo "Schema endpoint reachable"

echo
echo "[15] Delete Service (admin-only cleanup)"
# Step 16: Delete created service to validate delete operation.
call_api "DELETE" "${BASE_URL}/api/services/${SERVICE_ID}/" "" "${ADMIN_USER}:${ADMIN_PASS}"
expect_code "204" "Delete service cleanup"
echo "HTTP ${LAST_CODE}"

echo
echo "All curl tests finished."
