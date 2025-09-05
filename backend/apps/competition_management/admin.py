from django.contrib import admin
from django.contrib.auth.decorators import user_passes_test
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.views import View
from django.urls import path, reverse
from django.utils.html import format_html
from django.db import transaction

from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.games.models import Game
from apps.users.models import User


def is_admin_or_superuser(user):
    """Check if user is admin or superuser"""
    return user.is_authenticated and (user.is_superuser or user.role == User.Role.ADMIN)


class CompetitionAdmin(admin.ModelAdmin):
    list_display = ['name', 'season', 'country', 'league_level', 'team_count', 'game_count']
    list_filter = ['country', 'league_level', 'season']
    search_fields = ['name', 'country', 'season']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'season')
        }),
        ('Rules & Settings', {
            'fields': ('quarter_length_minutes', 'overtime_length_minutes', 'shot_clock_seconds', 
                      'personal_foul_limit', 'team_fouls_for_bonus')
        }),
        ('Location & Level', {
            'fields': ('country', 'league_level')
        }),
    )
    
    def team_count(self, obj):
        return obj.teams.count()
    team_count.short_description = 'Teams'
    
    def game_count(self, obj):
        return Game.objects.filter(competition=obj).count()
    game_count.short_description = 'Games'
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('<int:competition_id>/manage-teams/', 
                 self.admin_site.admin_view(self.manage_teams_view), 
                 name='competition_manage_teams'),
            path('<int:competition_id>/schedule-game/', 
                 self.admin_site.admin_view(self.schedule_game_view), 
                 name='competition_schedule_game'),
            path('api/teams/<int:competition_id>/', 
                 self.admin_site.admin_view(self.get_teams_api), 
                 name='competition_teams_api'),
        ]
        return custom_urls + urls
    
    @user_passes_test(is_admin_or_superuser)
    def manage_teams_view(self, request, competition_id):
        """View for managing teams in a competition"""
        competition = get_object_or_404(Competition, id=competition_id)
        
        if request.method == 'POST':
            action = request.POST.get('action')
            team_id = request.POST.get('team_id')
            
            if action == 'add_team' and team_id:
                team = get_object_or_404(Team, id=team_id)
                if team.competition != competition:
                    team.competition = competition
                    team.save()
                    messages.success(request, f'Team {team.name} added to {competition.name}')
                else:
                    messages.warning(request, f'Team {team.name} is already in {competition.name}')
                    
            elif action == 'remove_team' and team_id:
                team = get_object_or_404(Team, id=team_id)
                team.competition = None
                team.save()
                messages.success(request, f'Team {team.name} removed from {competition.name}')
        
        # Get all teams and current competition teams
        all_teams = Team.objects.all()
        competition_teams = Team.objects.filter(competition=competition)
        available_teams = Team.objects.filter(competition__isnull=True)
        
        context = {
            'title': f'Manage Teams - {competition.name}',
            'competition': competition,
            'competition_teams': competition_teams,
            'available_teams': available_teams,
            'opts': self.model._meta,
            'has_change_permission': True,
        }
        
        return render(request, 'admin/competition_management/teams.html', context)
    
    @user_passes_test(is_admin_or_superuser)
    def schedule_game_view(self, request, competition_id):
        """View for scheduling games in a competition"""
        competition = get_object_or_404(Competition, id=competition_id)
        
        if request.method == 'POST':
            try:
                with transaction.atomic():
                    home_team_id = request.POST.get('home_team')
                    away_team_id = request.POST.get('away_team')
                    game_date = request.POST.get('game_date')
                    game_time = request.POST.get('game_time')
                    
                    if not all([home_team_id, away_team_id, game_date, game_time]):
                        messages.error(request, 'All fields are required')
                        return redirect('admin:competition_schedule_game', competition_id=competition_id)
                    
                    home_team = get_object_or_404(Team, id=home_team_id)
                    away_team = get_object_or_404(Team, id=away_team_id)
                    
                    if home_team == away_team:
                        messages.error(request, 'Home and away teams cannot be the same')
                        return redirect('admin:competition_schedule_game', competition_id=competition_id)
                    
                    # Create the game
                    from datetime import datetime
                    game_datetime = datetime.strptime(f'{game_date} {game_time}', '%Y-%m-%d %H:%M')
                    
                    game = Game.objects.create(
                        competition=competition,
                        home_team=home_team,
                        away_team=away_team,
                        game_date=game_datetime,
                        created_by=request.user
                    )
                    
                    messages.success(request, f'Game scheduled: {home_team.name} vs {away_team.name} on {game_datetime.strftime("%Y-%m-%d %H:%M")}')
                    return redirect('admin:competitions_competition_change', competition_id)
                    
            except Exception as e:
                messages.error(request, f'Error scheduling game: {str(e)}')
        
        # Get teams in this competition
        competition_teams = Team.objects.filter(competition=competition)
        
        context = {
            'title': f'Schedule Game - {competition.name}',
            'competition': competition,
            'teams': competition_teams,
            'opts': self.model._meta,
            'has_change_permission': True,
        }
        
        return render(request, 'admin/competition_management/schedule_game.html', context)
    
    @user_passes_test(is_admin_or_superuser)
    def get_teams_api(self, request, competition_id):
        """API endpoint to get teams for a competition"""
        competition = get_object_or_404(Competition, id=competition_id)
        teams = competition.teams.all()
        
        teams_data = [{'id': team.id, 'name': team.name} for team in teams]
        return JsonResponse({'teams': teams_data})


# Add custom admin actions
@admin.action(description='Assign selected teams to competition')
def assign_teams_to_competition(modeladmin, request, queryset):
    """Admin action to assign teams to a competition"""
    if request.POST.get('post'):
        competition_id = request.POST.get('competition_id')
        if competition_id:
            competition = get_object_or_404(Competition, id=competition_id)
            for team in queryset:
                competition.teams.add(team)
            modeladmin.message_user(request, f'Successfully assigned {queryset.count()} teams to {competition.name}')
        else:
            modeladmin.message_user(request, 'Please select a competition', level='ERROR')


class TeamAdmin(admin.ModelAdmin):
    list_display = ['name', 'competition_count', 'player_count', 'coach_count']
    list_filter = ['competition']
    search_fields = ['name']
    actions = [assign_teams_to_competition]
    
    def competition_count(self, obj):
        return obj.competition.name if obj.competition else 'None'
    competition_count.short_description = 'Competition'
    
    def player_count(self, obj):
        return obj.players.count()
    player_count.short_description = 'Players'
    
    def coach_count(self, obj):
        return obj.coaches.count()
    coach_count.short_description = 'Coaches'
