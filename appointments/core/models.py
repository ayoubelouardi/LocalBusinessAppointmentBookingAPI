from django.db import models


class Service(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    duration_minutes = models.PositiveIntegerField()
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return self.name


class BusinessProfile(models.Model):
    name = models.CharField(max_length=255)
    opening_time = models.TimeField()
    closing_time = models.TimeField()

    def __str__(self):
        return self.name


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        CANCELLED = "cancelled", "Cancelled"

    service = models.ForeignKey(
        Service, on_delete=models.CASCADE, related_name="bookings"
    )
    customer_name = models.CharField(max_length=255)
    customer_email = models.EmailField()
    appointment_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )

    def __str__(self):
        return f"{self.customer_name} - {self.service.name} ({self.appointment_date})"
