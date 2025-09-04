// lib/features/scouting/data/models/self_scouting_data.dart

class SelfScoutingData {
  final PlayerProfile playerProfile;
  final TeamPerformance teamPerformance;
  final SeasonStats seasonStats;
  final RecentGames recentGames;
  final PlayerComparison playerComparison;
  final TeamChemistry teamChemistry;
  final SeasonStorylines seasonStorylines;

  SelfScoutingData({
    required this.playerProfile,
    required this.teamPerformance,
    required this.seasonStats,
    required this.recentGames,
    required this.playerComparison,
    required this.teamChemistry,
    required this.seasonStorylines,
  });

  factory SelfScoutingData.fromJson(Map<String, dynamic> json) {
    return SelfScoutingData(
      playerProfile: PlayerProfile.fromJson(json['player_profile']),
      teamPerformance: TeamPerformance.fromJson(json['team_performance']),
      seasonStats: SeasonStats.fromJson(json['season_stats']),
      recentGames: RecentGames.fromJson(json['recent_games']),
      playerComparison: PlayerComparison.fromJson(json['player_comparison']),
      teamChemistry: TeamChemistry.fromJson(json['team_chemistry']),
      seasonStorylines: SeasonStorylines.fromJson(json['season_storylines']),
    );
  }
}

class PlayerProfile {
  final String name;
  final String position;
  final int jerseyNumber;
  final String team;
  final int gamesPlayed;
  final double minutesPerGame;
  final int totalPoints;
  final double pointsPerGame;
  final int totalAssists;
  final double assistsPerGame;
  final int totalRebounds;
  final double reboundsPerGame;
  final int totalSteals;
  final double stealsPerGame;
  final int totalBlocks;
  final double blocksPerGame;
  final int totalTurnovers;
  final double turnoversPerGame;
  final double fieldGoalPercentage;
  final double threePointPercentage;
  final double freeThrowPercentage;
  final double plusMinus;
  final List<String> strengths;
  final List<String> areasForImprovement;

  PlayerProfile({
    required this.name,
    required this.position,
    required this.jerseyNumber,
    required this.team,
    required this.gamesPlayed,
    required this.minutesPerGame,
    required this.totalPoints,
    required this.pointsPerGame,
    required this.totalAssists,
    required this.assistsPerGame,
    required this.totalRebounds,
    required this.reboundsPerGame,
    required this.totalSteals,
    required this.stealsPerGame,
    required this.totalBlocks,
    required this.blocksPerGame,
    required this.totalTurnovers,
    required this.turnoversPerGame,
    required this.fieldGoalPercentage,
    required this.threePointPercentage,
    required this.freeThrowPercentage,
    required this.plusMinus,
    required this.strengths,
    required this.areasForImprovement,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      jerseyNumber: json['jersey_number'] ?? 0,
      team: json['team'] ?? '',
      gamesPlayed: json['games_played'] ?? 0,
      minutesPerGame: (json['minutes_per_game'] ?? 0.0).toDouble(),
      totalPoints: json['total_points'] ?? 0,
      pointsPerGame: (json['points_per_game'] ?? 0.0).toDouble(),
      totalAssists: json['total_assists'] ?? 0,
      assistsPerGame: (json['assists_per_game'] ?? 0.0).toDouble(),
      totalRebounds: json['total_rebounds'] ?? 0,
      reboundsPerGame: (json['rebounds_per_game'] ?? 0.0).toDouble(),
      totalSteals: json['total_steals'] ?? 0,
      stealsPerGame: (json['steals_per_game'] ?? 0.0).toDouble(),
      totalBlocks: json['total_blocks'] ?? 0,
      blocksPerGame: (json['blocks_per_game'] ?? 0.0).toDouble(),
      totalTurnovers: json['total_turnovers'] ?? 0,
      turnoversPerGame: (json['turnovers_per_game'] ?? 0.0).toDouble(),
      fieldGoalPercentage: (json['field_goal_percentage'] ?? 0.0).toDouble(),
      threePointPercentage: (json['three_point_percentage'] ?? 0.0).toDouble(),
      freeThrowPercentage: (json['free_throw_percentage'] ?? 0.0).toDouble(),
      plusMinus: (json['plus_minus'] ?? 0.0).toDouble(),
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement: List<String>.from(json['areas_for_improvement'] ?? []),
    );
  }
}

