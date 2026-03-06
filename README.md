# Local Business Appointment Booking API

A REST API for local businesses (salons, clinics, repair shops) to manage services and customer appointments.

## Features

- **Service Management**: CRUD operations for services (name, description, duration, price)
- **Business Profile**: Business hours management (opening/closing times)
- **Booking System**: Create, confirm, or cancel appointments
- **Availability Engine**: Calculate available time slots for a specific date
- **Schedule View**: View daily agenda for business owners

## Tech Stack

- Python 3.x
- Django 4.2+
- Django REST Framework
- SQLite (default) / PostgreSQL (production)

## Setup

1. Create virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run migrations:
   ```bash
   python manage.py migrate
   ```

4. Start development server:
   ```bash
   python manage.py runserver
   ```

5. Open API docs:
   - Swagger UI: `http://127.0.0.1:8000/api/docs/`
   - OpenAPI schema: `http://127.0.0.1:8000/api/schema/`

## API Endpoints

- `GET /api/services/` - List/Create services
- `GET /api/services/{id}/` - Retrieve/Update/Delete service
- `GET /api/business-profiles/` - List/Create business profiles
- `GET /api/bookings/` - List/Create bookings
- `PATCH /api/bookings/{id}/` - Update booking status (confirm/cancel)

## License

MIT
