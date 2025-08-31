# backend/apps/users/management/commands/populate_db.py

import datetime
import json
import os
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction

# Import all necessary models
from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.games.models import Game
from apps.plays.models import PlayCategory, PlayDefinition
from apps.events.models import CalendarEvent
from apps.possessions.models import Possession

User = get_user_model()


class Command(BaseCommand):
    help = "Populates the database with a large, realistic set of NBB league data."

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS("--- Starting Database Population ---"))

        # Clean up old data
        self.stdout.write("Deleting old data...")
        Possession.objects.all().delete()
        CalendarEvent.objects.all().delete()
        Game.objects.all().delete()
        PlayDefinition.objects.all().delete()
        PlayCategory.objects.all().delete()
        Team.objects.all().delete()
        Competition.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        self.stdout.write("Old data deleted.")

        # Get superuser
        superuser = User.objects.filter(is_superuser=True).order_by("pk").first()
        if not superuser:
            self.stdout.write(
                self.style.ERROR(
                    'FATAL: No superuser found. Please create one first with "python manage.py createsuperuser".'
                )
            )
            return

        self.stdout.write("Creating NBB Competition...")
        nbb_competition, _ = Competition.objects.get_or_create(
            name="Novo Basquete Brasil",
            defaults={"season": "2025-2026", "created_by": superuser},
        )

        # Create NBB Teams, coaches, players
        self.stdout.write("Creating 18 NBB teams, 18 coaches, and 20 players per team...")

        nbb_teams_data = [
            {'name': 'Bauru Basket', 'full_name': 'Zopone/Unimed/Bauru Basket'},
            {'name': 'Botafogo', 'full_name': 'Botafogo'},
            {'name': 'Brasília Basquete', 'full_name': 'CAIXA/Brasília Basquete'},
            {'name': 'Caxias do Sul', 'full_name': 'Caxias do Sul Basquete'},
            {"name": "Corinthians", "full_name": "Sport Club Corinthians Paulista"},
            {"name": "Flamengo", "full_name": "Clube de Regatas do Flamengo"},
            {"name": "Fortaleza B.C.", "full_name": "Fortaleza Basquete Cearense/CFO"},
            {'name': 'Sesi Franca', 'full_name': 'Franca Basquete'},
            {'name': 'Minas', 'full_name': 'KTO Minas'},
            {'name': 'Mogi Basquete', 'full_name': 'Desk Manager Mogi Basquete'},
            {
                "name": "Pato Basquete",
                "full_name": "Associação Basquetebol Arte de Pato Branco",
            },
            {'name': 'Paulistano', 'full_name': 'Paulistano/Corpore'},
            {'name': 'Pinheiros', 'full_name': 'Esporte Clube Pinheiros'},
            {'name': 'São José', 'full_name': 'Farma Conde/São José Basketball'},
            {"name": "São Paulo", "full_name": "São Paulo Futebol Clube"},
            {'name': 'União Corinthians', 'full_name': 'Ceisc/União Corinthians'},
            {'name': 'Unifacisa', 'full_name': 'Unifacisa'},
            {"name": "Vasco da Gama", "full_name": "R10 Score Vasco da Gama"},
        ]

        # Define realistic player names by nationality
        serbian_names = [
            ("Nikola", "Jokić"), ("Bogdan", "Bogdanović"), ("Nemanja", "Bjelica"), ("Miloš", "Teodosić"),
            ("Stefan", "Jović"), ("Marko", "Gudurić"), ("Nikola", "Mirotić"), ("Vasilije", "Micić"),
            ("Aleksandar", "Vezenkov"), ("Filip", "Petrusev"), ("Nikola", "Kalinić"), ("Stefan", "Birčević"),
            ("Milan", "Mačvan"), ("Nemanja", "Dangubić"), ("Marko", "Simonović"), ("Aleksa", "Avramović"),
            ("Ognjen", "Dobrić"), ("Dejan", "Davidovac"), ("Stefan", "Lazarević"), ("Nikola", "Rakićević"),
            ("Vladimir", "Lučić"), ("Miroslav", "Raduljica"), ("Nemanja", "Nedović"), ("Stefan", "Marković"),
            ("Branko", "Lazić"), ("Dragan", "Milosavljević"), ("Uroš", "Tripković"), ("Marko", "Keselj"),
            ("Novica", "Veličković"), ("Dušan", "Kecman"), ("Milan", "Gurović"), ("Predrag", "Stojaković"),
            ("Vlade", "Divac"), ("Peja", "Stojaković"), ("Dejan", "Bodiroga"), ("Željko", "Rebrača"),
            ("Predrag", "Danilović"), ("Sasha", "Đorđević"), ("Žarko", "Paspalj"), ("Vlado", "Šćepanović"),
            ("Miroslav", "Berić"), ("Dragan", "Tarlać"), ("Željko", "Obradović"), ("Dejan", "Tomasević"),
            ("Predrag", "Drobnjak"), ("Marko", "Jarić"), ("Darko", "Miličić"), ("Nenad", "Krstić"),
            ("Vladimir", "Radmanović"), ("Igor", "Rakočević"), ("Miloš", "Vujanić"), ("Predrag", "Savović"),
            ("Dragan", "Lukovski"), ("Vule", "Avdalović"), ("Stefan", "Nikolić"), ("Milan", "Mačvan"),
            ("Nemanja", "Krstić"), ("Stefan", "Birčević"), ("Bogdan", "Bogdanović"), ("Nemanja", "Dangubić"),
            ("Marko", "Simonović"), ("Aleksa", "Avramović"), ("Ognjen", "Dobrić"), ("Dejan", "Davidovac"),
            ("Stefan", "Lazarević"), ("Nikola", "Rakićević"), ("Vladimir", "Lučić"), ("Miroslav", "Raduljica"),
            ("Nemanja", "Nedović"), ("Stefan", "Marković"), ("Branko", "Lazić"), ("Dragan", "Milosavljević"),
            ("Uroš", "Tripković"), ("Marko", "Keselj"), ("Novica", "Veličković"), ("Dušan", "Kecman"),
            ("Milan", "Gurović"), ("Predrag", "Stojaković"), ("Vlade", "Divac"), ("Peja", "Stojaković"),
            ("Dejan", "Bodiroga"), ("Željko", "Rebrača"), ("Predrag", "Danilović"), ("Sasha", "Đorđević"),
            ("Žarko", "Paspalj"), ("Vlado", "Šćepanović"), ("Miroslav", "Berić"), ("Dragan", "Tarlać"),
            ("Željko", "Obradović"), ("Dejan", "Tomasević"), ("Predrag", "Drobnjak"), ("Marko", "Jarić"),
            ("Darko", "Miličić"), ("Nenad", "Krstić"), ("Vladimir", "Radmanović"), ("Igor", "Rakočević"),
            ("Miloš", "Vujanić"), ("Predrag", "Savović"), ("Dragan", "Lukovski"), ("Vule", "Avdalović"),
            ("Stefan", "Nikolić"), ("Milan", "Mačvan"), ("Nemanja", "Krstić"), ("Stefan", "Birčević"),
        ]
        
        us_names = [
            ("LeBron", "James"), ("Stephen", "Curry"), ("Kevin", "Durant"), ("Giannis", "Antetokounmpo"),
            ("Luka", "Dončić"), ("Joel", "Embiid"), ("Nikola", "Jokić"), ("Jayson", "Tatum"),
            ("Devin", "Booker"), ("Damian", "Lillard"), ("Jimmy", "Butler"), ("Anthony", "Davis"),
            ("Zion", "Williamson"), ("Ja", "Morant"), ("Trae", "Young"), ("Donovan", "Mitchell"),
            ("Jaylen", "Brown"), ("Bam", "Adebayo"), ("De'Aaron", "Fox"), ("Shai", "Gilgeous-Alexander"),
            ("Bradley", "Beal"), ("Karl-Anthony", "Towns"), ("Rudy", "Gobert"), ("Domantas", "Sabonis"),
            ("Julius", "Randle"), ("Zach", "LaVine"), ("DeMar", "DeRozan"), ("Fred", "VanVleet"),
            ("Tyrese", "Haliburton"), ("Pascal", "Siakam"), ("OG", "Anunoby"), ("Scottie", "Barnes"),
            ("Cade", "Cunningham"), ("Jalen", "Green"), ("Paolo", "Banchero"), ("Franz", "Wagner"),
            ("Evan", "Mobley"), ("Jalen", "Suggs"), ("Josh", "Giddey"), ("Chet", "Holmgren"),
            ("Victor", "Wembanyama"), ("Scoot", "Henderson"), ("Brandon", "Miller"), ("Amen", "Thompson"),
            ("Ausar", "Thompson"), ("Jarace", "Walker"), ("Taylor", "Hendricks"), ("Anthony", "Black"),
            ("Bilal", "Coulibaly"), ("Keyonte", "George"), ("Jett", "Howard"), ("Gradey", "Dick"),
            ("Jordan", "Hawkins"), ("Kobe", "Bufkin"), ("Jalen", "Hood-Schifino"), ("Nick", "Smith"),
            ("Brice", "Sensabaugh"), ("Noah", "Clowney"), ("Dereck", "Lively"), ("Olivier", "Maxence-Prosper"),
            ("Jaime", "Jaquez"), ("Brandin", "Podziemski"), ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"),
            ("Ben", "Sheppard"), ("Colby", "Jones"), ("Julian", "Strawther"), ("Kris", "Murray"),
            ("Toumani", "Camara"), ("Hunter", "Tyson"), ("Andre", "Jackson"), ("Seth", "Lundy"),
            ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"), ("Amari", "Bailey"), ("Tristan", "Vukčević"),
            ("Rayan", "Rupert"), ("James", "Nnaji"), ("Leonard", "Miller"), ("Colin", "Castleton"),
            ("Ricky", "Council"), ("Mouhamadou", "Gueye"), ("Isaiah", "Wong"), ("Jordan", "Walsh"),
            ("Emoni", "Bates"), ("Dariq", "Whitehead"), ("Keyontae", "Johnson"), ("Jalen", "Wilson"),
            ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"), ("Ben", "Sheppard"), ("Colby", "Jones"),
            ("Julian", "Strawther"), ("Kris", "Murray"), ("Toumani", "Camara"), ("Hunter", "Tyson"),
            ("Andre", "Jackson"), ("Seth", "Lundy"), ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"),
            ("Amari", "Bailey"), ("Tristan", "Vukčević"), ("Rayan", "Rupert"), ("James", "Nnaji"),
            ("Leonard", "Miller"), ("Colin", "Castleton"), ("Ricky", "Council"), ("Mouhamadou", "Gueye"),
            ("Isaiah", "Wong"), ("Jordan", "Walsh"), ("Emoni", "Bates"), ("Dariq", "Whitehead"),
            ("Keyontae", "Johnson"), ("Jalen", "Wilson"), ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"),
        ]
        
        brazilian_names = [
            ("Anderson", "Varejão"), ("Nenê", "Hilário"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
            ("Nenê", "Hilário"), ("Anderson", "Varejão"), ("Leandrinho", "Barbosa"), ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"), ("Guilherme", "Deodato"), ("João", "Paulo"), ("Rafael", "Luz"),
            ("Lucas", "Mariano"), ("Augusto", "Lima"), ("Rafael", "Mineiro"), ("Didi", "Louzada"),
            ("Yago", "Santos"), ("Georginho", "De Paula"), ("Rafael", "Fischer"), ("Lucas", "Dias"),
            ("Bruno", "Caboclo"), ("Cristiano", "Felício"), ("Raul", "Neto"), ("Vítor", "Benite"),
            ("Marcelinho", "Huertas"), ("Alex", "Garcia"), ("Vítor", "Faverani"), ("Rafael", "Araújo"),
        ]
        
        australian_names = [
            ("Ben", "Simmons"), ("Patty", "Mills"), ("Joe", "Ingles"), ("Aron", "Baynes"),
            ("Dante", "Exum"), ("Matthew", "Dellavedova"), ("Thon", "Maker"), ("Jonah", "Bolden"),
            ("Ryan", "Broekhoff"), ("Mitch", "Creek"), ("Nathan", "Sobey"), ("Chris", "Goulding"),
            ("Daniel", "Johnson"), ("Jock", "Landale"), ("Duop", "Reath"), ("Will", "Magnay"),
            ("Sam", "Froling"), ("Kyle", "Adnam"), ("Todd", "Blanchfield"), ("Mitch", "McCarron"),
            ("Josh", "Giddey"), ("Dyson", "Daniels"), ("Luke", "Travers"), ("Tyrese", "Proctor"),
            ("Johnny", "Furphy"), ("Alex", "Sarr"), ("Zach", "Edey"), ("Tristan", "da Silva"),
            ("Harrison", "Ingram"), ("Jordan", "Walsh"), ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"),
            ("Ben", "Sheppard"), ("Colby", "Jones"), ("Julian", "Strawther"), ("Kris", "Murray"),
            ("Toumani", "Camara"), ("Hunter", "Tyson"), ("Andre", "Jackson"), ("Seth", "Lundy"),
            ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"), ("Amari", "Bailey"), ("Tristan", "Vukčević"),
            ("Rayan", "Rupert"), ("James", "Nnaji"), ("Leonard", "Miller"), ("Colin", "Castleton"),
            ("Ricky", "Council"), ("Mouhamadou", "Gueye"), ("Isaiah", "Wong"), ("Jordan", "Walsh"),
            ("Emoni", "Bates"), ("Dariq", "Whitehead"), ("Keyontae", "Johnson"), ("Jalen", "Wilson"),
            ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"), ("Ben", "Sheppard"), ("Colby", "Jones"),
            ("Julian", "Strawther"), ("Kris", "Murray"), ("Toumani", "Camara"), ("Hunter", "Tyson"),
            ("Andre", "Jackson"), ("Seth", "Lundy"), ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"),
            ("Amari", "Bailey"), ("Tristan", "Vukčević"), ("Rayan", "Rupert"), ("James", "Nnaji"),
            ("Leonard", "Miller"), ("Colin", "Castleton"), ("Ricky", "Council"), ("Mouhamadou", "Gueye"),
            ("Isaiah", "Wong"), ("Jordan", "Walsh"), ("Emoni", "Bates"), ("Dariq", "Whitehead"),
            ("Keyontae", "Johnson"), ("Jalen", "Wilson"), ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"),
            ("Ben", "Sheppard"), ("Colby", "Jones"), ("Julian", "Strawther"), ("Kris", "Murray"),
            ("Toumani", "Camara"), ("Hunter", "Tyson"), ("Andre", "Jackson"), ("Seth", "Lundy"),
            ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"), ("Amari", "Bailey"), ("Tristan", "Vukčević"),
            ("Rayan", "Rupert"), ("James", "Nnaji"), ("Leonard", "Miller"), ("Colin", "Castleton"),
            ("Ricky", "Council"), ("Mouhamadou", "Gueye"), ("Isaiah", "Wong"), ("Jordan", "Walsh"),
            ("Emoni", "Bates"), ("Dariq", "Whitehead"), ("Keyontae", "Johnson"), ("Jalen", "Wilson"),
            ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"), ("Ben", "Sheppard"), ("Colby", "Jones"),
            ("Julian", "Strawther"), ("Kris", "Murray"), ("Toumani", "Camara"), ("Hunter", "Tyson"),
            ("Andre", "Jackson"), ("Seth", "Lundy"), ("Mouhamed", "Gueye"), ("Maxwell", "Lewis"),
            ("Amari", "Bailey"), ("Tristan", "Vukčević"), ("Rayan", "Rupert"), ("James", "Nnaji"),
            ("Leonard", "Miller"), ("Colin", "Castleton"), ("Ricky", "Council"), ("Mouhamadou", "Gueye"),
            ("Isaiah", "Wong"), ("Jordan", "Walsh"), ("Emoni", "Bates"), ("Dariq", "Whitehead"),
            ("Keyontae", "Johnson"), ("Jalen", "Wilson"), ("Trayce", "Jackson-Davis"), ("Marcus", "Sasser"),
        ]
        
        # Combine all names and ensure uniqueness
        all_names = serbian_names + us_names + brazilian_names + australian_names
        
        # Remove duplicates while preserving order
        seen = set()
        unique_names = []
        for name in all_names:
            username = f"{name[0].lower()}.{name[1].lower()}"
            if username not in seen:
                seen.add(username)
                unique_names.append(name)
        
        all_names = unique_names
        random.shuffle(all_names)  # Shuffle to randomize distribution
        
        self.stdout.write(f"  - Total unique player names: {len(all_names)}")
        
        all_teams = []
        name_index = 0
        for i, team_data in enumerate(nbb_teams_data):
            # Create a unique coach for each team
            coach = User.objects.create_user(
                username=f"coach_{i+1}",
                password="password",
                first_name=f'Coach_{team_data["name"]}',
                last_name="User",
                role=User.Role.COACH,
                coach_type="HEAD_COACH",
            )

            team = Team.objects.create(
                name=team_data["name"],
                competition=nbb_competition,
                created_by=superuser,
                logo_url="https://via.placeholder.com/100",
            )

            team.coaches.add(coach)

            # Create and assign 20 players to this team
            team_players = []
            for j in range(20):
                if name_index < len(all_names):
                    first_name, last_name = all_names[name_index]
                    name_index += 1
                    username = f"{first_name.lower()}.{last_name.lower()}"
                else:
                    # Fallback names if we run out - ensure unique usernames
                    player_num = (i * 20) + j + 1
                    first_name = f"Player{player_num}"
                    last_name = f"Team{i+1}"
                    username = f"player{player_num}.team{i+1}"
                
                player = User.objects.create_user(
                    username=username,
                    password="password",
                    first_name=first_name,
                    last_name=last_name,
                    role=User.Role.PLAYER,
                    jersey_number=random.randint(0, 99),
                )
                team_players.append(player)
            team.players.set(team_players)
            all_teams.append(team)
            self.stdout.write(
                f"  - Created team: {team.name} with 1 coach and 20 players."
            )

        # --- 5. LOAD PLAY DEFINITIONS FROM JSON ---
        self.stdout.write("Loading generic play definitions...")
        default_team, _ = Team.objects.get_or_create(
            name="Default Play Templates",
            defaults={"competition": nbb_competition, "created_by": superuser},
        )

        PlayCategory.objects.all().delete()
        PlayDefinition.objects.filter(team=default_team).delete()

        json_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "plays",
            "fixtures",
            "initial_play_definitions.json",
        )
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        for category_data in data:
            category, _ = PlayCategory.objects.get_or_create(
                name=category_data["category"]
            )
            for play_data in category_data["plays"]:
                # Use get_or_create to avoid creating duplicates for the same team.
                # It looks for a play with this name and team.
                # If it exists, it does nothing.
                # If it doesn't exist, it creates it using the 'defaults'.
                play_def, created = PlayDefinition.objects.get_or_create(
                    name=play_data["name"],
                    team=default_team,
                    defaults={
                        "category": category,
                        "subcategory": play_data.get("subcategory"),
                        "action_type": play_data.get("action_type", "NORMAL"),
                        "play_type": "OFFENSIVE",  # A sensible default
                    },
                )
        self.stdout.write("Play definitions loaded.")

        # Create sample games
        self.stdout.write("Creating 50 sample games (20 Fortaleza games)...")
        
        # Find Fortaleza team
        fortaleza_team = None
        for team in all_teams:
            if "Fortaleza" in team.name:
                fortaleza_team = team
                break
        
        if not fortaleza_team:
            self.stdout.write(self.style.ERROR("Fortaleza team not found!"))
            return
        
        games = []
        
        # Create 20 Fortaleza games
        for i in range(20):
            # Fortaleza plays against different teams
            opponent = random.choice([team for team in all_teams if team != fortaleza_team])
            
            # Randomly decide if Fortaleza is home or away
            if random.choice([True, False]):
                home_team = fortaleza_team
                away_team = opponent
            else:
                home_team = opponent
                away_team = fortaleza_team
            
            # Random scores
            home_score = random.randint(70, 120)
            away_score = random.randint(70, 120)
            
            game = Game.objects.create(
                competition=nbb_competition,
                home_team=home_team,
                away_team=away_team,
                game_date=datetime.date.today() - datetime.timedelta(days=random.randint(1, 365)),
                home_team_score=home_score,
                away_team_score=away_score,
            )
            games.append(game)
        
        # Create 30 additional games (non-Fortaleza)
        for i in range(30):
            # Random teams (excluding Fortaleza for variety)
            available_teams = [team for team in all_teams if team != fortaleza_team]
            home_team = random.choice(available_teams)
            away_team = random.choice([team for team in available_teams if team != home_team])
            
            # Random scores
            home_score = random.randint(70, 120)
            away_score = random.randint(70, 120)
            
            game = Game.objects.create(
                competition=nbb_competition,
                home_team=home_team,
                away_team=away_team,
                game_date=datetime.date.today() - datetime.timedelta(days=random.randint(1, 365)),
                home_team_score=home_score,
                away_team_score=away_score,
            )
            games.append(game)
        
        self.stdout.write(f"  - Created {len(games)} games total")
        self.stdout.write(f"  - {20} Fortaleza games")
        self.stdout.write(f"  - {30} other games")

        # --- 7. CREATE SAMPLE POSSESSIONS ---
        self.stdout.write("Creating sample possessions for games...")
        outcomes = [choice[0] for choice in Possession.OutcomeChoices.choices]
        offensive_sets = [
            choice[0] for choice in Possession.OffensiveSetChoices.choices
        ]
        defensive_sets = [
            choice[0] for choice in Possession.DefensiveSetChoices.choices
        ]
        pnr_types = [choice[0] for choice in Possession.PnRTypeChoices.choices]
        pnr_results = [choice[0] for choice in Possession.PnRResultChoices.choices]
        defensive_pnr = [choice[0] for choice in Possession.DefensivePnRChoices.choices]
        shoot_qualities = [
            choice[0] for choice in Possession.ShootQualityChoices.choices
        ]
        time_ranges = [choice[0] for choice in Possession.TimeRangeChoices.choices]

        # Define realistic offensive and defensive sequences
        offensive_sequences = [
            "Pass -> Screen -> Shot",
            "Dribble -> Pass -> Paint Touch -> Kick Out -> Shot",
            "Handoff -> Screen -> Drive -> Pass -> Shot",
            "Post Up -> Double Team -> Pass -> Shot",
            "Transition -> Fast Break -> Layup",
            "Pick and Roll -> Roll -> Pass -> Shot",
            "Pick and Pop -> Pop -> Shot",
            "Backdoor Cut -> Pass -> Layup",
            "Flare Screen -> Catch -> Shot",
            "Isolation -> Drive -> Shot",
            "Offensive Rebound -> Putback",
            "Pass -> Pass -> Pass -> Shot",
            "Screen -> Roll -> Pass -> Paint Touch -> Shot",
            "Handoff -> Drive -> Pass -> Shot",
            "Post Up -> Shot",
        ]

        defensive_sequences = [
            "Man to Man -> Contest -> Rebound",
            "Zone 2-3 -> Close Out -> Contest",
            "Press -> Trap -> Steal",
            "Switch -> Contest -> Block",
            "Ice -> Force Baseline -> Contest",
            "Go Over -> Contest -> Rebound",
            "Box Out -> Rebound",
            "Help Defense -> Rotate -> Contest",
            "Double Team -> Rotate -> Contest",
            "Trap -> Rotate -> Contest",
            "Deny -> Steal",
            "Close Out -> Contest -> Rebound",
            "Help -> Contest -> Rebound",
            "Switch -> Contest -> Rebound",
            "No Help -> Contest -> Rebound",
        ]

        for game in games:
            for i in range(
                random.randint(15, 30)
            ):  # Create a random number of possessions
                possession_team = random.choice([game.home_team, game.away_team])
                opponent_team = (
                    game.away_team
                    if possession_team == game.home_team
                    else game.home_team
                )
                quarter = random.randint(1, 4)

                # Determine if this is an offensive or defensive possession
                is_offensive_possession = random.choice([True, False])
                
                # Select appropriate sequences based on possession type
                if is_offensive_possession:
                    offensive_sequence = random.choice(offensive_sequences)
                    defensive_sequence = ""
                else:
                    offensive_sequence = ""
                    defensive_sequence = random.choice(defensive_sequences)

                Possession.objects.create(
                    game=game,
                    team=possession_team,
                    opponent=opponent_team,
                    quarter=quarter,
                    start_time_in_game=f"{random.randint(0,11):02}:{random.randint(0,59):02}",
                    duration_seconds=random.randint(5, 24),
                    outcome=random.choice(outcomes),
                    points_scored=random.randint(0, 3),
                    offensive_set=random.choice(offensive_sets),
                    pnr_type=random.choice(pnr_types),
                    pnr_result=random.choice(pnr_results),
                    has_paint_touch=random.choice([True, False]),
                    has_kick_out=random.choice([True, False]),
                    has_extra_pass=random.choice([True, False]),
                    number_of_passes=random.randint(1, 5),
                    is_offensive_rebound=random.choice([True, False]),
                    offensive_rebound_count=random.randint(0, 3),
                    defensive_set=random.choice(defensive_sets),
                    defensive_pnr=random.choice(defensive_pnr),
                    box_out_count=random.randint(0, 4),
                    offensive_rebounds_allowed=random.randint(0, 2),
                    shoot_time=random.randint(5, 20),
                    shoot_quality=random.choice(shoot_qualities),
                    time_range=random.choice(time_ranges),
                    after_timeout=random.choice([True, False]),
                    offensive_sequence=offensive_sequence,
                    defensive_sequence=defensive_sequence,
                    notes=f"Sample possession {i+1}",
                    created_by=superuser,
                )

        self.stdout.write(self.style.SUCCESS("--- Database Population Complete! ---"))
