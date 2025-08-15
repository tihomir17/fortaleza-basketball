# apps/teams/models.py
from django.db import models
from django.conf import settings

class Team(models.Model):
    name = models.CharField(max_length=255, unique=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='created_teams')
    
    players = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='player_on_teams', # A unique name for the reverse relationship
        blank=True
    )
    coaches = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='coach_on_teams', # A unique name for the reverse relationship
        blank=True
    )

    def __str__(self):
        return self.name