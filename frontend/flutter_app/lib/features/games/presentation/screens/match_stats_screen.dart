// lib/features/games/presentation/screens/match_stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/repositories/game_repository.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import 'package:fortaleza_basketball_analytics/features/possessions/data/models/possession_model.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class MatchStatsScreen extends StatefulWidget {
  final int gameId;
  const MatchStatsScreen({super.key, required this.gameId});

  @override
  State<MatchStatsScreen> createState() => _MatchStatsScreenState();
}

class _MatchStatsScreenState extends State<MatchStatsScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  Game? _game;
  List<Possession> _possessions = [];
  // Computed stats
  late Map<int, int> _homePointsByQ = {}; // quarter -> points
  late Map<int, int> _awayPointsByQ = {};
  int _homeTotal = 0;
  int _awayTotal = 0;
  int _totalPossessions = 0;
  double _offPpp = 0.0;
  double _defPpp = 0.0;
  int _fgMakes = 0;
  int _fgAttempts = 0;
  // Shot-type breakdown per team
  int _h2m = 0, _h2a = 0, _h3m = 0, _h3a = 0, _hftm = 0, _hfta = 0;
  int _a2m = 0, _a2a = 0, _a3m = 0, _a3a = 0, _aftm = 0, _afta = 0;
  // Rebounds & turnovers
  int _hOffReb = 0, _aOffReb = 0, _hDefReb = 0, _aDefReb = 0;
  int _hTov = 0, _aTov = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Include potential Overtime (OT) tab as the 6th tab
    _tabController = TabController(length: 6, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _loading = false;
        });
        return;
      }

      final repo = sl<GameRepository>();
      // Load game details (names/scores)
      final game = await repo.getGameDetails(token: token, gameId: widget.gameId, includePossessions: false);
      // Load ALL possessions (auto-pagination)
      final possJson = await repo.getAllGamePossessions(
        token: token,
        gameId: widget.gameId,
        pageSize: 200,
      );
      final possessions = possJson.map((e) => Possession.fromJson(e)).toList();

      _computeStats(game, possessions);

      setState(() {
        _game = game;
        _possessions = possessions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load stats: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Reload',
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'MATCH'),
            Tab(text: '1ST QUARTER'),
            Tab(text: '2ND QUARTER'),
            Tab(text: '3RD QUARTER'),
            Tab(text: '4TH QUARTER'),
            Tab(text: 'OT'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _game == null
                  ? const Center(child: Text('No stats available'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildContent(theme),
                        _buildQuarterContent(theme, 1),
                        _buildQuarterContent(theme, 2),
                        _buildQuarterContent(theme, 3),
                        _buildQuarterContent(theme, 4),
                        _buildQuarterContent(theme, 5),
                      ],
                    ),
    );
  }
 
  void _computeStats(Game game, List<Possession> possessions) {
    // Track all four quarters plus potential Overtime (5)
    _homePointsByQ = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    _awayPointsByQ = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    _homeTotal = 0;
    _awayTotal = 0;
    _totalPossessions = possessions.length;
    _offPpp = 0.0;
    _defPpp = 0.0;
    _fgMakes = 0;
    _fgAttempts = 0;
    // Reset shot-type breakdowns to avoid accumulation on refresh
    _h2m = 0; _h2a = 0; _h3m = 0; _h3a = 0; _hftm = 0; _hfta = 0;
    _a2m = 0; _a2a = 0; _a3m = 0; _a3a = 0; _aftm = 0; _afta = 0;

    int makes = 0;
    int attempts = 0;
    int hMissFG = 0, aMissFG = 0;

    for (final p in possessions) {
      final teamId = p.team?.team.id;
      if (teamId == null) {
        // Skip malformed possession entries without team
        continue;
      }
      
      // More robust team identification
      bool isHome;
      if (teamId == game.homeTeam.id) {
        isHome = true;
      } else if (teamId == game.awayTeam.id) {
        isHome = false;
      } else {
        // If team ID doesn't match either home or away, try to determine by team name
        final teamName = p.team?.team.name;
        if (teamName == game.homeTeam.name) {
          isHome = true;
        } else if (teamName == game.awayTeam.name) {
          isHome = false;
        } else {
          continue; // Skip this possession
        }
      }
      
      final pts = p.pointsScored;
      
      if (pts > 0) {
        if (isHome) {
          _homeTotal += pts;
          _homePointsByQ[p.quarter] = (_homePointsByQ[p.quarter] ?? 0) + pts;
        } else {
          _awayTotal += pts;
          _awayPointsByQ[p.quarter] = (_awayPointsByQ[p.quarter] ?? 0) + pts;
        }
      }

      final outcome = p.outcome;
      final isFgMake = outcome == 'MADE_2PTS' || outcome == 'MADE_3PTS';
      final isFgMiss = outcome == 'MISSED_2PTS' || outcome == 'MISSED_3PTS';
      if (isFgMake) {
        makes += 1;
        attempts += 1;
        if (isHome) {
          if (outcome == 'MADE_2PTS') {
            _h2m += 1;
          } else {
            _h3m += 1;
          }
          if (outcome == 'MADE_2PTS') {
            _h2a += 1;
          } else {
            _h3a += 1;
          }
        } else {
          if (outcome == 'MADE_2PTS') {
            _a2m += 1;
          } else {
            _a3m += 1;
          }
          if (outcome == 'MADE_2PTS') {
            _a2a += 1;
          } else {
            _a3a += 1;
          }
        }
      } else if (isFgMiss) {
        attempts += 1;
        if (isHome) {
          if (outcome == 'MISSED_2PTS') {
            _h2a += 1;
            hMissFG += 1;
          } else {
            _h3a += 1;
            hMissFG += 1;
          }
        } else {
          if (outcome == 'MISSED_2PTS') {
            _a2a += 1;
            aMissFG += 1;
          } else {
            _a3a += 1;
            aMissFG += 1;
          }
        }
      }

      // Free throws
      if (outcome == 'MADE_FT') {
        if (isHome) {
          _hftm += 1;
          _hfta += 1;
        } else {
          _aftm += 1;
          _afta += 1;
        }
      } else if (outcome == 'MISSED_FT') {
        if (isHome) {
          _hfta += 1;
        } else {
          _afta += 1;
        }
      }

      // Rebounds
      if (outcome == 'OFFENSIVE_REBOUND') {
        if (isHome) {
          _hOffReb += 1;
        } else {
          _aOffReb += 1;
        }
      }

      // Turnovers
      if (outcome == 'TURNOVER') {
        if (isHome) {
          _hTov += 1;
        } else {
          _aTov += 1;
        }
      }
    }

    _fgMakes = makes;
    _fgAttempts = attempts;

    // Calculate PPP
    final totalPoints = _homeTotal + _awayTotal;
    _offPpp = _totalPossessions > 0 ? totalPoints / _totalPossessions : 0.0;
    _defPpp = _offPpp; // combined view

    // Derive defensive rebounds as opponent missed FGs minus opponent offensive rebounds
    _hDefReb = (aMissFG - _aOffReb).clamp(0, 1000000);
    _aDefReb = (hMissFG - _hOffReb).clamp(0, 1000000);
  }

  Widget _buildContent(ThemeData theme) {
    final game = _game;
    if (game == null) {
      return const Center(child: Text('No game'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('${game.homeTeam.name} $_homeTotal - $_awayTotal ${game.awayTeam.name}'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard('Total Possessions', _totalPossessions.toString(), Icons.sports_basketball, Colors.blue),
              _statCard('PPP', _offPpp.toStringAsFixed(2), Icons.trending_up, Colors.green),
              _statCard('FG%', _fgAttempts > 0 ? '${((_fgMakes/_fgAttempts)*100).toStringAsFixed(1)}%' : '0%', Icons.percent, Colors.deepPurple),
              _statCard('Points', (_homeTotal + _awayTotal).toString(), Icons.scoreboard, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Per-Quarter Scoring'),
          _perQuarterBars(game),
          const SizedBox(height: 24),

          _sectionTitle('Shot Breakdown'),
          _shotBreakdownTable(game),

          const SizedBox(height: 24),
          _sectionTitle('Scoring'),
          _compareBlock(
            game,
            rows: [
              _Metric('Field Goals Attempted', (_h2a + _h3a), (_a2a + _a3a)),
              _Metric('Field Goals Made', (_h2m + _h3m), (_a2m + _a3m)),
              _Metric('Field Goals %',
                  (_h2a + _h3a) > 0 ? (((_h2m + _h3m) / (_h2a + _h3a)) * 100).round() : 0,
                  (_a2a + _a3a) > 0 ? (((_a2m + _a3m) / (_a2a + _a3a)) * 100).round() : 0,
                  isPercent: true),
              _Metric('2-Point Field G. Attempted', _h2a, _a2a),
              _Metric('2-Point Field Goals Made', _h2m, _a2m),
              _Metric('2-Point Field Goals %', _h2a > 0 ? ((_h2m / _h2a) * 100).round() : 0,
                  _a2a > 0 ? ((_a2m / _a2a) * 100).round() : 0, isPercent: true),
              _Metric('3-Point Field G. Attempted', _h3a, _a3a),
              _Metric('3-Point Field Goals Made', _h3m, _a3m),
              _Metric('3-Point Field Goals %', _h3a > 0 ? ((_h3m / _h3a) * 100).round() : 0,
                  _a3a > 0 ? ((_a3m / _a3a) * 100).round() : 0, isPercent: true),
              _Metric('Free Throws Attempted', _hfta, _afta),
              _Metric('Free Throws Made', _hftm, _aftm),
              _Metric('Free Throws %', _hfta > 0 ? ((_hftm / _hfta) * 100).round() : 0,
                  _afta > 0 ? ((_aftm / _afta) * 100).round() : 0, isPercent: true),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Rebounds'),
          _compareBlock(
            game,
            rows: [
              _Metric('Offensive Rebounds', _hOffReb, _aOffReb),
              _Metric('Defensive Rebounds', _hDefReb, _aDefReb),
              _Metric('Total Rebounds', _hOffReb + _hDefReb, _aOffReb + _aDefReb),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Other'),
          _compareBlock(
            game,
            rows: [
              _Metric('Turnovers', _hTov, _aTov),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterContent(ThemeData theme, int quarter) {
    final game = _game!;
    final qPoss = _possessions.where((p) => p.quarter == quarter).toList();
    // compute quick per-quarter numbers
    int hPts = 0, aPts = 0;
    int h2m = 0, h2a = 0, h3m = 0, h3a = 0, hftm = 0, hfta = 0;
    int a2m = 0, a2a = 0, a3m = 0, a3a = 0, aftm = 0, afta = 0;
    for (final p in qPoss) {
      final teamId = p.team?.team.id;
      if (teamId == null) continue;
      final isHome = teamId == game.homeTeam.id;
      final o = p.outcome;
      final pts = p.pointsScored;
      if (isHome) {
        hPts += pts;
        if (o == 'MADE_2PTS') { h2m++; h2a++; }
        else if (o == 'MISSED_2PTS') { h2a++; }
        else if (o == 'MADE_3PTS') { h3m++; h3a++; }
        else if (o == 'MISSED_3PTS') { h3a++; }
        else if (o == 'MADE_FTS' || o == 'MISSED_FTS') { hfta++; if (o == 'MADE_FTS') hftm++; }
      } else {
        aPts += pts;
        if (o == 'MADE_2PTS') { a2m++; a2a++; }
        else if (o == 'MISSED_2PTS') { a2a++; }
        else if (o == 'MADE_3PTS') { a3m++; a3a++; }
        else if (o == 'MISSED_3PTS') { a3a++; }
        else if (o == 'MADE_FTS' || o == 'MISSED_FTS') { afta++; if (o == 'MADE_FTS') aftm++; }
      }
    }

    final fgHomeAtt = h2a + h3a;
    final fgAwayAtt = a2a + a3a;
    final fgHomeMade = h2m + h3m;
    final fgAwayMade = a2m + a3m;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Scoring'),
          _compareBlock(
            game,
            rows: [
              _Metric('Points', hPts, aPts),
              _Metric('Field Goals Attempted', fgHomeAtt, fgAwayAtt),
              _Metric('Field Goals Made', fgHomeMade, fgAwayMade),
              _Metric('Field Goals %', fgHomeAtt > 0 ? ((fgHomeMade/fgHomeAtt)*100).round() : 0,
                  fgAwayAtt > 0 ? ((fgAwayMade/fgAwayAtt)*100).round() : 0, isPercent: true),
              _Metric('2-Point Field G. Attempted', h2a, a2a),
              _Metric('2-Point Field Goals Made', h2m, a2m),
              _Metric('2-Point Field Goals %', h2a>0?((h2m/h2a)*100).round():0,
                  a2a>0?((a2m/a2a)*100).round():0, isPercent: true),
              _Metric('3-Point Field G. Attempted', h3a, a3a),
              _Metric('3-Point Field Goals Made', h3m, a3m),
              _Metric('3-Point Field Goals %', h3a>0?((h3m/h3a)*100).round():0,
                  a3a>0?((a3m/a3a)*100).round():0, isPercent: true),
              _Metric('Free Throws Attempted', hfta, afta),
              _Metric('Free Throws Made', hftm, aftm),
              _Metric('Free Throws %', hfta>0?((hftm/hfta)*100).round():0,
                  afta>0?((aftm/afta)*100).round():0, isPercent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _keyValueList(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return const Text('No data');
    }
    final entries = data.entries.take(12).toList();
    return Column(
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key.toString().replaceAll('_', ' '))),
                    Text(e.value.toString()),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _perQuarterBars(Game game) {
    final maxQPoints = [
      _homePointsByQ[1]! + _awayPointsByQ[1]!,
      _homePointsByQ[2]! + _awayPointsByQ[2]!,
      _homePointsByQ[3]! + _awayPointsByQ[3]!,
      _homePointsByQ[4]! + _awayPointsByQ[4]!,
    ].fold<int>(1, (m, v) => v > m ? v : m);

    Widget rowForQ(int q) {
      final homePts = _homePointsByQ[q] ?? 0;
      final awayPts = _awayPointsByQ[q] ?? 0;
      final total = (homePts + awayPts).clamp(1, 999);
      final homeFrac = homePts / total;
      final awayFrac = awayPts / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q$q  •  ${game.homeTeam.name} $homePts  |  ${game.awayTeam.name} $awayPts'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: (homeFrac * 1000).round(),
                  child: Container(height: 14, color: Colors.blueAccent.withOpacity(0.8)),
                ),
                Expanded(
                  flex: (awayFrac * 1000).round(),
                  child: Container(height: 14, color: Colors.redAccent.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        rowForQ(1),
        rowForQ(2),
        rowForQ(3),
        rowForQ(4),
      ],
    );
  }

  Widget _compareBlock(Game game, {required List<_Metric> rows}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((m) => _compareRow(
                left: m.left,
                right: m.right,
                label: m.label,
                isPercent: m.isPercent,
              ))
          .toList(),
    );
  }

  Widget _compareRow({required int left, required int right, required String label, bool isPercent = false}) {
    final total = (left + right).clamp(1, 1000000);
    final leftFrac = left / total;
    final rightFrac = right / total;
    String fmt(int v) => isPercent ? '$v%' : v.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 40, child: Text(fmt(left), textAlign: TextAlign.left)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 40, child: Text(fmt(right), textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: (leftFrac * 1000).round(),
                child: Container(height: 10, color: Colors.white),
              ),
              Expanded(
                flex: (rightFrac * 1000).round(),
                child: Container(height: 10, color: Colors.pinkAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

 

Widget _shotBreakdownTable(Game game) {
    Widget row(String label, int hMade, int hAtt, int aMade, int aAtt) {
      String pct(int m, int a) => a > 0 ? '${(m / a * 100).toStringAsFixed(1)}%' : '0%';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label)),
            Expanded(child: Text('$hMade/$hAtt (${pct(hMade, hAtt)})', textAlign: TextAlign.center)),
            Expanded(child: Text('$aMade/$aAtt (${pct(aMade, aAtt)})', textAlign: TextAlign.center)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 90),
            Expanded(child: Text(game.homeTeam.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(game.awayTeam.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: 8),
        row('2PT', _h2m, _h2a, _a2m, _a2a),
        row('3PT', _h3m, _h3a, _a3m, _a3a),
        row('FT', _hftm, _hfta, _aftm, _afta),
      ],
    );
  }
}

class _Metric {
  final String label;
  final int left;
  final int right;
  final bool isPercent;
  _Metric(this.label, this.left, this.right, {this.isPercent = false});
}
