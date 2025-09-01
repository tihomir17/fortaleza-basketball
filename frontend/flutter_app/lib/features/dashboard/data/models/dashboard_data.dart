// lib/features/dashboard/data/models/dashboard_data.dart

class DashboardData {
  final QuickStats quickStats;
  final List<RecentActivity> recentActivity;
  final List<UpcomingGame> upcomingGames;
  final List<UpcomingGame> recentGames;
  final List<RecentReport> recentReports;
  final List<QuickAction> quickActions;

  DashboardData({
    required this.quickStats,
    required this.recentActivity,
    required this.upcomingGames,
    required this.recentGames,
    required this.recentReports,
    required this.quickActions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      quickStats: QuickStats.fromJson(json['quick_stats'] ?? {}),
      recentActivity: (json['recent_activity'] as List?)
          ?.map((e) => RecentActivity.fromJson(e))
          .toList() ?? [],
      upcomingGames: (json['upcoming_games'] as List?)
          ?.map((e) => UpcomingGame.fromJson(e))
          .toList() ?? [],
      recentGames: (json['recent_games'] as List?)
          ?.map((e) => UpcomingGame.fromJson(e))
          .toList() ?? [],
      recentReports: (json['recent_reports'] as List?)
          ?.map((e) => RecentReport.fromJson(e))
          .toList() ?? [],
      quickActions: (json['quick_actions'] as List?)
          ?.map((e) => QuickAction.fromJson(e))
          .toList() ?? [],
    );
  }
}

class QuickStats {
  final int totalGames;
  final int totalPossessions;
  final int recentPossessions;
  final double avgPossessionsPerGame;

  QuickStats({
    required this.totalGames,
    required this.totalPossessions,
    required this.recentPossessions,
    required this.avgPossessionsPerGame,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      totalGames: json['total_games'] ?? 0,
      totalPossessions: json['total_possessions'] ?? 0,
      recentPossessions: json['recent_possessions'] ?? 0,
      avgPossessionsPerGame: (json['avg_possessions_per_game'] ?? 0.0).toDouble(),
    );
  }
}

class RecentActivity {
  final int id;
  final GameInfo game;
  final String team;
  final String? opponent;
  final int quarter;
  final String outcome;
  final String offensiveSet;
  final DateTime createdAt;

  RecentActivity({
    required this.id,
    required this.game,
    required this.team,
    this.opponent,
    required this.quarter,
    required this.outcome,
    required this.offensiveSet,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'],
      game: GameInfo.fromJson(json['game']),
      team: json['team'] ?? '',
      opponent: json['opponent'],
      quarter: json['quarter'] ?? 1,
      outcome: json['outcome'] ?? '',
      offensiveSet: json['offensive_set'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class GameInfo {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final DateTime gameDate;

  GameInfo({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.gameDate,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json['id'] ?? 0,
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      gameDate: DateTime.parse(json['game_date']),
    );
  }
}

class UpcomingGame {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String competition;
  final DateTime gameDate;
  final int homeTeamScore;
  final int awayTeamScore;
  final int quarter;

  UpcomingGame({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.gameDate,
    required this.homeTeamScore,
    required this.awayTeamScore,
    required this.quarter,
  });

  factory UpcomingGame.fromJson(Map<String, dynamic> json) {
    return UpcomingGame(
      id: json['id'] ?? 0,
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      competition: json['competition'] ?? '',
      gameDate: DateTime.parse(json['game_date']),
      homeTeamScore: json['home_team_score'] ?? 0,
      awayTeamScore: json['away_team_score'] ?? 0,
      quarter: json['quarter'] ?? 1,
    );
  }
}

class RecentReport {
  final int id;
  final String title;
  final String team;
  final String createdBy;
  final DateTime createdAt;
  final double fileSizeMb;

  RecentReport({
    required this.id,
    required this.title,
    required this.team,
    required this.createdBy,
    required this.createdAt,
    required this.fileSizeMb,
  });

  factory RecentReport.fromJson(Map<String, dynamic> json) {
    return RecentReport(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      team: json['team'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      fileSizeMb: (json['file_size_mb'] ?? 0.0).toDouble(),
    );
  }
}

class QuickAction {
  final String title;
  final String icon;
  final String route;

  QuickAction({
    required this.title,
    required this.icon,
    required this.route,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      title: json['title'] ?? '',
      icon: json['icon'] ?? '',
      route: json['route'] ?? '',
    );
  }
}
