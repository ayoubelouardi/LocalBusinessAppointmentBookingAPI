from datetime import datetime, timedelta

from .models import Booking, BusinessProfile


def get_available_slots(target_date, slot_minutes=15):
    profile = BusinessProfile.objects.first()
    if profile is None:
        return []

    day_start = datetime.combine(target_date, profile.opening_time)
    day_end = datetime.combine(target_date, profile.closing_time)

    bookings = list(
        Booking.objects.filter(
            appointment_date=target_date,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        )
        .order_by("start_time")
        .values("start_time", "end_time")
    )

    slots = []
    cursor = day_start
    while cursor + timedelta(minutes=slot_minutes) <= day_end:
        slot_end = cursor + timedelta(minutes=slot_minutes)
        overlaps = any(
            datetime.combine(target_date, booking["start_time"]) < slot_end
            and datetime.combine(target_date, booking["end_time"]) > cursor
            for booking in bookings
        )
        if not overlaps:
            slots.append(
                {
                    "start_time": cursor.time().isoformat(timespec="minutes"),
                    "end_time": slot_end.time().isoformat(timespec="minutes"),
                }
            )
        cursor = slot_end

    return slots
