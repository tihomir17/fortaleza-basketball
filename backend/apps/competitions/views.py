# apps/competitions/views.py
from rest_framework import viewsets, permissions
from .models import Competition
from .serializers import CompetitionSerializer


class CompetitionViewSet(viewsets.ModelViewSet):
    queryset = Competition.objects.all().order_by("name")
    serializer_class = CompetitionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
