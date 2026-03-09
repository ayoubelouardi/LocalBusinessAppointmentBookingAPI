# Deployment Guide (General + Leapcell)

This guide is validated against the current codebase and works as a general deployment reference for Django platforms (including Leapcell).

## What This Project Expects

- Python runtime: `3.12` (or compatible 3.11+)
- Web server: Gunicorn
- Entrypoint: `appointments.wsgi:application`
- HTTP port: from `$PORT` (default `8080`)
- Database:
  - Local/dev default: SQLite
  - Production: PostgreSQL via `DATABASE_URL`

## Required Environment Variables

- `DJANGO_SECRET_KEY` (required in production)
- `DJANGO_DEBUG=False` (required in production)
- `DJANGO_ALLOWED_HOSTS` (comma-separated, no spaces)
  - Example: `your-domain.com,.leapcell.dev,127.0.0.1`

## Optional Environment Variables

- `DATABASE_URL` (recommended for production)
  - Example: `postgres://user:pass@host:5432/dbname`
- `PORT` (platform usually injects this)
- `GUNICORN_WORKERS` (default in script: `2`)

## Build and Start Commands (Generic)

Build command:

```bash
pip install -r requirements.txt
```

Start command:

```bash
bash scripts/deploy-production.sh
```

This start script will:
1. Install requirements
2. Run migrations
3. Collect static files
4. Start Gunicorn on `:$PORT`

## Included Deployment Scripts

- Production: `scripts/deploy-production.sh`
- Development: `scripts/deploy-dev.sh`

Run locally for production-like startup:

```bash
PORT=8080 DJANGO_DEBUG=False bash scripts/deploy-production.sh
```

Run locally for dev startup:

```bash
bash scripts/deploy-dev.sh
```

## Leapcell Configuration (Suggested)

Use these values in Leapcell service settings:

- Branch: `main`
- Root directory: `./`
- Runtime: Python 3.12
- Build command: `pip install -r requirements.txt`
- Start command: `bash scripts/deploy-production.sh`
- Serving port: `8080`

Set environment variables in Leapcell:

- `DJANGO_SECRET_KEY=<secure-random-value>`
- `DJANGO_DEBUG=False`
- `DJANGO_ALLOWED_HOSTS=<your-hostname>,.leapcell.dev`
- `DATABASE_URL=<postgres-connection-url>` (recommended)

## Health Checks

- Liveness endpoint: `GET /api/`
- Readiness endpoint: `GET /api/schema/`

## Notes Verified Against Current Code

- `DATABASE_URL` is now supported in `appointments/settings.py` for PostgreSQL.
- `STATIC_ROOT` is configured as `staticfiles` for `collectstatic`.
- Gunicorn target is `appointments.wsgi:application` (correct format).

## Common Deployment Errors and Fixes

- **400 Bad Request / DisallowedHost**
  - Fix: add your deployed hostname to `DJANGO_ALLOWED_HOSTS`.
- **Database connection errors**
  - Fix: verify `DATABASE_URL` format and network access.
- **Migration errors on startup**
  - Fix: ensure DB user has schema migration permissions.
- **Static files missing in admin**
  - Fix: keep `collectstatic --noinput` in startup script.

## Security Checklist

- `DJANGO_DEBUG=False`
- strong `DJANGO_SECRET_KEY`
- production database credentials stored in platform secrets
- HTTPS enabled by platform
