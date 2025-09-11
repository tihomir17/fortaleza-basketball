# apps/plays/admin.py

from django.contrib import admin
from .models import PlayDefinition, PlayCategory, PlayStep


class PlayStepInline(admin.TabularInline):
    model = PlayStep
    extra = 0
    ordering = ['order']


@admin.register(PlayDefinition)
class PlayDefinitionAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'play_type', 'category', 'difficulty', 
        'duration', 'players', 'success_rate', 'is_favorite', 
        'created_by', 'last_used'
    ]
    list_filter = [
        'play_type', 'category', 'difficulty', 'is_favorite', 
        'created_by', 'last_used'
    ]
    search_fields = ['name', 'description', 'tags']
    list_editable = ['is_favorite', 'success_rate']
    inlines = [PlayStepInline]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'play_type', 'team', 'parent')
        }),
        ('Categorization', {
            'fields': ('category', 'subcategory', 'tags', 'difficulty')
        }),
        ('Play Details', {
            'fields': ('duration', 'players', 'action_type')
        }),
        ('Media', {
            'fields': ('diagram_url', 'video_url'),
            'classes': ('collapse',)
        }),
        ('Statistics', {
            'fields': ('success_rate', 'last_used', 'is_favorite'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_by',),
            'classes': ('collapse',)
        }),
    )


@admin.register(PlayCategory)
class PlayCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'description']
    search_fields = ['name', 'description']


@admin.register(PlayStep)
class PlayStepAdmin(admin.ModelAdmin):
    list_display = ['play', 'order', 'title', 'duration']
    list_filter = ['play__play_type', 'play__category']
    search_fields = ['title', 'description', 'play__name']
    ordering = ['play', 'order']
