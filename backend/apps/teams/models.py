# apps/teams/models.py
from django.db import models
from django.conf import settings


class Team(models.Model):
    name = models.CharField(max_length=255, unique=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="created_teams"
    )

    players = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="player_on_teams",  # A unique name for the reverse relationship
        blank=True,
    )
    coaches = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="coach_on_teams",  # A unique name for the reverse relationship
        blank=True,
    )
    staff = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="staff_on_teams",  # A unique name for the reverse relationship
        blank=True,
    )

    competition = models.ForeignKey(
        "competitions.Competition",
        on_delete=models.CASCADE,
        related_name="teams",
        null=True,  # Allow teams to exist without a competition for now
        blank=True,
    )

    logo_url = models.URLField(blank=True, null=True)

    class Meta:
        ordering = ['name']  # Add ordering to prevent pagination warnings
        indexes = [
            models.Index(fields=["name"]),
            models.Index(fields=["competition"]),
            models.Index(fields=["created_by"]),
        ]

    def __str__(self):
        return self.name
