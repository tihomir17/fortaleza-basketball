# apps/plays/views.py

from .models import PlayDefinition, PlayStep
from .serializers import PlayDefinitionSerializer, PlayCategory, PlayCategorySerializer
from apps.teams.models import Team
from apps.users.models import User
from django.db.models import Q  # pyright: ignore[reportMissingImports]
from rest_framework import (  # pyright: ignore[reportMissingImports]
    viewsets,
    permissions,
    status,
)  # pyright: ignore[reportMissingImports]
from rest_framework.decorators import action  # pyright: ignore[reportMissingImports]
from rest_framework.response import (  # pyright: ignore[reportMissingImports]
    Response,
)  # Make sure this is imported  # pyright: ignore[reportMissingImports]
from django_filters.rest_framework import (  # pyright: ignore[reportMissingImports]
    DjangoFilterBackend,
)  # pyright: ignore[reportMissingImports]
from .filters import PlayCategoryFilter, PlayDefinitionFilter
from apps.users.permissions import IsTeamScopedObject  # New import


class PlayCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    A simple ViewSet for listing all PlayCategories, ordered by their ID.
    """

    queryset = PlayCategory.objects.all().order_by("id")
    serializer_class = PlayCategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_class = PlayCategoryFilter


class PlayDefinitionViewSet(viewsets.ModelViewSet):
    queryset = PlayDefinition.objects.all()
    serializer_class = PlayDefinitionSerializer
    permission_classes = [permissions.IsAuthenticated]

    # THIS IS THE CORRECTED METHOD
    def get_queryset(self):
        user = self.request.user

        if not user.is_authenticated:
            return PlayDefinition.objects.none()

        # Superusers can see/edit everything
        if user.is_superuser:
            return self.queryset

        # --- NEW PERMISSION LOGIC ---
        # 1. Get all teams the user is a member of.
        user_teams = Team.objects.filter(Q(coaches=user) | Q(players=user))

        # 2. Get the "Default Play Templates" team.
        try:
            default_team = Team.objects.get(name="Default Play Templates")
        except Team.DoesNotExist:
            default_team = None

        # 3. Build the final query.
        # A user can see plays that belong to their teams.
        allowed_plays_query = Q(team__in=user_teams)

        # If the user is a COACH, they can ALSO see the default templates.
        if user.role == User.Role.COACH and default_team:
            allowed_plays_query |= Q(team=default_team)

        return self.queryset.filter(allowed_plays_query).distinct()

    @action(detail=False, methods=["get"])
    def templates(self, request):
        """
        Returns the master list of all generic play definitions used for the
        live tracking screen buttons.
        """
        try:
            # Find the template team by its specific name
            template_team = Team.objects.get(name="Default Play Templates")
            # Filter plays belonging only to that team
            template_plays = PlayDefinition.objects.filter(team=template_team)
            serializer = self.get_serializer(template_plays, many=True)
            return Response(serializer.data)
        except Team.DoesNotExist:
            return Response(
                {
                    "error": "The 'Default Play Templates' team was not found in the database."
                },
                status=status.HTTP_404_NOT_FOUND,
            )

    @action(detail=True, methods=["patch"])
    def favorite(self, request, pk=None):
        """
        Toggle the favorite status of a play.
        """
        try:
            play = self.get_object()
            play.is_favorite = not play.is_favorite
            play.save()
            serializer = self.get_serializer(play)
            return Response(serializer.data)
        except PlayDefinition.DoesNotExist:
            return Response(
                {"error": "Play not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

    @action(detail=True, methods=["post"])
    def duplicate(self, request, pk=None):
        """
        Duplicate a play with a new name.
        """
        try:
            original_play = self.get_object()
            new_name = request.data.get('name', f"{original_play.name} (Copy)")
            
            # Create a new play based on the original
            new_play = PlayDefinition.objects.create(
                name=new_name,
                description=original_play.description,
                play_type=original_play.play_type,
                team=original_play.team,
                parent=original_play.parent,
                category=original_play.category,
                subcategory=original_play.subcategory,
                action_type=original_play.action_type,
                diagram_url=original_play.diagram_url,
                video_url=original_play.video_url,
                tags=original_play.tags,
                difficulty=original_play.difficulty,
                duration=original_play.duration,
                players=original_play.players,
                success_rate=original_play.success_rate,
                last_used=original_play.last_used,
                is_favorite=False,  # New copy is not favorite by default
                created_by=request.user,
            )
            
            # Copy the steps
            for step in original_play.steps.all():
                PlayStep.objects.create(
                    play=new_play,
                    order=step.order,
                    title=step.title,
                    description=step.description,
                    diagram=step.diagram,
                    duration=step.duration,
                )
            
            serializer = self.get_serializer(new_play)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except PlayDefinition.DoesNotExist:
            return Response(
                {"error": "Play not found"},
                status=status.HTTP_404_NOT_FOUND,
            )
