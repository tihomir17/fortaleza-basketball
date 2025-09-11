"""
Comprehensive tests for Game model and views.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from apps.teams.models import Team
from apps.competitions.models import Competition
from .models import Game, GameStats

User = get_user_model()


class GameModelTests(TestCase):
    """Test Game model."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            description='A test competition'
        )
        self.home_team = Team.objects.create(
            name='Home Team',
            description='Home team',
            competition=self.competition
        )
        self.away_team = Team.objects.create(
            name='Away Team',
            description='Away team',
            competition=self.competition
        )
        self.game = Game.objects.create(
            home_team=self.home_team,
            away_team=self.away_team,
            scheduled_time=timezone.now(),
            status='SCHEDULED',
            home_score=0,
            away_score=0
        )
    
    def test_game_creation(self):
        """Test creating a game."""
        self.assertEqual(self.game.home_team, self.home_team)
        self.assertEqual(self.game.away_team, self.away_team)
        self.assertEqual(self.game.status, 'SCHEDULED')
        self.assertEqual(self.game.home_score, 0)
        self.assertEqual(self.game.away_score, 0)
    
    def test_game_string_representation(self):
        """Test game string representation."""
        expected = f"{self.home_team.name} vs {self.away_team.name}"
        self.assertEqual(str(self.game), expected)
    
    def test_game_status_transitions(self):
        """Test game status transitions."""
        # Start game
        self.game.status = 'IN_PROGRESS'
        self.game.save()
        self.assertEqual(self.game.status, 'IN_PROGRESS')
        
        # Complete game
        self.game.status = 'COMPLETED'
        self.game.home_score = 85
        self.game.away_score = 78
        self.game.save()
        self.assertEqual(self.game.status, 'COMPLETED')
        self.assertEqual(self.game.home_score, 85)
        self.assertEqual(self.game.away_score, 78)
    
    def test_game_stats_creation(self):
        """Test creating game stats."""
        stats = GameStats.objects.create(
            game=self.game,
            team=self.home_team,
            points=85,
            rebounds=42,
            assists=18,
            steals=8,
            blocks=5,
            turnovers=12,
            field_goals_made=32,
            field_goals_attempted=68,
            three_pointers_made=8,
            three_pointers_attempted=22,
            free_throws_made=13,
            free_throws_attempted=18
        )
        
        self.assertEqual(stats.game, self.game)
        self.assertEqual(stats.team, self.home_team)
        self.assertEqual(stats.points, 85)
        self.assertEqual(stats.field_goal_percentage, 47.1)  # 32/68 * 100
        self.assertEqual(stats.three_point_percentage, 36.4)  # 8/22 * 100
        self.assertEqual(stats.free_throw_percentage, 72.2)  # 13/18 * 100


