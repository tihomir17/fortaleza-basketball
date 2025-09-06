# backend/apps/games/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Game


@admin.register(Game)
class GameAdmin(admin.ModelAdmin):
    list_display = (
        'game_date',
        'home_team_link',
        'away_team_link',
        'competition_link',
        'status_badge',
        'created_by_link',
    )
    
    list_filter = (
        'competition',
        'game_date',
        'created_at',
    )
    
    search_fields = (
        'home_team__name',
        'away_team__name',
        'competition__name',
        'created_by__username',
    )
    
    ordering = ('-game_date',)
    list_per_page = 25
    
    fieldsets = (
        ('Game Details', {
            'fields': ('game_date', 'home_team', 'away_team', 'competition')
        }),
        ('Game Status', {
            'fields': ('is_blowout', 'clutch_situations'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ('created_at', 'updated_at')
    
    def home_team_link(self, obj):
        """Display home team as a link"""
        if obj.home_team:
            url = reverse('admin:teams_team_change', args=[obj.home_team.pk])
            return format_html('<a href="{}">{}</a>', url, obj.home_team.name)
        return "-"
    home_team_link.short_description = "Home Team"
    
    def away_team_link(self, obj):
        """Display away team as a link"""
        if obj.away_team:
            url = reverse('admin:teams_team_change', args=[obj.away_team.pk])
            return format_html('<a href="{}">{}</a>', url, obj.away_team.name)
        return "-"
    away_team_link.short_description = "Away Team"
    
    def competition_link(self, obj):
        """Display competition as a link"""
        if obj.competition:
            url = reverse('admin:competitions_competition_change', args=[obj.competition.pk])
            return format_html('<a href="{}">{}</a>', url, obj.competition.name)
        return "-"
    competition_link.short_description = "Competition"
    
    def created_by_link(self, obj):
        """Display creator as a link"""
        if obj.created_by:
            url = reverse('admin:users_user_change', args=[obj.created_by.pk])
            return format_html('<a href="{}">{}</a>', url, obj.created_by.username)
        return "-"
    created_by_link.short_description = "Created By"
    
    def status_badge(self, obj):
        """Display game status with colored badge"""
        if obj.is_blowout:
            return format_html(
                '<span class="badge badge-warning">Blowout</span>'
            )
        elif obj.clutch_situations:
            return format_html(
                '<span class="badge badge-danger">Clutch</span>'
            )
        else:
            return format_html(
                '<span class="badge badge-success">Normal</span>'
            )
    status_badge.short_description = "Status"
