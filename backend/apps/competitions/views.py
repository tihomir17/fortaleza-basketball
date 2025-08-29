# apps/competitions/views.py
from rest_framework import viewsets, permissions
from django_filters.rest_framework import DjangoFilterBackend
from .models import Competition
from .serializers import CompetitionSerializer
from .filters import CompetitionFilter
from apps.users.permissions import IsTeamScopedObject


class CompetitionViewSet(viewsets.ModelViewSet):
    queryset = Competition.objects.all().order_by("name").select_related("created_by")
    serializer_class = CompetitionSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = CompetitionFilter

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
