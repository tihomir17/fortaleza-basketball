# apps/plays/views.py
from rest_framework import viewsets, permissions
from .models import PlayDefinition
from .serializers import PlayDefinitionSerializer

class PlayDefinitionViewSet(viewsets.ModelViewSet):
    queryset = PlayDefinition.objects.all()
    serializer_class = PlayDefinitionSerializer
    permission_classes = [permissions.IsAuthenticated]