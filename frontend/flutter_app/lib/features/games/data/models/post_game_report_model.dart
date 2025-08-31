// lib/features/games/data/models/post_game_report_model.dart

class PostGameReport {
  final GameInfo gameInfo;
  final OffenceAnalytics offence;
  final DefenceAnalytics defence;
  final SummaryStats summary;

  PostGameReport({
    required this.gameInfo,
    required this.offence,
    required this.defence,
    required this.summary,
  });

  factory PostGameReport.fromJson(Map<String, dynamic> json) {
    return PostGameReport(
      gameInfo: GameInfo.fromJson(json['game_info']),
      offence: OffenceAnalytics.fromJson(json['offence']),
      defence: DefenceAnalytics.fromJson(json['defence']),
      summary: SummaryStats.fromJson(json['summary']),
    );
  }
}

class GameInfo {
  final int id;
  final TeamInfo homeTeam;
  final TeamInfo awayTeam;
  final int? homeScore;
  final int? awayScore;
  final DateTime gameDate;

  GameInfo({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.gameDate,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json['id'],
      homeTeam: TeamInfo.fromJson(json['home_team']),
      awayTeam: TeamInfo.fromJson(json['away_team']),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      gameDate: DateTime.parse(json['game_date']),
    );
  }
}

class TeamInfo {
  final int id;
  final String name;
  final String? logoUrl;

  TeamInfo({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
    );
  }
}

class OffenceAnalytics {
  final TransitionData transition;
  final Map<String, PlayTypeStats> offensiveSets;
  final PnrData pnr;
  final Map<String, PlayTypeStats> vsPnrCoverage;
  final Map<String, PlayTypeStats> otherOffensive;

  OffenceAnalytics({
    required this.transition,
    required this.offensiveSets,
    required this.pnr,
    required this.vsPnrCoverage,
    required this.otherOffensive,
  });

  factory OffenceAnalytics.fromJson(Map<String, dynamic> json) {
    return OffenceAnalytics(
      transition: TransitionData.fromJson(json['transition']),
      offensiveSets: (json['offensive_sets'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PlayTypeStats.fromJson(value)),
      ),
      pnr: PnrData.fromJson(json['pnr']),
      vsPnrCoverage: (json['vs_pnr_coverage'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PlayTypeStats.fromJson(value)),
      ),
      otherOffensive: (json['other_offensive'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PlayTypeStats.fromJson(value)),
      ),
    );
  }
}

class TransitionData {
  final PlayTypeStats fastBreak;
  final PlayTypeStats transition;
  final PlayTypeStats earlyOff;

  TransitionData({
    required this.fastBreak,
    required this.transition,
    required this.earlyOff,
  });

  factory TransitionData.fromJson(Map<String, dynamic> json) {
    return TransitionData(
      fastBreak: PlayTypeStats.fromJson(json['fast_break']),
      transition: PlayTypeStats.fromJson(json['transition']),
      earlyOff: PlayTypeStats.fromJson(json['early_off']),
    );
  }
}

class PnrData {
  final PlayTypeStats ballHandler;
  final PlayTypeStats rollMan;
  final PlayTypeStats thirdGuy;

  PnrData({
    required this.ballHandler,
    required this.rollMan,
    required this.thirdGuy,
  });

  factory PnrData.fromJson(Map<String, dynamic> json) {
    return PnrData(
      ballHandler: PlayTypeStats.fromJson(json['ball_handler']),
      rollMan: PlayTypeStats.fromJson(json['roll_man']),
      thirdGuy: PlayTypeStats.fromJson(json['third_guy']),
    );
  }
}

class DefenceAnalytics {
  final Map<String, PlayTypeStats> coverage;

  DefenceAnalytics({
    required this.coverage,
  });

  factory DefenceAnalytics.fromJson(Map<String, dynamic> json) {
    return DefenceAnalytics(
      coverage: (json['coverage'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PlayTypeStats.fromJson(value)),
      ),
    );
  }
}

class PlayTypeStats {
  final int possessions;
  final double ppp;
  final double adjustedSq;

  PlayTypeStats({
    required this.possessions,
    required this.ppp,
    required this.adjustedSq,
  });

  factory PlayTypeStats.fromJson(Map<String, dynamic> json) {
    return PlayTypeStats(
      possessions: json['possessions'],
      ppp: (json['ppp'] as num).toDouble(),
      adjustedSq: (json['adjusted_sq'] as num).toDouble(),
    );
  }
}

class SummaryStats {
  final Map<String, TaggingUpData> taggingUp;
  final PaintTouchData paintTouch;
  final BestPlayersData bestOffensive5;
  final BestPlayersData bestDefensive5;
  final Map<String, QuarterData> quarters;

  SummaryStats({
    required this.taggingUp,
    required this.paintTouch,
    required this.bestOffensive5,
    required this.bestDefensive5,
    required this.quarters,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      taggingUp: (json['tagging_up'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, TaggingUpData.fromJson(value)),
      ),
      paintTouch: PaintTouchData.fromJson(json['paint_touch']),
      bestOffensive5: BestPlayersData.fromJson(json['best_offensive_5']),
      bestDefensive5: BestPlayersData.fromJson(json['best_defensive_5']),
      quarters: (json['quarters'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, QuarterData.fromJson(value)),
      ),
    );
  }
}

class TaggingUpData {
  final int playerNo;
  final int count;
  final double percentage;

  TaggingUpData({
    required this.playerNo,
    required this.count,
    required this.percentage,
  });

  factory TaggingUpData.fromJson(Map<String, dynamic> json) {
    return TaggingUpData(
      playerNo: json['player_no'],
      count: json['count'],
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class PaintTouchData {
  final int count;
  final int points;
  final int possessions;
  final double percentage;

  PaintTouchData({
    required this.count,
    required this.points,
    required this.possessions,
    required this.percentage,
  });

  factory PaintTouchData.fromJson(Map<String, dynamic> json) {
    return PaintTouchData(
      count: json['count'],
      points: json['points'],
      possessions: json['possessions'],
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class BestPlayersData {
  final List<PlayerData> players;

  BestPlayersData({
    required this.players,
  });

  factory BestPlayersData.fromJson(Map<String, dynamic> json) {
    return BestPlayersData(
      players: (json['players'] as List<dynamic>)
          .map((player) => PlayerData.fromJson(player))
          .toList(),
    );
  }
}

class PlayerData {
  final int id;
  final String name;
  final double stats;

  PlayerData({
    required this.id,
    required this.name,
    required this.stats,
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      id: json['id'],
      name: json['name'],
      stats: (json['stats'] as num).toDouble(),
    );
  }
}

class QuarterData {
  final String quarter;
  final double offPpp;
  final double defPpp;

  QuarterData({
    required this.quarter,
    required this.offPpp,
    required this.defPpp,
  });

  factory QuarterData.fromJson(Map<String, dynamic> json) {
    return QuarterData(
      quarter: json['quarter'],
      offPpp: (json['off_ppp'] as num).toDouble(),
      defPpp: (json['def_ppp'] as num).toDouble(),
    );
  }
}
