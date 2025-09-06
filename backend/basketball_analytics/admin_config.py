# basketball_analytics/admin_config.py

from django.contrib import admin
from django.contrib.admin import AdminSite
from django.utils.html import format_html
from django.urls import path, reverse
from django.http import HttpResponse
from django.template.response import TemplateResponse
from django.db.models import Count
from apps.users.models import User
from apps.teams.models import Team
from apps.games.models import Game
from apps.competitions.models import Competition


class ModernAdminSite(AdminSite):
    """Ultra-modern admin site with enhanced features"""
    
    site_header = "🏀 Basketball Analytics"
    site_title = "Basketball Analytics"
    index_title = "Dashboard"
    site_url = "/"
    
    def get_urls(self):
        """Add custom URLs"""
        urls = super().get_urls()
        custom_urls = [
            path('analytics/', self.admin_view(self.analytics_view), name='analytics'),
            path('reports/', self.admin_view(self.reports_view), name='reports'),
        ]
        return custom_urls + urls
    
    def index(self, request, extra_context=None):
        """Enhanced dashboard with real-time statistics"""
        extra_context = extra_context or {}
        
        # Get comprehensive statistics
        stats = {
            'total_users': User.objects.count(),
            'total_teams': Team.objects.count(),
            'total_games': Game.objects.count(),
            'total_competitions': Competition.objects.count(),
            'recent_users': User.objects.order_by('-date_joined')[:5],
            'recent_teams': Team.objects.order_by('-created_at')[:5],
            'recent_games': Game.objects.order_by('-created_at')[:5],
        }
        
        # Role-based statistics
        role_stats = User.objects.values('role').annotate(count=Count('role'))
        stats['role_breakdown'] = {item['role']: item['count'] for item in role_stats}
        
        # Coach type statistics
        coach_stats = User.objects.filter(role=User.Role.COACH).values('coach_type').annotate(count=Count('coach_type'))
        stats['coach_breakdown'] = {item['coach_type']: item['count'] for item in coach_stats}
        
        # Staff type statistics
        staff_stats = User.objects.filter(role=User.Role.STAFF).values('staff_type').annotate(count=Count('staff_type'))
        stats['staff_breakdown'] = {item['staff_type']: item['count'] for item in staff_stats}
        
        # Team statistics
        team_stats = Team.objects.annotate(
            coach_count=Count('coaches'),
            player_count=Count('players')
        ).order_by('-created_at')[:5]
        stats['team_details'] = team_stats
        
        # Game statistics
        game_stats = Game.objects.select_related('home_team', 'away_team', 'competition').order_by('-game_date')[:5]
        stats['game_details'] = game_stats
        
        extra_context.update(stats)
        return super().index(request, extra_context)
    
    def analytics_view(self, request):
        """Custom analytics view"""
        context = {
            'title': 'Analytics Dashboard',
            'has_permission': True,
        }
        return TemplateResponse(request, 'admin/analytics.html', context)
    
    def reports_view(self, request):
        """Custom reports view"""
        context = {
            'title': 'Reports',
            'has_permission': True,
        }
        return TemplateResponse(request, 'admin/reports.html', context)


# Create the modern admin site instance
admin_site = ModernAdminSite(name='modern_admin')

# Custom admin configuration
admin_site.site_header = "🏀 Basketball Analytics"
admin_site.site_title = "Basketball Analytics"
admin_site.index_title = "Modern Dashboard"
