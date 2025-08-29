from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from rest_framework_simplejwt.tokens import AccessToken

User = get_user_model()


class TeamPermissionsTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            username="admin", password="pwd", is_superuser=True
        )
        self.coach = User.objects.create_user(
            username="coach", password="pwd", role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username="player", password="pwd", role=User.Role.PLAYER
        )
        self.other_user = User.objects.create_user(username="other", password="pwd")

        self.team = Team.objects.create(name="Alpha", created_by=self.coach)
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)

        self.teams_url = reverse("team-list")
        self.team_detail_url = reverse("team-detail", args=[self.team.id])

    def auth(self, user):
        token = AccessToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(token)}")

    def test_member_can_read_team(self):
        self.auth(self.player)
        res = self.client.get(self.team_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_non_member_cannot_read_team(self):
        self.auth(self.other_user)
        res = self.client.get(self.team_detail_url)
        # Not found due to queryset scoping
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_coach_can_update_team(self):
        self.auth(self.coach)
        res = self.client.patch(
            self.team_detail_url, {"name": "AlphaUpdated"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.team.refresh_from_db()
        self.assertEqual(self.team.name, "AlphaUpdated")

    def test_player_cannot_update_team(self):
        self.auth(self.player)
        res = self.client.patch(
            self.team_detail_url, {"name": "NotAllowed"}, format="json"
        )
        self.assertIn(
            res.status_code, (status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND)
        )
