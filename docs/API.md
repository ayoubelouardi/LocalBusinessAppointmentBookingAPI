# Local Business Appointment Booking API

## Base URL

`/api/`

## Authentication

- Public read endpoints are open.
- Admin write endpoints require authenticated staff users.

## Endpoints

### Services

- `GET /api/services/` list services (supports `name`, `min_price`, `max_price`, `min_duration`, `max_duration` query params)
- `POST /api/services/` create service (admin only)
- `GET /api/services/{id}/` retrieve service
- `PUT /api/services/{id}/` update service (admin only)
- `DELETE /api/services/{id}/` delete service (admin only)

Create payload example:

```json
{
  "name": "Haircut",
  "description": "Standard haircut",
  "duration_minutes": 30,
  "price": "25.00"
}
```

### Business Profile

- `GET /api/business-profiles/` list business profiles
- `POST /api/business-profiles/` create business profile (admin only)
- `GET /api/business-profiles/{id}/` retrieve profile
- `PUT /api/business-profiles/{id}/` update profile (admin only)
- `DELETE /api/business-profiles/{id}/` delete profile (admin only)

Create payload example:

```json
{
  "name": "Joe's Salon",
  "address": "Main Street",
  "phone": "123456789",
  "email": "hello@joesalon.com",
  "opening_time": "09:00:00",
  "closing_time": "18:00:00"
}
```

### Bookings

- `GET /api/bookings/` list bookings
- `POST /api/bookings/` create booking request
- `GET /api/bookings/{id}/` retrieve booking
- `PATCH /api/bookings/{id}/confirm/` confirm pending booking (admin only)
- `PATCH /api/bookings/{id}/cancel/` cancel booking (idempotent)

Create payload example:

```json
{
  "service": 1,
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "appointment_date": "2026-03-10",
  "start_time": "10:00:00",
  "status": "pending"
}
```

Create response example:

```json
{
  "id": 1,
  "service": 1,
  "service_name": "Haircut",
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "appointment_date": "2026-03-10",
  "start_time": "10:00:00",
  "end_time": "10:30:00",
  "status": "pending"
}
```

### Availability

- `GET /api/availability/?date=YYYY-MM-DD` returns available slots

Response example:

```json
{
  "date": "2026-03-10",
  "slots": [
    {"start_time": "09:00", "end_time": "09:15"},
    {"start_time": "09:15", "end_time": "09:30"}
  ]
}
```

### Schedule

- `GET /api/schedule/?date=YYYY-MM-DD` returns bookings for the day (admin only)

## Error Response Format

```json
{
  "error": {
    "code": 400,
    "detail": {"field": ["error message"]},
    "type": "ValidationError"
  }
}
```

## Status Codes

- `200 OK` success read/update actions
- `201 Created` successful resource creation
- `400 Bad Request` validation errors
- `401 Unauthorized` unauthenticated for protected endpoint
- `403 Forbidden` authenticated but insufficient permissions
- `404 Not Found` resource missing
- `500 Internal Server Error` unexpected server error
