from django.contrib import admin
from .models import Service, BusinessProfile, Booking


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ("name", "duration_minutes", "price")


@admin.register(BusinessProfile)
class BusinessProfileAdmin(admin.ModelAdmin):
    list_display = ("name", "opening_time", "closing_time")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = (
        "customer_name",
        "service",
        "appointment_date",
        "start_time",
        "status",
    )
    list_filter = ("status", "appointment_date")
