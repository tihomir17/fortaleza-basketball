// lib/features/games/presentation/screens/post_game_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';
import '../../data/models/post_game_report_model.dart';
import '../../data/repositories/game_repository.dart';
import '../cubit/post_game_report_cubit.dart';
import '../cubit/post_game_report_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart' as main_app;

class PostGameReportScreen extends StatelessWidget {
  final int gameId;
  final int teamId;

  const PostGameReportScreen({
    super.key,
    required this.gameId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PostGameReportCubit(
        gameRepository: main_app.sl<GameRepository>(),
      )..fetchPostGameReport(
          gameId: gameId,
          teamId: teamId,
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A), // Dark background
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D2D2D),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'POST GAME REPORT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SidebarToggleAppBarButton(),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        body: BlocBuilder<PostGameReportCubit, PostGameReportState>(
          builder: (context, state) {
            if (state.status == PostGameReportStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0066CC),
                ),
              );
            }

            if (state.status == PostGameReportStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Unknown error',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PostGameReportCubit>().fetchPostGameReport(
                          gameId: gameId,
                          teamId: teamId,
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.status == PostGameReportStatus.success && state.report != null) {
              return _PostGameReportContent(report: state.report!);
            }

            return const Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostGameReportContent extends StatelessWidget {
  final PostGameReport report;

  const _PostGameReportContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with team logos and VS
          _buildHeader(),
          const SizedBox(height: 20),
          
          // Key Performance Summary
          _buildPerformanceSummary(),
          const SizedBox(height: 20),
          
          // Main content in three columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - OFFENCE
              Expanded(
                flex: 2,
                child: _buildOffenceSection(),
              ),
              const SizedBox(width: 12),
              
              // Middle column - DEFENCE
              Expanded(
                flex: 2,
                child: _buildDefenceSection(),
              ),
              const SizedBox(width: 12),
              
              // Right column - Summary sections
              Expanded(
                flex: 1,
                child: _buildSummarySections(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Home team logo
          Expanded(
            child: _buildTeamLogo(report.gameInfo.homeTeam, 'FORTALEZA'),
          ),
          
          // VS
          Expanded(
            child: Column(
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066CC),
                  ),
                ),
                if (report.gameInfo.homeScore != null && report.gameInfo.awayScore != null)
                  Text(
                    '${report.gameInfo.homeScore} - ${report.gameInfo.awayScore}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          // Away team logo
          Expanded(
            child: _buildTeamLogo(report.gameInfo.awayTeam, 'VS. Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(TeamInfo team, String fallbackName) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF0066CC),
          backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
          child: team.logoUrl == null
              ? Text(
                  team.name.isNotEmpty ? team.name[0].toUpperCase() : fallbackName[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          team.name.isNotEmpty ? team.name : fallbackName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOffenceSection() {
    return Column(
      children: [
        // OFFENCE header
        _buildSectionHeader('OFFENCE', const Color(0xFF0066CC)),
        const SizedBox(height: 12),
        
        // TRANSITION
        _buildSubSection('TRANSITION', [
          _buildDataRow('Fast Break', report.offence.transition.fastBreak),
          _buildDataRow('Transition', report.offence.transition.transition),
          _buildDataRow('Early Off (<14s)', report.offence.transition.earlyOff),
        ]),
        const SizedBox(height: 12),
        
        // OFFENCE SETS (showing first 10 sets)
        _buildSubSection('OFFENCE SETS', [
          for (int i = 1; i <= 10; i++)
            _buildDataRow('Set $i', report.offence.offensiveSets['set_$i'] ?? _emptyStats()),
        ]),
        const SizedBox(height: 12),
        
        // PnR
        _buildSubSection('PnR', [
          _buildDataRow('Ball Handler', report.offence.pnr.ballHandler),
          _buildDataRow('Roll Man', report.offence.pnr.rollMan),
          _buildDataRow('3rd Guy', report.offence.pnr.thirdGuy),
        ]),
        const SizedBox(height: 12),
        
        // VS PnR Coverage
        _buildSubSection('VS PnR Coverage', [
          _buildDataRow('Switch', report.offence.vsPnrCoverage['switch'] ?? _emptyStats()),
          _buildDataRow('Hedge', report.offence.vsPnrCoverage['hedge'] ?? _emptyStats()),
          _buildDataRow('Drop', report.offence.vsPnrCoverage['drop'] ?? _emptyStats()),
          _buildDataRow('Trap', report.offence.vsPnrCoverage['trap'] ?? _emptyStats()),
        ]),
        const SizedBox(height: 12),
        
        // OTHER OFF PARTS
        _buildSubSection('OTHER OFF PARTS', [
          _buildDataRow('Closeout', report.offence.otherOffensive['closeout'] ?? _emptyStats()),
          _buildDataRow('Cuts', report.offence.otherOffensive['cuts'] ?? _emptyStats()),
          _buildDataRow('Kick Out', report.offence.otherOffensive['kick_out'] ?? _emptyStats()),
          _buildDataRow('Extra Pass', report.offence.otherOffensive['extra_pass'] ?? _emptyStats()),
          _buildDataRow('After OffReb', report.offence.otherOffensive['after_off_reb'] ?? _emptyStats()),
        ]),
      ],
    );
  }

  Widget _buildDefenceSection() {
    return Column(
      children: [
        // DEFENCE header
        _buildSectionHeader('DEFENCE', const Color(0xFFCC0000)),
        const SizedBox(height: 12),
        
        // COVERAGE
        _buildSubSection('COVERAGE', [
          _buildDataRow('Switch', report.defence.coverage['switch'] ?? _emptyStats()),
          _buildDataRow('... Low Post', report.defence.coverage['switch_low_post'] ?? _emptyStats()),
          _buildDataRow('... Isolation', report.defence.coverage['switch_isolation'] ?? _emptyStats()),
          _buildDataRow('... 3rd Guy', report.defence.coverage['switch_third_guy'] ?? _emptyStats()),
          _buildDataRow('Hedge', report.defence.coverage['hedge'] ?? _emptyStats()),
          _buildDataRow('Drop/Weak', report.defence.coverage['drop_weak'] ?? _emptyStats()),
          _buildDataRow('... Ball Handler', report.defence.coverage['drop_ball_handler'] ?? _emptyStats()),
          _buildDataRow('... Big Guy', report.defence.coverage['drop_big_guy'] ?? _emptyStats()),
          _buildDataRow('... 3rd Guy', report.defence.coverage['drop_third_guy'] ?? _emptyStats()),
          _buildDataRow('Isolation', report.defence.coverage['isolation'] ?? _emptyStats()),
          _buildDataRow('... High Post', report.defence.coverage['isolation_high_post'] ?? _emptyStats()),
          _buildDataRow('... Low Post', report.defence.coverage['isolation_low_post'] ?? _emptyStats()),
        ]),
        const SizedBox(height: 12),
        
        // Secondary COVERAGE banner
        _buildSectionHeader('COVERAGE', const Color(0xFFCC0000)),
      ],
    );
  }

  Widget _buildSummarySections() {
    return Column(
      children: [
        // TAGGING UP
        _buildSectionHeader('TAGGING UP', const Color(0xFF00CC00)),
        _buildTaggingUpTable(),
        const SizedBox(height: 12),
        
        // PAINT TOUCH
        _buildSectionHeader('PAINT TOUCH', const Color(0xFF808080)),
        _buildPaintTouchTable(),
        const SizedBox(height: 12),
        
        // BEST OFFENSIVE 5
        _buildSectionHeader('BEST OFFENSIVE 5', const Color(0xFF8000CC)),
        _buildBestPlayersTable(report.summary.bestOffensive5),
        const SizedBox(height: 12),
        
        // BEST DEFENSIVE 5
        _buildSectionHeader('BEST DEFENSIVE 5', const Color(0xFF8000CC)),
        _buildBestPlayersTable(report.summary.bestDefensive5),
        const SizedBox(height: 12),
        
        // QUARTERS
        _buildSectionHeader('QUARTERS', const Color(0xFF8000CC)),
        _buildQuartersTable(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF404040),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Play Types', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Poss.', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(child: Text('PPP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(child: Text('A. SQ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Data rows
              ...rows,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String playType, PlayTypeStats stats) {
    // Color coding based on performance
    Color pppColor = _getPerformanceColor(stats.ppp);
    Color possessionColor = stats.possessions > 0 ? Colors.green : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF404040), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              playType,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: possessionColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                stats.possessions.toString(),
                style: TextStyle(
                  color: possessionColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: pppColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                stats.ppp.toStringAsFixed(1),
                style: TextStyle(
                  color: pppColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: pppColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                stats.adjustedSq.toStringAsFixed(1),
                style: TextStyle(
                  color: pppColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double ppp) {
    if (ppp >= 1.2) return Colors.green;
    if (ppp >= 0.8) return Colors.orange;
    if (ppp > 0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildPerformanceSummary() {
    // Calculate key metrics
    final fastBreak = report.offence.transition.fastBreak;
    final kickOut = report.offence.otherOffensive['kick_out'] ?? _emptyStats();
    final extraPass = report.offence.otherOffensive['extra_pass'] ?? _emptyStats();
    final paintTouch = report.summary.paintTouch;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0066CC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: const Color(0xFF0066CC), size: 24),
              const SizedBox(width: 8),
              Text(
                'KEY PERFORMANCE METRICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Fast Break',
                  '${fastBreak.possessions}',
                  '${fastBreak.ppp.toStringAsFixed(1)} PPP',
                  _getPerformanceColor(fastBreak.ppp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Kick Out',
                  '${kickOut.possessions}',
                  '${kickOut.ppp.toStringAsFixed(1)} PPP',
                  _getPerformanceColor(kickOut.ppp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Extra Pass',
                  '${extraPass.possessions}',
                  '${extraPass.ppp.toStringAsFixed(1)} PPP',
                  _getPerformanceColor(extraPass.ppp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Paint Touch',
                  '${paintTouch.count}',
                  '${paintTouch.percentage.toStringAsFixed(1)}%',
                  paintTouch.percentage > 25 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaggingUpTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Players No.', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('X', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Off Reb', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Data rows
          for (int i = 0; i < 6; i++)
            _buildTaggingUpRow(i, report.summary.taggingUp['player_$i'] ?? _emptyTaggingUp()),
        ],
      ),
    );
  }

  Widget _buildTaggingUpRow(int playerNo, TaggingUpData data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF404040), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              playerNo.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              data.count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              data.count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${data.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaintTouchTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
                         child: const Row(
               children: [
                 Expanded(child: Text('No.', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                 Expanded(child: Text('Points', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                 Expanded(child: Text('Poss', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                 Expanded(child: Text('PPP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
               ],
             ),
          ),
          // Data row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    report.summary.paintTouch.count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    report.summary.paintTouch.points.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    report.summary.paintTouch.possessions.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
                                 Expanded(
                   child: Text(
                     report.summary.paintTouch.possessions > 0 
                         ? (report.summary.paintTouch.points / report.summary.paintTouch.possessions).toStringAsFixed(1)
                         : '0.0',
                     style: const TextStyle(color: Colors.white, fontSize: 10),
                     textAlign: TextAlign.center,
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPlayersTable(BestPlayersData data) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Expanded(
                    child: Text(
                      '#',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          // Data row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Expanded(
                    child: Text(
                      data.players[i].id.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuartersTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('QT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(child: Text('OFF PPP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('DEF PPP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Data rows
          for (int i = 1; i <= 4; i++)
            _buildQuarterRow(report.summary.quarters['quarter_$i'] ?? _emptyQuarter()),
          if (report.summary.quarters.containsKey('overtime'))
            _buildQuarterRow(report.summary.quarters['overtime']!),
        ],
      ),
    );
  }

  Widget _buildQuarterRow(QuarterData data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF404040), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.quarter,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              data.offPpp.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              data.defPpp.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  PlayTypeStats _emptyStats() {
    return PlayTypeStats(possessions: 0, ppp: 0.0, adjustedSq: 0.0);
  }

  TaggingUpData _emptyTaggingUp() {
    return TaggingUpData(playerNo: 0, count: 0, percentage: 0.0);
  }

  QuarterData _emptyQuarter() {
    return QuarterData(quarter: '', offPpp: 0.0, defPpp: 0.0);
  }
}
