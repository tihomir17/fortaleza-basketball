from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.games.models import Game, GameRoster
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from apps.users.models import User
from datetime import date, time, timedelta, datetime
import random
import math

User = get_user_model()


class Command(BaseCommand):
    help = "Populate database with ultra-realistic Brazilian basketball data including storylines"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear-existing",
            action="store_true",
            help="Clear existing data before populating",
        )
        parser.add_argument(
            "--seasons",
            type=int,
            default=2,
            help="Number of seasons to generate (default: 2 for 2024-2025 and 2025-2026)",
        )

    def handle(self, *args, **options):
        if options["clear_existing"]:
            self.stdout.write("Clearing existing data...")

            # Clear in proper order to avoid foreign key constraints
            Possession.objects.all().delete()
            self.stdout.write("✓ Possessions cleared")

            GameRoster.objects.all().delete()
            self.stdout.write("✓ Game rosters cleared")

            Game.objects.all().delete()
            self.stdout.write("✓ Games cleared")

            # Clear team players first
            for team in Team.objects.all():
                team.players.clear()
            self.stdout.write("✓ Team players cleared")

            Team.objects.all().delete()
            self.stdout.write("✓ Teams cleared")

            User.objects.filter(is_superuser=False).delete()
            self.stdout.write("✓ Non-admin users cleared")

            self.stdout.write("All existing data cleared successfully")
        else:
            self.stdout.write("Checking for existing data...")
            existing_teams = Team.objects.count()
            existing_games = Game.objects.count()
            if existing_teams > 0 or existing_games > 0:
                self.stdout.write(
                    self.style.WARNING(
                        f"Found existing data: {existing_teams} teams, {existing_games} games. "
                        "Use --clear-existing to remove all data first."
                    )
                )
                return

        self.stdout.write("Creating admin user...")
        admin_user = self.create_admin_user()

        self.stdout.write("Creating competitions for multiple seasons...")
        competitions = self.create_seasons(admin_user)

        # Verify database is empty
        self.verify_database_empty()

        self.stdout.write("Creating teams with Brazilian basketball characteristics...")
        teams = self.create_realistic_teams(admin_user)

        self.stdout.write(
            "Creating players with realistic Brazilian basketball profiles..."
        )
        self.create_realistic_players(teams, admin_user)

        self.stdout.write("Generating season storylines and rivalries...")
        self.create_storylines(teams)

        for season, competition in competitions.items():
            self.stdout.write(f"Generating season {season}...")
            self.generate_season(teams, competition, admin_user, season)

        self.stdout.write(
            self.style.SUCCESS(
                "Ultra-realistic basketball database populated successfully!"
            )
        )

    def create_admin_user(self):
        """Create an admin user for creating teams and games"""
        admin_user, created = User.objects.get_or_create(
            username="admin",
            defaults={
                "first_name": "Admin",
                "last_name": "User",
                "email": "admin@example.com",
                "is_staff": True,
                "is_superuser": True,
            },
        )
        if created:
            admin_user.set_password("password123")
            admin_user.save()
            self.stdout.write("Created admin user: admin")
        else:
            self.stdout.write("Admin user already exists")
        return admin_user

    def verify_database_empty(self):
        """Verify that the database is empty before proceeding"""
        team_count = Team.objects.count()
        user_count = User.objects.filter(is_superuser=False).count()
        game_count = Game.objects.count()
        possession_count = Possession.objects.count()

        if team_count > 0 or user_count > 0 or game_count > 0 or possession_count > 0:
            self.stdout.write(
                self.style.ERROR(
                    f"Database not empty: {team_count} teams, {user_count} users, "
                    f"{game_count} games, {possession_count} possessions. "
                    "Use --clear-existing to clear all data first."
                )
            )
            raise Exception(
                "Database must be empty to proceed. Use --clear-existing flag."
            )

    def create_seasons(self, admin_user):
        """Create competitions for multiple seasons"""
        seasons = {}
        current_year = date.today().year

        for i in range(2):  # 2024-2025 and 2025-2026
            season_year = current_year - 1 + i
            season_name = f"Temporada {season_year}-{season_year + 1}"

            competition, created = Competition.objects.get_or_create(
                name=season_name, defaults={"created_by": admin_user}
            )

            if created:
                self.stdout.write(f"Created competition: {competition.name}")
            else:
                self.stdout.write(f"Using existing competition: {competition.name}")

            seasons[season_year] = competition

        return seasons

    def create_realistic_teams(self, admin_user):
        """Create teams with realistic Brazilian basketball characteristics"""
        teams = []

        # Real Brazilian basketball teams with characteristics
        team_data = [
            {
                "name": "Flamengo Basquete",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.15,
                "fan_base": "large",
                "budget": "high",
            },
            {
                "name": "Franca Basquete",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.12,
                "fan_base": "medium",
                "budget": "medium",
            },
            {
                "name": "São Paulo F.C.",
                "style": "balanced",
                "strength": "balanced",
                "home_court_advantage": 0.10,
                "fan_base": "large",
                "budget": "high",
            },
            {
                "name": "Minas Tênis Clube",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.08,
                "fan_base": "medium",
                "budget": "medium",
            },
            {
                "name": "Pinheiros",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.05,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Bauru Basket",
                "style": "balanced",
                "strength": "balanced",
                "home_court_advantage": 0.06,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Mogi das Cruzes",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.04,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Limeira",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.03,
                "fan_base": "small",
                "budget": "low",
            },
        ]

        for team_info in team_data:
            team, created = Team.objects.get_or_create(
                name=team_info["name"], defaults={"created_by": admin_user}
            )

            if created:
                self.stdout.write(
                    f"Created new team: {team.name} ({team_info['style']} style)"
                )
            else:
                self.stdout.write(f"Using existing team: {team.name}")

            # Store team characteristics for later use (these are not database fields, just for logic)
            team.style = team_info["style"]
            team.strength = team_info["strength"]
            team.home_court_advantage = team_info["home_court_advantage"]
            team.fan_base = team_info["fan_base"]
            team.budget = team_info["budget"]

            teams.append(team)

        return teams

    def create_realistic_players(self, teams, admin_user):
        """Create players with realistic Brazilian basketball profiles"""
        # Brazilian basketball player characteristics
        positions = ["PG", "SG", "SF", "PF", "C"]
        position_weights = [0.2, 0.25, 0.25, 0.2, 0.1]  # More guards and forwards

        for team in teams:
            # Create 20 players per team (12 active + 8 reserves)
            for i in range(20):
                position = random.choices(positions, weights=position_weights)[0]
                player = self.create_realistic_player(team, position, i, admin_user)

                # Add player to team
                team.players.add(player)

            self.stdout.write(f"Created {team.players.count()} players for {team.name}")

    def create_realistic_player(self, team, position, player_index, admin_user):
        """Create a single player with realistic Brazilian basketball characteristics"""
        # Brazilian basketball player names (mix of Brazilian and international)
        first_names = [
            "João",
            "Pedro",
            "Lucas",
            "Gabriel",
            "Rafael",
            "Thiago",
            "Bruno",
            "André",
            "Carlos",
            "Diego",
            "Felipe",
            "Marcelo",
            "Ricardo",
            "Fernando",
            "Alexandre",
            "Marcos",
            "Paulo",
            "Roberto",
            "Daniel",
            "Eduardo",
            "Leonardo",
            "Rodrigo",
            "Anderson",
            "Varejão",
            "Nenê",
            "Barbosa",
            "Splitter",
            "Huertas",
            "Garcia",
        ]

        last_names = [
            "Silva",
            "Santos",
            "Oliveira",
            "Souza",
            "Rodrigues",
            "Ferreira",
            "Almeida",
            "Pereira",
            "Lima",
            "Gomes",
            "Costa",
            "Ribeiro",
            "Carvalho",
            "Alves",
            "Pinto",
            "Cavalcanti",
            "Dias",
            "Castro",
            "Campos",
            "Cardoso",
            "Correia",
            "Cunha",
            "Dantas",
            "Duarte",
            "Farias",
            "Fernandes",
            "Freitas",
            "Gonçalves",
        ]

        # International players (common in Brazilian basketball)
        international_names = [
            "Johnson",
            "Williams",
            "Brown",
            "Jones",
            "Garcia",
            "Miller",
            "Davis",
            "Rodriguez",
            "Martinez",
            "Anderson",
            "Taylor",
            "Thomas",
            "Hernandez",
            "Moore",
            "Martin",
            "Lee",
            "Perez",
            "Thompson",
            "White",
            "Harris",
        ]

        # 70% Brazilian, 30% International
        if random.random() < 0.7:
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
        else:
            first_name = random.choice(international_names)
            last_name = random.choice(international_names)

        username = f"{first_name.lower()}.{last_name.lower()}{player_index + 1 if player_index > 0 else ''}"

        # Create user
        user = User.objects.create_user(
            username=username,
            first_name=first_name,
            last_name=last_name,
            email=f"{username}@{team.name.lower().replace(' ', '').replace('.', '')}.com",
            password="password123",
        )

        # Set player characteristics based on position and team style
        user.position = position
        user.team = team
        user.jersey_number = random.randint(1, 99)

        # Player skill ratings (1-100 scale)
        user.overall_rating = self.calculate_player_rating(
            position, team.style, player_index
        )
        user.three_point_rating = self.calculate_three_point_rating(
            position, team.style
        )
        user.defense_rating = self.calculate_defense_rating(position, team.strength)
        user.passing_rating = self.calculate_passing_rating(position)
        user.rebounding_rating = self.calculate_rebounding_rating(position)

        user.save()

        return user

    def calculate_player_rating(self, position, team_style, player_index):
        """Calculate overall player rating based on position and team style"""
        base_rating = 65  # Base rating for all players

        # Position bonuses
        position_bonuses = {
            "PG": 5,  # Point guards get slight bonus
            "SG": 3,  # Shooting guards
            "SF": 2,  # Small forwards
            "PF": 1,  # Power forwards
            "C": 0,  # Centers
        }

        # Team style bonuses
        style_bonuses = {"fast_paced": 3, "defensive": 2, "balanced": 1}

        # Player index affects rating (first 12 players are better)
        if player_index < 12:
            player_bonus = random.randint(5, 15)
        else:
            player_bonus = random.randint(-5, 5)

        total_rating = (
            base_rating
            + position_bonuses[position]
            + style_bonuses[team_style]
            + player_bonus
        )

        # Ensure rating is within 50-95 range
        return max(50, min(95, total_rating))

    def calculate_three_point_rating(self, position, team_style):
        """Calculate three-point shooting rating"""
        base_rating = 60

        # Position bonuses for 3PT
        position_bonuses = {"PG": 10, "SG": 15, "SF": 8, "PF": 2, "C": -5}

        # Team style affects 3PT emphasis
        style_bonuses = {"fast_paced": 8, "defensive": 2, "balanced": 5}

        total_rating = (
            base_rating
            + position_bonuses[position]
            + style_bonuses[team_style]
            + random.randint(-10, 10)
        )
        return max(30, min(95, total_rating))

    def calculate_defense_rating(self, position, team_strength):
        """Calculate defensive rating"""
        base_rating = 65

        # Position bonuses for defense
        position_bonuses = {"PG": 5, "SG": 3, "SF": 8, "PF": 10, "C": 15}

        # Team strength affects defense
        strength_bonuses = {"defensive": 15, "balanced": 8, "offensive": 2}

        total_rating = (
            base_rating
            + position_bonuses[position]
            + strength_bonuses[team_strength]
            + random.randint(-8, 8)
        )
        return max(40, min(95, total_rating))

    def calculate_passing_rating(self, position):
        """Calculate passing rating"""
        base_rating = 60

        position_bonuses = {"PG": 20, "SG": 10, "SF": 5, "PF": 3, "C": 8}

        total_rating = base_rating + position_bonuses[position] + random.randint(-5, 5)
        return max(40, min(95, total_rating))

    def calculate_rebounding_rating(self, position):
        """Calculate rebounding rating"""
        base_rating = 60

        position_bonuses = {"PG": -5, "SG": -3, "SF": 5, "PF": 15, "C": 20}

        total_rating = base_rating + position_bonuses[position] + random.randint(-5, 5)
        return max(40, min(95, total_rating))

    def create_storylines(self, teams):
        """Create realistic storylines and rivalries between teams"""
        self.stdout.write("Creating team rivalries and storylines...")

        # Major rivalries (based on real Brazilian basketball)
        rivalries = [
            (
                "Flamengo Basquete",
                "São Paulo F.C.",
                "Classic rivalry - biggest clubs in Brazil",
            ),
            ("Franca Basquete", "Bauru Basket", "São Paulo state rivalry"),
            ("Minas Tênis Clube", "Pinheiros", "Regional rivalry"),
            ("Flamengo Basquete", "Franca Basquete", "Recent championship rivalry"),
        ]

        for team1_name, team2_name, description in rivalries:
            team1 = next((t for t in teams if t.name == team1_name), None)
            team2 = next((t for t in teams if t.name == team2_name), None)

            if team1 and team2:
                # Store rivalry information
                team1.rival_team = team2
                team2.rival_team = team1
                self.stdout.write(
                    f"Created rivalry: {team1_name} vs {team2_name} - {description}"
                )

    def generate_season(self, teams, competition, admin_user, season_year):
        """Generate a complete season with realistic scheduling and outcomes"""
        self.stdout.write(f"Generating season {season_year}...")

        # Generate regular season games
        regular_season_games = self.generate_regular_season(
            teams, competition, admin_user, season_year
        )

        # Generate playoff games
        playoff_games = self.generate_playoffs(
            teams, competition, admin_user, season_year
        )

        # Generate possessions for all games
        all_games = regular_season_games + playoff_games
        self.generate_realistic_possessions(all_games, admin_user)

        self.stdout.write(
            f"Season {season_year} complete: {len(all_games)} games generated"
        )

    def generate_regular_season(self, teams, competition, admin_user, season_year):
        """Generate regular season with realistic scheduling"""
        games = []

        # Each team plays every other team twice (home and away)
        for i, home_team in enumerate(teams):
            for j, away_team in enumerate(teams):
                if i != j:  # Don't play against yourself
                    # Home game
                    home_game = self.create_realistic_game(
                        home_team,
                        away_team,
                        competition,
                        admin_user,
                        season_year,
                        "regular",
                    )
                    games.append(home_game)

                    # Away game (later in season)
                    away_game = self.create_realistic_game(
                        away_team,
                        home_team,
                        competition,
                        admin_user,
                        season_year,
                        "regular",
                    )
                    games.append(away_game)

        self.stdout.write(f"Generated {len(games)} regular season games")
        return games

    def create_realistic_game(
        self, home_team, away_team, competition, admin_user, season_year, game_type
    ):
        """Create a realistic game with proper scheduling"""
        # Season scheduling logic
        if season_year == 2024:
            base_date = date(2024, 10, 15)  # Season starts October 2024
        else:  # 2025
            base_date = date(2025, 10, 15)  # Season starts October 2025

        # Add some randomness to game dates
        days_offset = random.randint(0, 180)  # 6 month season
        game_date = base_date + timedelta(days=days_offset)

        # Game time (most games in evening)
        if random.random() < 0.8:
            game_time = time(19, 30)  # 7:30 PM
        else:
            game_time = time(20, 0)  # 8:00 PM

        game_datetime = datetime.combine(game_date, game_time)

        # Create game
        game = Game.objects.create(
            home_team=home_team,
            away_team=away_team,
            competition=competition,
            game_date=game_datetime,
            home_team_score=0,
            away_team_score=0,
            quarter=1,
            created_by=admin_user,
        )

        # Create rosters for this game
        self.create_game_rosters(game)

        return game

    def create_game_rosters(self, game):
        """Create 12-player rosters for each team in the game"""
        # Home team roster
        home_roster = GameRoster.objects.create(game=game, team=game.home_team)

        # Select 12 players (5 starters + 7 bench)
        home_players = list(game.home_team.players.all())
        random.shuffle(home_players)

        home_roster.players.set(home_players[:12])
        home_roster.starting_five.set(home_players[:5])

        # Away team roster
        away_roster = GameRoster.objects.create(game=game, team=game.away_team)

        away_players = list(game.away_team.players.all())
        random.shuffle(away_players)

        away_roster.players.set(away_players[:12])
        away_roster.starting_five.set(away_players[:5])

    def generate_playoffs(self, teams, competition, admin_user, season_year):
        """Generate playoff games with realistic bracket"""
        self.stdout.write("Generating playoff games...")

        # Top 8 teams make playoffs
        playoff_teams = teams[:8]
        playoff_games = []

        # Quarterfinals
        quarterfinal_games = self.generate_playoff_round(
            playoff_teams, competition, admin_user, season_year, "quarterfinal"
        )
        playoff_games.extend(quarterfinal_games)

        # Semifinals (winners of quarterfinals)
        semifinal_teams = self.simulate_playoff_winners(quarterfinal_games)
        semifinal_games = self.generate_playoff_round(
            semifinal_teams, competition, admin_user, season_year, "semifinal"
        )
        playoff_games.extend(semifinal_games)

        # Finals
        final_teams = self.simulate_playoff_winners(semifinal_games)
        final_games = self.generate_playoff_round(
            final_teams, competition, admin_user, season_year, "final"
        )
        playoff_games.extend(final_games)

        return playoff_games

    def generate_playoff_round(
        self, teams, competition, admin_user, season_year, round_name
    ):
        """Generate games for a specific playoff round"""
        games = []

        # Pair teams for this round
        for i in range(0, len(teams), 2):
            if i + 1 < len(teams):
                home_team = teams[i]
                away_team = teams[i + 1]

                # Best of 3 series
                for game_num in range(3):
                    game = self.create_realistic_game(
                        home_team,
                        away_team,
                        competition,
                        admin_user,
                        season_year,
                        round_name,
                    )
                    games.append(game)

        return games

    def simulate_playoff_winners(self, games):
        """Simulate winners of playoff games to advance to next round"""
        # This is a placeholder - in real implementation, you'd simulate actual game outcomes
        # For now, just return first 4 teams
        return list(set([game.home_team for game in games[:4]]))

    def generate_realistic_possessions(self, games, admin_user):
        """Generate realistic possessions for all games"""
        self.stdout.write("Generating realistic possessions for all games...")

        for game in games:
            self.stdout.write(
                f"Generating possessions for {game.home_team.name} vs {game.away_team.name}"
            )

            # Generate possessions for this game
            possessions = self.generate_game_possessions(game, admin_user)

            # Update game scores based on possessions
            self.update_game_scores(game, possessions)

            self.stdout.write(f"Generated {len(possessions)} possessions for {game}")

    def generate_game_possessions(self, game, admin_user):
        """Generate realistic possessions for a single game"""
        possessions = []

        # Realistic possession count: 70-80 per team
        total_possessions = random.randint(70, 80)

        # Game quarters (4 quarters + potential overtime)
        quarters = [1, 2, 3, 4]
        if random.random() < 0.1:  # 10% chance of overtime
            quarters.append(5)

        current_possession = 0
        home_score = 0
        away_score = 0

        for quarter in quarters:
            quarter_possessions = total_possessions // len(quarters)

            for _ in range(quarter_possessions):
                if current_possession >= total_possessions:
                    break

                # Determine which team has possession
                home_team = game.home_team
                away_team = game.away_team

                # Home team gets slight advantage
                if random.random() < 0.52:
                    offensive_team = home_team
                    defensive_team = away_team
                else:
                    offensive_team = away_team
                    defensive_team = home_team

                # Generate possession outcome
                possession = self.create_realistic_possession(
                    game,
                    offensive_team,
                    defensive_team,
                    quarter,
                    current_possession,
                    admin_user,
                )

                possessions.append(possession)

                # Update scores
                if offensive_team == home_team:
                    home_score += possession.points_scored
                else:
                    away_score += possession.points_scored

                current_possession += 1

        return possessions

    def create_realistic_possession(
        self, game, offensive_team, defensive_team, quarter, possession_num, admin_user
    ):
        """Create a single realistic possession"""
        # Get rosters for this game
        home_roster = GameRoster.objects.get(game=game, team=game.home_team)
        away_roster = GameRoster.objects.get(game=game, team=game.away_team)

        # Select players on court (5 from each team)
        home_players = list(home_roster.starting_five.all())
        away_players = list(away_roster.starting_five.all())

        # Add some bench players randomly
        if random.random() < 0.3:  # 30% chance of bench player
            bench_players = list(
                home_roster.players.exclude(id__in=[p.id for p in home_players])
            )
            if bench_players:
                home_players[random.randint(0, 4)] = random.choice(bench_players)

        if random.random() < 0.3:
            bench_players = list(
                away_roster.players.exclude(id__in=[p.id for p in away_players])
            )
            if bench_players:
                away_players[random.randint(0, 4)] = random.choice(bench_players)

        # Determine possession outcome based on realistic basketball probabilities
        outcome = self.determine_possession_outcome(offensive_team, defensive_team)

        # Create possession
        possession = Possession.objects.create(
            game=game,
            team=home_roster if offensive_team == game.home_team else away_roster,
            opponent=away_roster if offensive_team == game.home_team else home_roster,
            quarter=quarter,
            outcome=outcome,
            points_scored=self.calculate_points_scored(outcome),
            duration_seconds=random.randint(15, 25),  # 15-25 second possessions
            offensive_set="Set 1",  # Placeholder
            defensive_set="Man-to-Man",  # Placeholder
            start_time_in_game=f"{random.randint(0, 9)}:{random.randint(0, 59):02d}",
            created_by=admin_user,
        )

        # Set players on court
        if offensive_team == game.home_team:
            possession.players_on_court.set(home_players)
            possession.defensive_players_on_court.set(away_players)
        else:
            possession.players_on_court.set(away_players)
            possession.defensive_players_on_court.set(home_players)

        return possession

    def determine_possession_outcome(self, offensive_team, defensive_team):
        """Determine realistic possession outcome based on team strengths"""
        # Base probabilities for different outcomes
        outcomes = [
            ("MADE_2PTS", 0.45),  # 45% chance of made 2-pointer
            ("MISSED_2PTS", 0.25),  # 25% chance of missed 2-pointer
            ("MADE_3PTS", 0.15),  # 15% chance of made 3-pointer
            ("MISSED_3PTS", 0.10),  # 10% chance of missed 3-pointer
            ("TURNOVER", 0.05),  # 5% chance of turnover
        ]

        # Adjust based on team characteristics
        if offensive_team.strength == "offensive":
            # Offensive teams get better shooting percentages
            outcomes = [
                ("MADE_2PTS", 0.50),
                ("MISSED_2PTS", 0.20),
                ("MADE_3PTS", 0.18),
                ("MISSED_3PTS", 0.08),
                ("TURNOVER", 0.04),
            ]
        elif defensive_team.strength == "defensive":
            # Defensive teams force more misses and turnovers
            outcomes = [
                ("MADE_2PTS", 0.40),
                ("MISSED_2PTS", 0.30),
                ("MADE_3PTS", 0.12),
                ("MISSED_3PTS", 0.13),
                ("TURNOVER", 0.05),
            ]

        # Select outcome based on probabilities
        rand = random.random()
        cumulative_prob = 0

        for outcome, probability in outcomes:
            cumulative_prob += probability
            if rand <= cumulative_prob:
                return outcome

        return "MISSED_2PTS"  # Default fallback

    def calculate_points_scored(self, outcome):
        """Calculate points scored based on outcome"""
        if outcome == "MADE_2PTS":
            return 2
        elif outcome == "MADE_3PTS":
            return 3
        elif outcome == "MADE_FTS":
            return 1
        else:
            return 0

    def update_game_scores(self, game, possessions):
        """Update game scores based on generated possessions"""
        home_score = 0
        away_score = 0

        for possession in possessions:
            if possession.team.team == game.home_team:
                home_score += possession.points_scored
            else:
                away_score += possession.points_scored

        # Update game scores
        game.home_team_score = home_score
        game.away_team_score = away_score
        game.save()

        self.stdout.write(
            f"Updated {game}: {game.home_team.name} {home_score} - {away_score} {game.away_team.name}"
        )
