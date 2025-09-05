from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404

from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.games.models import Game
from apps.users.models import User


@require_http_methods(["GET"])
@login_required
def get_teams_for_competition(request, competition_id):
    """API endpoint to get teams for a specific competition"""
    try:
        competition = get_object_or_404(Competition, id=competition_id)
        teams = Team.objects.filter(competition=competition)

        teams_data = [
            {
                "id": team.id,
                "name": team.name,
                "style": team.get_style_display(),
                "strength": team.get_strength_display(),
            }
            for team in teams
        ]

        return JsonResponse(
            {
                "success": True,
                "teams": teams_data,
                "competition": {
                    "id": competition.id,
                    "name": competition.name,
                },
            }
        )

    except Exception as e:
        return JsonResponse({"success": False, "error": str(e)}, status=400)


@require_http_methods(["GET"])
@login_required
def get_competitions(request):
    """API endpoint to get all competitions"""
    try:
        competitions = Competition.objects.all().order_by("-start_date")

        competitions_data = [
            {
                "id": comp.id,
                "name": comp.name,
                "start_date": comp.start_date.isoformat() if comp.start_date else None,
                "end_date": comp.end_date.isoformat() if comp.end_date else None,
                "country": comp.country,
                "league_level": comp.league_level,
                "team_count": Team.objects.filter(competition=comp).count(),
            }
            for comp in competitions
        ]

        return JsonResponse({"success": True, "competitions": competitions_data})

    except Exception as e:
        return JsonResponse({"success": False, "error": str(e)}, status=400)


@require_http_methods(["POST"])
@login_required
def schedule_game(request):
    """API endpoint to schedule a new game"""
    try:
        # Check if user is coach or admin
        if not (
            request.user.role == User.Role.COACH
            or request.user.is_superuser
            or request.user.role == User.Role.ADMIN
        ):
            return JsonResponse(
                {
                    "success": False,
                    "error": "Only coaches and admins can schedule games",
                },
                status=403,
            )

        competition_id = request.POST.get("competition_id")
        home_team_id = request.POST.get("home_team_id")
        away_team_id = request.POST.get("away_team_id")
        game_date = request.POST.get("game_date")
        game_time = request.POST.get("game_time")

        if not all([competition_id, home_team_id, away_team_id, game_date, game_time]):
            return JsonResponse(
                {"success": False, "error": "All fields are required"}, status=400
            )

        competition = get_object_or_404(Competition, id=competition_id)
        home_team = get_object_or_404(Team, id=home_team_id)
        away_team = get_object_or_404(Team, id=away_team_id)

        if home_team == away_team:
            return JsonResponse(
                {"success": False, "error": "Home and away teams cannot be the same"},
                status=400,
            )

        # Check if teams are in the competition
        if home_team.competition != competition:
            return JsonResponse(
                {
                    "success": False,
                    "error": f"{home_team.name} is not in {competition.name}",
                },
                status=400,
            )

        if away_team.competition != competition:
            return JsonResponse(
                {
                    "success": False,
                    "error": f"{away_team.name} is not in {competition.name}",
                },
                status=400,
            )

        # Create the game
        from datetime import datetime

        game_datetime = datetime.strptime(f"{game_date} {game_time}", "%Y-%m-%d %H:%M")

        game = Game.objects.create(
            competition=competition,
            home_team=home_team,
            away_team=away_team,
            game_date=game_datetime,
            created_by=request.user,
        )

        return JsonResponse(
            {
                "success": True,
                "game": {
                    "id": game.id,
                    "home_team": home_team.name,
                    "away_team": away_team.name,
                    "game_date": game_datetime.isoformat(),
                    "competition": competition.name,
                },
            }
        )

    except Exception as e:
        return JsonResponse({"success": False, "error": str(e)}, status=400)
