import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from apps.teams.models import Team
from apps.games.models import Game
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from apps.possessions.services import StatsService, PlayerStatsService

User = get_user_model()


class StatsServiceTestCase(APITestCase):
    """Test cases for StatsService"""

    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach",
            email="coach@test.com",
            password="testpass123",
            role=User.Role.COACH,
        )
        self.player1 = User.objects.create_user(
            username="player1",
            email="player1@test.com",
            password="testpass123",
            role=User.Role.PLAYER,
        )
        self.player2 = User.objects.create_user(
            username="player2",
            email="player2@test.com",
            password="testpass123",
            role=User.Role.PLAYER,
        )

        # Create teams
        self.team_a = Team.objects.create(name="Team A", created_by=self.coach)
        self.team_b = Team.objects.create(name="Team B", created_by=self.coach)

        # Add members to teams
        self.team_a.players.add(self.player1)
        self.team_a.coaches.add(self.coach)
        self.team_b.players.add(self.player2)

        # Create competition
        self.competition = Competition.objects.create(
            name="Test Competition", season="2024-2025", created_by=self.coach
        )

        # Create games
        self.game1 = Game.objects.create(
            competition=self.competition,
            home_team=self.team_a,
            away_team=self.team_b,
            game_date=timezone.now(),
        )
        self.game2 = Game.objects.create(
            competition=self.competition,
            home_team=self.team_b,
            away_team=self.team_a,
            game_date=timezone.now() - timedelta(days=7),
        )

        # Create possessions with various scenarios
        self.create_test_possessions()

    def create_test_possessions(self):
        """Create test possessions with various scenarios"""
        # Offensive possessions for Team A
        Possession.objects.create(
            game=self.game1,
            team=self.team_a,
            opponent=self.team_b,
            quarter=1,
            start_time_in_game="10:00",
            duration_seconds=15,
            outcome=Possession.OutcomeChoices.MADE_2PTS,
            points_scored=2,
            offensive_set=Possession.OffensiveSetChoices.PICK_AND_ROLL,
            pnr_type=Possession.PnRTypeChoices.BALL_SCREEN,
            pnr_result=Possession.PnRResultChoices.SCORER,
            has_paint_touch=True,
            has_kick_out=False,
            has_extra_pass=True,
            number_of_passes=3,
            is_offensive_rebound=False,
            offensive_rebound_count=0,
            defensive_set=Possession.DefensiveSetChoices.MAN_TO_MAN,
            defensive_pnr=Possession.DefensivePnRChoices.SWITCH,
            box_out_count=2,
            offensive_rebounds_allowed=0,
            shoot_time=Possession.ShootTimeChoices.EARLY,
            shoot_quality=Possession.ShootQualityChoices.GOOD,
            time_range=Possession.TimeRangeChoices.EARLY_SHOT_CLOCK,
            after_timeout=False,
            created_by=self.coach,
        )

        Possession.objects.create(
            game=self.game1,
            team=self.team_a,
            opponent=self.team_b,
            quarter=2,
            start_time_in_game="05:30",
            duration_seconds=20,
            outcome=Possession.OutcomeChoices.MADE_3PTS,
            points_scored=3,
            offensive_set=Possession.OffensiveSetChoices.HANDOFF,
            pnr_type=Possession.PnRTypeChoices.OFF_BALL_SCREEN,
            pnr_result=Possession.PnRResultChoices.BIG_GUY,
            has_paint_touch=False,
            has_kick_out=True,
            has_extra_pass=False,
            number_of_passes=2,
            is_offensive_rebound=True,
            offensive_rebound_count=1,
            defensive_set=Possession.DefensiveSetChoices.ZONE_2_3,
            defensive_pnr=Possession.DefensivePnRChoices.NONE,
            box_out_count=0,
            offensive_rebounds_allowed=1,
            shoot_time=Possession.ShootTimeChoices.LATE,
            shoot_quality=Possession.ShootQualityChoices.EXCELLENT,
            time_range=Possession.TimeRangeChoices.LATE_SHOT_CLOCK,
            after_timeout=True,
            created_by=self.coach,
        )

        # Defensive possessions for Team A (opponent scoring)
        Possession.objects.create(
            game=self.game1,
            team=self.team_b,
            opponent=self.team_a,
            quarter=1,
            start_time_in_game="09:45",
            duration_seconds=12,
            outcome=Possession.OutcomeChoices.MADE_2PTS,
            points_scored=2,
            offensive_set=Possession.OffensiveSetChoices.ISOLATION,
            pnr_type=Possession.PnRTypeChoices.NONE,
            pnr_result=Possession.PnRResultChoices.NONE,
            has_paint_touch=True,
            has_kick_out=False,
            has_extra_pass=False,
            number_of_passes=1,
            is_offensive_rebound=False,
            offensive_rebound_count=0,
            defensive_set=Possession.DefensiveSetChoices.MAN_TO_MAN,
            defensive_pnr=Possession.DefensivePnRChoices.ICE,
            box_out_count=3,
            offensive_rebounds_allowed=0,
            shoot_time=Possession.ShootTimeChoices.MID,
            shoot_quality=Possession.ShootQualityChoices.AVERAGE,
            time_range=Possession.TimeRangeChoices.MID_SHOT_CLOCK,
            after_timeout=False,
            created_by=self.coach,
        )

        Possession.objects.create(
            game=self.game1,
            team=self.team_b,
            opponent=self.team_a,
            quarter=2,
            start_time_in_game="03:15",
            duration_seconds=18,
            outcome=Possession.OutcomeChoices.MISSED_2PTS,
            points_scored=0,
            offensive_set=Possession.OffensiveSetChoices.PICK_AND_ROLL,
            pnr_type=Possession.PnRTypeChoices.HANDOFF_SCREEN,
            pnr_result=Possession.PnRResultChoices.PASS,
            has_paint_touch=False,
            has_kick_out=True,
            has_extra_pass=True,
            number_of_passes=4,
            is_offensive_rebound=True,
            offensive_rebound_count=2,
            defensive_set=Possession.DefensiveSetChoices.ZONE_2_3,
            defensive_pnr=Possession.DefensivePnRChoices.GO_OVER,
            box_out_count=1,
            offensive_rebounds_allowed=2,
            shoot_time=Possession.ShootTimeChoices.EARLY,
            shoot_quality=Possession.ShootQualityChoices.POOR,
            time_range=Possession.TimeRangeChoices.EARLY_SHOT_CLOCK,
            after_timeout=False,
            created_by=self.coach,
        )

        # Add players to possessions
        possession1 = Possession.objects.get(quarter=1, team=self.team_a)
        possession1.players_on_court.add(self.player1, self.player2)

        possession2 = Possession.objects.get(quarter=2, team=self.team_a)
        possession2.players_on_court.add(self.player1)
        possession2.offensive_rebound_players.add(self.player1)

        possession3 = Possession.objects.get(quarter=1, team=self.team_b)
        possession3.players_on_court.add(self.player1, self.player2)

        possession4 = Possession.objects.get(quarter=2, team=self.team_b)
        possession4.players_on_court.add(self.player1)
        possession4.offensive_rebound_players.add(self.player1, self.player2)

    def test_quarter_stats(self):
        """Test quarter statistics calculation"""
        service = StatsService(self.team_a)

        # Test offensive quarter stats
        offensive_stats = service.get_quarter_stats(offensive=True)
        self.assertEqual(offensive_stats["team"], "Team A")
        self.assertTrue(offensive_stats["offensive"])
        self.assertEqual(len(offensive_stats["quarter_stats"]), 2)

        # Check quarter 1 stats
        q1_stats = next(
            q for q in offensive_stats["quarter_stats"] if q["quarter"] == 1
        )
        self.assertEqual(q1_stats["total_possessions"], 1)
        self.assertEqual(q1_stats["total_points"], 2)
        self.assertEqual(q1_stats["avg_ppp"], 2.0)
        self.assertEqual(q1_stats["successful_possessions"], 1)
        self.assertEqual(q1_stats["success_rate"], 100.0)

        # Check quarter 2 stats
        q2_stats = next(
            q for q in offensive_stats["quarter_stats"] if q["quarter"] == 2
        )
        self.assertEqual(q2_stats["total_possessions"], 1)
        self.assertEqual(q2_stats["total_points"], 3)
        self.assertEqual(q2_stats["avg_ppp"], 3.0)
        self.assertEqual(q2_stats["successful_possessions"], 1)
        self.assertEqual(q2_stats["success_rate"], 100.0)

        # Test defensive quarter stats
        defensive_stats = service.get_quarter_stats(offensive=False)
        self.assertEqual(defensive_stats["team"], "Team A")
        self.assertFalse(defensive_stats["offensive"])
        self.assertEqual(len(defensive_stats["quarter_stats"]), 2)

    def test_offensive_set_stats(self):
        """Test offensive set statistics"""
        service = StatsService(self.team_a)
        stats = service.get_offensive_set_stats()

        self.assertEqual(stats["team"], "Team A")
        self.assertEqual(len(stats["offensive_set_stats"]), 2)

        # Check PICK_AND_ROLL stats
        pnr_stats = next(
            s
            for s in stats["offensive_set_stats"]
            if s["offensive_set"] == "PICK_AND_ROLL"
        )
        self.assertEqual(pnr_stats["total_possessions"], 1)
        self.assertEqual(pnr_stats["total_points"], 2)
        self.assertEqual(pnr_stats["avg_ppp"], 2.0)
        self.assertEqual(pnr_stats["pnr_possessions"], 1)
        self.assertEqual(pnr_stats["paint_touch_possessions"], 1)
        self.assertEqual(pnr_stats["extra_pass_possessions"], 1)

        # Check HANDOFF stats
        handoff_stats = next(
            s for s in stats["offensive_set_stats"] if s["offensive_set"] == "HANDOFF"
        )
        self.assertEqual(handoff_stats["total_possessions"], 1)
        self.assertEqual(handoff_stats["total_points"], 3)
        self.assertEqual(handoff_stats["avg_ppp"], 3.0)
        self.assertEqual(handoff_stats["pnr_possessions"], 1)
        self.assertEqual(handoff_stats["kick_out_possessions"], 1)

    def test_defensive_set_stats(self):
        """Test defensive set statistics"""
        service = StatsService(self.team_a)
        stats = service.get_defensive_set_stats()

        self.assertEqual(stats["team"], "Team A")
        self.assertEqual(len(stats["defensive_set_stats"]), 2)

        # Check MAN_TO_MAN stats
        man_stats = next(
            s
            for s in stats["defensive_set_stats"]
            if s["defensive_set"] == "MAN_TO_MAN"
        )
        self.assertEqual(man_stats["total_possessions"], 1)
        self.assertEqual(man_stats["points_allowed"], 2)
        self.assertEqual(man_stats["avg_points_allowed"], 2.0)
        self.assertEqual(man_stats["stops"], 0)
        self.assertEqual(man_stats["stop_rate"], 0.0)
        self.assertEqual(man_stats["pnr_defense_possessions"], 1)
        self.assertEqual(man_stats["box_outs"], 3)

        # Check ZONE_2_3 stats
        zone_stats = next(
            s for s in stats["defensive_set_stats"] if s["defensive_set"] == "ZONE_2_3"
        )
        self.assertEqual(zone_stats["total_possessions"], 1)
        self.assertEqual(zone_stats["points_allowed"], 0)
        self.assertEqual(zone_stats["avg_points_allowed"], 0.0)
        self.assertEqual(zone_stats["stops"], 1)
        self.assertEqual(zone_stats["stop_rate"], 100.0)
        self.assertEqual(zone_stats["offensive_rebounds_allowed"], 2)

    def test_pnr_stats(self):
        """Test pick and roll statistics"""
        service = StatsService(self.team_a)

        # Test offensive PnR stats
        offensive_pnr = service.get_pnr_stats(offensive=True)
        self.assertEqual(offensive_pnr["team"], "Team A")
        self.assertTrue(offensive_pnr["offensive"])
        self.assertEqual(len(offensive_pnr["pnr_stats"]), 2)

        # Check BALL_SCREEN stats
        ball_screen_stats = next(
            s for s in offensive_pnr["pnr_stats"] if s["pnr_type"] == "BALL_SCREEN"
        )
        self.assertEqual(ball_screen_stats["total_possessions"], 1)
        self.assertEqual(ball_screen_stats["total_points"], 2)
        self.assertEqual(ball_screen_stats["avg_ppp"], 2.0)
        self.assertEqual(ball_screen_stats["successful_possessions"], 1)
        self.assertEqual(ball_screen_stats["success_rate"], 100.0)

        # Test defensive PnR stats
        defensive_pnr = service.get_pnr_stats(offensive=False)
        self.assertEqual(defensive_pnr["team"], "Team A")
        self.assertFalse(defensive_pnr["offensive"])
        self.assertEqual(len(defensive_pnr["pnr_stats"]), 2)

    def test_sequence_stats(self):
        """Test sequence action statistics"""
        service = StatsService(self.team_a)
        stats = service.get_sequence_stats()

        self.assertEqual(stats["team"], "Team A")

        # Check paint touch stats
        paint_touch = stats["paint_touch"]
        self.assertEqual(paint_touch["total_possessions"], 1)
        self.assertEqual(paint_touch["total_points"], 2)
        self.assertEqual(paint_touch["avg_ppp"], 2.0)
        self.assertEqual(paint_touch["success_rate"], 100.0)

        # Check kick out stats
        kick_out = stats["kick_out"]
        self.assertEqual(kick_out["total_possessions"], 1)
        self.assertEqual(kick_out["total_points"], 3)
        self.assertEqual(kick_out["avg_ppp"], 3.0)
        self.assertEqual(kick_out["success_rate"], 100.0)

        # Check extra pass stats
        extra_pass = stats["extra_pass"]
        self.assertEqual(extra_pass["total_possessions"], 1)
        self.assertEqual(extra_pass["total_points"], 2)
        self.assertEqual(extra_pass["avg_ppp"], 2.0)
        self.assertEqual(extra_pass["success_rate"], 100.0)

        # Check pass distribution
        self.assertEqual(len(stats["pass_distribution"]), 2)

    def test_offensive_rebound_stats(self):
        """Test offensive rebound statistics"""
        service = StatsService(self.team_a)
        stats = service.get_offensive_rebound_stats()

        self.assertEqual(stats["team"], "Team A")

        # Check overall stats
        overall = stats["overall_stats"]
        self.assertEqual(overall["total_offensive_rebounds"], 1)
        self.assertEqual(overall["total_points_after_oreb"], 3)
        self.assertEqual(overall["avg_points_after_oreb"], 3.0)
        self.assertEqual(overall["success_rate_after_oreb"], 100.0)

        # Check player stats
        self.assertEqual(len(stats["player_stats"]), 1)
        player_stat = stats["player_stats"][0]
        self.assertEqual(player_stat["offensive_rebounds"], 1)
        self.assertEqual(player_stat["points_after_oreb"], 3)
        self.assertEqual(player_stat["avg_points_after_oreb"], 3.0)

    def test_box_out_stats(self):
        """Test box out statistics"""
        service = StatsService(self.team_a)
        stats = service.get_box_out_stats()

        self.assertEqual(stats["team"], "Team A")

        # Check overall stats
        overall = stats["overall_stats"]
        self.assertEqual(overall["total_possessions"], 2)
        self.assertEqual(overall["total_box_outs"], 4)
        self.assertEqual(overall["avg_box_outs_per_possession"], 2.0)
        self.assertEqual(overall["offensive_rebounds_allowed"], 2)
        self.assertEqual(overall["defensive_rebounds"], 1)
        self.assertEqual(overall["defensive_rebound_rate"], 50.0)

    def test_shooting_stats(self):
        """Test shooting statistics"""
        service = StatsService(self.team_a)
        stats = service.get_shooting_stats()

        self.assertEqual(stats["team"], "Team A")

        # Check shoot time stats
        self.assertEqual(len(stats["shoot_time_stats"]), 2)

        # Check shoot quality stats
        self.assertEqual(len(stats["shoot_quality_stats"]), 2)

        # Check time range stats
        self.assertEqual(len(stats["time_range_stats"]), 2)

    def test_timeout_stats(self):
        """Test timeout statistics"""
        service = StatsService(self.team_a)
        stats = service.get_timeout_stats()

        self.assertEqual(stats["team"], "Team A")

        # Check after timeout stats
        ato = stats["after_timeout"]
        self.assertEqual(ato["total_possessions"], 1)
        self.assertEqual(ato["total_points"], 3)
        self.assertEqual(ato["avg_ppp"], 3.0)
        self.assertEqual(ato["success_rate"], 100.0)

        # Check regular possession stats
        regular = stats["regular_possessions"]
        self.assertEqual(regular["total_possessions"], 1)
        self.assertEqual(regular["total_points"], 2)
        self.assertEqual(regular["avg_ppp"], 2.0)
        self.assertEqual(regular["success_rate"], 100.0)

    def test_lineup_stats(self):
        """Test lineup statistics"""
        service = StatsService(self.team_a)
        stats = service.get_lineup_stats(min_possessions=1)

        self.assertEqual(stats["team"], "Team A")
        self.assertEqual(stats["min_possessions"], 1)

        # Check offensive lineups
        self.assertEqual(len(stats["offensive_lineups"]), 2)

        # Check defensive lineups
        self.assertEqual(len(stats["defensive_lineups"]), 2)

    def test_game_range_stats(self):
        """Test game range statistics"""
        service = StatsService(self.team_a)
        stats = service.get_game_range_stats(1)

        self.assertEqual(stats["team"], "Team A")
        self.assertEqual(stats["game_count"], 1)

        # Check overall stats
        overall = stats["overall_stats"]
        self.assertEqual(overall["total_possessions"], 2)
        self.assertEqual(overall["total_points"], 5)
        self.assertEqual(overall["avg_ppp"], 2.5)
        self.assertEqual(overall["success_rate"], 100.0)

        # Check game stats
        self.assertEqual(len(stats["game_stats"]), 1)

    def test_comprehensive_report(self):
        """Test comprehensive report"""
        service = StatsService(self.team_a)
        report = service.get_comprehensive_report()

        self.assertEqual(report["team"], "Team A")
        self.assertIsNone(report["game_range"])

        # Check that all stats are included
        self.assertIn("quarter_stats", report)
        self.assertIn("offensive_set_stats", report)
        self.assertIn("defensive_set_stats", report)
        self.assertIn("pnr_stats", report)
        self.assertIn("sequence_stats", report)
        self.assertIn("offensive_rebound_stats", report)
        self.assertIn("box_out_stats", report)
        self.assertIn("shooting_stats", report)
        self.assertIn("timeout_stats", report)
        self.assertIn("lineup_stats", report)
        self.assertIsNone(report["game_range_stats"])

    def test_comprehensive_report_with_game_range(self):
        """Test comprehensive report with game range"""
        service = StatsService(self.team_a)
        report = service.get_comprehensive_report(game_range=1)

        self.assertEqual(report["team"], "Team A")
        self.assertEqual(report["game_range"], 1)
        self.assertIsNotNone(report["game_range_stats"])


