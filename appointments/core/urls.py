from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ServiceViewSet,
    BusinessProfileViewSet,
    BookingViewSet,
    AvailabilityView,
)

router = DefaultRouter()
router.register(r"services", ServiceViewSet)
router.register(r"business-profiles", BusinessProfileViewSet)
router.register(r"bookings", BookingViewSet)

urlpatterns = [
    path("availability/", AvailabilityView.as_view(), name="availability"),
    path("", include(router.urls)),
]
