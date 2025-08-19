# apps/plays/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class PlayDefinition(models.Model):
    """
    Stores the definition of an offensive or defensive play.
    """

    class PlayType(models.TextChoices):
        OFFENSIVE = "OFFENSIVE", _("Offensive")
        DEFENSIVE = "DEFENSIVE", _("Defensive")

    name = models.CharField(_("Play Name"), max_length=255)
    description = models.TextField(_("Description"), blank=True, null=True)
    play_type = models.CharField(
        _("Play Type"), max_length=50, choices=PlayType.choices
    )
    team = models.ForeignKey(
        "teams.Team",
        on_delete=models.CASCADE,
        related_name="plays",
        help_text=_("The team this play belongs to."),
    )
    parent = models.ForeignKey(
        "self",  # This makes the relationship point to the same model
        on_delete=models.CASCADE,  # If a parent is deleted, its children are also deleted
        null=True,  # A play can have no parent (it's a top-level category)
        blank=True,  # It's optional in the Django admin
        related_name="children",  # How we can find children from a parent instance
    )
    # Optional: A diagram or video link for the play
    diagram_url = models.URLField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)

    class Meta:
        # A team should not have two plays with the same name
        unique_together = ("name", "team")

    def __str__(self):
        # A nice string representation for the admin
        if self.parent:
            return f"{self.parent.name} -> {self.name}"
        return self.name