class TeamPerformance {
  final String teamName;
  final int wins;
  final int losses;
  final double winPercentage;
  final int gamesPlayed;
  final int totalPoints;
  final int totalPointsAllowed;
  final double pointsPerGame;
  final double pointsAllowedPerGame;
  final double pointDifferential;
  final int totalRebounds;
  final double reboundsPerGame;
  final int totalAssists;
  final double assistsPerGame;
  final int totalSteals;
  final double stealsPerGame;
  final int totalBlocks;
  final double blocksPerGame;
  final int totalTurnovers;
  final double turnoversPerGame;
  final double fieldGoalPercentage;
  final double fieldGoalPercentageAllowed;
  final double threePointPercentage;
  final double threePointPercentageAllowed;
  final int offensiveRating;
  final int defensiveRating;
  final int netRating;
  final String teamStyle;
  final String teamStrength;
  final List<String> teamStrengths;
  final List<String> teamWeaknesses;

  TeamPerformance({
    required this.teamName,
    required this.wins,
    required this.losses,
    required this.winPercentage,
    required this.gamesPlayed,
    required this.totalPoints,
    required this.totalPointsAllowed,
    required this.pointsPerGame,
    required this.pointsAllowedPerGame,
    required this.pointDifferential,
    required this.totalRebounds,
    required this.reboundsPerGame,
    required this.totalAssists,
    required this.assistsPerGame,
    required this.totalSteals,
    required this.stealsPerGame,
    required this.totalBlocks,
    required this.blocksPerGame,
    required this.totalTurnovers,
    required this.turnoversPerGame,
    required this.fieldGoalPercentage,
    required this.fieldGoalPercentageAllowed,
    required this.threePointPercentage,
    required this.threePointPercentageAllowed,
    required this.offensiveRating,
    required this.defensiveRating,
    required this.netRating,
    required this.teamStyle,
    required this.teamStrength,
    required this.teamStrengths,
    required this.teamWeaknesses,
  });

  factory TeamPerformance.fromJson(Map<String, dynamic> json) {
    return TeamPerformance(
      teamName: json['team_name'] ?? '',
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      winPercentage: (json['win_percentage'] ?? 0.0).toDouble(),
      gamesPlayed: json['games_played'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      totalPointsAllowed: json['total_points_allowed'] ?? 0,
      pointsPerGame: (json['points_per_game'] ?? 0.0).toDouble(),
      pointsAllowedPerGame: (json['points_allowed_per_game'] ?? 0.0).toDouble(),
      pointDifferential: (json['point_differential'] ?? 0.0).toDouble(),
      totalRebounds: json['total_rebounds'] ?? 0,
      reboundsPerGame: (json['rebounds_per_game'] ?? 0.0).toDouble(),
      totalAssists: json['total_assists'] ?? 0,
      assistsPerGame: (json['assists_per_game'] ?? 0.0).toDouble(),
      totalSteals: json['total_steals'] ?? 0,
      stealsPerGame: (json['steals_per_game'] ?? 0.0).toDouble(),
      totalBlocks: json['total_blocks'] ?? 0,
      blocksPerGame: (json['blocks_per_game'] ?? 0.0).toDouble(),
      totalTurnovers: json['total_turnovers'] ?? 0,
      turnoversPerGame: (json['turnovers_per_game'] ?? 0.0).toDouble(),
      fieldGoalPercentage: (json['field_goal_percentage'] ?? 0.0).toDouble(),
      fieldGoalPercentageAllowed: (json['field_goal_percentage_allowed'] ?? 0.0).toDouble(),
      threePointPercentage: (json['three_point_percentage'] ?? 0.0).toDouble(),
      threePointPercentageAllowed: (json['three_point_percentage_allowed'] ?? 0.0).toDouble(),
      offensiveRating: json['offensive_rating'] ?? 0,
      defensiveRating: json['defensive_rating'] ?? 0,
      netRating: json['net_rating'] ?? 0,
      teamStyle: json['team_style'] ?? '',
      teamStrength: json['team_strength'] ?? '',
      teamStrengths: List<String>.from(json['team_strengths'] ?? []),
      teamWeaknesses: List<String>.from(json['team_weaknesses'] ?? []),
    );
  }
}

class SeasonStats {
  final int currentSeason;
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final double overallWinPercentage;
  final int totalPoints;
  final double averagePointsPerGame;
  final int totalRebounds;
  final double averageReboundsPerGame;
  final int totalAssists;
  final double averageAssistsPerGame;
  final int totalSteals;
  final double averageStealsPerGame;
  final int totalBlocks;
  final double averageBlocksPerGame;
  final int totalTurnovers;
  final double averageTurnoversPerGame;
  final double overallFieldGoalPercentage;
  final double overallThreePointPercentage;
  final double overallFreeThrowPercentage;
  final List<MonthlyPerformance> monthlyPerformance;
  final List<OpponentPerformance> opponentPerformance;

