from datetime import datetime, timedelta

from django.db import transaction
from rest_framework import serializers

from .models import Service, BusinessProfile, Booking


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ["id", "name", "description", "duration_minutes", "price"]


class BusinessProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessProfile
        fields = [
            "id",
            "name",
            "address",
            "phone",
            "email",
            "opening_time",
            "closing_time",
        ]


class BookingSerializer(serializers.ModelSerializer):
    end_time = serializers.TimeField(read_only=True)
    service_name = serializers.CharField(source="service.name", read_only=True)

    class Meta:
        model = Booking
        fields = [
            "id",
            "service",
            "service_name",
            "customer_name",
            "customer_email",
            "appointment_date",
            "start_time",
            "end_time",
            "status",
        ]

    def validate(self, attrs):
        start_time = attrs.get("start_time")
        if start_time is None:
            return attrs

        service = attrs.get("service")
        if service is None and self.instance is not None:
            service = self.instance.service
        if service is None:
            raise serializers.ValidationError({"service": "Service is required."})

        start_dt = datetime.combine(datetime.today(), start_time)
        end_dt = start_dt + timedelta(minutes=service.duration_minutes)
        attrs["end_time"] = end_dt.time()
        return attrs

    def create(self, validated_data):
        with transaction.atomic():
            has_conflict = (
                Booking.objects.select_for_update()
                .filter(
                    appointment_date=validated_data["appointment_date"],
                    status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
                    start_time__lt=validated_data["end_time"],
                    end_time__gt=validated_data["start_time"],
                )
                .exists()
            )
            if has_conflict:
                raise serializers.ValidationError(
                    {"start_time": "This time slot is already booked."}
                )
            return super().create(validated_data)

    def update(self, instance, validated_data):
        validated_data.pop("end_time", None)
        return super().update(instance, validated_data)
