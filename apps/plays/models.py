# apps/plays/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class PlayDefinition(models.Model):
    """
    Stores the definition of an offensive or defensive play.
    """
    class PlayType(models.TextChoices):
        OFFENSIVE = 'OFFENSIVE', _('Offensive')
        DEFENSIVE = 'DEFENSIVE', _('Defensive')

    name = models.CharField(_('Play Name'), max_length=255)
    description = models.TextField(_('Description'), blank=True, null=True)
    play_type = models.CharField(_('Play Type'), max_length=50, choices=PlayType.choices)
    team = models.ForeignKey(
        'teams.Team',
        on_delete=models.CASCADE,
        related_name='plays',
        help_text=_('The team this play belongs to.')
    )
    # Optional: A diagram or video link for the play
    diagram_url = models.URLField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)


    class Meta:
        # A team should not have two plays with the same name
        unique_together = ('name', 'team')

    def __str__(self):
        return f"{self.team.name} - {self.name} ({self.play_type})"
