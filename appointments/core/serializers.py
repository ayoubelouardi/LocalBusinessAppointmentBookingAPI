from datetime import datetime, timedelta
from django.db import transaction
from rest_framework import serializers
from .models import Service, BusinessProfile, Booking


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = "__all__"


class BusinessProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessProfile
        fields = "__all__"


class BookingSerializer(serializers.ModelSerializer):
    end_time = serializers.TimeField(read_only=True)

    class Meta:
        model = Booking
        fields = "__all__"

    def create(self, validated_data):
        service = validated_data["service"]
        start_time = validated_data["start_time"]
        start_dt = datetime.combine(datetime.today(), start_time)
        end_dt = start_dt + timedelta(minutes=service.duration_minutes)
        validated_data["end_time"] = end_dt.time()

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
