# apps/possessions/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class Possession(models.Model):
    """
    Tracks a single possession in a game or practice.
    """
    # A Game or Practice session this possession belongs to would be a good addition later
    # session = models.ForeignKey('sessions.Session', on_delete=models.CASCADE)

    team = models.ForeignKey(
        'teams.Team',
        on_delete=models.CASCADE,
        related_name='possessions',
        help_text=_('The team that has the possession.')
    )
    play_definition = models.ForeignKey(
        'plays.PlayDefinition',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='executed_in_possessions'
    )
    players_on_court = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='possessions_on_court'
    )
    start_timestamp = models.DateTimeField(auto_now_add=True)
    end_timestamp = models.DateTimeField(null=True, blank=True)
    # The tracking data (e.g., player coordinates, events) could be a JSONField
    tracking_data = models.JSONField(
        null=True,
        blank=True,
        help_text=_('Stores detailed events or coordinates for this possession.')
    )
    outcome = models.CharField(
        _('Outcome'),
        max_length=100,
        blank=True,
        help_text=_('e.g., Made 2pt Shot, Turnover, Defensive Rebound')
    )

    def __str__(self):
        return f"Possession for {self.team.name} at {self.start_timestamp.strftime('%Y-%m-%d %H:%M')}"
