from datetime import date

from rest_framework import viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Service, BusinessProfile, Booking
from .serializers import ServiceSerializer, BusinessProfileSerializer, BookingSerializer
from .permissions import IsAdminOrReadOnly
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


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer


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
