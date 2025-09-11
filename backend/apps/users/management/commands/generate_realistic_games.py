# backend/apps/users/management/commands/generate_realistic_games.py

import datetime
import json
import os
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction
from decimal import Decimal

# Import all necessary models
from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.games.models import Game
from apps.plays.models import PlayCategory, PlayDefinition
from apps.events.models import CalendarEvent
from apps.possessions.models import Possession

User = get_user_model()


class RealisticGameGenerator:
    """Generates realistic basketball games with proper possession-based scoring."""

    def __init__(self, plays_by_category):
        self.plays_by_category = plays_by_category

        # Basketball constants
        self.POSSESSIONS_PER_QUARTER = (18, 25)  # Range of possessions per quarter
        self.QUARTER_SCORE_RANGE = (15, 30)  # Points per quarter range
        self.SCORE_PROBABILITIES = {
            "2PTS": 0.45,  # 45% chance of 2-point field goal
            "3PTS": 0.25,  # 25% chance of 3-point field goal
            "FT": 0.20,  # 20% chance of free throws
            "0PTS": 0.10,  # 10% chance of no points (turnover, missed shot)
        }

        # Possession outcome probabilities (using actual model choices)
        self.POSSESSION_OUTCOMES = {
            "MADE_2PTS": 0.45,  # Made 2-point field goal
            "MADE_3PTS": 0.25,  # Made 3-point field goal
            "MADE_FTS": 0.20,  # Made free throws
            "MISSED_2PTS": 0.05,  # Missed 2-point shot
            "MISSED_3PTS": 0.03,  # Missed 3-point shot
            "TURNOVER": 0.02,  # Turnover
        }

        # Per-game team rosters and on-court lineups
        # key: (game_id, team_id) -> List[User]
        self._game_team_roster = {}
        # key: (game_id, team_id, quarter) -> List[User]
        self._on_court_players = {}

    def _get_or_create_roster(self, game, team):
        """Get the list of players from the game roster"""
        game_roster = self._get_or_create_game_roster(game, team)
        return list(game_roster.players.all())

    def _get_or_create_game_roster(self, game, team):
        """Get or create a GameRoster for a team in a specific game"""
        from apps.games.models import GameRoster

        # Check if roster already exists
        existing_roster = GameRoster.objects.filter(game=game, team=team).first()
        if existing_roster:
            return existing_roster

        # Create new roster
        players = list(team.players.all())
        if len(players) >= 12:
            # Randomly select 12 players
            selected_players = random.sample(players, 12)
        else:
            # Use all available players
            selected_players = players

        # Create the roster
        roster = GameRoster.objects.create(game=game, team=team)
        roster.players.set(selected_players)

        # Select 5 players as starting five
        starting_five = (
            selected_players[:5] if len(selected_players) >= 5 else selected_players
        )
        roster.starting_five.set(starting_five)

        return roster

    def _get_or_init_on_court(self, game, team, quarter):
        key = (game.id, team.id, quarter)
        if key not in self._on_court_players:
            # Get the game roster and use its starting five
            game_roster = self._get_or_create_game_roster(game, team)
            starting_five = list(game_roster.starting_five.all())
            self._on_court_players[key] = starting_five[:]
            return self._on_court_players[key]
        # Occasionally make a substitution
        current = self._on_court_players[key]
        if random.random() < 0.25 and len(current) >= 1:
            game_roster = self._get_or_create_game_roster(game, team)
            bench = [p for p in game_roster.players.all() if p not in current]
            if bench:
                out_p = random.choice(current)
                in_p = random.choice(bench)
                current[current.index(out_p)] = in_p
        return current

    def generate_quarter_score_target(self):
        """Generate a realistic target score for a quarter (15-30 points)."""
        return random.randint(*self.QUARTER_SCORE_RANGE)

    def generate_possessions_for_quarter(
        self, target_score, team, opponent, game, quarter
    ):
        """Generate possessions that realistically reach the target score."""
        possessions = []
        current_score = 0
        possession_count = random.randint(*self.POSSESSIONS_PER_QUARTER)

        # Calculate how many possessions we need to reach target
        remaining_possessions = possession_count
        remaining_score = target_score - current_score

        for i in range(possession_count):
            # Determine if this possession should score based on remaining needs
            should_score = False
            if remaining_score > 0 and remaining_possessions > 0:
                # Higher probability of scoring if we need more points
                score_probability = min(0.8, remaining_score / remaining_possessions)
                should_score = random.random() < score_probability

            # Generate possession outcome
            if should_score and remaining_score > 0:
                # Determine scoring type based on remaining score and possessions
                if remaining_score >= 3 and random.random() < 0.3:
                    outcome = "MADE_3PTS"
                    points = 3
                elif remaining_score >= 2:
                    outcome = "MADE_2PTS"
                    points = 2
                else:
                    outcome = "MADE_FTS"
                    points = min(remaining_score, 2)  # Max 2 points for free throws

                current_score += points
                remaining_score -= points
            else:
                # Choose from non-scoring outcomes
                non_scoring_outcomes = ["MISSED_2PTS", "MISSED_3PTS", "TURNOVER"]
                outcome = random.choice(non_scoring_outcomes)
                points = 0

            # Create possession
            possession = self.create_realistic_possession(
                game=game,
                team=team,
                opponent=opponent,
                quarter=quarter,
                outcome=outcome,
                points_scored=points,
                possession_number=i + 1,
            )

            possessions.append(possession)
            remaining_possessions -= 1

            # Stop if we've reached our target score
            if current_score >= target_score:
                break

        return possessions, current_score

    def create_realistic_possession(
        self, game, team, opponent, quarter, outcome, points_scored, possession_number
    ):
        """Create a realistic possession with proper sequences and data."""

        # Generate realistic time data based on Brazilian league (10-minute quarters)
        # Use time remaining in quarter (MM:SS), e.g., 09:58 .. 00:01
        total_q_seconds = 10 * 60
        elapsed = random.randint(0, total_q_seconds - 1)
        remaining = total_q_seconds - elapsed
        start_minute = remaining // 60
        start_second = remaining % 60
        duration = random.randint(8, 24)  # 8-24 seconds per possession

        # Generate realistic sequences based on outcome
        if outcome in ["MADE_2PTS", "MADE_3PTS", "MADE_FTS"]:
            offensive_sequence = self.generate_scoring_offensive_sequence()
            defensive_sequence = ""
        else:
            offensive_sequence = self.generate_missed_offensive_sequence()
            defensive_sequence = self.generate_defensive_sequence()

        # Create possession object
        # Randomize offensive rebound count when applicable
        off_reb = 0
        if outcome in ["MISSED_2PTS", "MISSED_3PTS"] and random.random() < 0.25:
            off_reb = random.randint(1, 2)

        # Pick scorer/assistant/defense based on outcome
        # Use 12-man roster for all attributions
        team_roster = self._get_or_create_roster(game, team)
        scorer = None
        assisted_by = None
        blocked_by = None
        stolen_by = None
        fouled_by = None
        if team_roster:
            opponent_roster = (
                self._get_or_create_roster(game, opponent) if opponent else []
            )
            # Shooter attribution on all FG outcomes (made or missed)
            if outcome in [
                "MADE_2PTS",
                "MISSED_2PTS",
                "MADE_3PTS",
                "MISSED_3PTS",
                "MADE_FTS",
                "MISSED_FTS",
            ]:
                scorer = random.choice(team_roster)
                # Assisted probability higher on makes; slightly lower on misses
                if outcome in ["MADE_2PTS", "MADE_3PTS"] and random.random() < 0.5:
                    assisted_by = random.choice(team_roster)
                elif (
                    outcome in ["MISSED_2PTS", "MISSED_3PTS"] and random.random() < 0.15
                ):
                    assisted_by = random.choice(team_roster)
                # Fouls mainly occur on FT trips
                if outcome in ["MADE_FTS", "MISSED_FTS"] and opponent_roster:
                    fouled_by = random.choice(opponent_roster)
            # Blocks on a subset of missed FG
            if (
                outcome in ["MISSED_2PTS", "MISSED_3PTS"]
                and opponent_roster
                and random.random() < 0.12
            ):
                blocked_by = random.choice(opponent_roster)
            # Turnover attribution: committer and potential steal
            if outcome == "TURNOVER":
                scorer = random.choice(team_roster)  # turnover committer
                if opponent_roster and random.random() < 0.4:
                    stolen_by = random.choice(opponent_roster)

        # Get or create GameRoster instances for this game
        home_roster = self._get_or_create_game_roster(game, team)
        away_roster = (
            self._get_or_create_game_roster(game, opponent) if opponent else None
        )

        possession = Possession.objects.create(
            game=game,
            team=home_roster,
            opponent=away_roster,
            quarter=quarter,
            start_time_in_game=f"{start_minute:02}:{start_second:02}",
            duration_seconds=duration,
            outcome=outcome,
            offensive_sequence=offensive_sequence,
            defensive_sequence=defensive_sequence,
            points_scored=points_scored,
            created_by=game.created_by,
            scorer=scorer,
            assisted_by=assisted_by,
            blocked_by=blocked_by,
            stolen_by=stolen_by,
            fouled_by=fouled_by,
        )

        # Assign on-court players for BOTH teams and offensive rebounders (M2M)
        try:
            # Offensive team lineup
            offense_five = self._get_or_init_on_court(game, team, quarter)
            if offense_five:
                possession.players_on_court.set(offense_five)

            # Defensive team lineup (opponent)
            if opponent:
                defense_five = self._get_or_init_on_court(game, opponent, quarter)
                if defense_five:
                    possession.defensive_players_on_court.set(defense_five)

            # Offensive rebounders
            if off_reb > 0 and offense_five:
                rebounders = random.sample(
                    offense_five, k=min(off_reb, len(offense_five))
                )
                possession.offensive_rebound_players.set(rebounders)
        except Exception:
            pass

        return possession

    def generate_scoring_offensive_sequence(self):
        """Generate offensive sequence for scoring possessions."""
        sequence_parts = []

        # Add offensive set
        if "Offense" in self.plays_by_category:
            offensive_sets = [
                play
                for play in self.plays_by_category["Offense"]
                if play.startswith("Set")
            ]
            if offensive_sets:
                sequence_parts.append(random.choice(offensive_sets))

        # Add half court action
        if "Offense Half Court" in self.plays_by_category:
            half_court_actions = self.plays_by_category["Offense Half Court"]
            if half_court_actions:
                sequence_parts.append(random.choice(half_court_actions))

        # Add shot type
        if "Outcome" in self.plays_by_category:
            shot_types = [
                play
                for play in self.plays_by_category["Outcome"]
                if any(
                    keyword in play.lower()
                    for keyword in ["2pt", "3pt", "lay up", "shot"]
                )
            ]
            if shot_types:
                sequence_parts.append(random.choice(shot_types))

        # Add made result
        if "Outcome" in self.plays_by_category:
            made_results = [
                play
                for play in self.plays_by_category["Outcome"]
                if "made" in play.lower()
            ]
            if made_results:
                sequence_parts.append(random.choice(made_results))

        return " / ".join(sequence_parts) if sequence_parts else "Scoring Play"

    def generate_missed_offensive_sequence(self):
        """Generate offensive sequence for missed possessions."""
        sequence_parts = []

        # Add offensive set
        if "Offense" in self.plays_by_category:
            offensive_sets = [
                play
                for play in self.plays_by_category["Offense"]
                if play.startswith("Set")
            ]
            if offensive_sets:
                sequence_parts.append(random.choice(offensive_sets))

        # Add missed shot
        if "Outcome" in self.plays_by_category:
            missed_results = [
                play
                for play in self.plays_by_category["Outcome"]
                if "miss" in play.lower()
            ]
            if missed_results:
                sequence_parts.append(random.choice(missed_results))

        return " / ".join(sequence_parts) if sequence_parts else "Missed Play"

    def generate_defensive_sequence(self):
        """Generate defensive sequence."""
        sequence_parts = []

        # Add defensive formation
        if "Defense" in self.plays_by_category:
            defensive_formations = [
                play
                for play in self.plays_by_category["Defense"]
                if any(
                    keyword in play.lower()
                    for keyword in ["2-3", "3-2", "1-3-1", "1-2-2", "zone"]
                )
            ]
            if defensive_formations:
                sequence_parts.append(random.choice(defensive_formations))

        # Add defensive action
        if "Defense" in self.plays_by_category:
            defensive_actions = [
                play
                for play in self.plays_by_category["Defense"]
                if any(
                    keyword in play.lower()
                    for keyword in ["switch", "drop", "hedge", "trap"]
                )
            ]
            if defensive_actions:
                sequence_parts.append(random.choice(defensive_actions))

        return " / ".join(sequence_parts) if sequence_parts else "Defensive Play"

    def get_random_offensive_set(self):
        """Get random offensive set from choices."""
        choices = [choice[0] for choice in Possession.OffensiveSetChoices.choices]
        return random.choice(choices)

    def get_random_pnr_type(self):
        """Get random PnR type from choices."""
        choices = [choice[0] for choice in Possession.PnRTypeChoices.choices]
        return random.choice(choices)

    def get_random_pnr_result(self):
        """Get random PnR result from choices."""
        choices = [choice[0] for choice in Possession.PnRResultChoices.choices]
        return random.choice(choices)

    def get_random_defensive_set(self):
        """Get random defensive set from choices."""
        choices = [choice[0] for choice in Possession.DefensiveSetChoices.choices]
        return random.choice(choices)

    def get_random_defensive_pnr(self):
        """Get random defensive PnR from choices."""
        choices = [choice[0] for choice in Possession.DefensivePnRChoices.choices]
        return random.choice(choices)

    def get_random_shoot_quality(self):
        """Get random shoot quality from choices."""
        choices = [choice[0] for choice in Possession.ShootQualityChoices.choices]
        return random.choice(choices)

    def get_random_time_range(self):
        """Get random time range from choices."""
        choices = [choice[0] for choice in Possession.TimeRangeChoices.choices]
        return random.choice(choices)


