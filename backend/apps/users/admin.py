# apps/users/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import User


# We need to define a custom admin class to display our new fields
class CustomUserAdmin(UserAdmin):
    # Add our custom fields to the fieldsets
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'email')}),
        ('Basketball Info', {
            'fields': ('role', 'coach_type', 'staff_type', 'jersey_number', 'position'),
            'classes': ('collapse',)
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
            'classes': ('collapse',)
        }),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'password1', 'password2', 'role', 'coach_type', 'staff_type'),
        }),
    )
    
    list_display = (
        'username',
        'email',
        'full_name',
        'role_badge',
        'coach_type_display',
        'staff_type_display',
        'jersey_number',
        'is_active',
        'date_joined',
    )
    
    list_filter = (
        'role',
        'coach_type',
        'staff_type',
        'is_active',
        'is_staff',
        'is_superuser',
        'date_joined',
    )
    
    search_fields = ('username', 'first_name', 'last_name', 'email')
    ordering = ('-date_joined',)
    list_per_page = 25
    
    def full_name(self, obj):
        """Display full name"""
        if obj.first_name and obj.last_name:
            return f"{obj.first_name} {obj.last_name}"
        return "-"
    full_name.short_description = "Full Name"
    
    def role_badge(self, obj):
        """Display role with colored badge"""
        colors = {
            'ADMIN': 'red',
            'COACH': 'blue',
            'PLAYER': 'green',
            'STAFF': 'orange',
        }
        color = colors.get(obj.role, 'gray')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; border-radius: 3px; font-size: 11px;">{}</span>',
            color, obj.get_role_display()
        )
    role_badge.short_description = "Role"
    
    def coach_type_display(self, obj):
        """Display coach type if applicable"""
        if obj.role == User.Role.COACH and obj.coach_type != User.CoachType.NONE:
            return obj.get_coach_type_display()
        return "-"
    coach_type_display.short_description = "Coach Type"
    
    def staff_type_display(self, obj):
        """Display staff type if applicable"""
        if obj.role == User.Role.STAFF and obj.staff_type != User.StaffType.NONE:
            return obj.get_staff_type_display()
        return "-"
    staff_type_display.short_description = "Staff Type"


# Register your model with the custom admin class
admin.site.register(User, CustomUserAdmin)
