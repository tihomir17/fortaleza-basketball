# apps/plays/admin.py

from django.contrib import admin
from .models import PlayDefinition, PlayCategory

admin.site.register(PlayDefinition)
admin.site.register(PlayCategory)
