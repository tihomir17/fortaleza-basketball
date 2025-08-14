# basketball_analytics/urls.py

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Import the ViewSets from our apps
from apps.teams.views import TeamViewSet
from apps.plays.views import PlayDefinitionViewSet
from apps.possessions.views import PossessionViewSet

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'teams', TeamViewSet, basename='team')
router.register(r'plays', PlayDefinitionViewSet, basename='play')
router.register(r'possessions', PossessionViewSet, basename='possession')

urlpatterns = [
    # The Django admin site
    path('admin/', admin.site.urls),

    # Authentication endpoints from the 'users' app
    path('api/auth/', include('apps.users.urls')),

    # API endpoints registered with the router
    # This will create URLs like:
    # /api/teams/
    # /api/teams/{id}/
    # /api/plays/
    # etc.
    path('api/', include(router.urls)),
]