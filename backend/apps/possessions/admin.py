# apps/possessions/admin.py

from django.contrib import admin
from django.utils.html import format_html
from .models import Possession


@admin.register(Possession)
class PossessionAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'game_display', 'team_display', 'opponent_display', 
        'quarter', 'start_time_in_game', 'outcome', 'points_scored',
        'offensive_set', 'defensive_set', 'created_at'
    ]
    list_filter = [
        'outcome', 'quarter', 'offensive_set', 'defensive_set', 
        'created_at', 'game__home_team', 'game__away_team'
    ]
    search_fields = [
        'game__home_team__name', 'game__away_team__name', 
        'outcome', 'offensive_set', 'defensive_set'
    ]
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
    list_per_page = 50
    
    def game_display(self, obj):
        return f"{obj.game.home_team.name} vs {obj.game.away_team.name}"
    game_display.short_description = 'Game'
    
    def team_display(self, obj):
        return obj.team.team.name
    team_display.short_description = 'Team'
    
    def opponent_display(self, obj):
        return obj.opponent.team.name
    opponent_display.short_description = 'Opponent'
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('game', 'team', 'opponent', 'quarter', 'start_time_in_game', 'duration_seconds')
        }),
        ('Outcome', {
            'fields': ('outcome', 'points_scored')
        }),
        ('Plays', {
            'fields': ('offensive_set', 'defensive_set', 'pnr_type', 'pnr_result', 'defensive_pnr')
        }),
        ('Analysis', {
            'fields': ('has_paint_touch', 'has_kick_out', 'has_extra_pass', 'number_of_passes', 'shoot_quality', 'time_range')
        }),
        ('Players', {
            'fields': ('scorer', 'assisted_by', 'blocked_by', 'stolen_by', 'fouled_by', 'technical_foul_player')
        }),
        ('Rebounds', {
            'fields': ('is_offensive_rebound', 'offensive_rebound_players', 'offensive_rebound_count', 'box_out_count', 'offensive_rebounds_allowed')
        }),
        ('Special', {
            'fields': ('after_timeout', 'is_buzzer_beater', 'is_technical_foul', 'is_coach_challenge')
        }),
        ('Sequences', {
            'fields': ('offensive_sequence', 'defensive_sequence', 'notes')
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
