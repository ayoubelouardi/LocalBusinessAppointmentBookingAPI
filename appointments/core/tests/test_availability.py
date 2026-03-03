from datetime import date, time

from django.test import TestCase

from appointments.core.models import Booking, BusinessProfile, Service
from appointments.core.services import get_available_slots


class AvailabilityServiceTests(TestCase):
    def setUp(self):
        self.profile = BusinessProfile.objects.create(
            name="Salon One",
            address="Main Street",
            phone="123456",
            email="contact@salon.test",
            opening_time=time(9, 0),
            closing_time=time(12, 0),
        )
        self.service = Service.objects.create(
            name="Haircut",
            description="Basic",
            duration_minutes=30,
            price=20,
        )

    def test_returns_empty_when_no_business_profile(self):
        BusinessProfile.objects.all().delete()
        slots = get_available_slots(date(2026, 3, 10))
        self.assertEqual(slots, [])

    def test_excludes_overlapping_slots(self):
        Booking.objects.create(
            service=self.service,
            customer_name="Alice",
            customer_email="alice@test.com",
            appointment_date=date(2026, 3, 10),
            start_time=time(10, 0),
            end_time=time(10, 30),
            status=Booking.Status.CONFIRMED,
        )

        slots = get_available_slots(date(2026, 3, 10), slot_minutes=30)
        self.assertNotIn({"start_time": "10:00", "end_time": "10:30"}, slots)

    def test_returns_boundary_slots_within_business_hours(self):
        slots = get_available_slots(date(2026, 3, 10), slot_minutes=30)
        self.assertEqual(slots[0], {"start_time": "09:00", "end_time": "09:30"})
        self.assertEqual(slots[-1], {"start_time": "11:30", "end_time": "12:00"})
