# apps/events/models.py
from django.db import models
from django.conf import settings


class CalendarEvent(models.Model):
    class EventType(models.TextChoices):
        PRACTICE_TEAM = "PRACTICE_TEAM", "Team Practice"
        PRACTICE_INDIVIDUAL = "PRACTICE_INDIVIDUAL", "Individual Practice"
        OTHER = "OTHER", "Other"

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    event_type = models.CharField(max_length=50, choices=EventType.choices)

    # A team practice is linked to one team
    team = models.ForeignKey(
        "teams.Team",
        on_delete=models.CASCADE,
        related_name="team_events",
        null=True,
        blank=True,
    )

    # An individual practice can have multiple attendees
    attendees = models.ManyToManyField(
        settings.AUTH_USER_MODEL, related_name="individual_events", blank=True
    )

    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    class Meta:
        ordering = ["start_time"]

    def __str__(self):
        return self.title
