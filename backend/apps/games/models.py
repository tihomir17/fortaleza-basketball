# apps/games/models.py
from django.db import models
from django.conf import settings


class Game(models.Model):
    competition = models.ForeignKey(
        "competitions.Competition", on_delete=models.CASCADE, related_name="games"
    )
    home_team = models.ForeignKey(
        "teams.Team", on_delete=models.CASCADE, related_name="home_games"
    )
    away_team = models.ForeignKey(
        "teams.Team", on_delete=models.CASCADE, related_name="away_games"
    )
    game_date = models.DateTimeField()

    # Optional: You could add final scores here later
    home_team_score = models.PositiveIntegerField(null=True, blank=True)
    away_team_score = models.PositiveIntegerField(null=True, blank=True)

    class Meta:
        ordering = ["-game_date"]  # Show most recent games first

    def __str__(self):
        return f"{self.home_team.name} vs {self.away_team.name} on {self.game_date}"
