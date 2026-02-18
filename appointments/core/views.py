from rest_framework import viewsets
from .models import Service, BusinessProfile, Booking
from .serializers import ServiceSerializer, BusinessProfileSerializer, BookingSerializer
from .permissions import IsAdminOrReadOnly
from .filters import filter_services


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
