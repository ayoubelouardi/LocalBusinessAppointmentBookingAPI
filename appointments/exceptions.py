from django.core.exceptions import PermissionDenied
from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        return Response(
            {
                "error": {
                    "code": response.status_code,
                    "detail": response.data,
                    "type": exc.__class__.__name__,
                }
            },
            status=response.status_code,
        )

    if isinstance(exc, ValidationError):
        return Response(
            {
                "error": {
                    "code": status.HTTP_400_BAD_REQUEST,
                    "detail": exc.detail,
                    "type": "ValidationError",
                }
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    if isinstance(exc, PermissionDenied):
        return Response(
            {
                "error": {
                    "code": status.HTTP_403_FORBIDDEN,
                    "detail": "Permission denied.",
                    "type": "PermissionDenied",
                }
            },
            status=status.HTTP_403_FORBIDDEN,
        )

    if isinstance(exc, Http404):
        return Response(
            {
                "error": {
                    "code": status.HTTP_404_NOT_FOUND,
                    "detail": "Resource not found.",
                    "type": "NotFound",
                }
            },
            status=status.HTTP_404_NOT_FOUND,
        )

    return Response(
        {
            "error": {
                "code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "detail": "An unexpected error occurred.",
                "type": "ServerError",
            }
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
