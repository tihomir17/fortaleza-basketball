from django.urls import path
from . import views

app_name = 'competition_management'

urlpatterns = [
    path('api/competitions/', views.get_competitions, name='get_competitions'),
    path('api/competitions/<int:competition_id>/teams/', views.get_teams_for_competition, name='get_teams_for_competition'),
    path('api/schedule-game/', views.schedule_game, name='schedule_game'),
]
