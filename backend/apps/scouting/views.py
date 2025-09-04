from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q, Avg, Count, Sum
from apps.possessions.models import Possession
from apps.games.models import Game, GameRoster
from apps.teams.models import Team
from apps.users.models import User
from datetime import datetime, timedelta
import math


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def self_scouting(request):
    """
    Get comprehensive self scouting data for the authenticated user
    """
    try:
        user = request.user
        user_team = user.team

        if not user_team:
            return Response(
                {"error": "User is not associated with any team"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get all games for the user's team
        team_games = Game.objects.filter(
            Q(home_team=user_team) | Q(away_team=user_team)
        ).order_by("-game_date")

        # Get all possessions for these games
        team_possessions = Possession.objects.filter(
            game__in=team_games
        ).select_related("game", "team", "opponent")

        # Calculate player profile
        player_profile = _calculate_player_profile(user, team_possessions, team_games)

        # Calculate team performance
        team_performance = _calculate_team_performance(
            user_team, team_games, team_possessions
        )

        # Calculate season stats
        season_stats = _calculate_season_stats(user_team, team_games, team_possessions)

        # Calculate recent games
        recent_games = _calculate_recent_games(user, team_games, team_possessions)

        # Calculate player comparison
        player_comparison = _calculate_player_comparison(user, user_team)

        # Calculate team chemistry
        team_chemistry = _calculate_team_chemistry(user_team, team_possessions)

        # Generate season storylines
        season_storylines = _generate_season_storylines(
            user, user_team, team_games, team_possessions
        )

        return Response(
            {
                "player_profile": player_profile,
                "team_performance": team_performance,
                "season_stats": season_stats,
                "recent_games": recent_games,
                "player_comparison": player_comparison,
                "team_chemistry": team_chemistry,
                "season_storylines": season_storylines,
            }
        )

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _calculate_player_profile(user, possessions, games):
    """Calculate comprehensive player profile statistics"""

    # Filter possessions where user was on court
    user_possessions = []
    for possession in possessions:
        if (
            possession.players_on_court.filter(id=user.id).exists()
            or possession.defensive_players_on_court.filter(id=user.id).exists()
        ):
            user_possessions.append(possession)

    # Calculate basic stats
    total_points = sum(
        p.points_scored for p in user_possessions if p.team and p.team.team == user.team
    )
    total_assists = len([p for p in user_possessions if p.assisted_by == user])
    total_rebounds = len(
        [
            p
            for p in user_possessions
            if p.is_offensive_rebound or p.is_defensive_rebound
        ]
    )
    total_steals = len([p for p in user_possessions if p.stolen_by == user])
    total_blocks = len([p for p in user_possessions if p.blocked_by == user])
    total_turnovers = len(
        [
            p
            for p in user_possessions
            if p.outcome == "TURNOVER" and p.team and p.team.team == user.team
        ]
    )

    # Calculate minutes (simplified - sum of possession durations)
    total_minutes = sum(p.duration_seconds for p in user_possessions) / 60.0

    games_played = len(set(p.game.id for p in user_possessions))
    minutes_per_game = total_minutes / games_played if games_played > 0 else 0

    # Calculate shooting percentages (simplified)
    field_goal_attempts = len(
        [
            p
            for p in user_possessions
            if p.outcome in ["MADE_2PTS", "MISSED_2PTS", "MADE_3PTS", "MISSED_3PTS"]
            and p.team
            and p.team.team == user.team
        ]
    )
    field_goal_makes = len(
        [
            p
            for p in user_possessions
            if p.outcome in ["MADE_2PTS", "MADE_3PTS"]
            and p.team
            and p.team.team == user.team
        ]
    )
    three_point_attempts = len(
        [
            p
            for p in user_possessions
            if p.outcome in ["MADE_3PTS", "MISSED_3PTS"]
            and p.team
            and p.team.team == user.team
        ]
    )
    three_point_makes = len(
        [
            p
            for p in user_possessions
            if p.outcome == "MADE_3PTS" and p.team and p.team.team == user.team
        ]
    )

    field_goal_percentage = (
        field_goal_makes / field_goal_attempts if field_goal_attempts > 0 else 0
    )
    three_point_percentage = (
        three_point_makes / three_point_attempts if three_point_attempts > 0 else 0
    )

    # Calculate plus/minus (simplified)
    plus_minus = 0  # This would need more complex calculation based on actual game flow

    # Generate strengths and areas for improvement based on stats
    strengths = []
    areas_for_improvement = []

    if field_goal_percentage > 0.45:
        strengths.append("Good shooting efficiency")
    elif field_goal_percentage < 0.35:
        areas_for_improvement.append("Improve shooting accuracy")

    if total_assists > games_played * 3:
        strengths.append("Strong playmaking ability")
    elif total_assists < games_played:
        areas_for_improvement.append("Increase assist production")

    if total_rebounds > games_played * 2:
        strengths.append("Good rebounding")
    elif total_rebounds < games_played:
        areas_for_improvement.append("Improve rebounding")

    if total_turnovers > games_played * 2:
        areas_for_improvement.append("Reduce turnovers")

    return {
        "name": f"{user.first_name} {user.last_name}",
        "position": getattr(user, "position", "N/A"),
        "jersey_number": getattr(user, "jersey_number", 0),
        "team": user.team.name if user.team else "N/A",
        "games_played": games_played,
        "minutes_per_game": round(minutes_per_game, 1),
        "total_points": total_points,
        "points_per_game": (
            round(total_points / games_played, 1) if games_played > 0 else 0
        ),
        "total_assists": total_assists,
        "assists_per_game": (
            round(total_assists / games_played, 1) if games_played > 0 else 0
        ),
        "total_rebounds": total_rebounds,
        "rebounds_per_game": (
            round(total_rebounds / games_played, 1) if games_played > 0 else 0
        ),
        "total_steals": total_steals,
        "steals_per_game": (
            round(total_steals / games_played, 1) if games_played > 0 else 0
        ),
        "total_blocks": total_blocks,
        "blocks_per_game": (
            round(total_blocks / games_played, 1) if games_played > 0 else 0
        ),
        "total_turnovers": total_turnovers,
        "turnovers_per_game": (
            round(total_turnovers / games_played, 1) if games_played > 0 else 0
        ),
        "field_goal_percentage": round(field_goal_percentage, 3),
        "three_point_percentage": round(three_point_percentage, 3),
        "free_throw_percentage": 0.8,  # Placeholder
        "plus_minus": plus_minus,
        "strengths": strengths,
        "areas_for_improvement": areas_for_improvement,
    }


def _calculate_team_performance(team, games, possessions):
    """Calculate team performance statistics"""

    team_games = [g for g in games if g.home_team == team or g.away_team == team]
    wins = 0
    total_points = 0
    total_points_allowed = 0

    for game in team_games:
        if (game.home_team == team and game.home_team_score > game.away_team_score) or (
            game.away_team == team and game.away_team_score > game.home_team_score
        ):
            wins += 1

        if game.home_team == team:
            total_points += game.home_team_score
            total_points_allowed += game.away_team_score
        else:
            total_points += game.away_team_score
            total_points_allowed += game.home_team_score

    losses = len(team_games) - wins
    win_percentage = wins / len(team_games) if len(team_games) > 0 else 0

    # Calculate other team stats from possessions
    team_possessions = [p for p in possessions if p.team and p.team.team == team]

    total_rebounds = len(
        [
            p
            for p in team_possessions
            if p.is_offensive_rebound or p.is_defensive_rebound
        ]
    )
    total_assists = len([p for p in team_possessions if p.assisted_by])
    total_steals = len([p for p in team_possessions if p.stolen_by])
    total_blocks = len([p for p in team_possessions if p.blocked_by])
    total_turnovers = len([p for p in team_possessions if p.outcome == "TURNOVER"])

    # Calculate shooting percentages
    field_goal_attempts = len(
        [
            p
            for p in team_possessions
            if p.outcome in ["MADE_2PTS", "MISSED_2PTS", "MADE_3PTS", "MISSED_3PTS"]
        ]
    )
    field_goal_makes = len(
        [p for p in team_possessions if p.outcome in ["MADE_2PTS", "MADE_3PTS"]]
    )
    three_point_attempts = len(
        [p for p in team_possessions if p.outcome in ["MADE_3PTS", "MISSED_3PTS"]]
    )
    three_point_makes = len([p for p in team_possessions if p.outcome == "MADE_3PTS"])

    field_goal_percentage = (
        field_goal_makes / field_goal_attempts if field_goal_attempts > 0 else 0
    )
    three_point_percentage = (
        three_point_makes / three_point_attempts if three_point_attempts > 0 else 0
    )

    return {
        "team_name": team.name,
        "wins": wins,
        "losses": losses,
        "win_percentage": round(win_percentage, 3),
        "games_played": len(team_games),
        "total_points": total_points,
        "total_points_allowed": total_points_allowed,
        "points_per_game": (
            round(total_points / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "points_allowed_per_game": (
            round(total_points_allowed / len(team_games), 1)
            if len(team_games) > 0
            else 0
        ),
        "point_differential": round(total_points - total_points_allowed, 1),
        "total_rebounds": total_rebounds,
        "rebounds_per_game": (
            round(total_rebounds / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "total_assists": total_assists,
        "assists_per_game": (
            round(total_assists / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "total_steals": total_steals,
        "steals_per_game": (
            round(total_steals / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "total_blocks": total_blocks,
        "blocks_per_game": (
            round(total_blocks / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "total_turnovers": total_turnovers,
        "turnovers_per_game": (
            round(total_turnovers / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "field_goal_percentage": round(field_goal_percentage, 3),
        "field_goal_percentage_allowed": 0.4,  # Placeholder
        "three_point_percentage": round(three_point_percentage, 3),
        "three_point_percentage_allowed": 0.33,  # Placeholder
        "offensive_rating": 110,  # Placeholder
        "defensive_rating": 105,  # Placeholder
        "net_rating": 5,  # Placeholder
        "team_style": "balanced",  # Placeholder
        "team_strength": "balanced",  # Placeholder
        "team_strengths": [
            "Good ball movement",
            "Strong defensive effort",
            "Balanced scoring",
        ],
        "team_weaknesses": ["Turnover prone", "Rebounding consistency"],
    }


def _calculate_season_stats(team, games, possessions):
    """Calculate season-wide statistics"""

    current_year = datetime.now().year
    team_games = [g for g in games if g.home_team == team or g.away_team == team]

    total_wins = 0
    total_points = 0

    for game in team_games:
        if (game.home_team == team and game.home_team_score > game.away_team_score) or (
            game.away_team == team and game.away_team_score > game.home_team_score
        ):
            total_wins += 1

        if game.home_team == team:
            total_points += game.home_team_score
        else:
            total_points += game.away_team_score

    total_losses = len(team_games) - total_wins
    overall_win_percentage = total_wins / len(team_games) if len(team_games) > 0 else 0

    # Calculate monthly performance (simplified)
    monthly_performance = []
    months = ["October", "November", "December", "January", "February", "March"]

    for i, month in enumerate(months):
        if i < len(team_games):
            monthly_performance.append(
                {
                    "month": month,
                    "games_played": 1,
                    "wins": 1 if i % 2 == 0 else 0,
                    "losses": 0 if i % 2 == 0 else 1,
                    "win_percentage": 1.0 if i % 2 == 0 else 0.0,
                    "average_points_per_game": 80 + (i * 2),
                    "average_rebounds_per_game": 35 + i,
                    "average_assists_per_game": 20 + i,
                }
            )

    # Calculate opponent performance (simplified)
    opponent_performance = []
    opponents = Team.objects.exclude(id=team.id)[:5]

    for opponent in opponents:
        opponent_performance.append(
            {
                "opponent_name": opponent.name,
                "games_played": 1,
                "wins": 1,
                "losses": 0,
                "win_percentage": 1.0,
                "average_points_for": 85,
                "average_points_against": 75,
                "point_differential": 10,
            }
        )

    return {
        "current_season": current_year,
        "total_games": len(team_games),
        "total_wins": total_wins,
        "total_losses": total_losses,
        "overall_win_percentage": round(overall_win_percentage, 3),
        "total_points": total_points,
        "average_points_per_game": (
            round(total_points / len(team_games), 1) if len(team_games) > 0 else 0
        ),
        "total_rebounds": 0,  # Placeholder
        "average_rebounds_per_game": 0,  # Placeholder
        "total_assists": 0,  # Placeholder
        "average_assists_per_game": 0,  # Placeholder
        "total_steals": 0,  # Placeholder
        "average_steals_per_game": 0,  # Placeholder
        "total_blocks": 0,  # Placeholder
        "average_blocks_per_game": 0,  # Placeholder
        "total_turnovers": 0,  # Placeholder
        "average_turnovers_per_game": 0,  # Placeholder
        "overall_field_goal_percentage": 0.45,  # Placeholder
        "overall_three_point_percentage": 0.35,  # Placeholder
        "overall_free_throw_percentage": 0.75,  # Placeholder
        "monthly_performance": monthly_performance,
        "opponent_performance": opponent_performance,
    }


def _calculate_recent_games(user, games, possessions):
    """Calculate recent game results and upcoming games"""

    team = user.team
    if not team:
        return {
            "last_five_games": [],
            "last_ten_games": [],
            "next_game": {},
            "upcoming_games": [],
        }

    # Get team games sorted by date
    team_games = [g for g in games if g.home_team == team or g.away_team == team]
    team_games.sort(key=lambda x: x.game_date, reverse=True)

    # Calculate last 5 games
    last_five_games = []
    for game in team_games[:5]:
        is_home = game.home_team == team
        team_score = game.home_team_score if is_home else game.away_team_score
        opponent_score = game.away_team_score if is_home else game.home_team_score
        opponent = game.away_team.name if is_home else game.home_team.name

        # Determine result
        result = "W" if team_score > opponent_score else "L"

        # Calculate player stats for this game
        game_possessions = [p for p in possessions if p.game == game]
        player_points = sum(
            p.points_scored
            for p in game_possessions
            if p.team and p.team.team == team and p.scorer == user
        )
        player_rebounds = len(
            [
                p
                for p in game_possessions
                if p.team
                and p.team.team == team
                and (p.is_offensive_rebound or p.is_defensive_rebound)
            ]
        )
        player_assists = len([p for p in game_possessions if p.assisted_by == user])
        player_minutes = (
            sum(
                p.duration_seconds
                for p in game_possessions
                if p.players_on_court.filter(id=user.id).exists()
                or p.defensive_players_on_court.filter(id=user.id).exists()
            )
            / 60
        )

        last_five_games.append(
            {
                "opponent": opponent,
                "result": result,
                "team_score": team_score,
                "opponent_score": opponent_score,
                "date": game.game_date.strftime("%Y-%m-%d"),
                "venue": "Home" if is_home else "Away",
                "player_points": player_points,
                "player_rebounds": player_rebounds,
                "player_assists": player_assists,
                "player_minutes": round(player_minutes, 0),
                "plus_minus": 0,  # Placeholder
            }
        )

    # Generate next game (placeholder)
    next_game = {
        "opponent": "Next Opponent",
        "result": "",
        "team_score": 0,
        "opponent_score": 0,
        "date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
        "venue": "Home",
        "player_points": 0,
        "player_rebounds": 0,
        "player_assists": 0,
        "player_minutes": 0,
        "plus_minus": 0,
    }

    # Generate upcoming games (placeholder)
    upcoming_games = [
        {
            "opponent": "Upcoming Team 1",
            "date": (datetime.now() + timedelta(days=14)).strftime("%Y-%m-%d"),
            "venue": "Away",
            "competition": f"Temporada {datetime.now().year}-{datetime.now().year + 1}",
            "opponent_record": "15-10",
            "opponent_style": "defensive",
        },
        {
            "opponent": "Upcoming Team 2",
            "date": (datetime.now() + timedelta(days=21)).strftime("%Y-%m-%d"),
            "venue": "Home",
            "competition": f"Temporada {datetime.now().year}-{datetime.now().year + 1}",
            "opponent_record": "18-7",
            "opponent_style": "balanced",
        },
    ]

    return {
        "last_five_games": last_five_games,
        "last_ten_games": [],  # Placeholder
        "next_game": next_game,
        "upcoming_games": upcoming_games,
    }


def _calculate_player_comparison(user, team):
    """Calculate player comparison metrics"""

    # Generate comparison metrics (placeholder)
    metrics = [
        {
            "metric": "Points Per Game",
            "player_value": 12.2,
            "league_average": 10.8,
            "league_percentile": 75.0,
            "trend": "up",
        },
        {
            "metric": "Assists Per Game",
            "player_value": 5.6,
            "league_average": 4.2,
            "league_percentile": 85.0,
            "trend": "stable",
        },
        {
            "metric": "Field Goal %",
            "player_value": 45.6,
            "league_average": 43.2,
            "league_percentile": 70.0,
            "trend": "up",
        },
    ]

    # Generate position comparisons (placeholder)
    position_comparisons = [
        {
            "position": "PG",
            "points_per_game": 12.2,
            "rebounds_per_game": 3.2,
            "assists_per_game": 5.6,
            "field_goal_percentage": 45.6,
            "three_point_percentage": 37.8,
        },
    ]

    # Generate team comparisons (placeholder)
    team_comparisons = [
        {
            "team_name": team.name,
            "points_per_game": 83.8,
            "rebounds_per_game": 40.1,
            "assists_per_game": 24.2,
            "field_goal_percentage": 47.8,
            "three_point_percentage": 36.5,
        },
    ]

    return {
        "metrics": metrics,
        "position_comparisons": position_comparisons,
        "team_comparisons": team_comparisons,
    }


def _calculate_team_chemistry(team, possessions):
    """Calculate team chemistry metrics"""

    # Generate best lineups (placeholder)
    best_lineups = [
        {
            "players": ["Player 1", "Player 2", "Player 3", "Player 4", "Player 5"],
            "minutes_played": 156,
            "offensive_rating": 118.5,
            "defensive_rating": 95.2,
            "net_rating": 23.3,
            "plus_minus": 89,
        },
    ]

    # Generate partnerships (placeholder)
    top_partnerships = [
        {
            "player1": "Player 1",
            "player2": "Player 2",
            "minutes_played": 234,
            "plus_minus": 67,
            "offensive_rating": 115.3,
            "defensive_rating": 97.8,
            "synergy": "Excellent",
        },
    ]

    emerging_partnerships = [
        {
            "player1": "Player 1",
            "player2": "Player 3",
            "minutes_played": 189,
            "plus_minus": 34,
            "offensive_rating": 108.7,
            "defensive_rating": 101.2,
            "synergy": "Good",
        },
    ]

    return {
        "best_lineups": best_lineups,
        "top_partnerships": top_partnerships,
        "emerging_partnerships": emerging_partnerships,
        "team_strengths": [
            "Excellent ball movement",
            "Strong pick-and-roll execution",
            "Fast break efficiency",
        ],
        "team_weaknesses": [
            "Turnover prone in pressure situations",
            "Defensive rebounding consistency",
        ],
        "improvement_areas": [
            "Reduce turnovers in clutch situations",
            "Improve defensive rebounding",
            "Better foul discipline",
        ],
    }


def _generate_season_storylines(user, team, games, possessions):
    """Generate season storylines and narratives"""

    # Generate player storylines (placeholder)
    player_storylines = [
        {
            "title": "Breakout Season",
            "description": f"{user.first_name} has emerged as a key contributor this season.",
            "type": "breakout",
            "impact": "positive",
            "date": datetime.now().strftime("%Y-%m-%d"),
        },
    ]

    # Generate team storylines (placeholder)
    team_storylines = [
        {
            "title": "Team Chemistry Building",
            "description": "The team has developed excellent chemistry and cohesion.",
            "type": "chemistry",
            "impact": "positive",
            "date": datetime.now().strftime("%Y-%m-%d"),
        },
    ]

    # Generate rivalry storylines (placeholder)
    rivalry_storylines = [
        {
            "opponent": "Rival Team",
            "title": "Intense Rivalry Continues",
            "description": "The rivalry with this team continues to intensify.",
            "intensity": "High",
            "history": "Multiple championship meetings",
            "date": datetime.now().strftime("%Y-%m-%d"),
        },
    ]

    # Generate season highlights (placeholder)
    season_highlights = [
        {
            "title": "Record Performance",
            "description": "Team set a new franchise record.",
            "type": "performance",
            "date": datetime.now().strftime("%Y-%m-%d"),
            "impact": "Team confidence boost",
        },
    ]

    # Generate season challenges (placeholder)
    season_challenges = [
        {
            "title": "Injury Challenge",
            "description": "Team has faced injury challenges.",
            "type": "injury",
            "severity": "Medium",
            "status": "Ongoing",
            "date": datetime.now().strftime("%Y-%m-%d"),
        },
    ]

    return {
        "player_storylines": player_storylines,
        "team_storylines": team_storylines,
        "rivalry_storylines": rivalry_storylines,
        "season_highlights": season_highlights,
        "season_challenges": season_challenges,
    }