  SeasonStats({
    required this.currentSeason,
    required this.totalGames,
    required this.totalWins,
    required this.totalLosses,
    required this.overallWinPercentage,
    required this.totalPoints,
    required this.averagePointsPerGame,
    required this.totalRebounds,
    required this.averageReboundsPerGame,
    required this.totalAssists,
    required this.averageAssistsPerGame,
    required this.totalSteals,
    required this.averageStealsPerGame,
    required this.totalBlocks,
    required this.averageBlocksPerGame,
    required this.totalTurnovers,
    required this.averageTurnoversPerGame,
    required this.overallFieldGoalPercentage,
    required this.overallThreePointPercentage,
    required this.overallFreeThrowPercentage,
    required this.monthlyPerformance,
    required this.opponentPerformance,
  });

  factory SeasonStats.fromJson(Map<String, dynamic> json) {
    return SeasonStats(
      currentSeason: json['current_season'] ?? 0,
      totalGames: json['total_games'] ?? 0,
      totalWins: json['total_wins'] ?? 0,
      totalLosses: json['total_losses'] ?? 0,
      overallWinPercentage: (json['overall_win_percentage'] ?? 0.0).toDouble(),
      totalPoints: json['total_points'] ?? 0,
      averagePointsPerGame: (json['average_points_per_game'] ?? 0.0).toDouble(),
      totalRebounds: json['total_rebounds'] ?? 0,
      averageReboundsPerGame: (json['average_rebounds_per_game'] ?? 0.0).toDouble(),
      totalAssists: json['total_assists'] ?? 0,
      averageAssistsPerGame: (json['average_assists_per_game'] ?? 0.0).toDouble(),
      totalSteals: json['total_steals'] ?? 0,
      averageStealsPerGame: (json['average_steals_per_game'] ?? 0.0).toDouble(),
      totalBlocks: json['total_blocks'] ?? 0,
      averageBlocksPerGame: (json['average_blocks_per_game'] ?? 0.0).toDouble(),
      totalTurnovers: json['total_turnovers'] ?? 0,
      averageTurnoversPerGame: (json['average_turnovers_per_game'] ?? 0.0).toDouble(),
      overallFieldGoalPercentage: (json['overall_field_goal_percentage'] ?? 0.0).toDouble(),
      overallThreePointPercentage: (json['overall_three_point_percentage'] ?? 0.0).toDouble(),
      overallFreeThrowPercentage: (json['overall_free_throw_percentage'] ?? 0.0).toDouble(),
      monthlyPerformance: (json['monthly_performance'] as List?)
          ?.map((e) => MonthlyPerformance.fromJson(e))
          .toList() ?? [],
      opponentPerformance: (json['opponent_performance'] as List?)
          ?.map((e) => OpponentPerformance.fromJson(e))
          .toList() ?? [],
    );
  }
}

class MonthlyPerformance {
  final String month;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final double winPercentage;
  final double averagePointsPerGame;
  final double averageReboundsPerGame;
  final double averageAssistsPerGame;

  MonthlyPerformance({
    required this.month,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.winPercentage,
    required this.averagePointsPerGame,
    required this.averageReboundsPerGame,
    required this.averageAssistsPerGame,
  });

  factory MonthlyPerformance.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformance(
      month: json['month'] ?? '',
      gamesPlayed: json['games_played'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      winPercentage: (json['win_percentage'] ?? 0.0).toDouble(),
      averagePointsPerGame: (json['average_points_per_game'] ?? 0.0).toDouble(),
      averageReboundsPerGame: (json['average_rebounds_per_game'] ?? 0.0).toDouble(),
      averageAssistsPerGame: (json['average_assists_per_game'] ?? 0.0).toDouble(),
    );
  }
}

class OpponentPerformance {
  final String opponentName;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final double winPercentage;
  final double averagePointsFor;
  final double averagePointsAgainst;
  final double pointDifferential;

  OpponentPerformance({
    required this.opponentName,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.winPercentage,
    required this.averagePointsFor,
    required this.averagePointsAgainst,
    required this.pointDifferential,
  });

