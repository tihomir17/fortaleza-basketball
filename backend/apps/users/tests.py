# backend/apps/users/tests.py

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model

User = get_user_model()


class UserAuthTests(APITestCase):
    def setUp(self):
        # This method is run before each test
        self.register_url = reverse("auth_register")
        self.login_url = reverse("token_obtain_pair")
        self.me_url = reverse("current_user")
        self.user_data = {
            "username": "testuser",
            "email": "test@example.com",
            "password": "strongpassword123",
            "role": User.Role.PLAYER,
        }

    def test_user_registration(self):
        """
        Ensure we can register a new user.
        """
        response = self.client.post(self.register_url, self.user_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(User.objects.get().username, "testuser")

    def test_user_login(self):
        """
        Ensure a registered user can log in and get tokens.
        """
        # First, create the user
        User.objects.create_user(**self.user_data)

        # Now, try to log in
        login_data = {
            "username": self.user_data["username"],
            "password": self.user_data["password"],
        }
        response = self.client.post(self.login_url, login_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_access_protected_endpoint_unauthenticated(self):
        """
        Ensure unauthenticated users cannot access protected endpoints.
        """
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_access_protected_endpoint_authenticated(self):
        """
        Ensure an authenticated user can access the '/api/auth/me/' endpoint.
        """
        # Create user and log them in to get the token
        user = User.objects.create_user(**self.user_data)
        self.client.force_authenticate(user=user)

        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["username"], self.user_data["username"])
