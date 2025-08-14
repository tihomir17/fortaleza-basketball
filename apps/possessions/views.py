# apps/possessions/views.py
from rest_framework import viewsets, permissions
from .models import Possession
from .serializers import PossessionSerializer

class PossessionViewSet(viewsets.ModelViewSet):
    queryset = Possession.objects.all()
    serializer_class = PossessionSerializer
    permission_classes = [permissions.IsAuthenticated]