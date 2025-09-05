# apps/teams/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Team


@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'competition_link',
        'created_by_link',
        'coaches_count',
        'players_count',
        'created_at',
    )
    
    list_filter = (
        'competition',
        'created_at',
    )
    
    search_fields = ('name', 'created_by__username', 'created_by__first_name', 'created_by__last_name')
    ordering = ('-created_at',)
    list_per_page = 25
    
    fieldsets = (
        (None, {
            'fields': ('name', 'competition', 'created_by')
        }),
        ('Team Members', {
            'fields': ('coaches', 'players'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ('created_at', 'updated_at')
    filter_horizontal = ('coaches', 'players')
    
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
    
    def coaches_count(self, obj):
        """Display number of coaches"""
        count = obj.coaches.count()
        if count > 0:
            url = reverse('admin:users_user_changelist') + f'?teams__id__exact={obj.pk}&role=COACH'
            return format_html('<a href="{}">{} coaches</a>', url, count)
        return "0 coaches"
    coaches_count.short_description = "Coaches"
    
    def players_count(self, obj):
        """Display number of players"""
        count = obj.players.count()
        if count > 0:
            url = reverse('admin:users_user_changelist') + f'?teams__id__exact={obj.pk}&role=PLAYER'
            return format_html('<a href="{}">{} players</a>', url, count)
        return "0 players"
    players_count.short_description = "Players"
