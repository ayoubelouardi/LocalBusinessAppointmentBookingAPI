#!/usr/bin/env bash

set -euo pipefail

APP_PORT="${PORT:-8000}"
PYTHON_BIN="${PYTHON_BIN:-./venv/bin/python}"

if [ ! -x "${PYTHON_BIN}" ]; then
  PYTHON_BIN="python3"
fi

echo "[deploy-dev] Installing dependencies"
"${PYTHON_BIN}" -m pip install -r requirements.txt

echo "[deploy-dev] Running migrations"
"${PYTHON_BIN}" manage.py migrate --noinput

echo "[deploy-dev] Starting Django development server on :${APP_PORT}"
exec "${PYTHON_BIN}" manage.py runserver "0.0.0.0:${APP_PORT}"
