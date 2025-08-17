# apps/games/views.py
from rest_framework import viewsets, permissions
from .models import Game
from .serializers import GameSerializer


class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    permission_classes = [permissions.IsAuthenticated]

    # Optional: Add filtering to only show games from a user's competitions/teams
