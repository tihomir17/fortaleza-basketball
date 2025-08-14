# apps/teams/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class Team(models.Model):
    """
    Represents a basketball team.
    """
    name = models.CharField(_('Team Name'), max_length=255, unique=True)
    # A team can have multiple coaches, but we'll link to a primary contact/creator
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_teams'
    )
    players = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='teams',
        limit_choices_to={'role': 'PLAYER'},
        blank=True
    )
    coaches = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='coaching_teams',
        limit_choices_to={'role': 'COACH'},
        blank=True
    )

    def __str__(self):
        return self.name
