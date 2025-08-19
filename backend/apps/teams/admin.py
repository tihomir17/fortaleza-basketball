# apps/teams/admin.py

from django.contrib import admin
from .models import Team

# A simple registration is enough for this model
admin.site.register(Team)