class GameAPITests(APITestCase):
    """Test Game API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            description='A test competition'
        )
        self.home_team = Team.objects.create(
            name='Home Team',
            description='Home team',
            competition=self.competition
        )
        self.away_team = Team.objects.create(
            name='Away Team',
            description='Away team',
            competition=self.competition
        )
        self.game = Game.objects.create(
            home_team=self.home_team,
            away_team=self.away_team,
            scheduled_time=timezone.now(),
            status='SCHEDULED',
            home_score=0,
            away_score=0
        )
        
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_games(self):
        """Test listing games."""
        url = reverse('game-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['home_team']['name'], 'Home Team')
        self.assertEqual(response.data['results'][0]['away_team']['name'], 'Away Team')
    
    def test_retrieve_game(self):
        """Test retrieving a single game."""
        url = reverse('game-detail', kwargs={'pk': self.game.pk})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['home_team']['name'], 'Home Team')
        self.assertEqual(response.data['away_team']['name'], 'Away Team')
        self.assertEqual(response.data['status'], 'SCHEDULED')
    
    def test_create_game(self):
        """Test creating a new game."""
        url = reverse('game-list')
        data = {
            'home_team': self.home_team.id,
            'away_team': self.away_team.id,
            'scheduled_time': timezone.now().isoformat(),
            'status': 'SCHEDULED',
            'home_score': 0,
            'away_score': 0
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['home_team']['name'], 'Home Team')
        self.assertEqual(response.data['away_team']['name'], 'Away Team')
        self.assertEqual(response.data['status'], 'SCHEDULED')
    
    def test_update_game(self):
        """Test updating a game."""
        url = reverse('game-detail', kwargs={'pk': self.game.pk})
        data = {
            'status': 'IN_PROGRESS',
            'home_score': 45,
            'away_score': 42
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'IN_PROGRESS')
        self.assertEqual(response.data['home_score'], 45)
        self.assertEqual(response.data['away_score'], 42)
    
    def test_delete_game(self):
        """Test deleting a game."""
        url = reverse('game-detail', kwargs={'pk': self.game.pk})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Game.objects.filter(pk=self.game.pk).exists())
    
    def test_game_filtering(self):
        """Test filtering games by various criteria."""
        # Create additional games
        Game.objects.create(
            home_team=self.away_team,
            away_team=self.home_team,
            scheduled_time=timezone.now(),
            status='COMPLETED',
            home_score=78,
            away_score=85
        )
        
        Game.objects.create(
            home_team=self.home_team,
            away_team=self.away_team,
            scheduled_time=timezone.now(),
            status='CANCELLED',
            home_score=0,
            away_score=0
        )
        
        url = reverse('game-list')
        
        # Filter by status
        response = self.client.get(url, {'status': 'SCHEDULED'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['status'], 'SCHEDULED')
        
        # Filter by team
        response = self.client.get(url, {'team': self.home_team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)  # Home team appears in 2 games
        
        # Filter by date range
        from datetime import datetime, timedelta
        today = datetime.now().date()
        tomorrow = today + timedelta(days=1)
        
        response = self.client.get(url, {
            'scheduled_time_after': today.isoformat(),
            'scheduled_time_before': tomorrow.isoformat()
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 3)  # All games are today
    
    def test_game_search(self):
        """Test searching games by team names."""
        url = reverse('game-list')
        response = self.client.get(url, {'search': 'Home'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['home_team']['name'], 'Home Team')
    
    def test_upcoming_games(self):
        """Test getting upcoming games."""
        url = reverse('game-upcoming')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['status'], 'SCHEDULED')
    
    def test_recent_games(self):
        """Test getting recent games."""
        # Complete the game to make it recent
        self.game.status = 'COMPLETED'
        self.game.home_score = 85
        self.game.away_score = 78
        self.game.save()
        
        url = reverse('game-recent')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['status'], 'COMPLETED')
    
    def test_game_validation_errors(self):
        """Test game validation error handling."""
        url = reverse('game-list')
        
        # Test missing required fields
        data = {
            'away_team': self.away_team.id,
            'scheduled_time': timezone.now().isoformat()
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('home_team', response.data)
        
        # Test same team for home and away
        data = {
            'home_team': self.home_team.id,
            'away_team': self.home_team.id,  # Same team
            'scheduled_time': timezone.now().isoformat()
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_unauthorized_access(self):
        """Test that unauthorized users cannot access games."""
        self.client.credentials()  # Remove auth token
        
        url = reverse('game-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        url = reverse('game-detail', kwargs={'pk': self.game.pk})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class GameStatsAPITests(APITestCase):
    """Test GameStats API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.competition = Competition.objects.create(
            name='Test Competition',
            description='A test competition'
        )
        self.team = Team.objects.create(
            name='Test Team',
            description='Test team',
            competition=self.competition
        )
        self.game = Game.objects.create(
            home_team=self.team,
            away_team=self.team,
            scheduled_time=timezone.now(),
            status='COMPLETED',
            home_score=85,
            away_score=78
        )
        self.stats = GameStats.objects.create(
            game=self.game,
            team=self.team,
            points=85,
            rebounds=42,
            assists=18,
            steals=8,
            blocks=5,
            turnovers=12,
            field_goals_made=32,
            field_goals_attempted=68,
            three_pointers_made=8,
            three_pointers_attempted=22,
            free_throws_made=13,
            free_throws_attempted=18
        )
        
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_list_game_stats(self):
        """Test listing game stats."""
        url = reverse('gamestats-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['points'], 85)
        self.assertEqual(response.data['results'][0]['team']['name'], 'Test Team')
    
    def test_retrieve_game_stats(self):
        """Test retrieving a single game stats."""
        url = reverse('gamestats-detail', kwargs={'pk': self.stats.pk})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['points'], 85)
        self.assertEqual(response.data['rebounds'], 42)
        self.assertEqual(response.data['assists'], 18)
        self.assertEqual(response.data['field_goal_percentage'], 47.1)
    
    def test_create_game_stats(self):
        """Test creating new game stats."""
        url = reverse('gamestats-list')
        data = {
            'game': self.game.id,
            'team': self.team.id,
            'points': 78,
            'rebounds': 38,
            'assists': 15,
            'steals': 6,
            'blocks': 3,
            'turnovers': 14,
            'field_goals_made': 28,
            'field_goals_attempted': 65,
            'three_pointers_made': 6,
            'three_pointers_attempted': 20,
            'free_throws_made': 16,
            'free_throws_attempted': 22
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['points'], 78)
        self.assertEqual(response.data['rebounds'], 38)
        self.assertEqual(response.data['field_goal_percentage'], 43.1)
    
    def test_update_game_stats(self):
        """Test updating game stats."""
        url = reverse('gamestats-detail', kwargs={'pk': self.stats.pk})
        data = {
            'points': 90,
            'rebounds': 45,
            'assists': 20
        }
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['points'], 90)
        self.assertEqual(response.data['rebounds'], 45)
        self.assertEqual(response.data['assists'], 20)
    
    def test_delete_game_stats(self):
        """Test deleting game stats."""
        url = reverse('gamestats-detail', kwargs={'pk': self.stats.pk})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(GameStats.objects.filter(pk=self.stats.pk).exists())
    
    def test_game_stats_filtering(self):
        """Test filtering game stats."""
        url = reverse('gamestats-list')
        
        # Filter by game
        response = self.client.get(url, {'game': self.game.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        
        # Filter by team
        response = self.client.get(url, {'team': self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        
        # Filter by points range
        response = self.client.get(url, {'points__gte': 80})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        
        response = self.client.get(url, {'points__gte': 90})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 0)
