from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.games.models import Game, GameRoster
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from apps.users.models import User
from datetime import date, time, timedelta, datetime
import random

User = get_user_model()


class Command(BaseCommand):
    help = (
        "Populate database with realistic basketball data using roster-first approach"
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--teams", type=int, default=4, help="Number of teams to create"
        )
        parser.add_argument(
            "--players-per-team",
            type=int,
            default=20,
            help="Number of players per team",
        )
        parser.add_argument(
            "--games", type=int, default=10, help="Number of games to create"
        )
        parser.add_argument(
            "--clear-existing",
            action="store_true",
            help="Clear existing data before populating",
        )

    def handle(self, *args, **options):
        if options["clear_existing"]:
            self.stdout.write("Clearing existing data...")
            Possession.objects.all().delete()
            GameRoster.objects.all().delete()
            Game.objects.all().delete()
            Team.objects.all().delete()
            User.objects.filter(is_superuser=False).delete()

        self.stdout.write("Creating admin user...")
        admin_user = self.create_admin_user()

        self.stdout.write("Creating competition...")
        competition = self.create_competition(admin_user)

        self.stdout.write("Creating teams and players...")
        teams = self.create_teams_and_players(
            options["teams"], options["players_per_team"], admin_user, competition
        )

        self.stdout.write("Creating games...")
        games = self.create_games(teams, options["games"], admin_user, competition)

        self.stdout.write("Creating game rosters...")
        self.create_game_rosters(games)

        self.stdout.write("Generating possessions...")
        self.generate_possessions(games, admin_user)

        self.stdout.write(self.style.SUCCESS("Database populated successfully!"))

    def create_teams_and_players(
        self, num_teams, players_per_team, admin_user, competition
    ):
        """Create teams with realistic player names"""
        teams = []

        # Brazilian basketball team names
        team_names = [
            "Fortaleza B.C.",
            "Brasília Basquete",
            "Flamengo Basquete",
            "São Paulo F.C.",
            "Minas Tênis Clube",
            "Franca Basquete",
            "Pinheiros",
            "Bauru Basket",
            "Mogi das Cruzes",
            "Limeira",
        ]

        for i in range(num_teams):
            team_name = team_names[i] if i < len(team_names) else f"Team {i+1}"
            team = Team.objects.create(name=team_name, created_by=admin_user)

            # Create players for this team
            for j in range(players_per_team):
                first_name = self.get_random_first_name()
                last_name = self.get_random_last_name()
                username = (
                    f"{first_name.lower()}.{last_name.lower()}{j+1 if j > 0 else ''}"
                )

                user = User.objects.create_user(
                    username=username,
                    first_name=first_name,
                    last_name=last_name,
                    email=f"{username}@example.com",
                    password="password123",
                )

                # Add player to team
                team.players.add(user)

            teams.append(team)
            self.stdout.write(
                f"Created team: {team.name} with {team.players.count()} players"
            )

        return teams

    def create_competition(self, admin_user):
        """Create a competition for the teams"""
        competition, created = Competition.objects.get_or_create(
            name=f"Season {date.today().year}", defaults={"created_by": admin_user}
        )
        if created:
            self.stdout.write(f"Created competition: {competition.name}")
        else:
            self.stdout.write(f"Using existing competition: {competition.name}")
        return competition

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

    def create_games(self, teams, num_games, admin_user, competition):
        """Create games between teams"""
        games = []
        base_date = date.today()

        for i in range(num_games):
            # Alternate between teams
            home_team = teams[i % len(teams)]
            away_team = teams[(i + 1) % len(teams)]

            # Create game on different dates
            game_date = base_date + timedelta(days=i)
            game_time = time(19, 30)  # 7:30 PM

            # Combine date and time into datetime
            game_datetime = datetime.combine(game_date, game_time)
            # Make timezone-aware
            from django.utils import timezone
            if timezone.is_naive(game_datetime):
                game_datetime = timezone.make_aware(game_datetime)

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

            games.append(game)
            self.stdout.write(
                f"Created game: {home_team.name} vs {away_team.name} on {game_date}"
            )

        return games

    def create_game_rosters(self, games):
        """Create 12-player rosters for each team in each game"""
        for game in games:
            # Create roster for home team
            home_roster = self.create_team_roster(game, game.home_team)

            # Create roster for away team
            away_roster = self.create_team_roster(game, game.away_team)

            self.stdout.write(
                f"Created rosters for {game}: {home_roster.players.count()} home, {away_roster.players.count()} away"
            )

    def create_team_roster(self, game, team):
        """Create a 12-player roster for a team in a specific game"""
        # Get all players from the team
        all_players = list(team.players.all())

        # Randomly select 12 players for this game
        selected_players = random.sample(all_players, min(12, len(all_players)))

        # Create the roster
        roster = GameRoster.objects.create(game=game, team=team)

        # Add all 12 players
        roster.players.set(selected_players)

        # Select 5 players as starting five
        starting_five = random.sample(selected_players, 5)
        roster.starting_five.set(starting_five)

        return roster

    def generate_possessions(self, games, admin_user):
        """Generate realistic possessions for each game"""
        for game in games:
            self.stdout.write(f"Generating possessions for {game}...")

            # Get the rosters for this game
            home_roster = GameRoster.objects.get(game=game, team=game.home_team)
            away_roster = GameRoster.objects.get(game=game, team=game.away_team)

            # Generate possessions for each quarter
            for quarter in range(1, 5):  # Q1-Q4
                self.generate_quarter_possessions(
                    game, home_roster, away_roster, quarter, admin_user
                )

            # 25% chance of overtime
            if random.random() < 0.25:
                self.generate_quarter_possessions(
                    game, home_roster, away_roster, 5, admin_user
                )  # OT

    def generate_quarter_possessions(
        self, game, home_roster, away_roster, quarter, admin_user
    ):
        """Generate possessions for a specific quarter"""
        # Determine number of possessions (18-25 per quarter)
        num_possessions = random.randint(18, 25)

        # Determine quarter score range (15-30 points total)
        target_score = random.randint(15, 30)

        # Generate possessions
        possessions = []
        current_score = 0

        for i in range(num_possessions):
            # Determine which team has possession
            is_home_possession = random.choice([True, False])
            offensive_roster = home_roster if is_home_possession else away_roster
            defensive_roster = away_roster if is_home_possession else home_roster

            # Generate possession outcome
            outcome, points = self.generate_possession_outcome(
                current_score, target_score, num_possessions - i
            )

            # Create possession
            possession = Possession.objects.create(
                game=game,
                team=offensive_roster,
                opponent=defensive_roster,
                quarter=quarter,
                start_time_in_game=self.generate_time_in_quarter(),
                duration_seconds=random.randint(15, 25),
                outcome=outcome,
                offensive_sequence=self.generate_offensive_sequence(),
                defensive_sequence=self.generate_defensive_sequence(),
                points_scored=points,
                created_by=admin_user,
            )

            # Set players on court (5 from offensive team, 5 from defensive team)
            offensive_players = random.sample(list(offensive_roster.players.all()), 5)
            defensive_players = random.sample(list(defensive_roster.players.all()), 5)

            possession.players_on_court.set(offensive_players)
            possession.defensive_players_on_court.set(defensive_players)

            # Set player attributions if scoring
            if points > 0:
                scorer = random.choice(offensive_players)
                possession.scorer = scorer
                possession.save()

                # 70% chance of assist
                if random.random() < 0.7:
                    assist_player = random.choice(
                        [p for p in offensive_players if p != scorer]
                    )
                    possession.assisted_by = assist_player
                    possession.save()

            # Handle rebounds
            if outcome in ["MISSED_2PTS", "MISSED_3PTS"]:
                if random.random() < 0.3:  # 30% chance of offensive rebound
                    possession.is_offensive_rebound = True
                    possession.offensive_rebound_count = random.randint(1, 2)
                    possession.offensive_rebound_players.set(
                        random.sample(
                            offensive_players, possession.offensive_rebound_count
                        )
                    )
                else:
                    # Defensive rebound
                    rebounder = random.choice(defensive_players)
                    possession.defensive_players_on_court.add(rebounder)

            # Handle blocks and steals
            if (
                outcome in ["MISSED_2PTS", "MISSED_3PTS"] and random.random() < 0.15
            ):  # 15% chance of block
                blocker = random.choice(defensive_players)
                possession.blocked_by = blocker
                possession.save()

            if random.random() < 0.1:  # 10% chance of steal
                stealer = random.choice(defensive_players)
                possession.stolen_by = stealer
                possession.save()

            # Handle fouls
            if (
                outcome == "FOUL" and random.random() < 0.8
            ):  # 80% chance of foul attribution
                fouler = random.choice(offensive_players)
                possession.fouled_by = fouler
                possession.save()

            current_score += points
            possessions.append(possession)

        self.stdout.write(
            f"  Q{quarter}: {len(possessions)} possessions, {current_score} points"
        )

    def generate_possession_outcome(
        self, current_score, target_score, possessions_remaining
    ):
        """Generate realistic possession outcome based on game context"""
        if current_score >= target_score:
            # Game is already won, reduce scoring
            if random.random() < 0.3:
                return random.choice(["MADE_2PTS", "MADE_3PTS"]), random.choice([2, 3])
            else:
                return random.choice(["MISSED_2PTS", "MISSED_3PTS", "TURNOVER"]), 0

        # Normal possession
        outcomes = [
            ("MADE_2PTS", 2, 0.45),  # 45% chance
            ("MADE_3PTS", 3, 0.15),  # 15% chance
            ("MADE_FTS", 1, 0.05),  # 5% chance
            ("MISSED_2PTS", 0, 0.20),  # 20% chance
            ("MISSED_3PTS", 0, 0.10),  # 10% chance
            ("TURNOVER", 0, 0.03),  # 3% chance
            ("FOUL", 0, 0.02),  # 2% chance
        ]

        # Weighted random choice
        rand = random.random()
        cumulative = 0
        for outcome, points, probability in outcomes:
            cumulative += probability
            if rand <= cumulative:
                return outcome, points

        return "MISSED_2PTS", 0

    def generate_time_in_quarter(self):
        """Generate time remaining in quarter (MM:SS format)"""
        minutes = random.randint(0, 9)
        seconds = random.randint(0, 59)
        return f"{minutes:02d}:{seconds:02d}"

    def generate_offensive_sequence(self):
        """Generate realistic offensive sequence description"""
        sequences = [
            "Pick and roll with kick out",
            "Post up with double team",
            "Transition fast break",
            "Offensive rebound putback",
            "Handoff with screen",
            "Isolation play",
            "Backdoor cut",
            "Flare screen for 3",
        ]
        return random.choice(sequences)

    def generate_defensive_sequence(self):
        """Generate realistic defensive sequence description"""
        sequences = [
            "Man to man defense",
            "2-3 zone defense",
            "Switch on pick and roll",
            "Help defense rotation",
            "Box out for rebound",
            "Double team in post",
            "Press defense",
            "Trap on pick and roll",
        ]
        return random.choice(sequences)

    def get_random_first_name(self):
        """Get random Brazilian first name"""
        names = [
            "João",
            "Pedro",
            "Lucas",
            "Gabriel",
            "Rafael",
            "Daniel",
            "Marcelo",
            "André",
            "Thiago",
            "Bruno",
            "Carlos",
            "Eduardo",
            "Felipe",
            "Guilherme",
            "Henrique",
            "Igor",
            "Juliano",
            "Leonardo",
            "Matheus",
            "Nicolas",
            "Otávio",
            "Paulo",
            "Ricardo",
            "Samuel",
            "Thiago",
            "Vinicius",
            "Wagner",
            "Xavier",
            "Yago",
            "Zé",
        ]
        return random.choice(names)

    def get_random_last_name(self):
        """Get random Brazilian last name"""
        names = [
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
            "Martins",
            "Carvalho",
            "Alves",
            "Lopes",
            "Soares",
            "Fernandes",
            "Vieira",
            "Barbosa",
            "Rocha",
            "Dias",
            "Nascimento",
            "Moreira",
            "Sousa",
            "Melo",
            "Cardoso",
            "Correia",
            "Mendes",
            "Dantas",
            "Cavalcanti",
            "Araújo",
            "Castro",
            "Monteiro",
        ]
        return random.choice(names)
