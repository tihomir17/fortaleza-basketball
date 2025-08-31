# backend/apps/teams/tests.py

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from apps.competitions.models import Competition
from .models import Team

User = get_user_model()


class TeamAPITests(APITestCase):
    def setUp(self):
        self.coach_user = User.objects.create_user(
            username="coach", password="password", role=User.Role.COACH
        )
        self.other_user = User.objects.create_user(
            username="other", password="password", role=User.Role.COACH
        )

        self.competition = Competition.objects.create(
            name="Test League", season="2025", created_by=self.coach_user
        )

        self.team = Team.objects.create(
            name="My Team", competition=self.competition, created_by=self.coach_user
        )
        self.team.coaches.add(self.coach_user)

        self.other_team = Team.objects.create(
            name="Other Team", competition=self.competition, created_by=self.other_user
        )

    def test_list_teams_as_member(self):
        """
        Ensure a logged-in user can only see teams they are a member of.
        """
        self.client.force_authenticate(user=self.coach_user)
        response = self.client.get(reverse("team-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get("count"), 1)
        self.assertEqual(len(response.data.get("results", [])), 1)
        self.assertEqual(response.data["results"][0]["name"], "My Team")

    def test_list_teams_as_non_member(self):
        """
        Ensure a logged-in user cannot see teams they are not a member of.
        """
        self.client.force_authenticate(user=self.other_user)
        response = self.client.get(reverse("team-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get("count"), 0)
        self.assertEqual(len(response.data.get("results", [])), 0)

    def test_create_team(self):
        """
        Ensure a logged-in user can create a new team.
        """
        self.client.force_authenticate(user=self.coach_user)
        url = reverse("team-list")
        data = {"name": "New Team", "competition": self.competition.id}
        response = self.client.post(url, data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Team.objects.count(), 3)
        # Check that the creator is automatically added as a coach
        new_team = Team.objects.get(name="New Team")
        self.assertIn(self.coach_user, new_team.coaches.all())