class Command(BaseCommand):
    help = "Generates realistic basketball games with possession-based scoring and realistic quarter scores."

    def add_arguments(self, parser):
        parser.add_argument(
            "--games",
            type=int,
            default=20,
            help="Number of games to generate (default: 20)",
        )
        parser.add_argument(
            "--fortaleza-games",
            type=int,
            default=10,
            help="Number of Fortaleza games to generate (default: 10)",
        )
        parser.add_argument(
            "--clear-existing",
            action="store_true",
            help="Clear existing games and possessions before generating new ones",
        )

    def load_play_definitions(self):
        """Load play definitions from JSON file."""
        json_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "..",
            "data",
            "initial_play_definitions.json",
        )

        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        plays_by_category = {}
        for category_data in data:
            category_name = category_data["category"]
            plays_by_category[category_name] = []
            for play_data in category_data["plays"]:
                plays_by_category[category_name].append(play_data["name"])

        return plays_by_category

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(
            self.style.SUCCESS("--- Starting Realistic Game Generation ---")
        )

        num_games = options["games"]
        num_fortaleza_games = options["fortaleza_games"]
        clear_existing = options["clear_existing"]

        # Clear existing data if requested
        if clear_existing:
            self.stdout.write("Clearing existing games and possessions...")
            Possession.objects.all().delete()
            Game.objects.all().delete()
            self.stdout.write("Existing data cleared.")

        # Get superuser
        superuser = User.objects.filter(is_superuser=True).order_by("pk").first()
        if not superuser:
            self.stdout.write(
                self.style.ERROR(
                    'FATAL: No superuser found. Please create one first with "python manage.py createsuperuser".'
                )
            )
            return

        # Get or create competition
        nbb_competition, _ = Competition.objects.get_or_create(
            name="Novo Basquete Brasil",
            defaults={"season": "2025-2026", "created_by": superuser},
        )

        # Get teams
        teams = list(Team.objects.all())
        if not teams:
            self.stdout.write(
                self.style.ERROR(
                    'No teams found. Please run "python manage.py populate_db" first to create teams.'
                )
            )
            return

        # Find Fortaleza team
        fortaleza_team = None
        for team in teams:
            if "Fortaleza" in team.name:
                fortaleza_team = team
                break

        if not fortaleza_team:
            self.stdout.write(
                self.style.WARNING(
                    "Fortaleza team not found. Will generate games with random teams."
                )
            )

        # Load play definitions
        self.stdout.write("Loading play definitions...")
        plays_by_category = self.load_play_definitions()

        # Initialize game generator
        game_generator = RealisticGameGenerator(plays_by_category)

        # Generate games
        self.stdout.write(f"Generating {num_games} realistic games...")

        games_created = 0

        # Generate Fortaleza games first
        if fortaleza_team:
            self.stdout.write(f"Generating {num_fortaleza_games} Fortaleza games...")
            for i in range(num_fortaleza_games):
                # Fortaleza plays against different teams
                opponent = random.choice(
                    [team for team in teams if team != fortaleza_team]
                )

                # Randomly decide if Fortaleza is home or away
                if random.choice([True, False]):
                    home_team = fortaleza_team
                    away_team = opponent
                else:
                    home_team = opponent
                    away_team = fortaleza_team

                game = self.generate_realistic_game(
                    game_generator,
                    home_team,
                    away_team,
                    nbb_competition,
                    superuser,
                    i + 1,
                )
                games_created += 1

                self.stdout.write(
                    f"  - Created Fortaleza game {i+1}: {home_team.name} vs {away_team.name} "
                    f"({game.home_team_score}-{game.away_team_score})"
                )

        # Generate remaining games
        remaining_games = num_games - num_fortaleza_games
        if remaining_games > 0:
            self.stdout.write(f"Generating {remaining_games} additional games...")
            for i in range(remaining_games):
                # Random teams
                home_team = random.choice(teams)
                away_team = random.choice([team for team in teams if team != home_team])

                game = self.generate_realistic_game(
                    game_generator,
                    home_team,
                    away_team,
                    nbb_competition,
                    superuser,
                    num_fortaleza_games + i + 1,
                )
                games_created += 1

                self.stdout.write(
                    f"  - Created game {num_fortaleza_games + i+1}: {home_team.name} vs {away_team.name} "
                    f"({game.home_team_score}-{game.away_team_score})"
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"--- Realistic Game Generation Complete! ---\n"
                f"Created {games_created} games with realistic scoring and possessions."
            )
        )

    def generate_realistic_game(
        self, game_generator, home_team, away_team, competition, created_by, game_number
    ):
        """Generate a single realistic game with proper quarter scoring."""

        # Random game date in the last 6 months
        game_date = datetime.datetime.now() - datetime.timedelta(
            days=random.randint(1, 180)
        )
        # Make timezone-aware
        from django.utils import timezone
        if timezone.is_naive(game_date):
            game_date = timezone.make_aware(game_date)

        # Generate quarter scores
        home_quarter_scores = []
        away_quarter_scores = []
        home_total = 0
        away_total = 0

        # Generate scores for each quarter
        for quarter in range(1, 5):
            home_quarter_score = game_generator.generate_quarter_score_target()
            away_quarter_score = game_generator.generate_quarter_score_target()

            home_quarter_scores.append(home_quarter_score)
            away_quarter_scores.append(away_quarter_score)
            home_total += home_quarter_score
            away_total += away_quarter_score

        # Create game
        game = Game.objects.create(
            competition=competition,
            home_team=home_team,
            away_team=away_team,
            game_date=game_date,
            home_team_score=home_total,
            away_team_score=away_total,
            created_by=created_by,
        )

        # Generate possessions for each quarter
        all_possessions = []

        for quarter in range(1, 5):
            # Generate possessions for home team in this quarter
            home_possessions, home_actual_score = (
                game_generator.generate_possessions_for_quarter(
                    home_quarter_scores[quarter - 1],
                    home_team,
                    away_team,
                    game,
                    quarter,
                )
            )

            # Generate possessions for away team in this quarter
            away_possessions, away_actual_score = (
                game_generator.generate_possessions_for_quarter(
                    away_quarter_scores[quarter - 1],
                    away_team,
                    home_team,
                    game,
                    quarter,
                )
            )

            all_possessions.extend(home_possessions)
            all_possessions.extend(away_possessions)

            # Log quarter scores
            self.stdout.write(
                f"    Q{quarter}: {home_team.name} {home_actual_score} - "
                f"{away_team.name} {away_actual_score}"
            )

        # Bulk create all possessions
        Possession.objects.bulk_create(all_possessions)

        self.stdout.write(
            f"    Total: {home_team.name} {home_total} - {away_team.name} {away_total} "
            f"({len(all_possessions)} possessions)"
        )

        return game
