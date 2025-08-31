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
            "outcome": "MADE_2PTS",
            "offensive_set": "PICK_AND_ROLL",
            "pnr_type": "BALL_SCREEN",
            "pnr_result": "SCORER",
            "has_paint_touch": True,
            "has_kick_out": False,
            "has_extra_pass": True,
            "number_of_passes": 3,
            "defensive_set": "MAN_TO_MAN",
            "defensive_pnr": "SWITCH",
            "box_out_count": 2,
            "offensive_rebounds_allowed": 0,
            "shoot_time": 12,
            "shoot_quality": "GOOD",
            "time_range": "EARLY_SHOT_CLOCK",
            "after_timeout": False,
            "notes": "Test possession",
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
        self.assertEqual(new_possession.created_by, self.coach)
        self.assertEqual(new_possession.offensive_set, "PICK_AND_ROLL")
        self.assertEqual(new_possession.pnr_type, "BALL_SCREEN")
        self.assertEqual(new_possession.pnr_result, "SCORER")
        self.assertEqual(new_possession.has_paint_touch, True)
        self.assertEqual(new_possession.has_kick_out, False)
        self.assertEqual(new_possession.has_extra_pass, True)
        self.assertEqual(new_possession.number_of_passes, 3)
        self.assertEqual(new_possession.defensive_set, "MAN_TO_MAN")
        self.assertEqual(new_possession.defensive_pnr, "SWITCH")
        self.assertEqual(new_possession.box_out_count, 2)
        self.assertEqual(new_possession.offensive_rebounds_allowed, 0)
        self.assertEqual(new_possession.shoot_time, 12)
        self.assertEqual(new_possession.shoot_quality, "GOOD")
        self.assertEqual(new_possession.time_range, "EARLY_SHOT_CLOCK")
        self.assertEqual(new_possession.after_timeout, False)
        self.assertEqual(new_possession.notes, "Test possession")
        self.assertEqual(
            new_possession.points_scored, 2
        )  # Auto-calculated from outcome
