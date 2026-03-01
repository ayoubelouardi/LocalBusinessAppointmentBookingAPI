import logging


logger = logging.getLogger("appointments.core")


def log_booking_conflict(appointment_date, start_time, end_time, customer_email):
    logger.warning(
        "booking_conflict_detected",
        extra={
            "appointment_date": str(appointment_date),
            "start_time": str(start_time),
            "end_time": str(end_time),
            "customer_email": customer_email,
        },
    )


def log_api_failure(endpoint, status_code, error_type, detail):
    logger.error(
        "api_failure",
        extra={
            "endpoint": endpoint,
            "status_code": status_code,
            "error_type": error_type,
            "detail": str(detail),
        },
    )
