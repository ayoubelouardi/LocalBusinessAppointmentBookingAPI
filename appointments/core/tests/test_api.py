from datetime import date, time

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from appointments.core.models import Booking, BusinessProfile, Service


class AppointmentApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.service = Service.objects.create(
            name="Haircut",
            description="Basic haircut",
            duration_minutes=30,
            price=25,
        )
        BusinessProfile.objects.create(
            name="Salon Test",
            address="Main Road",
            phone="111222333",
            email="info@salon.test",
            opening_time=time(9, 0),
            closing_time=time(17, 0),
        )

    def test_get_services(self):
        response = self.client.get("/api/services/")
        self.assertEqual(response.status_code, 200)

    def test_create_booking_and_auto_end_time(self):
        payload = {
            "service": self.service.id,
            "customer_name": "Mona",
            "customer_email": "mona@test.com",
            "appointment_date": str(date(2026, 3, 10)),
            "start_time": "10:00:00",
            "status": "pending",
        }
        response = self.client.post("/api/bookings/", payload, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["end_time"], "10:30:00")

    def test_availability_endpoint(self):
        response = self.client.get("/api/availability/?date=2026-03-10")
        self.assertEqual(response.status_code, 200)
        self.assertIn("slots", response.data)

    def test_schedule_requires_admin(self):
        response = self.client.get("/api/schedule/?date=2026-03-10")
        self.assertEqual(response.status_code, 403)

    def test_confirm_booking_as_admin(self):
        booking = Booking.objects.create(
            service=self.service,
            customer_name="Tim",
            customer_email="tim@test.com",
            appointment_date=date(2026, 3, 10),
            start_time=time(11, 0),
            end_time=time(11, 30),
            status=Booking.Status.PENDING,
        )
        User = get_user_model()
        admin = User.objects.create_user(
            username="admin",
            password="secret123",
            is_staff=True,
        )
        self.client.force_authenticate(user=admin)
        response = self.client.patch(f"/api/bookings/{booking.id}/confirm/")
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.status, Booking.Status.CONFIRMED)
