# apps/users/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

# We need to define a custom admin class to display our new fields
class CustomUserAdmin(UserAdmin):
    # Add our custom fields to the fieldsets
    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('role', 'coach_type')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        (None, {'fields': ('role', 'coach_type')}),
    )
    list_display = ('username', 'email', 'first_name', 'last_name', 'role', 'coach_type', 'is_staff')


# Register your model with the custom admin class
admin.site.register(User, CustomUserAdmin)