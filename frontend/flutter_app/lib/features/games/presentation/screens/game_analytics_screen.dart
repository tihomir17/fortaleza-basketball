// lib/features/games/presentation/screens/game_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/game_repository.dart';
import 'package:flutter_app/main.dart';
import 'scouting_reports_screen.dart';

class GameAnalyticsScreen extends StatefulWidget {
  const GameAnalyticsScreen({super.key});

  @override
  State<GameAnalyticsScreen> createState() => _GameAnalyticsScreenState();
}

class _GameAnalyticsScreenState extends State<GameAnalyticsScreen> {
  // Filter states
  int? _selectedTeamId;
  int? _selectedQuarter;
  int? _selectedLastGames;
  String? _selectedOutcome;
  String? _selectedHomeAway;
  int _minPossessions = 10;
  int? _customLastGames;
  final TextEditingController _customGamesController = TextEditingController();
  
  // Analytics data
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Don't load analytics here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load analytics after dependencies are available
    if (_analyticsData == null && !_isLoading) {
      // Use post-frame callback to ensure build is complete
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAnalytics();
        }
      });
    }
  }

  @override
  void dispose() {
    _customGamesController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      // Use custom games value if available, otherwise use selected last games
      final lastGamesToUse = _selectedLastGames == -1 ? _customLastGames : _selectedLastGames;
      
      // Show loading message using post-frame callback to avoid build-time issues
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading analytics data...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
      
      final analyticsData = await sl<GameRepository>().getComprehensiveAnalytics(
        token: token,
        teamId: _selectedTeamId,
        quarter: _selectedQuarter,
        lastGames: lastGamesToUse,
        outcome: _selectedOutcome,
        homeAway: _selectedHomeAway,
        minPossessions: _minPossessions,
      );

      setState(() {
        _analyticsData = analyticsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTeams = context.watch<TeamCubit>().state.teams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear cache and reload
              GameRepository.clearAnalyticsCache();
              _loadAnalytics();
            },
            tooltip: 'Refresh Analytics (Clear Cache)',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Comprehensive Filters
          _buildComprehensiveFilters(userTeams),
          
          // Analytics Content
          Expanded(
            child: _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveFilters(List<Team> userTeams) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Row 1: Team and Quarter
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedTeamId,
                    hint: const Text('Select Team'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Teams')),
                      ...userTeams.map((team) => DropdownMenuItem(
                        value: team.id,
                        child: Text(team.name),
                      )),
                    ],
                    onChanged: (teamId) {
                      setState(() => _selectedTeamId = teamId);
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedQuarter,
                    hint: const Text('Quarter'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Quarters')),
                      const DropdownMenuItem<int?>(value: 1, child: Text('Q1')),
                      const DropdownMenuItem<int?>(value: 2, child: Text('Q2')),
                      const DropdownMenuItem<int?>(value: 3, child: Text('Q3')),
                      const DropdownMenuItem<int?>(value: 4, child: Text('Q4')),
                      const DropdownMenuItem<int?>(value: 5, child: Text('OT')),
                    ],
                    onChanged: (quarter) {
                      setState(() => _selectedQuarter = quarter);
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Row 2: Last Games and Outcome
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedLastGames,
                    hint: const Text('Last X Games'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('All Games')),
                      DropdownMenuItem<int?>(value: 5, child: Text('Last 5 Games')),
                      DropdownMenuItem<int?>(value: 10, child: Text('Last 10 Games')),
                      DropdownMenuItem<int?>(value: 15, child: Text('Last 15 Games')),
                      DropdownMenuItem<int?>(value: 20, child: Text('Last 20 Games')),
                      DropdownMenuItem<int?>(value: 30, child: Text('Last 30 Games')),
                      DropdownMenuItem<int?>(value: -1, child: Text('Custom...')),
                    ],
                    onChanged: (lastGames) {
                      setState(() {
                        _selectedLastGames = lastGames;
                        if (lastGames != -1) {
                          _customLastGames = null;
                          _customGamesController.clear();
                        }
                      });
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedOutcome,
                    hint: const Text('Outcome'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Outcomes')),
                      const DropdownMenuItem<String?>(value: 'W', child: Text('Wins')),
                      const DropdownMenuItem<String?>(value: 'L', child: Text('Losses')),
                    ],
                    onChanged: (outcome) {
                      setState(() => _selectedOutcome = outcome);
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Custom Games Input (shown when "Custom..." is selected)
            if (_selectedLastGames == -1)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customGamesController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Games',
                        hintText: 'Enter number of games (1-100)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final games = int.tryParse(value);
                        setState(() => _customLastGames = games);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _customLastGames != null && _customLastGames! > 0 ? () {
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    } : null,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            
            // Row 3: Home/Away and Min Possessions
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedHomeAway,
                    hint: const Text('Home/Away'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Games')),
                      const DropdownMenuItem<String?>(value: 'Home', child: Text('Home Games')),
                      const DropdownMenuItem<String?>(value: 'Away', child: Text('Away Games')),
                    ],
                    onChanged: (homeAway) {
                      setState(() => _selectedHomeAway = homeAway);
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _minPossessions,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelText: 'Min Possessions',
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5+ Possessions')),
                      DropdownMenuItem(value: 10, child: Text('10+ Possessions')),
                      DropdownMenuItem(value: 15, child: Text('15+ Possessions')),
                      DropdownMenuItem(value: 20, child: Text('20+ Possessions')),
                    ],
                    onChanged: (minPoss) {
                      setState(() => _minPossessions = minPoss!);
                      GameRepository.clearAnalyticsCache();
                      _loadAnalytics();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                GameRepository.clearAnalyticsCache();
                _loadAnalytics();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analyticsData == null) {
      return const Center(
        child: Text('No analytics data available.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummarySection(),
          const SizedBox(height: 24),
          _buildOffensiveAnalysisSection(),
          const SizedBox(height: 24),
          _buildDefensiveAnalysisSection(),
          const SizedBox(height: 24),
          _buildPlayerAnalysisSection(),
          const SizedBox(height: 24),
          _buildDetailedBreakdownSection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summary = _analyticsData!['summary'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary Statistics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SummaryCard(
                  title: 'Total Possessions',
                  value: summary['total_possessions'].toString(),
                  icon: Icons.sports_basketball,
                  color: Colors.blue,
                ),
                _SummaryCard(
                  title: 'Offensive PPP',
                  value: summary['offensive_ppp'].toString(),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _SummaryCard(
                  title: 'Defensive PPP',
                  value: summary['defensive_ppp'].toString(),
                  icon: Icons.shield,
                  color: Colors.red,
                ),
                _SummaryCard(
                  title: 'Avg Time',
                  value: '${summary['avg_possession_time']}s',
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffensiveAnalysisSection() {
    final offensive = _analyticsData!['offensive_analysis'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offensive Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // PnR Analysis
            if (offensive['pnr_analysis'] != null && offensive['pnr_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Pick & Roll', offensive['pnr_analysis']),
            
            // Paint Touch Analysis
            if (offensive['paint_touch_analysis'] != null && offensive['paint_touch_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Paint Touch', offensive['paint_touch_analysis']),
            
            // Kick Out Analysis
            if (offensive['kick_out_analysis'] != null && offensive['kick_out_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Kick Out', offensive['kick_out_analysis']),
            
            // Extra Pass Analysis
            if (offensive['extra_pass_analysis'] != null && offensive['extra_pass_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Extra Pass', offensive['extra_pass_analysis']),
            
            // Offensive Rebound Analysis
            if (offensive['offensive_rebound_analysis'] != null && offensive['offensive_rebound_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Offensive Rebound', offensive['offensive_rebound_analysis']),
            
            // Shot Time Analysis
            if (offensive['shot_time_analysis'] != null && offensive['shot_time_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Shot Time', offensive['shot_time_analysis']),
            
            // After Timeout Analysis
            if (offensive['after_timeout_analysis'] != null && offensive['after_timeout_analysis'].isNotEmpty)
              _buildAnalysisSubsection('After Timeout', offensive['after_timeout_analysis']),
          ],
        ),
      ),
    );
  }

  Widget _buildDefensiveAnalysisSection() {
    final defensive = _analyticsData!['defensive_analysis'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Defensive Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // PnR Defense
            if (defensive['pnr_defense'] != null && defensive['pnr_defense'].isNotEmpty)
              _buildAnalysisSubsection('PnR Defense', defensive['pnr_defense']),
            
            // Box Out Analysis
            if (defensive['box_out_analysis'] != null && defensive['box_out_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Box Out', defensive['box_out_analysis']),
            
            // Defensive Rebound Analysis
            if (defensive['defensive_rebound_analysis'] != null && defensive['defensive_rebound_analysis'].isNotEmpty)
              _buildAnalysisSubsection('Defensive Rebound', defensive['defensive_rebound_analysis']),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAnalysisSection() {
    final playerAnalysis = _analyticsData!['player_analysis'] as Map<String, dynamic>;
    final players = playerAnalysis['players'] as Map<String, dynamic>?;
    
    if (players == null || players.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Performance (${playerAnalysis['min_possessions_threshold']}+ possessions)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...players.entries.map((entry) {
              final player = entry.value as Map<String, dynamic>;
              return ListTile(
                title: Text(player['player_name']),
                subtitle: Text('${player['possessions']} possessions'),
                trailing: Text(
                  '${player['ppp']} PPP',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdownSection() {
    final breakdown = _analyticsData!['detailed_breakdown'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quarter Breakdown
            if (breakdown['quarter_breakdown'] != null && breakdown['quarter_breakdown'].isNotEmpty)
              _buildBreakdownSubsection('Quarter Breakdown', breakdown['quarter_breakdown']),
            
            // Home/Away Breakdown
            if (breakdown['home_away_breakdown'] != null && breakdown['home_away_breakdown'].isNotEmpty)
              _buildBreakdownSubsection('Home/Away Breakdown', breakdown['home_away_breakdown']),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSubsection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            
            if (value is Map<String, dynamic>) {
              return _AnalysisChip(
                label: key,
                value: value,
              );
            } else {
              return _AnalysisChip(
                label: key,
                value: {'value': value},
              );
            }
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBreakdownSubsection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...data.entries.map((entry) {
          final period = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          return ListTile(
            title: Text(period),
            subtitle: Text('${stats['possessions']} possessions'),
            trailing: Text(
              '${stats['ppp']} PPP',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _exportReport() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      // Use custom games value if available, otherwise use selected last games
      final lastGamesToUse = _selectedLastGames == -1 ? _customLastGames : _selectedLastGames;

      // Export PDF with current filter settings and save as scouting report
      final reportData = await sl<GameRepository>().exportAnalyticsPDF(
        token: token,
        teamId: _selectedTeamId,
        quarter: _selectedQuarter,
        lastGames: lastGamesToUse,
        outcome: _selectedOutcome,
        homeAway: _selectedHomeAway,
        minPossessions: _minPossessions,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report "${reportData['title']}" saved to Scouting Reports'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Reports',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to scouting reports screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScoutingReportsScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final String label;
  final Map<String, dynamic> value;
  
  const _AnalysisChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue = '';
    if (value.containsKey('ppp')) {
      displayValue = '${value['ppp']} PPP';
    } else if (value.containsKey('possessions')) {
      displayValue = '${value['possessions']} pos';
    } else if (value.containsKey('value')) {
      displayValue = value['value'].toString();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            displayValue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
