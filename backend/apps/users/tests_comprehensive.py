"""
Comprehensive tests for User model and authentication.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User

User = get_user_model()


class UserModelTests(TestCase):
    """Test User model."""
    
    def test_user_creation(self):
        """Test creating a user."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
        
        self.assertEqual(user.username, 'testuser')
        self.assertEqual(user.email, 'test@example.com')
        self.assertEqual(user.first_name, 'Test')
        self.assertEqual(user.last_name, 'User')
        self.assertTrue(user.check_password('testpass123'))
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
    
    def test_superuser_creation(self):
        """Test creating a superuser."""
        user = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123'
        )
        
        self.assertEqual(user.username, 'admin')
        self.assertEqual(user.email, 'admin@example.com')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
    
    def test_user_string_representation(self):
        """Test user string representation."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            first_name='Test',
            last_name='User'
        )
        
        self.assertEqual(str(user), 'testuser')
    
    def test_user_full_name(self):
        """Test user full name property."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            first_name='Test',
            last_name='User'
        )
        
        self.assertEqual(user.get_full_name(), 'Test User')
    
    def test_user_short_name(self):
        """Test user short name property."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            first_name='Test',
            last_name='User'
        )
        
        self.assertEqual(user.get_short_name(), 'Test')
    
    def test_user_role_choices(self):
        """Test user role choices."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            role=User.Role.COACH
        )
        
        self.assertEqual(user.role, User.Role.COACH)
        self.assertEqual(user.get_role_display(), 'Coach')
    
    def test_user_phone_number(self):
        """Test user phone number field."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            phone_number='+1234567890'
        )
        
        self.assertEqual(user.phone_number, '+1234567890')
    
    def test_user_date_of_birth(self):
        """Test user date of birth field."""
        from datetime import date
        
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            date_of_birth=date(1990, 1, 1)
        )
        
        self.assertEqual(user.date_of_birth, date(1990, 1, 1))
    
    def test_user_is_active(self):
        """Test user is_active field."""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            is_active=False
        )
        
        self.assertFalse(user.is_active)
    
    def test_user_email_required(self):
        """Test that email is required."""
        with self.assertRaises(ValueError):
            User.objects.create_user(
                username='testuser',
                email='',
                password='testpass123'
            )


class AuthenticationAPITests(APITestCase):
    """Test authentication API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )
    
    def test_user_registration(self):
        """Test user registration endpoint."""
        url = reverse('user-register')
        data = {
            'username': 'newuser',
            'email': 'newuser@example.com',
            'password': 'newpass123',
            'password_confirm': 'newpass123',
            'first_name': 'New',
            'last_name': 'User'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['username'], 'newuser')
        self.assertEqual(response.data['email'], 'newuser@example.com')
        self.assertEqual(response.data['first_name'], 'New')
        self.assertEqual(response.data['last_name'], 'User')
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
    
    def test_user_registration_password_mismatch(self):
        """Test user registration with password mismatch."""
        url = reverse('user-register')
        data = {
            'username': 'newuser',
            'email': 'newuser@example.com',
            'password': 'newpass123',
            'password_confirm': 'differentpass',
            'first_name': 'New',
            'last_name': 'User'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', response.data)
    
    def test_user_registration_duplicate_username(self):
        """Test user registration with duplicate username."""
        url = reverse('user-register')
        data = {
            'username': 'testuser',  # Already exists
            'email': 'newuser@example.com',
            'password': 'newpass123',
            'password_confirm': 'newpass123',
            'first_name': 'New',
            'last_name': 'User'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', response.data)
    
    def test_user_login(self):
        """Test user login endpoint."""
        url = reverse('user-login')
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertEqual(response.data['user']['username'], 'testuser')
        self.assertEqual(response.data['user']['email'], 'test@example.com')
    
    def test_user_login_invalid_credentials(self):
        """Test user login with invalid credentials."""
        url = reverse('user-login')
        data = {
            'username': 'testuser',
            'password': 'wrongpassword'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertIn('error', response.data)
    
    def test_user_login_inactive_user(self):
        """Test user login with inactive user."""
        self.user.is_active = False
        self.user.save()
        
        url = reverse('user-login')
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_token_refresh(self):
        """Test token refresh endpoint."""
        refresh = RefreshToken.for_user(self.user)
        
        url = reverse('token-refresh')
        data = {
            'refresh': str(refresh)
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
    
    def test_token_refresh_invalid_token(self):
        """Test token refresh with invalid token."""
        url = reverse('token-refresh')
        data = {
            'refresh': 'invalid-token'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_user_profile(self):
        """Test getting user profile."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-profile')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'testuser')
        self.assertEqual(response.data['email'], 'test@example.com')
        self.assertEqual(response.data['first_name'], 'Test')
        self.assertEqual(response.data['last_name'], 'User')
    
    def test_user_profile_update(self):
        """Test updating user profile."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-profile')
        data = {
            'first_name': 'Updated',
            'last_name': 'Name',
            'phone_number': '+1234567890'
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['first_name'], 'Updated')
        self.assertEqual(response.data['last_name'], 'Name')
        self.assertEqual(response.data['phone_number'], '+1234567890')
    
    def test_user_logout(self):
        """Test user logout endpoint."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-logout')
        data = {
            'refresh': str(refresh)
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Successfully logged out')
    
    def test_unauthorized_access(self):
        """Test that unauthorized users cannot access protected endpoints."""
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_password_change(self):
        """Test changing user password."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-change-password')
        data = {
            'old_password': 'testpass123',
            'new_password': 'newpass123',
            'new_password_confirm': 'newpass123'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Password changed successfully')
        
        # Verify old password no longer works
        self.assertFalse(self.user.check_password('testpass123'))
        self.assertTrue(self.user.check_password('newpass123'))
    
    def test_password_change_wrong_old_password(self):
        """Test changing password with wrong old password."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-change-password')
        data = {
            'old_password': 'wrongpassword',
            'new_password': 'newpass123',
            'new_password_confirm': 'newpass123'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('old_password', response.data)
    
    def test_password_change_mismatch(self):
        """Test changing password with mismatched new passwords."""
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-change-password')
        data = {
            'old_password': 'testpass123',
            'new_password': 'newpass123',
            'new_password_confirm': 'differentpass'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('new_password', response.data)


class UserPermissionsTests(APITestCase):
    """Test user permissions and role-based access."""
    
    def setUp(self):
        self.coach = User.objects.create_user(
            username='coach',
            email='coach@example.com',
            password='coachpass123',
            role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username='player',
            email='player@example.com',
            password='playerpass123',
            role=User.Role.PLAYER
        )
        self.admin = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass123',
            role=User.Role.ADMIN,
            is_staff=True
        )
    
    def test_coach_permissions(self):
        """Test coach user permissions."""
        refresh = RefreshToken.for_user(self.coach)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        # Coach should be able to access their profile
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'COACH')
    
    def test_player_permissions(self):
        """Test player user permissions."""
        refresh = RefreshToken.for_user(self.player)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        # Player should be able to access their profile
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'PLAYER')
    
    def test_admin_permissions(self):
        """Test admin user permissions."""
        refresh = RefreshToken.for_user(self.admin)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        # Admin should be able to access their profile
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'ADMIN')
        self.assertTrue(response.data['is_staff'])
    
    def test_user_list_permissions(self):
        """Test user list endpoint permissions."""
        # Regular users should not be able to list all users
        refresh = RefreshToken.for_user(self.coach)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        url = reverse('user-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Admin should be able to list users
        refresh = RefreshToken.for_user(self.admin)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data['results']), 3)  # At least our 3 test users
