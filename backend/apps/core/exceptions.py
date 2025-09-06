# apps/core/exceptions.py

from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError
from django.http import Http404
import logging

logger = logging.getLogger(__name__)


class BasketballAnalyticsException(Exception):
    """Base exception for Basketball Analytics application"""
    default_message = "An error occurred"
    default_code = "error"
    
    def __init__(self, message=None, code=None, details=None):
        self.message = message or self.default_message
        self.code = code or self.default_code
        self.details = details or {}
        super().__init__(self.message)


class TeamPermissionError(BasketballAnalyticsException):
    """Raised when user doesn't have permission to access team data"""
    default_message = "You don't have permission to access this team's data"
    default_code = "team_permission_denied"


class GamePermissionError(BasketballAnalyticsException):
    """Raised when user doesn't have permission to access game data"""
    default_message = "You don't have permission to access this game's data"
    default_code = "game_permission_denied"


class UserPermissionError(BasketballAnalyticsException):
    """Raised when user doesn't have permission to access user data"""
    default_message = "You don't have permission to access this user's data"
    default_code = "user_permission_denied"


class DataValidationError(BasketballAnalyticsException):
    """Raised when data validation fails"""
    default_message = "Data validation failed"
    default_code = "validation_error"


class FileUploadError(BasketballAnalyticsException):
    """Raised when file upload fails"""
    default_message = "File upload failed"
    default_code = "file_upload_error"


class EmailNotificationError(BasketballAnalyticsException):
    """Raised when email notification fails"""
    default_message = "Email notification failed"
    default_code = "email_notification_error"


class AnalyticsError(BasketballAnalyticsException):
    """Raised when analytics calculation fails"""
    default_message = "Analytics calculation failed"
    default_code = "analytics_error"


def custom_exception_handler(exc, context):
    """
    Custom exception handler that provides consistent error responses
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    # Get the request and view info
    request = context.get('request')
    view = context.get('view')
    
    # Log the exception
    logger.error(
        f"Exception in {view.__class__.__name__ if view else 'Unknown'}: {exc}",
        extra={
            'exception_type': type(exc).__name__,
            'path': request.path if request else 'Unknown',
            'method': request.method if request else 'Unknown',
            'user_id': getattr(request.user, 'id', None) if request and hasattr(request, 'user') else None,
        }
    )
    
    # Handle our custom exceptions
    if isinstance(exc, BasketballAnalyticsException):
        custom_response_data = {
            'error': {
                'code': exc.code,
                'message': exc.message,
                'details': exc.details,
            }
        }
        return Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
    
    # Handle Django ValidationError
    if isinstance(exc, ValidationError):
        custom_response_data = {
            'error': {
                'code': 'validation_error',
                'message': 'Data validation failed',
                'details': exc.message_dict if hasattr(exc, 'message_dict') else str(exc),
            }
        }
        return Response(custom_response_data, status=status.HTTP_400_BAD_REQUEST)
    
    # Handle Http404
    if isinstance(exc, Http404):
        custom_response_data = {
            'error': {
                'code': 'not_found',
                'message': 'The requested resource was not found',
                'details': {},
            }
        }
        return Response(custom_response_data, status=status.HTTP_404_NOT_FOUND)
    
    # If response is None, it means the exception wasn't handled
    if response is None:
        custom_response_data = {
            'error': {
                'code': 'internal_server_error',
                'message': 'An internal server error occurred',
                'details': {},
            }
        }
        return Response(custom_response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # Customize the response data for standard DRF exceptions
    if response is not None:
        custom_response_data = {
            'error': {
                'code': getattr(exc, 'default_code', 'error'),
                'message': response.data.get('detail', 'An error occurred') if isinstance(response.data, dict) else str(response.data),
                'details': response.data if isinstance(response.data, dict) and 'detail' not in response.data else {},
            }
        }
        response.data = custom_response_data
    
    return response
