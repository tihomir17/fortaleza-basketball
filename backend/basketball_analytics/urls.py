# basketball_analytics/urls.py

from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.routers import DefaultRouter
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)

# Import the ViewSets from our apps
from apps.teams.views import TeamViewSet
from apps.plays.views import PlayDefinitionViewSet
from apps.possessions.views import PossessionViewSet
from apps.competitions.views import CompetitionViewSet
from apps.users.views import UserViewSet
from apps.games.views import GameViewSet
from apps.events.views import CalendarEventViewSet
from apps.plays.views import PlayCategoryViewSet

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r"teams", TeamViewSet, basename="team")
router.register(r"plays", PlayDefinitionViewSet, basename="play")
router.register(r"users", UserViewSet, basename="user")
router.register(r"possessions", PossessionViewSet, basename="possession")
router.register(r"competitions", CompetitionViewSet, basename="competition")
router.register(r"games", GameViewSet, basename="game")
router.register(r"events", CalendarEventViewSet, basename="event")
router.register(r"play-categories", PlayCategoryViewSet, basename="playcategory")


def health_check(request):
    """Simple health check endpoint for frontend debugging"""
    return JsonResponse(
        {
            "status": "healthy",
            "message": "Basketball Analytics API is running",
            "version": "1.0.0",
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def auth_test(request):
    """Test endpoint to verify authentication is working"""
    return JsonResponse(
        {
            "status": "authenticated",
            "user": {
                "id": request.user.id,
                "username": request.user.username,
                "email": request.user.email,
                "role": request.user.role,
            },
            "message": "Authentication is working correctly",
        }
    )


urlpatterns = [
    # Health check endpoint
    path("api/health/", health_check, name="health_check"),
    # Authentication test endpoint
    path("api/auth-test/", auth_test, name="auth_test"),
    # The Django admin site
    path("admin/", admin.site.urls),
    # Authentication endpoints from the 'users' app
    path("api/auth/", include("apps.users.urls")),
    # API endpoints registered with the router
    # This will create URLs like:
    # /api/teams/
    # /api/teams/{id}/
    # /api/plays/
    # etc.
    path("api/", include(router.urls)),
    # Scouting endpoints
    path("api/scouting/", include("apps.scouting.urls")),
    # Spectacular API Schema and UI
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/schema/swagger-ui/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/schema/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
