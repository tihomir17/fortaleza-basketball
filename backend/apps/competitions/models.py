# apps/competitions/models.py
from django.db import models
from django.conf import settings


class Competition(models.Model):
    name = models.CharField(max_length=255, unique=True)
    season = models.CharField(max_length=50, help_text="E.g., 2024-2025")

    # Basketball-specific rules and parameters
    quarter_length_minutes = models.IntegerField(
        default=10, help_text="Length of each quarter in minutes"
    )
    overtime_length_minutes = models.IntegerField(
        default=5, help_text="Length of overtime periods in minutes"
    )
    shot_clock_seconds = models.IntegerField(
        default=24, help_text="Shot clock duration in seconds"
    )
    personal_foul_limit = models.IntegerField(
        default=5, help_text="Personal foul limit per player"
    )
    team_fouls_for_bonus = models.IntegerField(
        default=5, help_text="Team fouls needed for bonus free throws"
    )

    # Competition metadata
    country = models.CharField(
        max_length=100, default="Brazil", help_text="Country where competition is held"
    )
    league_level = models.CharField(
        max_length=50, default="Professional", help_text="Level of competition"
    )

    # The owner/creator of the competition
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.name} ({self.season})"
