# backend/apps/users/management/commands/add_realistic_possessions.py

import datetime
import json
import os
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction

# Import all necessary models
from apps.games.models import Game
from apps.plays.models import PlayCategory, PlayDefinition
from apps.possessions.models import Possession

User = get_user_model()


class RealisticPossessionGenerator:
    """Generates realistic possessions for existing games."""

    def __init__(self, plays_by_category):
        self.plays_by_category = plays_by_category

        # Basketball constants
        self.POSSESSIONS_PER_QUARTER = (18, 25)  # Range of possessions per quarter
        self.QUARTER_SCORE_RANGE = (15, 30)  # Points per quarter range

    def generate_possessions_for_game(self, game):
        """Generate realistic possessions for an existing game."""
        all_possessions = []

        # Get existing possessions count per quarter
        existing_possessions = Possession.objects.filter(game=game)

        # If game already has possessions, skip
        if existing_possessions.exists():
            return []

        # Generate quarter scores based on final game score
        home_quarter_scores = self.distribute_score_across_quarters(
            game.home_team_score
        )
        away_quarter_scores = self.distribute_score_across_quarters(
            game.away_team_score
        )

        # Generate possessions for each quarter
        for quarter in range(1, 5):
            # Generate possessions for home team in this quarter
            home_possessions = self.generate_possessions_for_quarter(
                home_quarter_scores[quarter - 1],
                game.home_team,
                game.away_team,
                game,
                quarter,
            )

            # Generate possessions for away team in this quarter
            away_possessions = self.generate_possessions_for_quarter(
                away_quarter_scores[quarter - 1],
                game.away_team,
                game.home_team,
                game,
                quarter,
            )

            all_possessions.extend(home_possessions)
            all_possessions.extend(away_possessions)

        return all_possessions

    def distribute_score_across_quarters(self, total_score):
        """Distribute total score across 4 quarters realistically."""
        # Start with base scores
        quarter_scores = [random.randint(15, 30) for _ in range(4)]

        # Adjust to match total score
        current_total = sum(quarter_scores)
        target_total = total_score

        # If we're too high, reduce some quarters
        if current_total > target_total:
            while current_total > target_total and any(
                score > 15 for score in quarter_scores
            ):
                for i in range(4):
                    if quarter_scores[i] > 15 and current_total > target_total:
                        quarter_scores[i] -= 1
                        current_total -= 1

        # If we're too low, increase some quarters
        elif current_total < target_total:
            while current_total < target_total and any(
                score < 30 for score in quarter_scores
            ):
                for i in range(4):
                    if quarter_scores[i] < 30 and current_total < target_total:
                        quarter_scores[i] += 1
                        current_total += 1

        return quarter_scores

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

        return possessions

    def create_realistic_possession(
        self, game, team, opponent, quarter, outcome, points_scored, possession_number
    ):
        """Create a realistic possession with proper sequences and data."""

        # Generate realistic time data based on Brazilian league (10-minute quarters)
        total_q_seconds = 10 * 60
        elapsed = random.randint(0, total_q_seconds - 1)
        final_remaining = total_q_seconds - elapsed
        start_minute = final_remaining // 60
        start_second = final_remaining % 60
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
        if outcome in ["MADE_2PTS", "MISSED_2PTS", "MADE_3PTS", "MISSED_3PTS"]:
            # Assign ORB only on missed FG sequences
            if outcome in ["MISSED_2PTS", "MISSED_3PTS"] and random.random() < 0.25:
                off_reb = random.randint(1, 2)

        possession = Possession(
            game=game,
            team=team,
            opponent=opponent,
            quarter=quarter,
            start_time_in_game=f"{start_minute:02}:{start_second:02}",
            duration_seconds=duration,
            outcome=outcome,
            points_scored=points_scored,
            # Offensive data
            offensive_set=self.get_random_offensive_set(),
            pnr_type=self.get_random_pnr_type(),
            pnr_result=self.get_random_pnr_result(),
            has_paint_touch=random.choice([True, False]),
            has_kick_out=random.choice([True, False]),
            has_extra_pass=random.choice([True, False]),
            number_of_passes=random.randint(1, 4),
            is_offensive_rebound=off_reb > 0,
            offensive_rebound_count=off_reb,
            # Defensive data
            defensive_set=self.get_random_defensive_set(),
            defensive_pnr=self.get_random_defensive_pnr(),
            box_out_count=random.randint(0, 3),
            offensive_rebounds_allowed=0,
            # Shot data
            shoot_time=random.randint(5, duration),
            shoot_quality=self.get_random_shoot_quality(),
            time_range=self.get_random_time_range(),
            # Other
            after_timeout=random.random() < 0.1,  # 10% chance of being after timeout
            offensive_sequence=offensive_sequence,
            defensive_sequence=defensive_sequence,
            notes=f"Generated possession {possession_number}",
            created_by=game.created_by,
        )

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
    help = "Adds realistic possessions to existing games with proper scoring logic."

    def add_arguments(self, parser):
        parser.add_argument(
            "--game-id",
            type=int,
            help="Specific game ID to add possessions to (optional)",
        )
        parser.add_argument(
            "--all-games",
            action="store_true",
            help="Add possessions to all games that don't have them",
        )
        parser.add_argument(
            "--clear-existing",
            action="store_true",
            help="Clear existing possessions before adding new ones",
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
            self.style.SUCCESS("--- Adding Realistic Possessions to Games ---")
        )

        game_id = options.get("game_id")
        all_games = options.get("all_games")
        clear_existing = options.get("clear_existing")

        # Load play definitions
        self.stdout.write("Loading play definitions...")
        plays_by_category = self.load_play_definitions()

        # Initialize possession generator
        possession_generator = RealisticPossessionGenerator(plays_by_category)

        if game_id:
            # Add possessions to specific game
            try:
                game = Game.objects.get(id=game_id)
                self.stdout.write(
                    f"Adding possessions to game: {game.home_team.name} vs {game.away_team.name}"
                )

                if clear_existing:
                    Possession.objects.filter(game=game).delete()
                    self.stdout.write("Cleared existing possessions.")

                possessions = possession_generator.generate_possessions_for_game(game)
                if possessions:
                    Possession.objects.bulk_create(possessions)
                    self.stdout.write(
                        f"Added {len(possessions)} possessions to game {game_id}"
                    )
                else:
                    self.stdout.write(
                        "Game already has possessions or no possessions generated."
                    )

            except Game.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f"Game with ID {game_id} not found.")
                )
                return

        elif all_games:
            # Add possessions to all games
            games = Game.objects.all()
            self.stdout.write(f"Processing {games.count()} games...")

            total_possessions_added = 0
            games_processed = 0

            for game in games:
                if clear_existing:
                    Possession.objects.filter(game=game).delete()

                possessions = possession_generator.generate_possessions_for_game(game)
                if possessions:
                    Possession.objects.bulk_create(possessions)
                    total_possessions_added += len(possessions)
                    games_processed += 1

                    self.stdout.write(
                        f"  - Game {game.id}: {game.home_team.name} vs {game.away_team.name} "
                        f"({game.home_team_score}-{game.away_team_score}) - "
                        f"Added {len(possessions)} possessions"
                    )

            self.stdout.write(
                self.style.SUCCESS(
                    f"--- Complete! ---\n"
                    f"Processed {games_processed} games\n"
                    f"Added {total_possessions_added} total possessions"
                )
            )

        else:
            self.stdout.write(
                self.style.WARNING(
                    "Please specify either --game-id <id> or --all-games to add possessions."
                )
            )
