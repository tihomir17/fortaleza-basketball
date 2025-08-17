# apps/competitions/models.py
from django.db import models
from django.conf import settings


class Competition(models.Model):
    name = models.CharField(max_length=255, unique=True)
    season = models.CharField(max_length=50, help_text="E.g., 2024-2025")
    # The owner/creator of the competition
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.name} ({self.season})"
