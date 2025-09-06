# apps/core/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from django.core.cache import cache
from django.conf import settings
import redis
import logging

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    Health check endpoint for monitoring and load balancers
    """
    health_status = {
        'status': 'healthy',
        'checks': {}
    }
    
    # Check database connection
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        health_status['checks']['database'] = 'healthy'
    except Exception as e:
        health_status['checks']['database'] = f'unhealthy: {str(e)}'
        health_status['status'] = 'unhealthy'
        logger.error(f"Database health check failed: {e}")
    
    # Check Redis connection
    try:
        cache.set('health_check', 'ok', 10)
        cache.get('health_check')
        health_status['checks']['redis'] = 'healthy'
    except Exception as e:
        health_status['checks']['redis'] = f'unhealthy: {str(e)}'
        health_status['status'] = 'unhealthy'
        logger.error(f"Redis health check failed: {e}")
    
    # Check if we're in debug mode (should be False in production)
    if settings.DEBUG:
        health_status['checks']['debug_mode'] = 'warning: debug mode enabled'
    else:
        health_status['checks']['debug_mode'] = 'healthy'
    
    # Return appropriate status code
    status_code = status.HTTP_200_OK if health_status['status'] == 'healthy' else status.HTTP_503_SERVICE_UNAVAILABLE
    
    return Response(health_status, status=status_code)


@api_view(['GET'])
@permission_classes([AllowAny])
def readiness_check(request):
    """
    Readiness check endpoint for Kubernetes
    """
    try:
        # Check if database is ready
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # Check if Redis is ready
        cache.set('readiness_check', 'ok', 10)
        
        return Response({'status': 'ready'}, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return Response({'status': 'not ready', 'error': str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


@api_view(['GET'])
@permission_classes([AllowAny])
def liveness_check(request):
    """
    Liveness check endpoint for Kubernetes
    """
    return Response({'status': 'alive'}, status=status.HTTP_200_OK)
