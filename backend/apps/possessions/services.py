from django.db.models import Count, Sum, Avg, Case, When, Value, F, Q, IntegerField
from django.db.models.functions import Coalesce
from .models import Possession
from apps.games.models import Game


class StatsService:
    """Service for calculating comprehensive basketball statistics"""

    def __init__(self, team):
        self.team = team

    def _get_base_queryset(self, offensive=True, game_range=None):
        """Get base queryset for the team's possessions"""
        if offensive:
            queryset = Possession.objects.filter(team__team=self.team)
        else:
            queryset = Possession.objects.filter(opponent__team=self.team)
        
        queryset = queryset.select_related("game", "team", "team__team", "opponent", "opponent__team")

        if game_range:
            # Get recent games based on game_range
            from django.db.models import Q
            recent_games = Game.objects.filter(
                Q(home_team=self.team) | Q(away_team=self.team)
            ).order_by("-game_date")[:game_range]
            queryset = queryset.filter(game__in=recent_games)

        return queryset

    def get_quarter_stats(self, offensive=True):
        """Get stats broken down by quarter"""
        queryset = self._get_base_queryset(offensive)

        stats = (
            queryset.values("quarter")
            .annotate(
                total_possessions=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                successful_possessions=Count(
                    Case(When(points_scored__gt=0, then=Value(1)))
                ),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("quarter")
        )

        return {
            "team": self.team.name,
            "offensive": offensive,
            "quarter_stats": list(stats),
        }

    def get_offensive_set_stats(self):
        """Get stats by offensive sets"""
        queryset = self._get_base_queryset(offensive=True)

        stats = (
            queryset.values("offensive_set")
            .annotate(
                total_possessions=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                successful_possessions=Count(
                    Case(When(points_scored__gt=0, then=Value(1)))
                ),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
                pnr_possessions=Count(
                    Case(When(pnr_type__isnull=False, then=Value(1)))
                ),
                paint_touch_possessions=Count(
                    Case(When(has_paint_touch=True, then=Value(1)))
                ),
                kick_out_possessions=Count(
                    Case(When(has_kick_out=True, then=Value(1)))
                ),
                extra_pass_possessions=Count(
                    Case(When(has_extra_pass=True, then=Value(1)))
                ),
            )
            .order_by("-total_possessions")
        )

        return {"team": self.team.name, "offensive_set_stats": list(stats)}

    def get_defensive_set_stats(self):
        """Get stats by defensive sets"""
        queryset = self._get_base_queryset(offensive=False)

        stats = (
            queryset.values("defensive_set")
            .annotate(
                total_possessions=Count("id"),
                points_allowed=Sum("points_scored"),
                avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
                stops=Count(Case(When(points_scored=0, then=Value(1)))),
                stop_rate=Coalesce(
                    Count(Case(When(points_scored=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
                pnr_defense_possessions=Count(
                    Case(When(defensive_pnr__isnull=False, then=Value(1)))
                ),
                offensive_rebounds_allowed=Sum("offensive_rebounds_allowed"),
                box_outs=Sum("box_out_count"),
            )
            .order_by("-total_possessions")
        )

        return {"team": self.team.name, "defensive_set_stats": list(stats)}

    def get_pnr_stats(self, offensive=True):
        """Get pick and roll statistics"""
        queryset = self._get_base_queryset(offensive)

        if offensive:
            stats = (
                queryset.filter(pnr_type__isnull=False)
                .values("pnr_type", "pnr_result")
                .annotate(
                    total_possessions=Count("id"),
                    total_points=Sum("points_scored"),
                    avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                    successful_possessions=Count(
                        Case(When(points_scored__gt=0, then=Value(1)))
                    ),
                    success_rate=Coalesce(
                        Count(Case(When(points_scored__gt=0, then=Value(1))))
                        * 100.0
                        / Count("id"),
                        0.0,
                    ),
                )
                .order_by("-total_possessions")
            )
        else:
            stats = (
                queryset.filter(defensive_pnr__isnull=False)
                .values("defensive_pnr")
                .annotate(
                    total_possessions=Count("id"),
                    points_allowed=Sum("points_scored"),
                    avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
                    stops=Count(Case(When(points_scored=0, then=Value(1)))),
                    stop_rate=Coalesce(
                        Count(Case(When(points_scored=0, then=Value(1))))
                        * 100.0
                        / Count("id"),
                        0.0,
                    ),
                )
                .order_by("-total_possessions")
            )

        return {
            "team": self.team.name,
            "offensive": offensive,
            "pnr_stats": list(stats),
        }

    def get_outcome_stats(self, offensive=True):
        """Get statistics by outcomes"""
        queryset = self._get_base_queryset(offensive)

        stats = (
            queryset.values("outcome")
            .annotate(
                total_possessions=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            )
            .order_by("-total_possessions")
        )

        return {
            "team": self.team.name,
            "offensive": offensive,
            "outcome_stats": list(stats),
        }

    def get_sequence_stats(self):
        """Get sequence action statistics (paint touch, kick out, extra pass)"""
        queryset = self._get_base_queryset(offensive=True)

        # Paint touch stats
        paint_touch_stats = queryset.filter(has_paint_touch=True).aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Kick out stats
        kick_out_stats = queryset.filter(has_kick_out=True).aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Extra pass stats
        extra_pass_stats = queryset.filter(has_extra_pass=True).aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Pass count distribution
        pass_distribution = (
            queryset.values("number_of_passes")
            .annotate(
                count=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            )
            .order_by("number_of_passes")
        )

        return {
            "team": self.team.name,
            "paint_touch": paint_touch_stats,
            "kick_out": kick_out_stats,
            "extra_pass": extra_pass_stats,
            "pass_distribution": list(pass_distribution),
        }

    def get_offensive_rebound_stats(self):
        """Get offensive rebound statistics"""
        queryset = self._get_base_queryset(offensive=True)

        # Overall offensive rebound stats
        overall_stats = queryset.filter(is_offensive_rebound=True).aggregate(
            total_offensive_rebounds=Count("id"),
            total_points_after_oreb=Sum("points_scored"),
            avg_points_after_oreb=Coalesce(Avg("points_scored"), 0.0),
            success_rate_after_oreb=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Offensive rebound count distribution
        oreb_count_stats = (
            queryset.values("offensive_rebound_count")
            .annotate(
                count=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            )
            .order_by("offensive_rebound_count")
        )

        # Players involved in offensive rebounds
        player_oreb_stats = (
            queryset.filter(is_offensive_rebound=True)
            .values("offensive_rebound_players__username")
            .annotate(
                offensive_rebounds=Count("id"),
                points_after_oreb=Sum("points_scored"),
                avg_points_after_oreb=Coalesce(Avg("points_scored"), 0.0),
            )
            .order_by("-offensive_rebounds")
        )

        return {
            "team": self.team.name,
            "overall_stats": overall_stats,
            "oreb_count_distribution": list(oreb_count_stats),
            "player_stats": list(player_oreb_stats),
        }

    def get_box_out_stats(self):
        """Get box out and defensive rebound statistics"""
        queryset = self._get_base_queryset(offensive=False)

        # Overall box out stats
        overall_stats = queryset.aggregate(
            total_possessions=Count("id"),
            total_box_outs=Sum("box_out_count"),
            avg_box_outs_per_possession=Coalesce(Avg("box_out_count"), 0.0),
            offensive_rebounds_allowed=Sum("offensive_rebounds_allowed"),
            defensive_rebounds=Count(Case(When(points_scored=0, then=Value(1)))),
            defensive_rebound_rate=Coalesce(
                Count(Case(When(points_scored=0, then=Value(1)))) * 100.0 / Count("id"),
                0.0,
            ),
        )

        # Box out effectiveness
        box_out_effectiveness = (
            queryset.values("box_out_count")
            .annotate(
                count=Count("id"),
                offensive_rebounds_allowed=Sum("offensive_rebounds_allowed"),
                defensive_rebounds=Count(Case(When(points_scored=0, then=Value(1)))),
            )
            .order_by("box_out_count")
        )

        return {
            "team": self.team.name,
            "overall_stats": overall_stats,
            "box_out_effectiveness": list(box_out_effectiveness),
        }

    def get_shooting_stats(self):
        """Get shooting quality and timing statistics"""
        queryset = self._get_base_queryset(offensive=True)

        # Shoot time distribution
        shoot_time_stats = (
            queryset.values("shoot_time")
            .annotate(
                count=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("shoot_time")
        )

        # Shoot quality distribution
        shoot_quality_stats = (
            queryset.values("shoot_quality")
            .annotate(
                count=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("shoot_quality")
        )

        # Time range distribution
        time_range_stats = (
            queryset.values("time_range")
            .annotate(
                count=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("time_range")
        )

        return {
            "team": self.team.name,
            "shoot_time_stats": list(shoot_time_stats),
            "shoot_quality_stats": list(shoot_quality_stats),
            "time_range_stats": list(time_range_stats),
        }

    def get_timeout_stats(self):
        """Get after timeout statistics"""
        queryset = self._get_base_queryset(offensive=True)

        # After timeout stats
        after_timeout_stats = queryset.filter(after_timeout=True).aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Regular possession stats (not after timeout)
        regular_stats = queryset.filter(after_timeout=False).aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        return {
            "team": self.team.name,
            "after_timeout": after_timeout_stats,
            "regular_possessions": regular_stats,
        }

    def get_lineup_stats(self, min_possessions=10):
        """Get lineup statistics with minimum possession threshold"""
        queryset = self._get_base_queryset(offensive=True)

        # Get lineups that meet minimum possession threshold
        lineup_stats = (
            queryset.values("players_on_court__username")
            .annotate(
                possessions=Count("id"),
                total_points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .filter(possessions__gte=min_possessions)
            .order_by("-avg_ppp")
        )

        # Defensive lineup stats
        defensive_queryset = self._get_base_queryset(offensive=False)
        defensive_lineup_stats = (
            defensive_queryset.values("players_on_court__username")
            .annotate(
                possessions=Count("id"),
                points_allowed=Sum("points_scored"),
                avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
                stops=Count(Case(When(points_scored=0, then=Value(1)))),
                stop_rate=Coalesce(
                    Count(Case(When(points_scored=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .filter(possessions__gte=min_possessions)
            .order_by("avg_points_allowed")
        )

        return {
            "team": self.team.name,
            "min_possessions": min_possessions,
            "offensive_lineups": list(lineup_stats),
            "defensive_lineups": list(defensive_lineup_stats),
        }

    def get_game_range_stats(self, game_count):
        """Get stats for specific number of recent games"""
        queryset = self._get_base_queryset(offensive=True, game_range=game_count)

        # Overall stats for the game range
        overall_stats = queryset.aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Stats by game
        game_stats = (
            queryset.values(
                "game__id",
                "game__game_date",
                "game__home_team__name",
                "game__away_team__name",
            )
            .annotate(
                possessions=Count("id"),
                points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("-game__game_date")
        )

        return {
            "team": self.team.name,
            "game_count": game_count,
            "overall_stats": overall_stats,
            "game_stats": list(game_stats),
        }

    def get_comprehensive_report(self, game_range=None):
        """Get comprehensive stats report"""
        # Get all the different stats
        quarter_stats = self.get_quarter_stats(offensive=True)
        offensive_set_stats = self.get_offensive_set_stats()
        defensive_set_stats = self.get_defensive_set_stats()
        pnr_stats = self.get_pnr_stats(offensive=True)
        sequence_stats = self.get_sequence_stats()
        offensive_rebound_stats = self.get_offensive_rebound_stats()
        box_out_stats = self.get_box_out_stats()
        shooting_stats = self.get_shooting_stats()
        timeout_stats = self.get_timeout_stats()

        # Get lineup stats with default minimum
        lineup_stats = self.get_lineup_stats(min_possessions=10)

        # Get game range stats if specified
        game_range_stats = None
        if game_range:
            game_range_stats = self.get_game_range_stats(game_range)

        return {
            "team": self.team.name,
            "game_range": game_range,
            "quarter_stats": quarter_stats,
            "offensive_set_stats": offensive_set_stats,
            "defensive_set_stats": defensive_set_stats,
            "pnr_stats": pnr_stats,
            "sequence_stats": sequence_stats,
            "offensive_rebound_stats": offensive_rebound_stats,
            "box_out_stats": box_out_stats,
            "shooting_stats": shooting_stats,
            "timeout_stats": timeout_stats,
            "lineup_stats": lineup_stats,
            "game_range_stats": game_range_stats,
        }


class PlayerStatsService:
    """Service for calculating player-specific statistics"""

    def __init__(self, player, team):
        self.player = player
        self.team = team

    def get_player_offensive_stats(self):
        """Get player's offensive statistics"""
        queryset = Possession.objects.filter(
            team__team=self.team, players_on_court=self.player
        ).select_related("game", "team", "team__team", "opponent", "opponent__team")

        # Overall offensive stats
        overall_stats = queryset.aggregate(
            total_possessions=Count("id"),
            total_points=Sum("points_scored"),
            avg_ppp=Coalesce(Avg("points_scored"), 0.0),
            success_rate=Coalesce(
                Count(Case(When(points_scored__gt=0, then=Value(1))))
                * 100.0
                / Count("id"),
                0.0,
            ),
        )

        # Stats by offensive set
        set_stats = (
            queryset.values("offensive_set")
            .annotate(
                possessions=Count("id"),
                points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("-possessions")
        )

        # PnR stats
        pnr_stats = (
            queryset.filter(pnr_type__isnull=False)
            .values("pnr_type", "pnr_result")
            .annotate(
                possessions=Count("id"),
                points=Sum("points_scored"),
                avg_ppp=Coalesce(Avg("points_scored"), 0.0),
                success_rate=Coalesce(
                    Count(Case(When(points_scored__gt=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("-possessions")
        )

        # Offensive rebound stats
        oreb_stats = queryset.filter(
            is_offensive_rebound=True, offensive_rebound_players=self.player
        ).aggregate(
            offensive_rebounds=Count("id"),
            points_after_oreb=Sum("points_scored"),
            avg_points_after_oreb=Coalesce(Avg("points_scored"), 0.0),
        )

        return {
            "overall": overall_stats,
            "by_set": list(set_stats),
            "pnr": list(pnr_stats),
            "offensive_rebounds": oreb_stats,
        }

    def get_player_defensive_stats(self):
        """Get player's defensive statistics"""
        queryset = Possession.objects.filter(
            opponent__team=self.team, players_on_court=self.player
        ).select_related("game", "team", "team__team", "opponent", "opponent__team")

        # Overall defensive stats
        overall_stats = queryset.aggregate(
            total_possessions=Count("id"),
            points_allowed=Sum("points_scored"),
            avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
            stops=Count(Case(When(points_scored=0, then=Value(1)))),
            stop_rate=Coalesce(
                Count(Case(When(points_scored=0, then=Value(1)))) * 100.0 / Count("id"),
                0.0,
            ),
        )

        # Stats by defensive set
        set_stats = (
            queryset.values("defensive_set")
            .annotate(
                possessions=Count("id"),
                points_allowed=Sum("points_scored"),
                avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
                stops=Count(Case(When(points_scored=0, then=Value(1)))),
                stop_rate=Coalesce(
                    Count(Case(When(points_scored=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("-possessions")
        )

        # PnR defense stats
        pnr_defense_stats = (
            queryset.filter(defensive_pnr__isnull=False)
            .values("defensive_pnr")
            .annotate(
                possessions=Count("id"),
                points_allowed=Sum("points_scored"),
                avg_points_allowed=Coalesce(Avg("points_scored"), 0.0),
                stops=Count(Case(When(points_scored=0, then=Value(1)))),
                stop_rate=Coalesce(
                    Count(Case(When(points_scored=0, then=Value(1))))
                    * 100.0
                    / Count("id"),
                    0.0,
                ),
            )
            .order_by("-possessions")
        )

        # Box out stats
        box_out_stats = queryset.aggregate(
            total_box_outs=Sum("box_out_count"),
            avg_box_outs_per_possession=Coalesce(Avg("box_out_count"), 0.0),
            offensive_rebounds_allowed=Sum("offensive_rebounds_allowed"),
        )

        return {
            "overall": overall_stats,
            "by_set": list(set_stats),
            "pnr_defense": list(pnr_defense_stats),
            "box_outs": box_out_stats,
        }
