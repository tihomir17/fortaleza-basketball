# backend/apps/games/views.py

from rest_framework import viewsets, permissions
from rest_framework.response import Response  # Import Response
from .models import Game
from .serializers import GameSerializer
import json  # Import json for pretty-printing


class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all().order_by("-game_date")  # Order by most recent
    serializer_class = GameSerializer
    permission_classes = [permissions.IsAuthenticated]

    # ADD THIS CUSTOM LIST METHOD FOR DEBUGGING
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)

        # --- START OF DEBUGGING LOGS ---
        print("\n--- INSIDE GameViewSet list METHOD ---")
        print(f"Found {len(serializer.data)} games to serialize.")

        # Pretty-print the final JSON data that is about to be sent
        print("--- FINAL JSON RESPONSE DATA ---")
        print(json.dumps(serializer.data, indent=2))
        print("--- END OF LOGS ---\n")
        # --- END OF DEBUGGING LOGS ---

        return Response(serializer.data)
