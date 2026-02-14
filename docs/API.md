# API Documentation

## Base URL

```
http://localhost:8000/api/
```

## Endpoints

### Services

#### List all services
```
GET /services/
```

#### Create a service
```
POST /services/
```

Request body:
```json
{
  "name": "Haircut",
  "description": "Standard haircut service",
  "duration_minutes": 30,
  "price": 25.00
}
```

#### Get service details
```
GET /services/{id}/
```

#### Update a service
```
PUT /services/{id}/
```

#### Delete a service
```
DELETE /services/{id}/
```

---

### Business Profiles

#### List all business profiles
```
GET /business-profiles/
```

#### Create a business profile
```
POST /business-profiles/
```

Request body:
```json
{
  "name": "Joe's Salon",
  "opening_time": "09:00:00",
  "closing_time": "18:00:00"
}
```

#### Get business profile details
```
GET /business-profiles/{id}/
```

---

### Bookings

#### List all bookings
```
GET /bookings/
```

#### Create a booking
```
POST /bookings/
```

Request body:
```json
{
  "service": 1,
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "appointment_date": "2026-03-15",
  "start_time": "10:00:00",
  "end_time": "10:30:00",
  "status": "pending"
}
```

#### Get booking details
```
GET /bookings/{id}/
```

#### Update booking status
```
PATCH /bookings/{id}/
```

Request body (confirm):
```json
{
  "status": "confirmed"
}
```

Request body (cancel):
```json
{
  "status": "cancelled"
}
```

#### Delete a booking
```
DELETE /bookings/{id}/
```

---

## Response Formats

### Success Response
```json
{
  "id": 1,
  "name": "Haircut",
  "description": "Standard haircut service",
  "duration_minutes": 30,
  "price": "25.00"
}
```

### Error Response
```json
{
  "field_name": ["Error message"]
}
```

---

## Status Codes

- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid request data
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error
