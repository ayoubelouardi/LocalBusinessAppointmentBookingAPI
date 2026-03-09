#!/usr/bin/env bash

set -euo pipefail

APP_PORT="${PORT:-8080}"
PYTHON_BIN="${PYTHON_BIN:-./venv/bin/python}"
# Optional: allow override of the start command for platforms that manage the process
# Example: START_CMD="python manage.py runserver 0.0.0.0:8080"
START_CMD="${START_CMD:-}"

if [ ! -x "${PYTHON_BIN}" ]; then
  PYTHON_BIN="python3"
fi

if [ -n "${START_CMD}" ]; then
  echo "[deploy-production] Using custom start command: ${START_CMD}"
  echo "[deploy-production] Installing dependencies"
  "${PYTHON_BIN}" -m pip install -r requirements.txt
  echo "[deploy-production] Running migrations"
  "${PYTHON_BIN}" manage.py migrate --noinput
  echo "[deploy-production] Collecting static files"
  "${PYTHON_BIN}" manage.py collectstatic --noinput
  echo "[deploy-production] Executing START_CMD"
  exec sh -c "${START_CMD}"
fi

echo "[deploy-production] Installing dependencies"
"${PYTHON_BIN}" -m pip install -r requirements.txt

echo "[deploy-production] Running migrations"
"${PYTHON_BIN}" manage.py migrate --noinput

echo "[deploy-production] Collecting static files"
"${PYTHON_BIN}" manage.py collectstatic --noinput

# If .env does not exist, create it from .env.example and generate secrets
if [ ! -f ".env" ]; then
  echo "[deploy-production] .env not found — creating from .env.example and generating secrets"
  if [ -f ".env.example" ]; then
    cp .env.example .env
  else
    touch .env
  fi

  # generate a secure Django secret key and an admin password
  DJANGO_SECRET_KEY="$(${PYTHON_BIN} - <<'PY'
import secrets
print(secrets.token_urlsafe(50))
PY
  )"

  ADMIN_PASS_GENERATED="$(${PYTHON_BIN} - <<'PY'
import secrets, string
alphabet = string.ascii_letters + string.digits + "!@#$%^&*-_"
print(''.join(secrets.choice(alphabet) for _ in range(16)))
PY
  )"

  # Append generated values to .env (do not expose other existing values)
  {
    echo "\n# Automatically generated values - do not commit";
    echo "DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}";
    echo "ADMIN_USER=admin";
    echo "ADMIN_PASS=${ADMIN_PASS_GENERATED}";
    echo "ADMIN_EMAIL=admin@example.com";
    echo "CREATE_SUPERUSER=yes";
  } >> .env

  chmod 600 .env || true
  echo "[deploy-production] Created .env and generated ADMIN_USER=admin and ADMIN_PASS (printed below). Save these credentials now!"
  echo "ADMIN_USER=admin"
  echo "ADMIN_PASS=${ADMIN_PASS_GENERATED}"
fi

# Load environment variables from .env into the script environment (if present)
if [ -f ".env" ]; then
  echo "[deploy-production] Loading .env variables"
  # Use Python's dotenv to safely parse and export values (handles quoting)
  eval "$(${PYTHON_BIN} - <<'PY'
from dotenv import dotenv_values
import shlex
data = dotenv_values('.env')
for k,v in data.items():
    if v is None:
        continue
    print('export %s=%s' % (k, shlex.quote(v)))
PY
  )"
fi

# Optionally create a superuser if requested and credentials are provided
CREATED_ADMIN="no"
if [ "${CREATE_SUPERUSER:-no}" = "yes" ]; then
  if [ -n "${ADMIN_USER:-}" ] && [ -n "${ADMIN_PASS:-}" ]; then
    echo "[deploy-production] Creating admin user '${ADMIN_USER}' (non-interactive)"
    # Use manage.py shell and read credentials from environment to avoid leaking password in process args
    "${PYTHON_BIN}" manage.py shell <<PY
from django.contrib.auth import get_user_model
import os
User = get_user_model()
username = os.environ['ADMIN_USER']
email = os.environ.get('ADMIN_EMAIL', 'admin@example.com')
password = os.environ['ADMIN_PASS']
User.objects.filter(username=username).delete()
User.objects.create_superuser(username=username, email=email, password=password)
print('ADMIN_CREATED')
PY
    CREATED_ADMIN="yes"
  else
    echo "[deploy-production] CREATE_SUPERUSER=yes but ADMIN_USER/ADMIN_PASS not provided; skipping admin creation"
  fi
fi

# Start the application
if [ -n "${START_CMD}" ]; then
  START_MODE="custom"
  START_DESC="${START_CMD}"
else
  START_MODE="runserver"
  START_DESC="${PYTHON_BIN} manage.py runserver 0.0.0.0:${APP_PORT}"
fi

# Summary output before starting the server (do not print secrets)
echo
echo "========================================"
echo "Deployment summary"
echo "----------------------------------------"
echo "App port:             ${APP_PORT}"
echo "Start mode:           ${START_MODE}"
echo "Start command:        ${START_DESC}"
echo "Migrations:           applied"
echo "Collectstatic:        executed"

if [ -n "${ADMIN_USER:-}" ]; then
  echo "Admin user:           ${ADMIN_USER}"
else
  echo "Admin user:           (none specified)"
fi

if [ -n "${ADMIN_PASS:-}" ]; then
  echo "Admin password:       (provided)"
else
  echo "Admin password:       (not provided - no admin will be created)"
fi

if [ -n "${DJANGO_SECRET_KEY:-}" ]; then
  echo "DJANGO_SECRET_KEY:    (present)"
else
  echo "DJANGO_SECRET_KEY:    (not present - using default DEV key)"
fi

echo "Note: Sensitive values are not printed. Ensure secrets are stored in your platform's secret manager."
echo "========================================"
echo

# Usage instructions (do not include secrets)
cat <<'INSTRUCTIONS'
Deployment instructions and examples

1) Provide credentials via a root-level .env file (DO NOT commit .env to git).

Example .env (store securely):
  ADMIN_USER=admin
  ADMIN_PASS=Your$tr0ngP@ss
  ADMIN_EMAIL=admin@example.com
  CREATE_SUPERUSER=yes
  DJANGO_SECRET_KEY=your-secure-secret

2) Run the script to deploy and start the app (creates admin when CREATE_SUPERUSER=yes):
  ./scripts/deploy-production.sh

3) Alternatively, use a custom start command (platforms may provide a process manager):
  START_CMD="python manage.py runserver 0.0.0.0:8080" ./scripts/deploy-production.sh

4) To create or reset the admin manually (non-interactive):
  ADMIN_PASS='Your$tr0ngP@ss' python manage.py shell -c "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.filter(username='admin').delete(); User.objects.create_superuser(username='admin', email='admin@example.com', password='${ADMIN_PASS}')"

Security notes:
- Never commit your .env file.
- Use your platform's secrets manager for production secrets.
- The script only reports presence of secrets, never their values.
INSTRUCTIONS


if [ "${START_MODE}" = "custom" ]; then
  echo "[deploy-production] Executing START_CMD"
  exec sh -c "${START_CMD}"
else
  echo "[deploy-production] Starting Django development server on :${APP_PORT}"
  exec "${PYTHON_BIN}" manage.py runserver 0.0.0.0:"${APP_PORT}"
fi
