#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
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

# Step 0: Verify server is reachable before running tests.
curl -sS "${BASE_URL}/api/" >/dev/null

# Step 0.5: Ensure database schema is up to date before test data setup.
"${PYTHON_BIN}" manage.py migrate --noinput >/dev/null

# Step 1: Reset database test data and ensure a known admin account exists.
"${PYTHON_BIN}" manage.py shell -c "from django.contrib.auth import get_user_model; from appointments.core.models import Booking, Service, BusinessProfile; Booking.objects.all().delete(); Service.objects.all().delete(); BusinessProfile.objects.all().delete(); User=get_user_model(); User.objects.filter(username='${ADMIN_USER}').delete(); User.objects.create_superuser(username='${ADMIN_USER}', email='admin@example.com', password='${ADMIN_PASS}')"

echo
echo "[1] Create Business Profile (admin-only)"
# Step 2: Create business profile required for availability and schedule calculations.
curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -X POST "${BASE_URL}/api/business-profiles/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Salon Test",
    "address": "Main Street",
    "phone": "123456789",
    "email": "owner@salon.test",
    "opening_time": "09:00:00",
    "closing_time": "17:00:00"
  }'

echo
echo "[2] Create Service (admin-only)"
# Step 3: Create a service used by bookings.
SERVICE_RESPONSE=$(curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -X POST "${BASE_URL}/api/services/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Haircut",
    "description": "Standard haircut",
    "duration_minutes": 30,
    "price": "25.00"
  }')
echo "${SERVICE_RESPONSE}"

SERVICE_ID=$(
  "${PYTHON_BIN}" -c "import json,sys; print(json.loads(sys.argv[1])['id'])" "${SERVICE_RESPONSE}"
)

echo
echo "[3] List Services"
# Step 4: Verify service listing endpoint works.
curl -sS "${BASE_URL}/api/services/"

echo
echo "[4] Filter Services by name"
# Step 5: Verify query filtering support on services endpoint.
curl -sS "${BASE_URL}/api/services/?name=hair"

echo
echo "[5] Update Service (admin-only)"
# Step 6: Update service details.
curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -X PATCH "${BASE_URL}/api/services/${SERVICE_ID}/" \
  -H "Content-Type: application/json" \
  -d '{"price": "30.00"}'

echo
echo "[6] Create Booking"
# Step 7: Create first booking and verify end_time is auto-calculated.
BOOKING_RESPONSE=$(curl -sS \
  -X POST "${BASE_URL}/api/bookings/" \
  -H "Content-Type: application/json" \
  -d "{
    \"service\": ${SERVICE_ID},
    \"customer_name\": \"John Doe\",
    \"customer_email\": \"john@example.com\",
    \"appointment_date\": \"2026-03-20\",
    \"start_time\": \"10:00:00\",
    \"status\": \"pending\"
  }")
echo "${BOOKING_RESPONSE}"

BOOKING_ID=$(
  "${PYTHON_BIN}" -c "import json,sys; print(json.loads(sys.argv[1])['id'])" "${BOOKING_RESPONSE}"
)

echo
echo "[7] Prevent Overlapping Booking"
# Step 8: Attempt overlapping booking; should return validation error.
curl -sS \
  -X POST "${BASE_URL}/api/bookings/" \
  -H "Content-Type: application/json" \
  -d "{
    \"service\": ${SERVICE_ID},
    \"customer_name\": \"Overlap User\",
    \"customer_email\": \"overlap@example.com\",
    \"appointment_date\": \"2026-03-20\",
    \"start_time\": \"10:15:00\",
    \"status\": \"pending\"
  }"

echo
echo "[8] Availability Endpoint"
# Step 9: Verify availability endpoint excludes occupied slots.
curl -sS "${BASE_URL}/api/availability/?date=2026-03-20"

echo
echo "[9] Confirm Booking (admin-only)"
# Step 10: Confirm pending booking via custom confirm action.
curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -X PATCH "${BASE_URL}/api/bookings/${BOOKING_ID}/confirm/"

echo
echo "[10] Cancel Booking (idempotent)"
# Step 11: Cancel booking via custom cancel action.
curl -sS \
  -X PATCH "${BASE_URL}/api/bookings/${BOOKING_ID}/cancel/"

echo
echo "[11] Cancel Booking Again"
# Step 12: Re-cancel same booking to validate idempotent behavior.
curl -sS \
  -X PATCH "${BASE_URL}/api/bookings/${BOOKING_ID}/cancel/"

echo
echo "[12] Schedule Endpoint (admin-only)"
# Step 13: View daily schedule as admin.
curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  "${BASE_URL}/api/schedule/?date=2026-03-20"

echo
echo "[13] Schedule Unauthorized Check"
# Step 14: Verify schedule endpoint rejects unauthenticated access.
curl -sS -i "${BASE_URL}/api/schedule/?date=2026-03-20"

echo
echo "[14] OpenAPI Schema"
# Step 15: Verify OpenAPI schema endpoint is available.
curl -sS "${BASE_URL}/api/schema/" >/dev/null && echo "Schema endpoint reachable"

echo
echo "[15] Delete Service (admin-only cleanup)"
# Step 16: Delete created service to validate delete operation.
curl -sS -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -X DELETE "${BASE_URL}/api/services/${SERVICE_ID}/" \
  -i

echo
echo "All curl tests finished."
