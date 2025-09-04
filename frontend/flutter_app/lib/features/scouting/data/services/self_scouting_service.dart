// lib/features/scouting/data/services/self_scouting_service.dart

import 'dart:convert';
import '../models/self_scouting_data.dart';
import '../../../../core/services/api_service.dart';

class SelfScoutingService {
  final ApiService _apiService;

  SelfScoutingService(this._apiService);

  Future<SelfScoutingData> getSelfScoutingData() async {
    try {
      final response = await _apiService.get('/scouting/self_scouting/');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        try {
          final selfScoutingData = SelfScoutingData.fromJson(data);
          return selfScoutingData;
        } catch (parseError) {
          throw Exception('Failed to parse self scouting data: $parseError');
        }
      } else {
        throw Exception('Failed to load self scouting data: ${response.statusCode}');
      }
    } catch (e) {
      // For now, fall back to mock data if API fails
      // print('API call failed, using mock data: $e');
      return getMockSelfScoutingData();
    }
  }

  Future<SelfScoutingData> getMockSelfScoutingData() async {
    // Return mock data for development/testing
    return SelfScoutingData(
      playerProfile: PlayerProfile(
        name: "João Silva",
        position: "PG",
        jerseyNumber: 7,
        team: "Flamengo Basquete",
        gamesPlayed: 28,
        minutesPerGame: 25.3,
        totalPoints: 342,
        pointsPerGame: 12.2,
        totalAssists: 156,
        assistsPerGame: 5.6,
        totalRebounds: 89,
        reboundsPerGame: 3.2,
        totalSteals: 45,
        stealsPerGame: 1.6,
        totalBlocks: 12,
        blocksPerGame: 0.4,
        totalTurnovers: 67,
        turnoversPerGame: 2.4,
        fieldGoalPercentage: 0.456,
        threePointPercentage: 0.378,
        freeThrowPercentage: 0.823,
        plusMinus: 156,
        strengths: [
          "Excellent court vision and passing",
          "Strong defensive instincts",
          "Clutch free throw shooting",
          "Leadership on court"
        ],
        areasForImprovement: [
          "Reduce turnovers",
          "Improve 3PT consistency",
          "Better shot selection"
        ],
      ),
      teamPerformance: TeamPerformance(
        teamName: "Flamengo Basquete",
        wins: 22,
        losses: 6,
        winPercentage: 0.786,
        gamesPlayed: 28,
        totalPoints: 2345,
        totalPointsAllowed: 1987,
        pointsPerGame: 83.8,
        pointsAllowedPerGame: 71.0,
        pointDifferential: 12.8,
        totalRebounds: 1123,
        reboundsPerGame: 40.1,
        totalAssists: 678,
        assistsPerGame: 24.2,
        totalSteals: 234,
        stealsPerGame: 8.4,
        totalBlocks: 156,
        blocksPerGame: 5.6,
        totalTurnovers: 445,
        turnoversPerGame: 15.9,
        fieldGoalPercentage: 0.478,
        fieldGoalPercentageAllowed: 0.412,
        threePointPercentage: 0.365,
        threePointPercentageAllowed: 0.334,
        offensiveRating: 112,
        defensiveRating: 98,
        netRating: 13,
        teamStyle: "fast_paced",
        teamStrength: "offensive",
        teamStrengths: [
          "High-scoring offense",
          "Fast break efficiency",
          "Three-point shooting",
          "Team chemistry"
        ],
        teamWeaknesses: [
          "Turnover prone",
          "Defensive rebounding",
          "Foul discipline"
        ],
      ),
      seasonStats: SeasonStats(
        currentSeason: 2025,
        totalGames: 28,
        totalWins: 22,
        totalLosses: 6,
        overallWinPercentage: 0.786,
        totalPoints: 2345,
        averagePointsPerGame: 83.8,
        totalRebounds: 1123,
        averageReboundsPerGame: 40.1,
        totalAssists: 678,
        averageAssistsPerGame: 24.2,
        totalSteals: 234,
        averageStealsPerGame: 8.4,
        totalBlocks: 156,
        averageBlocksPerGame: 5.6,
        totalTurnovers: 445,
        averageTurnoversPerGame: 15.9,
        overallFieldGoalPercentage: 0.478,
        overallThreePointPercentage: 0.365,
        overallFreeThrowPercentage: 0.789,
        monthlyPerformance: [
          MonthlyPerformance(
            month: "October",
            gamesPlayed: 8,
            wins: 7,
            losses: 1,
            winPercentage: 0.875,
            averagePointsPerGame: 85.2,
            averageReboundsPerGame: 41.3,
            averageAssistsPerGame: 25.1,
          ),
          MonthlyPerformance(
            month: "November",
            gamesPlayed: 7,
            wins: 6,
            losses: 1,
            winPercentage: 0.857,
            averagePointsPerGame: 82.7,
            averageReboundsPerGame: 39.8,
            averageAssistsPerGame: 23.9,
          ),
          MonthlyPerformance(
            month: "December",
            gamesPlayed: 6,
            wins: 4,
            losses: 2,
            winPercentage: 0.667,
            averagePointsPerGame: 81.3,
            averageReboundsPerGame: 38.9,
            averageAssistsPerGame: 22.7,
          ),
          MonthlyPerformance(
            month: "January",
            gamesPlayed: 7,
            wins: 5,
            losses: 2,
            winPercentage: 0.714,
            averagePointsPerGame: 84.1,
            averageReboundsPerGame: 40.2,
            averageAssistsPerGame: 24.8,
          ),
        ],
        opponentPerformance: [
          OpponentPerformance(
            opponentName: "Franca Basquete",
            gamesPlayed: 3,
            wins: 2,
            losses: 1,
            winPercentage: 0.667,
            averagePointsFor: 87.3,
            averagePointsAgainst: 82.1,
            pointDifferential: 5.2,
          ),
          OpponentPerformance(
            opponentName: "São Paulo F.C.",
            gamesPlayed: 3,
            wins: 1,
            losses: 2,
            winPercentage: 0.333,
            averagePointsFor: 79.7,
            averagePointsAgainst: 85.3,
            pointDifferential: -5.6,
          ),
        ],
      ),
      recentGames: RecentGames(
        lastFiveGames: [
          GameResult(
            opponent: "Bauru Basket",
            result: "W",
            teamScore: 89,
            opponentScore: 76,
            date: "2025-01-15",
            venue: "Home",
            playerPoints: 18,
            playerRebounds: 4,
            playerAssists: 7,
            playerMinutes: 28,
            plusMinus: 12,
          ),
          GameResult(
            opponent: "Pinheiros",
            result: "W",
            teamScore: 94,
            opponentScore: 82,
            date: "2025-01-12",
            venue: "Away",
            playerPoints: 15,
            playerRebounds: 3,
            playerAssists: 9,
            playerMinutes: 26,
            plusMinus: 8,
          ),
          GameResult(
            opponent: "Minas Tênis Clube",
            result: "L",
            teamScore: 78,
            opponentScore: 85,
            date: "2025-01-08",
            venue: "Away",
            playerPoints: 12,
            playerRebounds: 2,
            playerAssists: 4,
            playerMinutes: 24,
            plusMinus: -7,
          ),
          GameResult(
            opponent: "Mogi das Cruzes",
            result: "W",
            teamScore: 91,
            opponentScore: 73,
            date: "2025-01-05",
            venue: "Home",
            playerPoints: 20,
            playerRebounds: 5,
            playerAssists: 8,
            playerMinutes: 30,
            plusMinus: 15,
          ),
          GameResult(
            opponent: "Limeira",
            result: "W",
            teamScore: 87,
            opponentScore: 79,
            date: "2025-01-01",
            venue: "Away",
            playerPoints: 14,
            playerRebounds: 3,
            playerAssists: 6,
            playerMinutes: 25,
            plusMinus: 6,
          ),
        ],
        lastTenGames: [],
        nextGame: GameResult(
          opponent: "Franca Basquete",
          result: "",
          teamScore: 0,
          opponentScore: 0,
          date: "2025-01-20",
          venue: "Home",
          playerPoints: 0,
          playerRebounds: 0,
          playerAssists: 0,
          playerMinutes: 0,
          plusMinus: 0,
        ),
        upcomingGames: [
          UpcomingGame(
            opponent: "Franca Basquete",
            date: "2025-01-20",
            venue: "Home",
            competition: "Temporada 2025-2026",
            opponentRecord: "19-9",
            opponentStyle: "defensive",
          ),
          UpcomingGame(
            opponent: "São Paulo F.C.",
            date: "2025-01-25",
            venue: "Away",
            competition: "Temporada 2025-2026",
            opponentRecord: "20-8",
            opponentStyle: "balanced",
          ),
        ],
      ),
      playerComparison: PlayerComparison(
        metrics: [
          ComparisonMetric(
            metric: "Points Per Game",
            playerValue: 12.2,
            leagueAverage: 10.8,
            leaguePercentile: 75.0,
            trend: "up",
          ),
          ComparisonMetric(
            metric: "Assists Per Game",
            playerValue: 5.6,
            leagueAverage: 4.2,
            leaguePercentile: 85.0,
            trend: "stable",
          ),
          ComparisonMetric(
            metric: "Field Goal %",
            playerValue: 45.6,
            leagueAverage: 43.2,
            leaguePercentile: 70.0,
            trend: "up",
          ),
        ],
        positionComparisons: [
          PositionComparison(
            position: "PG",
            pointsPerGame: 12.2,
            reboundsPerGame: 3.2,
            assistsPerGame: 5.6,
            fieldGoalPercentage: 45.6,
            threePointPercentage: 37.8,
          ),
        ],
        teamComparisons: [
          TeamComparison(
            teamName: "Flamengo Basquete",
            pointsPerGame: 83.8,
            reboundsPerGame: 40.1,
            assistsPerGame: 24.2,
            fieldGoalPercentage: 47.8,
            threePointPercentage: 36.5,
          ),
        ],
      ),
      teamChemistry: TeamChemistry(
        bestLineups: [
          LineupPerformance(
            players: ["João Silva", "Carlos Santos", "Rafael Oliveira", "Thiago Costa", "Bruno Lima"],
            minutesPlayed: 156,
            offensiveRating: 118.5,
            defensiveRating: 95.2,
            netRating: 23.3,
            plusMinus: 89,
          ),
        ],
        topPartnerships: [
          PlayerPartnership(
            player1: "João Silva",
            player2: "Carlos Santos",
            minutesPlayed: 234,
            plusMinus: 67,
            offensiveRating: 115.3,
            defensiveRating: 97.8,
            synergy: "Excellent",
          ),
        ],
        emergingPartnerships: [
          PlayerPartnership(
            player1: "João Silva",
            player2: "Rafael Oliveira",
            minutesPlayed: 189,
            plusMinus: 34,
            offensiveRating: 108.7,
            defensiveRating: 101.2,
            synergy: "Good",
          ),
        ],
        teamStrengths: [
          "Excellent ball movement",
          "Strong pick-and-roll execution",
          "Fast break efficiency",
          "Three-point shooting depth"
        ],
        teamWeaknesses: [
          "Turnover prone in pressure situations",
          "Defensive rebounding consistency",
          "Foul discipline in close games"
        ],
        improvementAreas: [
          "Reduce turnovers in clutch situations",
          "Improve defensive rebounding",
          "Better foul discipline",
          "Enhance late-game execution"
        ],
      ),
      seasonStorylines: SeasonStorylines(
        playerStorylines: [
          PlayerStoryline(
            title: "Breakout Season for João Silva",
            description: "João has emerged as the team's primary playmaker, leading the league in assists while maintaining efficient scoring.",
            type: "breakout",
            impact: "positive",
            date: "2025-01-15",
          ),
          PlayerStoryline(
            title: "Improved Three-Point Shooting",
            description: "João's 3PT% has improved from 32% to 37.8% this season, making him a more complete offensive threat.",
            type: "improvement",
            impact: "positive",
            date: "2025-01-10",
          ),
        ],
        teamStorylines: [
          TeamStoryline(
            title: "Offensive Juggernaut",
            description: "Flamengo leads the league in scoring with 83.8 PPG, showcasing their fast-paced offensive style.",
            type: "performance",
            impact: "positive",
            date: "2025-01-15",
          ),
          TeamStoryline(
            title: "Chemistry Building",
            description: "The team has developed excellent chemistry, with the starting lineup posting a +23.3 net rating.",
            type: "chemistry",
            impact: "positive",
            date: "2025-01-12",
          ),
        ],
        rivalryStorylines: [
          RivalryStoryline(
            opponent: "Franca Basquete",
            title: "Championship Rivalry Intensifies",
            description: "The rivalry with Franca has reached new heights after last season's championship series.",
            intensity: "High",
            history: "Multiple championship meetings, intense regular season battles",
            date: "2025-01-20",
          ),
          RivalryStoryline(
            opponent: "São Paulo F.C.",
            title: "Classic Rivalry Renewed",
            description: "The biggest clubs in Brazil continue their historic rivalry with high-stakes matchups.",
            intensity: "High",
            history: "Decades of competition, largest fan bases in Brazil",
            date: "2025-01-25",
          ),
        ],
        seasonHighlights: [
          SeasonHighlight(
            title: "28-Point Comeback Victory",
            description: "Flamengo overcame a 28-point deficit to defeat Bauru Basket in overtime, showcasing incredible resilience.",
            type: "game",
            date: "2025-01-15",
            impact: "Team morale boost, confidence building",
          ),
          SeasonHighlight(
            title: "Record Three-Point Shooting",
            description: "Team set a new franchise record with 18 three-pointers in a single game against Pinheiros.",
            type: "performance",
            date: "2025-01-12",
            impact: "Offensive confidence, league recognition",
          ),
        ],
        seasonChallenges: [
          SeasonChallenge(
            title: "Injury to Key Player",
            description: "Starting center Bruno Lima suffered a minor ankle sprain, testing team depth.",
            type: "injury",
            severity: "Low",
            status: "Resolved",
            date: "2025-01-08",
          ),
          SeasonChallenge(
            title: "Turnover Issues in Close Games",
            description: "Team has struggled with turnovers in clutch situations, affecting late-game execution.",
            type: "performance",
            severity: "Medium",
            status: "Ongoing",
            date: "2025-01-15",
          ),
        ],
      ),
    );
  }
}
