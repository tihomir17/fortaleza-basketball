# apps/users/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from .views import RegisterView, CurrentUserView, UserSearchView, UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)

urlpatterns = [
    # POST /api/auth/register/
    path("register/", RegisterView.as_view(), name="auth_register"),
    # POST /api/auth/login/
    path("login/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    # POST /api/auth/login/refresh/
    path("login/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    # GET /api/auth/me/
    path("me/", CurrentUserView.as_view(), name="current_user"),
    path("search/", UserSearchView.as_view(), name="user_search"),
    # Include UserViewSet routes (includes change_password and reset_password actions)
    path("", include(router.urls)),
]
