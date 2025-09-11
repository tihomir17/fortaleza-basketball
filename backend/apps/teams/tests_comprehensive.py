"""
Comprehensive tests for Team model and views.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from apps.competitions.models import Competition
from .models import Team

User = get_user_model()


class TeamModelTests(TestCase):
    """Test Team model."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            created_by=self.user
        )
        self.team = Team.objects.create(
            name='Test Team',
            competition=self.competition,
            created_by=self.user
        )
    
    def test_team_creation(self):
        """Test creating a team."""
        self.assertEqual(self.team.name, 'Test Team')
        self.assertEqual(self.team.description, 'A test team')
        self.assertEqual(self.team.competition, self.competition)
        self.assertEqual(self.team.coaches.count(), 0)
        self.assertEqual(self.team.players.count(), 0)
    
    def test_team_string_representation(self):
        """Test team string representation."""
        self.assertEqual(str(self.team), 'Test Team')
    
    def test_add_coach(self):
        """Test adding a coach to a team."""
        self.team.coaches.add(self.user)
        self.assertEqual(self.team.coaches.count(), 1)
        self.assertIn(self.user, self.team.coaches.all())
    
    def test_add_player(self):
        """Test adding a player to a team."""
        player = User.objects.create_user(
            username='player1',
            email='player1@example.com',
            password='testpass123'
        )
        self.team.players.add(player)
        self.assertEqual(self.team.players.count(), 1)
        self.assertIn(player, self.team.players.all())
    
    def test_team_members(self):
        """Test getting all team members."""
        coach = User.objects.create_user(
            username='coach1',
            email='coach1@example.com',
            password='testpass123'
        )
        player = User.objects.create_user(
            username='player1',
            email='player1@example.com',
            password='testpass123'
        )
        
        self.team.coaches.add(coach)
        self.team.players.add(player)
        
        members = self.team.get_all_members()
        self.assertEqual(len(members), 2)
        self.assertIn(coach, members)
        self.assertIn(player, members)
    
    def test_team_unique_name_per_competition(self):
        """Test that team names are unique per competition."""
        # This should work - different competition
        other_competition = Competition.objects.create(
            name='Other Competition',
            description='Another competition'
        )
        Team.objects.create(
            name='Test Team',  # Same name, different competition
            competition=other_competition
        )
        
        # This should fail - same name, same competition
        with self.assertRaises(Exception):
            Team.objects.create(
                name='Test Team',  # Same name, same competition
                description='Duplicate team',
                competition=self.competition
            )


class TeamAPITests(APITestCase):
    """Test Team API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            created_by=self.user
        )
        self.team = Team.objects.create(
            name='Test Team',
            competition=self.competition,
            created_by=self.user
        )
        
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_teams(self):
        """Test listing teams."""
        url = reverse('team-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Test Team')
    
    def test_retrieve_team(self):
        """Test retrieving a single team."""
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Test Team')
        self.assertEqual(response.data['description'], 'A test team')
        self.assertEqual(response.data['competition'], self.competition.id)
    
    def test_create_team(self):
        """Test creating a new team."""
        url = reverse('team-list')
        data = {
            'name': 'New Team',
            'competition': self.competition.id
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'New Team')
        self.assertEqual(response.data['competition'], self.competition.id)
    
    def test_update_team(self):
        """Test updating a team."""
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        data = {
            'name': 'Updated Team',
            'description': 'An updated team',
            'competition': self.competition.id
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated Team')
        self.assertEqual(response.data['description'], 'An updated team')
    
    def test_delete_team(self):
        """Test deleting a team."""
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Team.objects.filter(pk=self.team.pk).exists())
    
    def test_team_filtering(self):
        """Test filtering teams by competition."""
        other_competition = Competition.objects.create(
            name='Other Competition',
            description='Another competition'
        )
        Team.objects.create(
            name='Other Team',
            description='Another team',
            competition=other_competition
        )
        
        url = reverse('team-list')
        response = self.client.get(url, {'competition': self.competition.id})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Test Team')
    
    def test_team_search(self):
        """Test searching teams by name."""
        url = reverse('team-list')
        response = self.client.get(url, {'search': 'Test'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Test Team')
    
    def test_team_validation_errors(self):
        """Test team validation error handling."""
        url = reverse('team-list')
        
        # Test missing required fields
        data = {
            'description': 'Team without name',
            'competition': self.competition.id
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('name', response.data)
        
        # Test invalid competition
        data = {
            'name': 'Invalid Team',
            'description': 'Team with invalid competition',
            'competition': 999  # Non-existent competition
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_unauthorized_access(self):
        """Test that unauthorized users cannot access teams."""
        self.client.credentials()  # Remove auth token
        
        url = reverse('team-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TeamMembershipTests(APITestCase):
    """Test team membership functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            created_by=self.user
        )
        self.team = Team.objects.create(
            name='Test Team',
            competition=self.competition,
            created_by=self.user
        )
        
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_add_coach_to_team(self):
        """Test adding a coach to a team."""
        coach = User.objects.create_user(
            username='coach1',
            email='coach1@example.com',
            password='testpass123'
        )
        
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        data = {
            'coaches': [coach.id]
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(coach.id, response.data['coaches'])
    
    def test_add_player_to_team(self):
        """Test adding a player to a team."""
        player = User.objects.create_user(
            username='player1',
            email='player1@example.com',
            password='testpass123'
        )
        
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        data = {
            'players': [player.id]
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(player.id, response.data['players'])
    
    def test_remove_member_from_team(self):
        """Test removing a member from a team."""
        coach = User.objects.create_user(
            username='coach1',
            email='coach1@example.com',
            password='testpass123'
        )
        self.team.coaches.add(coach)
        
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        data = {
            'coaches': []  # Remove all coaches
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['coaches']), 0)
    
    def test_team_membership_serialization(self):
        """Test that team membership is properly serialized."""
        coach = User.objects.create_user(
            username='coach1',
            email='coach1@example.com',
            password='testpass123',
            first_name='Coach',
            last_name='One'
        )
        player = User.objects.create_user(
            username='player1',
            email='player1@example.com',
            password='testpass123',
            first_name='Player',
            last_name='One'
        )
        
        self.team.coaches.add(coach)
        self.team.players.add(player)
        
        url = reverse('team-detail', kwargs={'pk': self.team.pk})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['coaches']), 1)
        self.assertEqual(len(response.data['players']), 1)
        
        # Check that coach and player details are included
        coach_data = response.data['coaches'][0]
        player_data = response.data['players'][0]
        
        self.assertEqual(coach_data['username'], 'coach1')
        self.assertEqual(coach_data['first_name'], 'Coach')
        self.assertEqual(player_data['username'], 'player1')
        self.assertEqual(player_data['first_name'], 'Player')
