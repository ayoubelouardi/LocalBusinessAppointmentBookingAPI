from datetime import date, time

from django.core.exceptions import ValidationError
from django.test import TestCase

from appointments.core.models import Booking, Service


class ServiceModelTests(TestCase):
    def test_service_duration_minimum_validation(self):
        service = Service(
            name="Quick Service",
            description="Invalid duration",
            duration_minutes=1,
            price=10,
        )
        with self.assertRaises(ValidationError):
            service.full_clean()

    def test_service_price_validation(self):
        service = Service(
            name="Negative Price",
            description="Invalid price",
            duration_minutes=20,
            price=-5,
        )
        with self.assertRaises(ValidationError):
            service.full_clean()


class BookingModelTests(TestCase):
    def setUp(self):
        self.service = Service.objects.create(
            name="Standard Haircut",
            description="Standard",
            duration_minutes=30,
            price=25,
        )

    def test_booking_status_choices(self):
        booking = Booking.objects.create(
            service=self.service,
            customer_name="Jane Doe",
            customer_email="jane@example.com",
            appointment_date=date(2026, 3, 5),
            start_time=time(10, 0),
            end_time=time(10, 30),
            status=Booking.Status.PENDING,
        )
        self.assertEqual(booking.status, Booking.Status.PENDING)

    def test_booking_status_transition_to_confirmed(self):
        booking = Booking.objects.create(
            service=self.service,
            customer_name="John Doe",
            customer_email="john@example.com",
            appointment_date=date(2026, 3, 5),
            start_time=time(11, 0),
            end_time=time(11, 30),
            status=Booking.Status.PENDING,
        )
        booking.status = Booking.Status.CONFIRMED
        booking.save()
        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.CONFIRMED)