  factory OpponentPerformance.fromJson(Map<String, dynamic> json) {
    return OpponentPerformance(
      opponentName: json['opponent_name'] ?? '',
      gamesPlayed: json['games_played'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      winPercentage: (json['win_percentage'] ?? 0.0).toDouble(),
      averagePointsFor: (json['average_points_for'] ?? 0.0).toDouble(),
      averagePointsAgainst: (json['average_points_against'] ?? 0.0).toDouble(),
      pointDifferential: (json['point_differential'] ?? 0.0).toDouble(),
    );
  }
}

class RecentGames {
  final List<GameResult> lastFiveGames;
  final List<GameResult> lastTenGames;
  final GameResult nextGame;
  final List<UpcomingGame> upcomingGames;

  RecentGames({
    required this.lastFiveGames,
    required this.lastTenGames,
    required this.nextGame,
    required this.upcomingGames,
  });

  factory RecentGames.fromJson(Map<String, dynamic> json) {
    return RecentGames(
      lastFiveGames: (json['last_five_games'] as List?)
          ?.map((e) => GameResult.fromJson(e))
          .toList() ?? [],
      lastTenGames: (json['last_ten_games'] as List?)
          ?.map((e) => GameResult.fromJson(e))
          .toList() ?? [],
      nextGame: GameResult.fromJson(json['next_game'] ?? {}),
      upcomingGames: (json['upcoming_games'] as List?)
          ?.map((e) => UpcomingGame.fromJson(e))
          .toList() ?? [],
    );
  }
}

class GameResult {
  final String opponent;
  final String result; // "W" or "L"
  final int teamScore;
  final int opponentScore;
  final String date;
  final String venue; // "Home" or "Away"
  final int playerPoints;
  final int playerRebounds;
  final int playerAssists;
  final int playerMinutes;
  final double plusMinus;

  GameResult({
    required this.opponent,
    required this.result,
    required this.teamScore,
    required this.opponentScore,
    required this.date,
    required this.venue,
    required this.playerPoints,
    required this.playerRebounds,
    required this.playerAssists,
    required this.playerMinutes,
    required this.plusMinus,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      opponent: json['opponent'] ?? '',
      result: json['result'] ?? '',
      teamScore: json['team_score'] ?? 0,
      opponentScore: json['opponent_score'] ?? 0,
      date: json['date'] ?? '',
      venue: json['venue'] ?? '',
      playerPoints: json['player_points'] ?? 0,
      playerRebounds: json['player_rebounds'] ?? 0,
      playerAssists: json['player_assists'] ?? 0,
      playerMinutes: json['player_minutes'] ?? 0,
      plusMinus: (json['plus_minus'] ?? 0.0).toDouble(),
    );
  }
}

class UpcomingGame {
  final String opponent;
  final String date;
  final String venue;
  final String competition;
  final String opponentRecord;
  final String opponentStyle;

  UpcomingGame({
    required this.opponent,
    required this.date,
    required this.venue,
    required this.competition,
    required this.opponentRecord,
    required this.opponentStyle,
  });

  factory UpcomingGame.fromJson(Map<String, dynamic> json) {
    return UpcomingGame(
      opponent: json['opponent'] ?? '',
      date: json['date'] ?? '',
      venue: json['venue'] ?? '',
      competition: json['competition'] ?? '',
      opponentRecord: json['opponent_record'] ?? '',
      opponentStyle: json['opponent_style'] ?? '',
    );
  }
}

class PlayerComparison {
  final List<ComparisonMetric> metrics;
  final List<PositionComparison> positionComparisons;
  final List<TeamComparison> teamComparisons;

  PlayerComparison({
    required this.metrics,
    required this.positionComparisons,
    required this.teamComparisons,
  });

