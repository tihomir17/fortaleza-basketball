# apps/plays/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class PlayCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        verbose_name_plural = "Play Categories"

    def __str__(self):
        return self.name


class PlayDefinition(models.Model):
    """
    Stores the definition of an offensive or defensive play.
    """

    name = models.CharField(_("Play Name"), max_length=255)
    description = models.TextField(_("Description"), blank=True, null=True)
    play_type = models.CharField(
        _("Play Type"),
        max_length=50,
        choices=[("OFFENSIVE", "Offensive"), ("DEFENSIVE", "Defensive")],
    )
    team = models.ForeignKey(
        "teams.Team", on_delete=models.CASCADE, related_name="plays"
    )
    parent = models.ForeignKey(
        "self", on_delete=models.CASCADE, null=True, blank=True, related_name="children"
    )

    # THIS IS THE CHANGED FIELD
    category = models.ForeignKey(
        PlayCategory,
        on_delete=models.SET_NULL,  # If a category is deleted, don't delete the plays
        related_name="plays",
        null=True,
        blank=True,
    )

    subcategory = models.CharField(
        _("UI Sub-Category"), max_length=100, blank=True, null=True
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
