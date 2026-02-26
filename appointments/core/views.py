from datetime import date

from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Service, BusinessProfile, Booking
from .serializers import ServiceSerializer, BusinessProfileSerializer, BookingSerializer
from .permissions import IsAdminOrReadOnly, IsAdminUser
from .filters import filter_services
from .services import get_available_slots


class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.all()
    serializer_class = ServiceSerializer
    permission_classes = [IsAdminOrReadOnly]

    def get_queryset(self):
        queryset = super().get_queryset()
        return filter_services(queryset, self.request.query_params)


class BusinessProfileViewSet(viewsets.ModelViewSet):
    queryset = BusinessProfile.objects.all()
    serializer_class = BusinessProfileSerializer
    permission_classes = [IsAdminOrReadOnly]


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer

    def get_permissions(self):
        if self.action == "confirm":
            return [IsAuthenticated(), IsAdminUser()]
        return [AllowAny()]

    @action(detail=True, methods=["patch"], url_path="confirm")
    def confirm(self, request, pk=None):
        booking = self.get_object()
        if booking.status != Booking.Status.PENDING:
            return Response(
                {"status": "Only pending bookings can be confirmed."},
                status=400,
            )
        booking.status = Booking.Status.CONFIRMED
        booking.save(update_fields=["status"])
        serializer = self.get_serializer(booking)
        return Response(serializer.data, status=200)

    @action(detail=True, methods=["patch"], url_path="cancel")
    def cancel(self, request, pk=None):
        booking = self.get_object()
        if booking.status == Booking.Status.CANCELLED:
            serializer = self.get_serializer(booking)
            return Response(serializer.data, status=200)

        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=["status"])
        serializer = self.get_serializer(booking)
        return Response(serializer.data, status=200)


class AvailabilityView(APIView):
    def get(self, request):
        raw_date = request.query_params.get("date")
        if not raw_date:
            return Response({"date": "Query parameter 'date' is required."}, status=400)

        try:
            target_date = date.fromisoformat(raw_date)
        except ValueError:
            return Response(
                {"date": "Invalid format. Use YYYY-MM-DD."},
                status=400,
            )

        slots = get_available_slots(target_date)
        return Response({"date": raw_date, "slots": slots}, status=200)


class ScheduleView(APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        raw_date = request.query_params.get("date")
        if not raw_date:
            return Response({"date": "Query parameter 'date' is required."}, status=400)

        try:
            target_date = date.fromisoformat(raw_date)
        except ValueError:
            return Response(
                {"date": "Invalid format. Use YYYY-MM-DD."},
                status=400,
            )

        bookings = Booking.objects.filter(appointment_date=target_date).order_by(
            "start_time"
        )
        serializer = BookingSerializer(bookings, many=True)
        return Response({"date": raw_date, "bookings": serializer.data}, status=200)
