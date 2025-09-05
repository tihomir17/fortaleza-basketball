from django.contrib import admin
from apps.competitions.models import Competition
from apps.teams.models import Team
from .admin import CompetitionAdmin, TeamAdmin

# Unregister existing admin classes if they exist
if admin.site.is_registered(Competition):
    admin.site.unregister(Competition)

if admin.site.is_registered(Team):
    admin.site.unregister(Team)

# Register our custom admin classes
admin.site.register(Competition, CompetitionAdmin)
admin.site.register(Team, TeamAdmin)
