# backend/apps/games/admin.py

from django.contrib import admin
from .models import Game

# This line tells the Django admin to create an interface for the Game model.
admin.site.register(Game)