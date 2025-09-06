# apps/core/admin_urls.py

from django.urls import path, include
from django.contrib import admin
from .admin_views import admin_site

# Use custom admin site
admin.site = admin_site

urlpatterns = [
    path('admin/', admin_site.urls),
]