class PlayerStatsServiceTestCase(APITestCase):
    """Test cases for PlayerStatsService"""

    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach",
            email="coach@test.com",
            password="testpass123",
            role=User.Role.COACH,
        )
        self.player = User.objects.create_user(
            username="player",
            email="player@test.com",
            password="testpass123",
            role=User.Role.PLAYER,
        )

        # Create team
        self.team = Team.objects.create(name="Test Team", created_by=self.coach)
        self.team.players.add(self.player)
        self.team.coaches.add(self.coach)

        # Create competition
        self.competition = Competition.objects.create(
            name="Test Competition", season="2024-2025", created_by=self.coach
        )

        # Create game
        self.game = Game.objects.create(
            competition=self.competition,
            home_team=self.team,
            away_team=self.team,
            game_date=timezone.now(),
        )

        # Create possessions
        self.create_test_possessions()

    def create_test_possessions(self):
        """Create test possessions for player stats"""
        # Offensive possession with player
        possession = Possession.objects.create(
            game=self.game,
            team=self.team,
            opponent=self.team,
            quarter=1,
            start_time_in_game="10:00",
            duration_seconds=15,
            outcome=Possession.OutcomeChoices.MADE_2PTS,
            points_scored=2,
            offensive_set=Possession.OffensiveSetChoices.PICK_AND_ROLL,
            pnr_type=Possession.PnRTypeChoices.BALL_SCREEN,
            pnr_result=Possession.PnRResultChoices.SCORER,
            has_paint_touch=True,
            has_kick_out=False,
            has_extra_pass=True,
            number_of_passes=3,
            is_offensive_rebound=False,
            offensive_rebound_count=0,
            defensive_set=Possession.DefensiveSetChoices.MAN_TO_MAN,
            defensive_pnr=Possession.DefensivePnRChoices.SWITCH,
            box_out_count=2,
            offensive_rebounds_allowed=0,
            shoot_time=Possession.ShootTimeChoices.EARLY,
            shoot_quality=Possession.ShootQualityChoices.GOOD,
            time_range=Possession.TimeRangeChoices.EARLY_SHOT_CLOCK,
            after_timeout=False,
            created_by=self.coach,
        )
        possession.players_on_court.add(self.player)

        # Defensive possession with player
        defensive_possession = Possession.objects.create(
            game=self.game,
            team=self.team,
            opponent=self.team,
            quarter=2,
            start_time_in_game="05:30",
            duration_seconds=20,
            outcome=Possession.OutcomeChoices.MISSED_2PTS,
            points_scored=0,
            offensive_set=Possession.OffensiveSetChoices.HANDOFF,
            pnr_type=Possession.PnRTypeChoices.NONE,
            pnr_result=Possession.PnRResultChoices.NONE,
            has_paint_touch=False,
            has_kick_out=True,
            has_extra_pass=False,
            number_of_passes=2,
            is_offensive_rebound=False,
            offensive_rebound_count=0,
            defensive_set=Possession.DefensiveSetChoices.ZONE_2_3,
            defensive_pnr=Possession.DefensivePnRChoices.ICE,
            box_out_count=3,
            offensive_rebounds_allowed=0,
            shoot_time=Possession.ShootTimeChoices.LATE,
            shoot_quality=Possession.ShootQualityChoices.POOR,
            time_range=Possession.TimeRangeChoices.LATE_SHOT_CLOCK,
            after_timeout=True,
            created_by=self.coach,
        )
        defensive_possession.players_on_court.add(self.player)

    def test_player_offensive_stats(self):
        """Test player offensive statistics"""
        service = PlayerStatsService(self.player, self.team)
        stats = service.get_player_offensive_stats()

        # Check overall stats
        overall = stats["overall"]
        self.assertEqual(overall["total_possessions"], 1)
        self.assertEqual(overall["total_points"], 2)
        self.assertEqual(overall["avg_ppp"], 2.0)
        self.assertEqual(overall["success_rate"], 100.0)

        # Check set stats
        self.assertEqual(len(stats["by_set"]), 1)
        set_stat = stats["by_set"][0]
        self.assertEqual(set_stat["offensive_set"], "PICK_AND_ROLL")
        self.assertEqual(set_stat["possessions"], 1)
        self.assertEqual(set_stat["points"], 2)
        self.assertEqual(set_stat["avg_ppp"], 2.0)
        self.assertEqual(set_stat["success_rate"], 100.0)

        # Check PnR stats
        self.assertEqual(len(stats["pnr"]), 1)
        pnr_stat = stats["pnr"][0]
        self.assertEqual(pnr_stat["pnr_type"], "BALL_SCREEN")
        self.assertEqual(pnr_stat["pnr_result"], "SCORER")
        self.assertEqual(pnr_stat["possessions"], 1)
        self.assertEqual(pnr_stat["points"], 2)
        self.assertEqual(pnr_stat["avg_ppp"], 2.0)
        self.assertEqual(pnr_stat["success_rate"], 100.0)

        # Check offensive rebound stats
        oreb = stats["offensive_rebounds"]
        self.assertEqual(oreb["offensive_rebounds"], 0)
        self.assertEqual(oreb["points_after_oreb"], 0)
        self.assertEqual(oreb["avg_points_after_oreb"], 0.0)

    def test_player_defensive_stats(self):
        """Test player defensive statistics"""
        service = PlayerStatsService(self.player, self.team)
        stats = service.get_player_defensive_stats()

        # Check overall stats
        overall = stats["overall"]
        self.assertEqual(overall["total_possessions"], 1)
        self.assertEqual(overall["points_allowed"], 0)
        self.assertEqual(overall["avg_points_allowed"], 0.0)
        self.assertEqual(overall["stops"], 1)
        self.assertEqual(overall["stop_rate"], 100.0)

        # Check set stats
        self.assertEqual(len(stats["by_set"]), 1)
        set_stat = stats["by_set"][0]
        self.assertEqual(set_stat["defensive_set"], "ZONE_2_3")
        self.assertEqual(set_stat["possessions"], 1)
        self.assertEqual(set_stat["points_allowed"], 0)
        self.assertEqual(set_stat["avg_points_allowed"], 0.0)
        self.assertEqual(set_stat["stops"], 1)
        self.assertEqual(set_stat["stop_rate"], 100.0)

        # Check PnR defense stats
        self.assertEqual(len(stats["pnr_defense"]), 1)
        pnr_defense_stat = stats["pnr_defense"][0]
        self.assertEqual(pnr_defense_stat["defensive_pnr"], "ICE")
        self.assertEqual(pnr_defense_stat["possessions"], 1)
        self.assertEqual(pnr_defense_stat["points_allowed"], 0)
        self.assertEqual(pnr_defense_stat["avg_points_allowed"], 0.0)
        self.assertEqual(pnr_defense_stat["stops"], 1)
        self.assertEqual(pnr_defense_stat["stop_rate"], 100.0)

        # Check box out stats
        box_outs = stats["box_outs"]
        self.assertEqual(box_outs["total_box_outs"], 3)
        self.assertEqual(box_outs["avg_box_outs_per_possession"], 3.0)
        self.assertEqual(box_outs["offensive_rebounds_allowed"], 0)


