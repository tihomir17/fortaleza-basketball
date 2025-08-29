from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import AccessToken
from apps.teams.models import Team
from apps.games.models import Game
from apps.competitions.models import Competition
from django.utils import timezone

User = get_user_model()


class GamePermissionsTests(APITestCase):
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

        self.games_url = reverse("game-list")

    def auth(self, user):
        token = AccessToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(token)}")

    def test_list_scoped_to_member_teams(self):
        # Create a game between A and B
        game = Game.objects.create(
            competition=self.comp,
            home_team=self.team_a,
            away_team=self.team_b,
            game_date=timezone.now(),
        )
        # Player is on team B, should see
        self.auth(self.player)
        res = self.client.get(self.games_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(res.data["count"], 1)
        # Other user not member should not see
        self.auth(self.other)
        res2 = self.client.get(self.games_url)
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.assertEqual(res2.data["count"], 0)

    def test_coach_can_create_game(self):
        self.auth(self.coach)
        res = self.client.post(
            self.games_url,
            {
                "competition": self.comp.id,
                "home_team": self.team_a.id,
                "away_team": self.team_b.id,
                "game_date": timezone.now().isoformat(),
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_player_cannot_create_game(self):
        self.auth(self.player)
        res = self.client.post(
            self.games_url,
            {
                "competition": self.comp.id,
                "home_team": self.team_a.id,
                "away_team": self.team_b.id,
                "game_date": timezone.now().isoformat(),
            },
            format="json",
        )
        self.assertIn(
            res.status_code, (status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND)
        )
