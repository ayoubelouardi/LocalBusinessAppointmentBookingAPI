# Deployment Configuration — LocalBusinessAppointmentBookingAPI

This document captures the deployment settings used for hosting the Local Business Appointment Booking API and lists operational notes you should follow when deploying to a cloud service (example values provided based on the supplied inputs).

Basic
- Service name: `LocalBusinessAppointmentBookingAPI-1emrgal`
- Workspace / Owner: `ayoubelouardioff2619` (as provided)
- Region: N. Virginia, US East (AWS `us-east-1`)

Source & runtime
- Branch: `main`
- Root directory: `./` (project root)
- Framework preset: `django` (Django + DRF)
- Runtime: `python3.12` (Debian slim variant suggested)

Build & run
- Build command:
  ```bash
  pip install -r requirements.txt
  ```
- Start command (example used by platform):
  ```bash
  _startup() { gunicorn --bind :8080 appointments.wsgi; }; _startup
  ```
- Serving port: `8080`

Resources
- Memory: `512 MB` (adjust to 1GB+ for production workloads)
- CPU: `2 cores` (adjust depending on expected concurrency)

Environment variables (recommended)
- DJANGO_SECRET_KEY — set to a secure secret in production (do NOT commit)
- DJANGO_DEBUG — `False` in production
- DJANGO_ALLOWED_HOSTS — comma-separated hosts (e.g. `example.com,127.0.0.1`)
- DATABASE_URL — production database (Postgres) connection string, e.g. `postgres://user:pass@host:5432/dbname`
- CELERY_BROKER_URL — if you add background jobs
- SENTRY_DSN — optional error reporting
- EMAIL_* variables — SMTP config if you send emails

Tip: the repo includes `appointments/env.py` which reads environment variables — ensure your platform injects the variables above.

Pre-deploy / startup tasks
- Run migrations at deploy time:
  ```bash
  python manage.py migrate --noinput
  ```
- Create an admin user if needed (one-time):
  ```bash
  python manage.py createsuperuser
  ```
- (Optional) Collect static files if you serve static assets via Django:
  ```bash
  python manage.py collectstatic --noinput
  ```

Healthchecks and readiness
- Liveness: HTTP GET `http://<service>:8080/api/` should return 200
- Readiness: Run database migration check or call `http://<service>:8080/api/schema/` (OpenAPI schema endpoint)

Logging & monitoring
- Use the platform's log drain/streaming to capture stdout/stderr — Gunicorn will write logs to stdout.
- The project contains a basic LOGGING configuration (`appointments/settings.py`) that writes to console; integrate with Sentry or your logging provider for errors.

Database
- Default in repo is SQLite for local development. For production, set `DATABASE_URL` to a managed Postgres instance and configure your platform accordingly.
- Use connection pooling and add indexes for booking queries (this repo already creates indexes on booking fields for performance).

Security & secrets
- Do not store secrets in repo. Use the platform's secret manager or environment variable system.
- Ensure `DJANGO_DEBUG=False` in production and set `ALLOWED_HOSTS` accordingly.
- Use HTTPS/TLS (the platform typically provides TLS termination).

Scaling & performance
- Use at least 2 Gunicorn workers for concurrency: `gunicorn -w 2 --bind :8080 appointments.wsgi`
- For high throughput, increase workers and memory and put the DB on a managed service.

Rollbacks & deployments
- Apply migrations in a backward-compatible way when possible. If a migration is destructive, plan a two-step deploy (schema change without code that uses it, then code deploy).
- Keep a database backup strategy before applying destructive migrations.

FAQ / quick checklist
- Ensure `pip install -r requirements.txt` completes in build step.
- Ensure `python manage.py migrate --noinput` runs before traffic is routed.
- Ensure `DJANGO_SECRET_KEY` and `DATABASE_URL` are set via the platform's environment/secret manager.
- Expose port `8080` in platform settings.

Contact
- If you need provider-specific YAML/manifest or a Dockerfile, state the target provider (Vercel, Heroku, AWS Elastic Beanstalk, ECS, or DigitalOcean App Platform) and I'll produce the exact manifest.
