# backend/apps/possessions/tests.py

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.competitions.models import Competition
from apps.games.models import Game
from .models import Possession
import datetime

User = get_user_model()


class PossessionAPITests(APITestCase):
    def setUp(self):
        self.coach = User.objects.create_user(
            username="coach", password="password", role=User.Role.COACH
        )
        self.competition = Competition.objects.create(
            name="L", season="S", created_by=self.coach
        )
        self.team1 = Team.objects.create(
            name="Team A", competition=self.competition, created_by=self.coach
        )
        self.team2 = Team.objects.create(
            name="Team B", competition=self.competition, created_by=self.coach
        )
        self.team1.coaches.add(self.coach)

        self.game = Game.objects.create(
            competition=self.competition,
            home_team=self.team1,
            away_team=self.team2,
            game_date=datetime.date.today(),
        )

        self.possession_data = {
            "game_id": self.game.id,
            "team_id": self.team1.id,
            "opponent_id": self.team2.id,
            "start_time_in_game": "11:45",
            "duration_seconds": 15,
            "quarter": 1,
            "outcome": "MADE_2PT",
            "offensive_sequence": "P&R -> Roll -> Score",
            "defensive_sequence": "Drop",
        }

    def test_create_possession(self):
        """
        Ensure a coach can log a new possession for a game their team is in.
        """
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-list")
        response = self.client.post(url, self.possession_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Possession.objects.count(), 1)

        new_possession = Possession.objects.first()
        self.assertEqual(new_possession.logged_by, self.coach)
        self.assertEqual(new_possession.offensive_sequence, "P&R -> Roll -> Score")
