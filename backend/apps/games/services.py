import json
from typing import Dict, List, Any, Optional
from django.db.models import Q, Count, Avg, Sum, F, Case, When, Value, IntegerField
from django.db.models.functions import Coalesce
from apps.games.models import Game
from apps.possessions.models import Possession
from apps.teams.models import Team
from apps.users.models import User


class GameAnalyticsService:
    """Service for calculating comprehensive game analytics and statistics."""

    @staticmethod
    def get_comprehensive_analytics(
        team_id: Optional[int] = None,
        game_ids: Optional[List[int]] = None,
        quarter_filter: Optional[int] = None,
        last_games: Optional[int] = None,
        outcome_filter: Optional[str] = None,
        home_away_filter: Optional[str] = None,
        min_possessions: int = 10,
    ) -> Dict[str, Any]:
        """
        Get comprehensive analytics with extensive filtering options.

        Args:
            team_id: Filter by specific team
            game_ids: Filter by specific games
            quarter_filter: Filter by quarter (1-4, 5 for OT)
            last_games: Filter by last X games (1 to total games)
            outcome_filter: Filter by outcome ('W', 'L')
            home_away_filter: Filter by home/away ('Home', 'Away')
            min_possessions: Minimum possessions for player analysis
        """

        # Optimize: Build game filters first to reduce possession queries
        game_filters = Q()

        # Filter by last X games
        if last_games and last_games > 0:
            if team_id:
                # Get games where the team was involved (home or away)
                team_games = Game.objects.filter(
                    Q(home_team_id=team_id) | Q(away_team_id=team_id)
                ).order_by("-game_date")[:last_games]
            else:
                # Get the most recent games overall
                team_games = Game.objects.all().order_by("-game_date")[:last_games]

            game_ids = list(team_games.values_list("id", flat=True))
            game_filters &= Q(id__in=game_ids)

        # Filter by outcome (Wins/Losses)
        if outcome_filter:
            if team_id:
                # Filter for specific team's wins/losses
                if outcome_filter == "W":
                    # Get games where team won
                    game_filters &= Q(
                        home_team_id=team_id, home_team_score__gt=F("away_team_score")
                    ) | Q(
                        away_team_id=team_id, away_team_score__gt=F("home_team_score")
                    )
                elif outcome_filter == "L":
                    # Get games where team lost
                    game_filters &= Q(
                        home_team_id=team_id, home_team_score__lt=F("away_team_score")
                    ) | Q(
                        away_team_id=team_id, away_team_score__lt=F("home_team_score")
                    )
            else:
                # Filter for all games with wins/losses (from home team perspective)
                if outcome_filter == "W":
                    # Home team wins
                    game_filters &= Q(home_team_score__gt=F("away_team_score"))
                elif outcome_filter == "L":
                    # Home team losses
                    game_filters &= Q(home_team_score__lt=F("away_team_score"))

        # Apply game filters to get filtered game IDs
        filtered_game_ids = None
        if game_filters:
            filtered_game_ids = list(
                Game.objects.filter(game_filters).values_list("id", flat=True)
            )
            if not filtered_game_ids:
                return {
                    "summary": {"total_possessions": 0},
                    "offensive_analysis": {},
                    "defensive_analysis": {},
                    "player_analysis": {},
                    "detailed_breakdown": {},
                    "filters_applied": {
                        "team_id": team_id,
                        "quarter_filter": quarter_filter,
                        "last_games": last_games,
                        "outcome_filter": outcome_filter,
                        "home_away_filter": home_away_filter,
                        "total_possessions_analyzed": 0,
                    },
                }

        # Base queryset with optimized prefetching
        possessions = Possession.objects.select_related(
            "game", "team", "opponent", "created_by"
        ).prefetch_related(
            "players_on_court",
            "offensive_rebound_players",
            "game__home_team",
            "game__away_team",
        )

        # Apply possession filters
        if filtered_game_ids:
            possessions = possessions.filter(game_id__in=filtered_game_ids)

        if game_ids:
            possessions = possessions.filter(game_id__in=game_ids)

        if team_id:
            possessions = possessions.filter(
                Q(team_id=team_id) | Q(opponent_id=team_id)
            )

        if quarter_filter:
            possessions = possessions.filter(quarter=quarter_filter)

        # Filter by home/away
        if home_away_filter:
            if team_id:
                # Filter for specific team's home/away games
                if home_away_filter == "Home":
                    # Filter for home games - team is home_team in the game
                    possessions = possessions.filter(
                        Q(team_id=team_id, game__home_team_id=team_id)
                        | Q(opponent_id=team_id, game__home_team_id=team_id)
                    )
                elif home_away_filter == "Away":
                    # Filter for away games - team is away_team in the game
                    possessions = possessions.filter(
                        Q(team_id=team_id, game__away_team_id=team_id)
                        | Q(opponent_id=team_id, game__away_team_id=team_id)
                    )
            else:
                # Filter for all home/away games (from home team perspective)
                if home_away_filter == "Home":
                    # All home team possessions
                    possessions = possessions.filter(team_id=F("game__home_team_id"))
                elif home_away_filter == "Away":
                    # All away team possessions
                    possessions = possessions.filter(team_id=F("game__away_team_id"))

        # Get basic stats
        total_possessions = possessions.count()
        if total_possessions == 0:
            return {
                "summary": {"total_possessions": 0},
                "offensive_analysis": {},
                "defensive_analysis": {},
                "player_analysis": {},
                "detailed_breakdown": {},
                "filters_applied": {
                    "team_id": team_id,
                    "quarter_filter": quarter_filter,
                    "last_games": last_games,
                    "outcome_filter": outcome_filter,
                    "home_away_filter": home_away_filter,
                    "total_possessions_analyzed": 0,
                },
            }

        # Calculate basic metrics with optimized queries
        offensive_possessions = possessions.filter(
            offensive_sequence__isnull=False
        ).exclude(offensive_sequence="")
        defensive_possessions = possessions.filter(
            defensive_sequence__isnull=False
        ).exclude(defensive_sequence="")

        # Summary statistics
        summary_stats = GameAnalyticsService._calculate_summary_stats(
            possessions, offensive_possessions, defensive_possessions, team_id
        )

        # Offensive analysis
        offensive_analysis = GameAnalyticsService._analyze_offensive_possessions(
            offensive_possessions, team_id
        )

        # Defensive analysis
        defensive_analysis = GameAnalyticsService._analyze_defensive_possessions(
            defensive_possessions, team_id
        )

        # Player analysis
        player_analysis = GameAnalyticsService._analyze_player_performance(
            possessions, team_id, min_possessions
        )

        # Detailed breakdown
        detailed_breakdown = GameAnalyticsService._get_detailed_breakdown(
            possessions, team_id
        )

        return {
            "summary": summary_stats,
            "offensive_analysis": offensive_analysis,
            "defensive_analysis": defensive_analysis,
            "player_analysis": player_analysis,
            "detailed_breakdown": detailed_breakdown,
            "filters_applied": {
                "team_id": team_id,
                "quarter_filter": quarter_filter,
                "last_games": last_games,
                "outcome_filter": outcome_filter,
                "home_away_filter": home_away_filter,
                "total_possessions_analyzed": total_possessions,
            },
        }

    @staticmethod
    def _calculate_summary_stats(
        possessions, offensive_possessions, defensive_possessions, team_id
    ):
        """Calculate summary statistics."""

        # Basic counts
        total_possessions = possessions.count()
        offensive_count = offensive_possessions.count()
        defensive_count = defensive_possessions.count()

        # Points analysis
        total_points = sum(p.points_scored for p in possessions if p.points_scored)
        offensive_points = sum(
            p.points_scored for p in offensive_possessions if p.points_scored
        )
        defensive_points = sum(
            p.points_scored for p in defensive_possessions if p.points_scored
        )

        # PPP calculations
        offensive_ppp = offensive_points / offensive_count if offensive_count > 0 else 0
        defensive_ppp = defensive_points / defensive_count if defensive_count > 0 else 0

        # Time analysis
        avg_possession_time = (
            possessions.aggregate(avg_time=Avg("duration_seconds"))["avg_time"] or 0
        )

        return {
            "total_possessions": total_possessions,
            "offensive_possessions": offensive_count,
            "defensive_possessions": defensive_count,
            "total_points": total_points,
            "offensive_points": offensive_points,
            "defensive_points": defensive_points,
            "offensive_ppp": round(offensive_ppp, 2),
            "defensive_ppp": round(defensive_ppp, 2),
            "avg_possession_time": round(avg_possession_time, 1),
            "total_ppp": (
                round(total_points / total_possessions, 2)
                if total_possessions > 0
                else 0
            ),
        }

    @staticmethod
    def _analyze_offensive_possessions(offensive_possessions, team_id):
        """Analyze offensive possessions with detailed breakdowns."""

        if not offensive_possessions.exists():
            return {}

        # PnR Analysis
        pnr_analysis = GameAnalyticsService._analyze_pnr_offense(offensive_possessions)

        # Paint Touch Analysis
        paint_touch_analysis = GameAnalyticsService._analyze_paint_touches(
            offensive_possessions
        )

        # Kick Out Analysis
        kick_out_analysis = GameAnalyticsService._analyze_kick_outs(
            offensive_possessions
        )

        # Extra Pass Analysis
        extra_pass_analysis = GameAnalyticsService._analyze_extra_passes(
            offensive_possessions
        )

        # Offensive Rebound Analysis
        off_reb_analysis = GameAnalyticsService._analyze_offensive_rebounds(
            offensive_possessions
        )

        # Shot Time Analysis
        shot_time_analysis = GameAnalyticsService._analyze_shot_times(
            offensive_possessions
        )

        # Shot Quality Analysis
        shot_quality_analysis = GameAnalyticsService._analyze_shot_quality(
            offensive_possessions
        )

        # After Timeout Analysis
        ato_analysis = GameAnalyticsService._analyze_after_timeout(
            offensive_possessions
        )

        return {
            "pnr_analysis": pnr_analysis,
            "paint_touch_analysis": paint_touch_analysis,
            "kick_out_analysis": kick_out_analysis,
            "extra_pass_analysis": extra_pass_analysis,
            "offensive_rebound_analysis": off_reb_analysis,
            "shot_time_analysis": shot_time_analysis,
            "shot_quality_analysis": shot_quality_analysis,
            "after_timeout_analysis": ato_analysis,
        }

    @staticmethod
    def _analyze_defensive_possessions(defensive_possessions, team_id):
        """Analyze defensive possessions with detailed breakdowns."""

        if not defensive_possessions.exists():
            return {}

        # PnR Defense Analysis
        pnr_defense = GameAnalyticsService._analyze_pnr_defense(defensive_possessions)

        # Box Out Analysis
        box_out_analysis = GameAnalyticsService._analyze_box_outs(defensive_possessions)

        # Defensive Rebound Analysis
        def_reb_analysis = GameAnalyticsService._analyze_defensive_rebounds(
            defensive_possessions
        )

        return {
            "pnr_defense": pnr_defense,
            "box_out_analysis": box_out_analysis,
            "defensive_rebound_analysis": def_reb_analysis,
        }

    @staticmethod
    def _analyze_pnr_offense(possessions):
        """Analyze PnR offensive performance."""

        # Filter PnR possessions
        pnr_possessions = possessions.filter(
            Q(offensive_sequence__icontains="PnR")
            | Q(offensive_sequence__icontains="Pick")
            | Q(offensive_sequence__icontains="Roll")
        )

        if not pnr_possessions.exists():
            return {}

        total_pnr = pnr_possessions.count()
        pnr_points = sum(p.points_scored for p in pnr_possessions if p.points_scored)
        pnr_ppp = pnr_points / total_pnr if total_pnr > 0 else 0

        # Analyze PnR results
        pnr_results = {}
        for possession in pnr_possessions:
            sequence = possession.offensive_sequence.lower()
            if "scorer" in sequence:
                pnr_results["scorer"] = pnr_results.get("scorer", 0) + 1
            elif "big guy" in sequence:
                pnr_results["big_guy"] = pnr_results.get("big_guy", 0) + 1
            elif "3rd guy" in sequence:
                pnr_results["3rd_guy"] = pnr_results.get("3rd_guy", 0) + 1

        return {
            "total_pnr_possessions": total_pnr,
            "pnr_points": pnr_points,
            "pnr_ppp": round(pnr_ppp, 2),
            "pnr_results": pnr_results,
        }

    @staticmethod
    def _analyze_paint_touches(possessions):
        """Analyze paint touch performance."""

        paint_touch_possessions = possessions.filter(
            Q(offensive_sequence__icontains="Paint Touch")
            | Q(offensive_sequence__icontains="Paint")
        )

        if not paint_touch_possessions.exists():
            return {}

        total_paint_touches = paint_touch_possessions.count()
        paint_touch_points = sum(
            p.points_scored for p in paint_touch_possessions if p.points_scored
        )
        paint_touch_ppp = (
            paint_touch_points / total_paint_touches if total_paint_touches > 0 else 0
        )

        return {
            "total_paint_touches": total_paint_touches,
            "paint_touch_points": paint_touch_points,
            "paint_touch_ppp": round(paint_touch_ppp, 2),
        }

    @staticmethod
    def _analyze_kick_outs(possessions):
        """Analyze kick out performance."""

        kick_out_possessions = possessions.filter(
            offensive_sequence__icontains="Kick Out"
        )

        if not kick_out_possessions.exists():
            return {}

        total_kick_outs = kick_out_possessions.count()
        kick_out_points = sum(
            p.points_scored for p in kick_out_possessions if p.points_scored
        )
        kick_out_ppp = kick_out_points / total_kick_outs if total_kick_outs > 0 else 0

        return {
            "total_kick_outs": total_kick_outs,
            "kick_out_points": kick_out_points,
            "kick_out_ppp": round(kick_out_ppp, 2),
        }

    @staticmethod
    def _analyze_extra_passes(possessions):
        """Analyze extra pass performance."""

        extra_pass_possessions = possessions.filter(
            Q(offensive_sequence__icontains="Extra Pass")
            | Q(offensive_sequence__icontains="Extra")
        )

        if not extra_pass_possessions.exists():
            return {}

        total_extra_passes = extra_pass_possessions.count()
        extra_pass_points = sum(
            p.points_scored for p in extra_pass_possessions if p.points_scored
        )
        extra_pass_ppp = (
            extra_pass_points / total_extra_passes if total_extra_passes > 0 else 0
        )

        return {
            "total_extra_passes": total_extra_passes,
            "extra_pass_points": extra_pass_points,
            "extra_pass_ppp": round(extra_pass_ppp, 2),
        }

    @staticmethod
    def _analyze_offensive_rebounds(possessions):
        """Analyze offensive rebound performance."""

        off_reb_possessions = possessions.filter(
            Q(offensive_sequence__icontains="Off Reb")
            | Q(offensive_sequence__icontains="Offensive Rebound")
            | Q(offensive_sequence__icontains="TOR")
        )

        if not off_reb_possessions.exists():
            return {}

        total_off_rebs = off_reb_possessions.count()
        off_reb_points = sum(
            p.points_scored for p in off_reb_possessions if p.points_scored
        )
        off_reb_ppp = off_reb_points / total_off_rebs if total_off_rebs > 0 else 0

        # Count players involved
        player_counts = {}
        for possession in off_reb_possessions:
            player_count = possession.offensive_rebound_players.count()
            player_counts[player_count] = player_counts.get(player_count, 0) + 1

        return {
            "total_offensive_rebounds": total_off_rebs,
            "off_reb_points": off_reb_points,
            "off_reb_ppp": round(off_reb_ppp, 2),
            "player_distribution": player_counts,
        }

    @staticmethod
    def _analyze_shot_times(possessions):
        """Analyze shot time performance."""

        # Group by shot time ranges
        shot_time_ranges = {
            "0-5s": possessions.filter(duration_seconds__lte=5),
            "6-10s": possessions.filter(
                duration_seconds__gt=5, duration_seconds__lte=10
            ),
            "11-15s": possessions.filter(
                duration_seconds__gt=10, duration_seconds__lte=15
            ),
            "16-20s": possessions.filter(
                duration_seconds__gt=15, duration_seconds__lte=20
            ),
            "20s+": possessions.filter(duration_seconds__gt=20),
        }

        analysis = {}
        for range_name, range_possessions in shot_time_ranges.items():
            if range_possessions.exists():
                count = range_possessions.count()
                points = sum(
                    p.points_scored for p in range_possessions if p.points_scored
                )
                ppp = points / count if count > 0 else 0

                analysis[range_name] = {
                    "possessions": count,
                    "points": points,
                    "ppp": round(ppp, 2),
                }

        return analysis

    @staticmethod
    def _analyze_shot_quality(possessions):
        """Analyze shot quality based on outcomes."""

        # This would need to be enhanced based on your shot quality definitions
        # For now, we'll analyze by outcome types
        outcomes = {}
        for possession in possessions:
            outcome = possession.outcome
            if outcome not in outcomes:
                outcomes[outcome] = {"count": 0, "points": 0}
            outcomes[outcome]["count"] += 1
            if possession.points_scored:
                outcomes[outcome]["points"] += possession.points_scored

        # Calculate PPP for each outcome
        for outcome in outcomes:
            count = outcomes[outcome]["count"]
            points = outcomes[outcome]["points"]
            outcomes[outcome]["ppp"] = round(points / count, 2) if count > 0 else 0

        return outcomes

    @staticmethod
    def _analyze_after_timeout(possessions):
        """Analyze after timeout performance."""

        ato_possessions = possessions.filter(
            Q(offensive_sequence__icontains="ATO")
            | Q(offensive_sequence__icontains="After Timeout")
            | Q(offensive_sequence__icontains="Timeout")
        )

        if not ato_possessions.exists():
            return {}

        total_ato = ato_possessions.count()
        ato_points = sum(p.points_scored for p in ato_possessions if p.points_scored)
        ato_ppp = ato_points / total_ato if total_ato > 0 else 0

        return {
            "total_ato_possessions": total_ato,
            "ato_points": ato_points,
            "ato_ppp": round(ato_ppp, 2),
        }

    @staticmethod
    def _analyze_pnr_defense(defensive_possessions):
        """Analyze PnR defensive performance."""

        pnr_defense = defensive_possessions.filter(
            Q(defensive_sequence__icontains="PnR")
            | Q(defensive_sequence__icontains="Switch")
            | Q(defensive_sequence__icontains="Drop")
            | Q(defensive_sequence__icontains="Blitz")
        )

        if not pnr_defense.exists():
            return {}

        total_pnr_defense = pnr_defense.count()
        pnr_defense_points_allowed = sum(
            p.points_scored for p in pnr_defense if p.points_scored
        )
        pnr_defense_ppp_allowed = (
            pnr_defense_points_allowed / total_pnr_defense
            if total_pnr_defense > 0
            else 0
        )

        return {
            "total_pnr_defense": total_pnr_defense,
            "pnr_defense_points_allowed": pnr_defense_points_allowed,
            "pnr_defense_ppp_allowed": round(pnr_defense_ppp_allowed, 2),
        }

    @staticmethod
    def _analyze_box_outs(defensive_possessions):
        """Analyze box out performance."""

        box_out_possessions = defensive_possessions.filter(
            defensive_sequence__icontains="BoxOut"
        )

        if not box_out_possessions.exists():
            return {}

        total_box_outs = box_out_possessions.count()
        box_out_points_allowed = sum(
            p.points_scored for p in box_out_possessions if p.points_scored
        )
        box_out_ppp_allowed = (
            box_out_points_allowed / total_box_outs if total_box_outs > 0 else 0
        )

        return {
            "total_box_outs": total_box_outs,
            "box_out_points_allowed": box_out_points_allowed,
            "box_out_ppp_allowed": round(box_out_ppp_allowed, 2),
        }

    @staticmethod
    def _analyze_defensive_rebounds(defensive_possessions):
        """Analyze defensive rebound performance."""

        def_reb_possessions = defensive_possessions.filter(
            Q(defensive_sequence__icontains="DefReb")
            | Q(defensive_sequence__icontains="Defensive Rebound")
        )

        if not def_reb_possessions.exists():
            return {}

        total_def_rebs = def_reb_possessions.count()

        return {"total_defensive_rebounds": total_def_rebs}

    @staticmethod
    def _analyze_player_performance(possessions, team_id, min_possessions):
        """Analyze individual player performance."""

        # Get all players involved in possessions
        player_stats = {}

        for possession in possessions:
            # Analyze players on court
            for player in possession.players_on_court.all():
                if player.id not in player_stats:
                    player_stats[player.id] = {
                        "player_name": f"{player.first_name} {player.last_name}",
                        "possessions": 0,
                        "points": 0,
                        "offensive_possessions": 0,
                        "defensive_possessions": 0,
                    }

                player_stats[player.id]["possessions"] += 1
                if possession.points_scored:
                    player_stats[player.id]["points"] += possession.points_scored

                # Determine if offensive or defensive possession
                if (
                    possession.offensive_sequence
                    and possession.offensive_sequence.strip()
                ):
                    player_stats[player.id]["offensive_possessions"] += 1
                if (
                    possession.defensive_sequence
                    and possession.defensive_sequence.strip()
                ):
                    player_stats[player.id]["defensive_possessions"] += 1

        # Filter by minimum possessions and calculate PPP
        qualified_players = {}
        for player_id, stats in player_stats.items():
            if stats["possessions"] >= min_possessions:
                stats["ppp"] = (
                    round(stats["points"] / stats["possessions"], 2)
                    if stats["possessions"] > 0
                    else 0
                )
                stats["offensive_ppp"] = (
                    round(stats["points"] / stats["offensive_possessions"], 2)
                    if stats["offensive_possessions"] > 0
                    else 0
                )
                qualified_players[player_id] = stats

        # Sort by PPP
        sorted_players = sorted(
            qualified_players.items(), key=lambda x: x[1]["ppp"], reverse=True
        )

        return {
            "players": dict(sorted_players),
            "min_possessions_threshold": min_possessions,
        }

    @staticmethod
    def _get_detailed_breakdown(possessions, team_id):
        """Get detailed breakdown by various categories."""

        # Quarter breakdown
        quarter_breakdown = {}
        for quarter in range(1, 6):  # 1-4 quarters + OT
            quarter_possessions = possessions.filter(quarter=quarter)
            if quarter_possessions.exists():
                count = quarter_possessions.count()
                points = sum(
                    p.points_scored for p in quarter_possessions if p.points_scored
                )
                ppp = points / count if count > 0 else 0
                quarter_breakdown[f"Q{quarter}"] = {
                    "possessions": count,
                    "points": points,
                    "ppp": round(ppp, 2),
                }

        # Home/Away breakdown
        home_away_breakdown = {}
        for possession in possessions:
            game = possession.game
            location = "Home" if possession.team_id == game.home_team_id else "Away"

            if location not in home_away_breakdown:
                home_away_breakdown[location] = {"possessions": 0, "points": 0}

            home_away_breakdown[location]["possessions"] += 1
            if possession.points_scored:
                home_away_breakdown[location]["points"] += possession.points_scored

        # Calculate PPP for home/away
        for location in home_away_breakdown:
            count = home_away_breakdown[location]["possessions"]
            points = home_away_breakdown[location]["points"]
            home_away_breakdown[location]["ppp"] = (
                round(points / count, 2) if count > 0 else 0
            )

        return {
            "quarter_breakdown": quarter_breakdown,
            "home_away_breakdown": home_away_breakdown,
        }

    # Legacy methods for backward compatibility
    @staticmethod
    def get_post_game_report(game_id, team_id):
        """
        Generate comprehensive post-game report with offensive and defensive analytics.
        Returns data structured exactly like the UI requirements.
        """
        try:
            game = Game.objects.get(id=game_id)
            team_possessions = Possession.objects.filter(
                game=game, team_id=team_id
            ).prefetch_related("team", "opponent")

            opponent_possessions = Possession.objects.filter(
                game=game, opponent_id=team_id
            ).prefetch_related("team", "opponent")

            return {
                "game_info": {
                    "id": game.id,
                    "home_team": {
                        "id": game.home_team.id,
                        "name": game.home_team.name,
                        "logo_url": game.home_team.logo_url,
                    },
                    "away_team": {
                        "id": game.away_team.id,
                        "name": game.away_team.name,
                        "logo_url": game.away_team.logo_url,
                    },
                    "home_score": game.home_team_score,
                    "away_score": game.away_team_score,
                    "game_date": game.game_date,
                },
                "offence": GameAnalyticsService._calculate_offensive_analytics(
                    team_possessions
                ),
                "defence": GameAnalyticsService._calculate_defensive_analytics(
                    opponent_possessions
                ),
                "summary": GameAnalyticsService._calculate_summary_stats_legacy(
                    game, team_possessions, opponent_possessions
                ),
            }
        except Game.DoesNotExist:
            return None

    @staticmethod
    def _calculate_offensive_analytics(possessions):
        """Calculate offensive possession analytics."""
        offensive_possessions = possessions.filter(
            offensive_sequence__isnull=False
        ).exclude(offensive_sequence="")

        # Transition analytics
        transition_data = {
            "fast_break": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Fast Break"
            ),
            "transition": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Transition"
            ),
            "early_off": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Early Off"
            ),
        }

        # Offensive sets analytics
        offensive_sets = {}
        for i in range(10):  # Sets 0-9
            offensive_sets[f"set_{i}"] = (
                GameAnalyticsService._calculate_play_type_stats(
                    offensive_possessions, f"Set {i}"
                )
            )

        # Pick and Roll analytics
        pnr_data = {
            "ball_handler": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Ball Handler"
            ),
            "roll_man": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Roll Man"
            ),
            "third_guy": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "3rd Guy"
            ),
        }

        # VS PnR Coverage analytics
        vs_pnr_coverage = {
            "switch": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Switch"
            ),
            "hedge": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Hedge"
            ),
            "drop": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Drop"
            ),
            "trap": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Trap"
            ),
        }

        # Other offensive parts
        other_offensive = {
            "closeout": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Closeout"
            ),
            "cuts": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Cuts"
            ),
            "kick_out": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Kick Out"
            ),
            "extra_pass": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "Extra Pass"
            ),
            "after_off_reb": GameAnalyticsService._calculate_play_type_stats(
                offensive_possessions, "After OffReb"
            ),
        }

        return {
            "transition": transition_data,
            "offensive_sets": offensive_sets,
            "pnr": pnr_data,
            "vs_pnr_coverage": vs_pnr_coverage,
            "other_offensive": other_offensive,
        }

    @staticmethod
    def _calculate_defensive_analytics(opponent_possessions):
        """Calculate defensive analytics based on opponent possessions."""
        defensive_possessions = opponent_possessions.filter(
            defensive_sequence__isnull=False
        ).exclude(defensive_sequence="")

        # Coverage analytics
        coverage_data = {
            "switch": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Switch"
            ),
            "switch_low_post": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Switch Low Post"
            ),
            "switch_isolation": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Switch Isolation"
            ),
            "switch_third_guy": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Switch 3rd Guy"
            ),
            "hedge": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Hedge"
            ),
            "drop_weak": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Drop/Weak"
            ),
            "drop_ball_handler": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Drop Ball Handler"
            ),
            "drop_big_guy": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Drop Big Guy"
            ),
            "drop_third_guy": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Drop 3rd Guy"
            ),
            "isolation": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Isolation"
            ),
            "isolation_high_post": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Isolation High Post"
            ),
            "isolation_low_post": GameAnalyticsService._calculate_play_type_stats(
                defensive_possessions, "Isolation Low Post"
            ),
        }

        return {
            "coverage": coverage_data,
        }

    @staticmethod
    def _calculate_summary_stats_legacy(game, team_possessions, opponent_possessions):
        """Calculate summary statistics for the report."""
        # Tagging up (player offensive rebounds)
        tagging_up = {}
        for i in range(6):  # Players 0-5
            player_rebounds = team_possessions.filter(
                is_offensive_rebound=True,
                # This would need to be connected to actual players
            ).count()
            tagging_up[f"player_{i}"] = {
                "player_no": i,
                "count": player_rebounds,
                "percentage": (
                    (player_rebounds / team_possessions.count() * 100)
                    if team_possessions.count() > 0
                    else 0
                ),
            }

        # Paint touch analytics
        paint_touches = team_possessions.filter(has_paint_touch=True)
        paint_touch_stats = {
            "count": paint_touches.count(),
            "points": paint_touches.aggregate(total=Sum("points_scored"))["total"] or 0,
            "possessions": paint_touches.count(),
            "percentage": (
                (paint_touches.count() / team_possessions.count() * 100)
                if team_possessions.count() > 0
                else 0
            ),
        }

        # Best offensive 5 (placeholder - would need player data)
        best_offensive_5 = {
            "players": [{"id": i, "name": f"Player {i}", "stats": 0} for i in range(5)]
        }

        # Best defensive 5 (placeholder - would need player data)
        best_defensive_5 = {
            "players": [{"id": i, "name": f"Player {i}", "stats": 0} for i in range(5)]
        }

        # Quarters breakdown
        quarters_data = {}
        for quarter in [1, 2, 3, 4]:
            quarter_team_possessions = team_possessions.filter(quarter=quarter)
            quarter_opponent_possessions = opponent_possessions.filter(quarter=quarter)

            off_ppp = GameAnalyticsService._calculate_ppp(quarter_team_possessions)
            def_ppp = GameAnalyticsService._calculate_ppp(quarter_opponent_possessions)

            quarters_data[f"quarter_{quarter}"] = {
                "quarter": f'{quarter}{"ST" if quarter == 1 else "ND" if quarter == 2 else "RD" if quarter == 3 else "TH"}',
                "off_ppp": off_ppp,
                "def_ppp": def_ppp,
            }

        # Add OT if exists
        ot_possessions = team_possessions.filter(quarter__gt=4)
        if ot_possessions.exists():
            ot_opponent_possessions = opponent_possessions.filter(quarter__gt=4)
            quarters_data["overtime"] = {
                "quarter": "OT",
                "off_ppp": GameAnalyticsService._calculate_ppp(ot_possessions),
                "def_ppp": GameAnalyticsService._calculate_ppp(ot_opponent_possessions),
            }

        return {
            "tagging_up": tagging_up,
            "paint_touch": paint_touch_stats,
            "best_offensive_5": best_offensive_5,
            "best_defensive_5": best_defensive_5,
            "quarters": quarters_data,
        }

    @staticmethod
    def _calculate_play_type_stats(possessions, play_type):
        """Calculate statistics for a specific play type."""
        filtered_possessions = possessions.filter(
            Q(offensive_sequence__icontains=play_type)
            | Q(defensive_sequence__icontains=play_type)
        )

        if not filtered_possessions.exists():
            return {
                "possessions": 0,
                "ppp": 0.0,
                "adjusted_sq": 0.0,
            }

        total_possessions = filtered_possessions.count()
        total_points = (
            filtered_possessions.aggregate(total=Sum("points_scored"))["total"] or 0
        )

        ppp = total_points / total_possessions if total_possessions > 0 else 0

        # Adjusted Shot Quality (simplified calculation)
        avg_shoot_quality = (
            filtered_possessions.aggregate(avg=Avg("shoot_quality"))["avg"] or 0
        )

        return {
            "possessions": total_possessions,
            "ppp": round(ppp, 2),
            "adjusted_sq": round(avg_shoot_quality, 2),
        }

    @staticmethod
    def _calculate_ppp(possessions):
        """Calculate Points Per Possession."""
        if not possessions.exists():
            return 0.0

        total_points = possessions.aggregate(total=Sum("points_scored"))["total"] or 0

        return round(total_points / possessions.count(), 2)
