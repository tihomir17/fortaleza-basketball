# apps/core/admin_views.py

from django.contrib import admin
from django.contrib.admin.views.main import ChangeList
from django.db.models import Count
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.games.models import Game
from apps.competitions.models import Competition

User = get_user_model()


class CustomAdminSite(admin.AdminSite):
    """Custom admin site with enhanced dashboard"""
    
    site_header = "Basketball Analytics Administration"
    site_title = "Basketball Analytics Admin"
    index_title = "Dashboard"
    
    def index(self, request, extra_context=None):
        """Custom dashboard with statistics"""
        extra_context = extra_context or {}
        
        # Get statistics
        stats = {
            'total_users': User.objects.count(),
            'total_teams': Team.objects.count(),
            'total_games': Game.objects.count(),
            'total_competitions': Competition.objects.count(),
            'recent_users': User.objects.order_by('-date_joined')[:5],
            'recent_teams': Team.objects.order_by('-created_at')[:5],
            'recent_games': Game.objects.order_by('-created_at')[:5],
        }
        
        # Add role-based statistics
        stats.update({
            'total_coaches': User.objects.filter(role=User.Role.COACH).count(),
            'total_players': User.objects.filter(role=User.Role.PLAYER).count(),
            'total_staff': User.objects.filter(role=User.Role.STAFF).count(),
            'total_admins': User.objects.filter(role=User.Role.ADMIN).count(),
        })
        
        extra_context.update(stats)
        return super().index(request, extra_context)


# Create custom admin site instance
admin_site = CustomAdminSite(name='basketball_admin')

# Register models with custom admin site
from apps.users.admin import CustomUserAdmin
from apps.teams.admin import TeamAdmin

admin_site.register(User, CustomUserAdmin)
admin_site.register(Team, TeamAdmin)