  factory PlayerComparison.fromJson(Map<String, dynamic> json) {
    return PlayerComparison(
      metrics: (json['metrics'] as List?)
          ?.map((e) => ComparisonMetric.fromJson(e))
          .toList() ?? [],
      positionComparisons: (json['position_comparisons'] as List?)
          ?.map((e) => PositionComparison.fromJson(e))
          .toList() ?? [],
      teamComparisons: (json['team_comparisons'] as List?)
          ?.map((e) => TeamComparison.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ComparisonMetric {
  final String metric;
  final double playerValue;
  final double leagueAverage;
  final double leaguePercentile;
  final String trend; // "up", "down", "stable"

  ComparisonMetric({
    required this.metric,
    required this.playerValue,
    required this.leagueAverage,
    required this.leaguePercentile,
    required this.trend,
  });

  factory ComparisonMetric.fromJson(Map<String, dynamic> json) {
    return ComparisonMetric(
      metric: json['metric'] ?? '',
      playerValue: (json['player_value'] ?? 0.0).toDouble(),
      leagueAverage: (json['league_average'] ?? 0.0).toDouble(),
      leaguePercentile: (json['league_percentile'] ?? 0.0).toDouble(),
      trend: json['trend'] ?? '',
    );
  }
}

class PositionComparison {
  final String position;
  final double pointsPerGame;
  final double reboundsPerGame;
  final double assistsPerGame;
  final double fieldGoalPercentage;
  final double threePointPercentage;

  PositionComparison({
    required this.position,
    required this.pointsPerGame,
    required this.reboundsPerGame,
    required this.assistsPerGame,
    required this.fieldGoalPercentage,
    required this.threePointPercentage,
  });

  factory PositionComparison.fromJson(Map<String, dynamic> json) {
    return PositionComparison(
      position: json['position'] ?? '',
      pointsPerGame: (json['points_per_game'] ?? 0.0).toDouble(),
      reboundsPerGame: (json['rebounds_per_game'] ?? 0.0).toDouble(),
      assistsPerGame: (json['assists_per_game'] ?? 0.0).toDouble(),
      fieldGoalPercentage: (json['field_goal_percentage'] ?? 0.0).toDouble(),
      threePointPercentage: (json['three_point_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class TeamComparison {
  final String teamName;
  final double pointsPerGame;
  final double reboundsPerGame;
  final double assistsPerGame;
  final double fieldGoalPercentage;
  final double threePointPercentage;

  TeamComparison({
    required this.teamName,
    required this.pointsPerGame,
    required this.reboundsPerGame,
    required this.assistsPerGame,
    required this.fieldGoalPercentage,
    required this.threePointPercentage,
  });

  factory TeamComparison.fromJson(Map<String, dynamic> json) {
    return TeamComparison(
      teamName: json['team_name'] ?? '',
      pointsPerGame: (json['points_per_game'] ?? 0.0).toDouble(),
      reboundsPerGame: (json['rebounds_per_game'] ?? 0.0).toDouble(),
      assistsPerGame: (json['assists_per_game'] ?? 0.0).toDouble(),
      fieldGoalPercentage: (json['field_goal_percentage'] ?? 0.0).toDouble(),
      threePointPercentage: (json['three_point_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class TeamChemistry {
  final List<LineupPerformance> bestLineups;
  final List<PlayerPartnership> topPartnerships;
  final List<PlayerPartnership> emergingPartnerships;
  final List<String> teamStrengths;
  final List<String> teamWeaknesses;
  final List<String> improvementAreas;

  TeamChemistry({
    required this.bestLineups,
    required this.topPartnerships,
    required this.emergingPartnerships,
    required this.teamStrengths,
    required this.teamWeaknesses,
    required this.improvementAreas,
  });

  factory TeamChemistry.fromJson(Map<String, dynamic> json) {
    return TeamChemistry(
      bestLineups: (json['best_lineups'] as List?)
          ?.map((e) => LineupPerformance.fromJson(e))
          .toList() ?? [],
      topPartnerships: (json['top_partnerships'] as List?)
          ?.map((e) => PlayerPartnership.fromJson(e))
          .toList() ?? [],
      emergingPartnerships: (json['emerging_partnerships'] as List?)
          ?.map((e) => PlayerPartnership.fromJson(e))
          .toList() ?? [],
      teamStrengths: List<String>.from(json['team_strengths'] ?? []),
      teamWeaknesses: List<String>.from(json['team_weaknesses'] ?? []),
      improvementAreas: List<String>.from(json['improvement_areas'] ?? []),
    );
  }
}

class LineupPerformance {
  final List<String> players;
  final int minutesPlayed;
  final double offensiveRating;
  final double defensiveRating;
  final double netRating;
  final double plusMinus;

  LineupPerformance({
    required this.players,
    required this.minutesPlayed,
    required this.offensiveRating,
    required this.defensiveRating,
    required this.netRating,
    required this.plusMinus,
  });

  factory LineupPerformance.fromJson(Map<String, dynamic> json) {
    return LineupPerformance(
      players: List<String>.from(json['players'] ?? []),
      minutesPlayed: json['minutes_played'] ?? 0,
      offensiveRating: (json['offensive_rating'] ?? 0.0).toDouble(),
      defensiveRating: (json['defensive_rating'] ?? 0.0).toDouble(),
      netRating: (json['net_rating'] ?? 0.0).toDouble(),
      plusMinus: (json['plus_minus'] ?? 0.0).toDouble(),
    );
  }
}

class PlayerPartnership {
  final String player1;
  final String player2;
  final int minutesPlayed;
  final double plusMinus;
  final double offensiveRating;
  final double defensiveRating;
  final String synergy; // "Excellent", "Good", "Average", "Poor"

  PlayerPartnership({
    required this.player1,
    required this.player2,
    required this.minutesPlayed,
    required this.plusMinus,
    required this.offensiveRating,
    required this.defensiveRating,
    required this.synergy,
  });

  factory PlayerPartnership.fromJson(Map<String, dynamic> json) {
    return PlayerPartnership(
      player1: json['player1'] ?? '',
      player2: json['player2'] ?? '',
      minutesPlayed: json['minutes_played'] ?? 0,
      plusMinus: (json['plus_minus'] ?? 0.0).toDouble(),
      offensiveRating: (json['offensive_rating'] ?? 0.0).toDouble(),
      defensiveRating: (json['defensive_rating'] ?? 0.0).toDouble(),
      synergy: json['synergy'] ?? '',
    );
  }
}

class SeasonStorylines {
  final List<PlayerStoryline> playerStorylines;
  final List<TeamStoryline> teamStorylines;
  final List<RivalryStoryline> rivalryStorylines;
  final List<SeasonHighlight> seasonHighlights;
  final List<SeasonChallenge> seasonChallenges;

  SeasonStorylines({
    required this.playerStorylines,
    required this.teamStorylines,
    required this.rivalryStorylines,
    required this.seasonHighlights,
    required this.seasonChallenges,
  });

  factory SeasonStorylines.fromJson(Map<String, dynamic> json) {
    return SeasonStorylines(
      playerStorylines: (json['player_storylines'] as List?)
          ?.map((e) => PlayerStoryline.fromJson(e))
          .toList() ?? [],
      teamStorylines: (json['team_storylines'] as List?)
          ?.map((e) => TeamStoryline.fromJson(e))
          .toList() ?? [],
      rivalryStorylines: (json['rivalry_storylines'] as List?)
          ?.map((e) => RivalryStoryline.fromJson(e))
          .toList() ?? [],
      seasonHighlights: (json['season_highlights'] as List?)
          ?.map((e) => SeasonHighlight.fromJson(e))
          .toList() ?? [],
      seasonChallenges: (json['season_challenges'] as List?)
          ?.map((e) => SeasonChallenge.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PlayerStoryline {
  final String title;
  final String description;
  final String type; // "breakout", "improvement", "challenge", "milestone"
  final String impact; // "positive", "negative", "neutral"
  final String date;

  PlayerStoryline({
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.date,
  });

  factory PlayerStoryline.fromJson(Map<String, dynamic> json) {
    return PlayerStoryline(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      impact: json['impact'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class TeamStoryline {
  final String title;
  final String description;
  final String type; // "chemistry", "strategy", "performance", "challenge"
  final String impact;
  final String date;

  TeamStoryline({
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.date,
  });

  factory TeamStoryline.fromJson(Map<String, dynamic> json) {
    return TeamStoryline(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      impact: json['impact'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class RivalryStoryline {
  final String opponent;
  final String title;
  final String description;
  final String intensity; // "High", "Medium", "Low"
  final String history;
  final String date;

  RivalryStoryline({
    required this.opponent,
    required this.title,
    required this.description,
    required this.intensity,
    required this.history,
    required this.date,
  });

  factory RivalryStoryline.fromJson(Map<String, dynamic> json) {
    return RivalryStoryline(
      opponent: json['opponent'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      intensity: json['intensity'] ?? '',
      history: json['history'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class SeasonHighlight {
  final String title;
  final String description;
  final String type; // "game", "performance", "team", "individual"
  final String date;
  final String impact;

  SeasonHighlight({
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.impact,
  });

  factory SeasonHighlight.fromJson(Map<String, dynamic> json) {
    return SeasonHighlight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      impact: json['impact'] ?? '',
    );
  }
}

class SeasonChallenge {
  final String title;
  final String description;
  final String type; // "injury", "performance", "team", "external"
  final String severity; // "High", "Medium", "Low"
  final String status; // "Active", "Resolved", "Ongoing"
  final String date;

  SeasonChallenge({
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.date,
  });

  factory SeasonChallenge.fromJson(Map<String, dynamic> json) {
    return SeasonChallenge(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      date: json['date'] ?? '',
    );
  }
}
