# **Local Business Appointment Booking API: Specification & ERD**

## **1\. Entity Relationship Diagram (ERD)**

The following diagram illustrates the data structure and relationships between Businesses, Services, and Bookings.

```
erDiagram
    BUSINESS_PROFILE {
        string business_id PK
        string name
        string address
        string phone
        string email
    }

    SERVICE {
        string service_id PK
        string business_id FK
        string name
        string description
        float price
    }

    BOOKING {
        string booking_id PK
        string customer_name
        string booking_date
        string start_time
        string service_id FK
    }

    BUSINESS_PROFILE ||--o{ SERVICE : "provides"
    SERVICE ||--o{ BOOKING : "books"
```

### **Model Details**

* **BusinessProfile:** Stores business-wide settings like operating hours.  
* **Service:** Defines the offerings (e.g., "Men's Haircut") linked to a specific business.  
* **Booking:** Captures customer details, the chosen service, and the scheduled time slot.

## **2\. API Endpoints**

The backend exposes the following RESTful endpoints to manage the booking lifecycle:

| Method | Endpoint | Description | Auth Required |
| :---- | :---- | :---- | :---- |
| **Service Management** |  |  |  |
| GET | /api/services/ | List all services offered by the business. | No |
| POST | /api/services/ | Create a new service (Admin only). | Yes |
| PUT | /api/services/{id}/ | Update service details (price, duration). | Yes |
| DELETE | /api/services/{id}/ | Remove a service from the offerings. | Yes |
| **Availability** |  |  |  |
| GET | /api/availability/ | Returns free time slots for a given ?date=. | No |
| **Booking Operations** |  |  |  |
| POST | /api/bookings/ | Create a new appointment request. | No |
| PATCH | /api/bookings/{id}/confirm/ | Admin confirmation of a pending slot. | Yes |
| PATCH | /api/bookings/{id}/cancel/ | Cancel an existing booking. | No/Yes |
| **Business Schedule** |  |  |  |
| GET | /api/schedule/ | View all bookings for a specific ?date=. | Yes |

## **3\. Implementation Notes**

* **Validation:** The /bookings/ endpoint will automatically calculate the end\_time based on the Service.duration\_minutes.  
* **Conflict Resolution:** The API uses Django ORM transactions to ensure no two bookings overlap for the same time slot.
