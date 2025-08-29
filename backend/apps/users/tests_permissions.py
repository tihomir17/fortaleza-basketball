from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import AccessToken
from apps.teams.models import Team

User = get_user_model()

class UserPermissionsTests(APITestCase):
    def setUp(self):
        self.coach = User.objects.create_user(username="coach", password="pwd", role=User.Role.COACH)
        self.player = User.objects.create_user(username="player", password="pwd", role=User.Role.PLAYER)
        self.other = User.objects.create_user(username="other", password="pwd")
        self.team = Team.objects.create(name="A", created_by=self.coach)
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)
        self.url = reverse("user-list")

    def auth(self, user):
        token = AccessToken.for_user(user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(token)}")

    def test_self_update_allowed(self):
        self.auth(self.player)
        detail = reverse("user-detail", args=[self.player.id])
        res = self.client.patch(detail, {"first_name": "P1"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_coach_can_update_player_on_team(self):
        self.auth(self.coach)
        detail = reverse("user-detail", args=[self.player.id])
        res = self.client.patch(detail, {"first_name": "P2"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_other_user_cannot_update(self):
        self.auth(self.other)
        detail = reverse("user-detail", args=[self.player.id])
        res = self.client.patch(detail, {"first_name": "X"}, format="json")
        self.assertIn(res.status_code, (status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND))
