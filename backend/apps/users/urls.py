# apps/users/urls.py

from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from .views import RegisterView, CurrentUserView, UserSearchView 

urlpatterns = [
    # POST /api/auth/register/
    path('register/', RegisterView.as_view(), name='auth_register'),
    # POST /api/auth/login/
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    # POST /api/auth/login/refresh/
    path('login/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # GET /api/auth/me/
    path('me/', CurrentUserView.as_view(), name='current_user'),
    path('search/', UserSearchView.as_view(), name='user_search'),
]