class StatsAPITestCase(APITestCase):
    """Test cases for stats API endpoints"""

    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach",
            email="coach@test.com",
            password="testpass123",
            role=User.Role.COACH,
        )
        self.player = User.objects.create_user(
            username="player",
            email="player@test.com",
            password="testpass123",
            role=User.Role.PLAYER,
        )

        # Create team
        self.team = Team.objects.create(name="Test Team", created_by=self.coach)
        self.team.players.add(self.player)
        self.team.coaches.add(self.coach)

        # Create competition
        self.competition = Competition.objects.create(
            name="Test Competition", season="2024-2025", created_by=self.coach
        )

        # Create game
        self.game = Game.objects.create(
            competition=self.competition,
            home_team=self.team,
            away_team=self.team,
            game_date=timezone.now(),
        )

        # Create possession
        self.possession = Possession.objects.create(
            game=self.game,
            team=self.team,
            opponent=self.team,
            quarter=1,
            start_time_in_game="10:00",
            duration_seconds=15,
            outcome=Possession.OutcomeChoices.MADE_2PTS,
            points_scored=2,
            offensive_set=Possession.OffensiveSetChoices.PICK_AND_ROLL,
            created_by=self.coach,
        )
        self.possession.players_on_court.add(self.player)

    def test_quarter_stats_endpoint(self):
        """Test quarter stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-quarter-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertTrue(data["offensive"])
        self.assertEqual(len(data["quarter_stats"]), 1)

    def test_offensive_set_stats_endpoint(self):
        """Test offensive set stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-offensive-set-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertEqual(len(data["offensive_set_stats"]), 1)

    def test_defensive_set_stats_endpoint(self):
        """Test defensive set stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-defensive-set-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertEqual(
            len(data["defensive_set_stats"]), 0
        )  # No defensive possessions for this team

    def test_pnr_stats_endpoint(self):
        """Test PnR stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-pnr-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertTrue(data["offensive"])
        self.assertEqual(len(data["pnr_stats"]), 1)  # One PnR possession

    def test_sequence_stats_endpoint(self):
        """Test sequence stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-sequence-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIn("paint_touch", data)
        self.assertIn("kick_out", data)
        self.assertIn("extra_pass", data)
        self.assertIn("pass_distribution", data)

    def test_offensive_rebound_stats_endpoint(self):
        """Test offensive rebound stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-offensive-rebound-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIn("overall_stats", data)
        self.assertIn("oreb_count_distribution", data)
        self.assertIn("player_stats", data)

    def test_box_out_stats_endpoint(self):
        """Test box out stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-box-out-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIn("overall_stats", data)
        self.assertIn("box_out_effectiveness", data)

    def test_shooting_stats_endpoint(self):
        """Test shooting stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-shooting-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIn("shoot_time_stats", data)
        self.assertIn("shoot_quality_stats", data)
        self.assertIn("time_range_stats", data)

    def test_timeout_stats_endpoint(self):
        """Test timeout stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-timeout-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIn("after_timeout", data)
        self.assertIn("regular_possessions", data)

    def test_lineup_stats_endpoint(self):
        """Test lineup stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-lineup-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertEqual(data["min_possessions"], 10)
        self.assertIn("offensive_lineups", data)
        self.assertIn("defensive_lineups", data)

    def test_game_range_stats_endpoint(self):
        """Test game range stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-game-range-stats")

        response = self.client.get(url, {"team_id": self.team.id, "game_count": 1})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertEqual(data["game_count"], 1)
        self.assertIn("overall_stats", data)
        self.assertIn("game_stats", data)

    def test_comprehensive_report_endpoint(self):
        """Test comprehensive report endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-comprehensive-report")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertIsNone(data["game_range"])
        self.assertIn("quarter_stats", data)
        self.assertIn("offensive_set_stats", data)
        self.assertIn("defensive_set_stats", data)
        self.assertIn("pnr_stats", data)
        self.assertIn("sequence_stats", data)
        self.assertIn("offensive_rebound_stats", data)
        self.assertIn("box_out_stats", data)
        self.assertIn("shooting_stats", data)
        self.assertIn("timeout_stats", data)
        self.assertIn("lineup_stats", data)

    def test_player_stats_endpoint(self):
        """Test player stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-player-stats")

        response = self.client.get(
            url, {"team_id": self.team.id, "player_id": self.player.id}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertIn("player", data)
        self.assertIn("offensive_stats", data)
        self.assertIn("defensive_stats", data)

        player_data = data["player"]
        self.assertEqual(player_data["id"], self.player.id)
        self.assertEqual(player_data["username"], "player")

    def test_outcome_stats_endpoint(self):
        """Test outcome stats endpoint"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-outcome-stats")

        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["team"], "Test Team")
        self.assertTrue(data["offensive"])
        self.assertIn("outcome_stats", data)

    def test_stats_endpoints_require_team_id(self):
        """Test that stats endpoints require team_id parameter"""
        self.client.force_authenticate(user=self.coach)

        endpoints = [
            "possession-quarter-stats",
            "possession-offensive-set-stats",
            "possession-defensive-set-stats",
            "possession-pnr-stats",
            "possession-sequence-stats",
            "possession-offensive-rebound-stats",
            "possession-box-out-stats",
            "possession-shooting-stats",
            "possession-timeout-stats",
            "possession-lineup-stats",
            "possession-game-range-stats",
            "possession-comprehensive-report",
            "possession-outcome-stats",
        ]

        for endpoint in endpoints:
            url = reverse(endpoint)
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
            self.assertIn("team_id parameter is required", response.data["error"])

    def test_player_stats_endpoint_requires_player_id(self):
        """Test that player stats endpoint requires both team_id and player_id"""
        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-player-stats")

        # Test without player_id
        response = self.client.get(url, {"team_id": self.team.id})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn(
            "team_id and player_id parameters are required", response.data["error"]
        )

        # Test without team_id
        response = self.client.get(url, {"player_id": self.player.id})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn(
            "team_id and player_id parameters are required", response.data["error"]
        )

    def test_stats_endpoints_require_authentication(self):
        """Test that stats endpoints require authentication"""
        endpoints = [
            "possession-quarter-stats",
            "possession-offensive-set-stats",
            "possession-defensive-set-stats",
            "possession-pnr-stats",
            "possession-sequence-stats",
            "possession-offensive-rebound-stats",
            "possession-box-out-stats",
            "possession-shooting-stats",
            "possession-timeout-stats",
            "possession-lineup-stats",
            "possession-game-range-stats",
            "possession-comprehensive-report",
            "possession-player-stats",
            "possession-outcome-stats",
        ]

        for endpoint in endpoints:
            url = reverse(endpoint)
            response = self.client.get(url, {"team_id": self.team.id})
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_stats_endpoints_require_team_access(self):
        """Test that stats endpoints require team access"""
        # Create another team that the coach doesn't have access to
        other_team = Team.objects.create(name="Other Team", created_by=self.player)

        self.client.force_authenticate(user=self.coach)

        endpoints = [
            "possession-quarter-stats",
            "possession-offensive-set-stats",
            "possession-defensive-set-stats",
            "possession-pnr-stats",
            "possession-sequence-stats",
            "possession-offensive-rebound-stats",
            "possession-box-out-stats",
            "possession-shooting-stats",
            "possession-timeout-stats",
            "possession-lineup-stats",
            "possession-game-range-stats",
            "possession-comprehensive-report",
            "possession-outcome-stats",
        ]

        for endpoint in endpoints:
            url = reverse(endpoint)
            response = self.client.get(url, {"team_id": other_team.id})
            self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
            self.assertIn("Team not found or access denied", response.data["error"])

    def test_player_stats_endpoint_requires_player_access(self):
        """Test that player stats endpoint requires player access"""
        # Create another player that's not on the team
        other_player = User.objects.create_user(
            username="other_player",
            email="other@test.com",
            password="testpass123",
            role=User.Role.PLAYER,
        )

        self.client.force_authenticate(user=self.coach)
        url = reverse("possession-player-stats")

        response = self.client.get(
            url, {"team_id": self.team.id, "player_id": other_player.id}
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn(
            "Team or player not found or access denied", response.data["error"]
        )
