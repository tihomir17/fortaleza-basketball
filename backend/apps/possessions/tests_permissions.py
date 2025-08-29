from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import AccessToken
from apps.teams.models import Team
from apps.games.models import Game
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from django.utils import timezone

User = get_user_model()


class PossessionPermissionsTests(APITestCase):
    def setUp(self):
        self.coach = User.objects.create_user(
            username="coach", password="pwd", role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username="player", password="pwd", role=User.Role.PLAYER
        )
        self.other = User.objects.create_user(username="other", password="pwd")

        self.comp = Competition.objects.create(
            name="League", season="2024-2025", created_by=self.coach
        )
        self.team_a = Team.objects.create(
            name="A", created_by=self.coach, competition=self.comp
        )
        self.team_b = Team.objects.create(
            name="B", created_by=self.coach, competition=self.comp
        )
        self.team_a.coaches.add(self.coach)
        self.team_b.players.add(self.player)

        self.game = Game.objects.create(
            competition=self.comp,
            home_team=self.team_a,
            away_team=self.team_b,
            game_date=timezone.now(),
        )
        self.url = reverse("possession-list")

    def auth(self, user):
        token = AccessToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(token)}")

    def test_member_can_read_possessions(self):
        p = Possession.objects.create(
            game=self.game,
            team=self.team_b,
            opponent=self.team_a,
            start_time_in_game="12:00",
            duration_seconds=10,
            quarter=1,
            outcome=Possession.OutcomeChoices.MADE_2PT,
            logged_by=self.coach,
        )
        self.auth(self.player)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(res.data["count"], 1)

    def test_coach_can_create_possession(self):
        self.auth(self.coach)
        res = self.client.post(
            self.url,
            {
                "game": self.game.id,
                "team": self.team_a.id,
                "opponent": self.team_b.id,
                "start_time_in_game": "11:50",
                "duration_seconds": 12,
                "quarter": 1,
                "outcome": Possession.OutcomeChoices.MADE_2PT,
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_player_cannot_create_possession(self):
        self.auth(self.player)
        res = self.client.post(
            self.url,
            {
                "game": self.game.id,
                "team": self.team_a.id,
                "opponent": self.team_b.id,
                "start_time_in_game": "11:50",
                "duration_seconds": 12,
                "quarter": 1,
                "outcome": Possession.OutcomeChoices.MADE_2PT,
            },
            format="json",
        )
        self.assertIn(
            res.status_code, (status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND)
        )
