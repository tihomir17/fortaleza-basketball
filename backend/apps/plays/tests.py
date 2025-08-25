# backend/apps/plays/tests.py

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.competitions.models import Competition
from .models import PlayDefinition

User = get_user_model()


class PlayAPITests(APITestCase):
    def setUp(self):
        self.coach = User.objects.create_user(
            username="coach", password="password", role=User.Role.COACH
        )
        self.competition = Competition.objects.create(
            name="Test League", season="2025", created_by=self.coach
        )
        self.team = Team.objects.create(
            name="My Team", competition=self.competition, created_by=self.coach
        )
        self.team.coaches.add(self.coach)

        self.play_data = {
            "name": "Horns Flare",
            "play_type": "OFFENSIVE",
            "team": self.team.id,
        }

    def test_create_play(self):
        """
        Ensure an authenticated user can create a play for their team.
        """
        self.client.force_authenticate(user=self.coach)
        url = reverse("play-list")
        response = self.client.post(url, self.play_data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(PlayDefinition.objects.count(), 1)

    def test_list_plays_for_team(self):
        """
        Ensure the nested endpoint /api/teams/{id}/plays/ works.
        """
        PlayDefinition.objects.create(
            name="Horns", team=self.team, play_type="OFFENSIVE"
        )

        self.client.force_authenticate(user=self.coach)
        # Note the action name 'plays' from the @action decorator
        url = reverse("team-plays", kwargs={"pk": self.team.pk})
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Horns")
