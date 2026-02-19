from rest_framework import serializers
from datetime import datetime, timedelta
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
        return super().create(validated_data)
