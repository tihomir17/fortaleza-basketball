// lib/features/games/presentation/screens/game_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  int? _selectedOpponentId;
  int? _selectedQuarter;
  int? _selectedLastGames;
  String? _selectedOutcome;
  String? _selectedHomeAway;
  int? _customLastGames;
  final TextEditingController _customGamesController = TextEditingController();
  
  // Analytics data
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get user teams and set default team (coach's team) if none selected
    final userTeams = context.read<TeamCubit>().state.teams;
    if (userTeams.isNotEmpty && _selectedTeamId == null) {
      setState(() {
        _selectedTeamId = userTeams.first.id; // Use coach's team automatically
      });
    }
    
    // Only load analytics if we have a team selected and no data
    if (_analyticsData == null && !_isLoading && _selectedTeamId != null) {
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

  void _safeClearCacheAndReload() {
    try {
      GameRepository.clearAnalyticsCache();
    } catch (e) {
    }
    _loadAnalytics();
  }

  void _navigateToPostGameReport() {
    // For now, we'll use a placeholder game ID since this is analytics screen
    // In a real implementation, you might want to get the game ID from context or parameters
    final gameId = 1; // Placeholder - you can modify this based on your needs
    final userTeams = context.read<TeamCubit>().state.teams;
    if (userTeams.isNotEmpty) {
      final teamId = userTeams.first.id;
      context.go('/games/$gameId/post-game-report?teamId=$teamId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No team selected for post-game report')),
      );
    }
  }

  void _navigateToAdvancedPostGameReport() {
    // For now, we'll use a placeholder game ID since this is analytics screen
    // In a real implementation, you might want to get the game ID from context or parameters
    final gameId = 1; // Placeholder - you can modify this based on your needs
    context.go('/games/$gameId/advanced-report');
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

      final lastGamesToUse = _selectedLastGames == -1 ? _customLastGames : _selectedLastGames;
      
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
        opponent: _selectedOpponentId,
        minPossessions: 10, // Fixed minimum possessions
      );

      if (analyticsData != null) {
        if (analyticsData['summary'] != null) {
        }
      }

      // Validate the analytics data structure
      if (analyticsData == null) {
        throw Exception('Analytics data is null');
      }

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _buildAppBarTitle(userTeams),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _safeClearCacheAndReload,
            tooltip: 'Refresh Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _navigateToPostGameReport,
            tooltip: 'Post Game Report',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _navigateToAdvancedPostGameReport,
            tooltip: 'Advanced Post-Game Report',
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
          // Enhanced Filters Section
          _buildEnhancedFilters(userTeams),
          
          // Analytics Content
          Expanded(
            child: _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(List<Team> userTeams) {
    final selectedTeam = userTeams.firstWhere(
      (team) => team.id == _selectedTeamId,
      orElse: () => userTeams.isNotEmpty ? userTeams.first : Team(
        id: 0, 
        name: 'No Team',
        players: [],
        coaches: [],
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Game Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (selectedTeam.id != 0) ...[
          const SizedBox(height: 2),
          Text(
            selectedTeam.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getTeamResultText(selectedTeam),
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }

  String _getTeamResultText(Team team) {
    if (_analyticsData == null || _analyticsData!['summary'] == null) {
      return 'Loading results...';
    }
    
    final summary = _analyticsData!['summary'] as Map<String, dynamic>;
    final totalGames = summary['total_games'] ?? 0;
    final wins = summary['wins'] ?? 0;
    final losses = summary['losses'] ?? 0;
    
    if (totalGames == 0) {
      return 'No games played';
    }
    
    return 'Record: $wins-$losses ($totalGames games)';
  }

  Widget _buildEnhancedFilters(List<Team> userTeams) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analytics Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  // Font suggestions: 'Poppins', 'Inter', 'Roboto'
                ),
              ),
            ],
          ),
          if (userTeams.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No teams available. Please ensure you are associated with a team.',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 20),
          
          // Opponent and Quarter Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<int?>(
                  value: _selectedOpponentId,
                  hint: 'Select Opponent',
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Opponents')),
                    ...userTeams.map((team) => DropdownMenuItem(
                      value: team.id,
                      child: Text(team.name),
                    )),
                  ],
                    onChanged: (opponentId) {
                      setState(() => _selectedOpponentId = opponentId);
                      _safeClearCacheAndReload();
                    },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown<int?>(
                  value: _selectedQuarter,
                  hint: 'Quarter',
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
                    _safeClearCacheAndReload();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Last Games and Outcome Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<int?>(
                  value: _selectedLastGames,
                  hint: 'Last X Games',
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
                    _safeClearCacheAndReload();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown<String?>(
                  value: _selectedOutcome,
                  hint: 'Outcome',
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Outcomes')),
                    const DropdownMenuItem<String?>(value: 'W', child: Text('Wins')),
                    const DropdownMenuItem<String?>(value: 'L', child: Text('Losses')),
                  ],
                  onChanged: (outcome) {
                    setState(() => _selectedOutcome = outcome);
                    _safeClearCacheAndReload();
                  },
                ),
              ),
            ],
          ),
          
          // Custom Games Input
          if (_selectedLastGames == -1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCustomInput(),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _customLastGames != null && _customLastGames! > 0 ? _safeClearCacheAndReload : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Home/Away Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<String?>(
                  value: _selectedHomeAway,
                  hint: 'Home/Away',
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Games')),
                    const DropdownMenuItem<String?>(value: 'Home', child: Text('Home Games')),
                    const DropdownMenuItem<String?>(value: 'Away', child: Text('Away Games')),
                  ],
                  onChanged: (homeAway) {
                    setState(() => _selectedHomeAway = homeAway);
                    _safeClearCacheAndReload();
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()), // Empty space to maintain layout
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<T?>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
        // Font suggestions: 'Inter', 'Roboto', 'SF Pro Text'
      ),
    );
  }

  Widget _buildCustomInput() {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: _customGamesController,
      decoration: InputDecoration(
        labelText: 'Number of Games',
        hintText: 'Enter number of games (1-100)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final games = int.tryParse(value);
        setState(() => _customLastGames = games);
      },
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics...'),
          ],
        ),
      );
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
              onPressed: _safeClearCacheAndReload,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    // Check if team is selected
    if (_selectedTeamId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_basketball, size: 64, color: Colors.blue[300]),
            const SizedBox(height: 16),
            Text(
              'Select a team to view analytics',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a team from the filters above to start analyzing game data',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_analyticsData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            Text(
              'No analytics data available',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try adjusting your filters or check if there are games with possessions for the selected team',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _safeClearCacheAndReload,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildEnhancedSummarySection(),
          const SizedBox(height: 24),
          _buildEnhancedOffensiveSection(),
          const SizedBox(height: 24),
          _buildEnhancedDefensiveSection(),
          const SizedBox(height: 24),
          _buildEnhancedPlayerSection(),
          const SizedBox(height: 24),
          _buildEnhancedBreakdownSection(),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummarySection() {
    if (_analyticsData == null || _analyticsData!['summary'] == null) {
      return const SizedBox();
    }
    
    final summary = _analyticsData!['summary'] as Map<String, dynamic>;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Summary Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  // Font suggestions: 'Poppins', 'Inter', 'Roboto'
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _EnhancedSummaryCard(
                title: 'Total Possessions',
                value: (summary['total_possessions'] ?? 0).toString(),
                icon: Icons.sports_basketball,
                color: Colors.blue,
              ),
              _EnhancedSummaryCard(
                title: 'Offensive PPP',
                value: (summary['offensive_ppp'] ?? 0.0).toString(),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              _EnhancedSummaryCard(
                title: 'Defensive PPP',
                value: (summary['defensive_ppp'] ?? 0.0).toString(),
                icon: Icons.shield,
                color: Colors.red,
              ),
              _EnhancedSummaryCard(
                title: 'Avg Time',
                value: '${summary['avg_possession_time'] ?? 0}s',
                icon: Icons.timer,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOffensiveSection() {
    if (_analyticsData == null || _analyticsData!['offensive_analysis'] == null) {
      return const SizedBox();
    }
    
    final offensive = _analyticsData!['offensive_analysis'] as Map<String, dynamic>;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Offensive Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (offensive['pnr_analysis'] != null && offensive['pnr_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Pick & Roll', offensive['pnr_analysis'], Colors.green),
          
          if (offensive['paint_touch_analysis'] != null && offensive['paint_touch_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Paint Touch', offensive['paint_touch_analysis'], Colors.blue),
          
          if (offensive['kick_out_analysis'] != null && offensive['kick_out_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Kick Out', offensive['kick_out_analysis'], Colors.purple),
          
          if (offensive['extra_pass_analysis'] != null && offensive['extra_pass_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Extra Pass', offensive['extra_pass_analysis'], Colors.orange),
          
          if (offensive['offensive_rebound_analysis'] != null && offensive['offensive_rebound_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Offensive Rebound', offensive['offensive_rebound_analysis'], Colors.teal),
          
          if (offensive['shot_time_analysis'] != null && offensive['shot_time_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Shot Time', offensive['shot_time_analysis'], Colors.indigo),
          
          if (offensive['after_timeout_analysis'] != null && offensive['after_timeout_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('After Timeout', offensive['after_timeout_analysis'], Colors.amber),
        ],
      ),
    );
  }

  Widget _buildEnhancedDefensiveSection() {
    if (_analyticsData == null || _analyticsData!['defensive_analysis'] == null) {
      return const SizedBox();
    }
    
    final defensive = _analyticsData!['defensive_analysis'] as Map<String, dynamic>;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Defensive Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (defensive['pnr_defense'] != null && defensive['pnr_defense'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('PnR Defense', defensive['pnr_defense'], Colors.red),
          
          if (defensive['box_out_analysis'] != null && defensive['box_out_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Box Out', defensive['box_out_analysis'], Colors.deepOrange),
          
          if (defensive['defensive_rebound_analysis'] != null && defensive['defensive_rebound_analysis'].isNotEmpty)
            _buildEnhancedAnalysisSubsection('Defensive Rebound', defensive['defensive_rebound_analysis'], Colors.pink),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlayerSection() {
    if (_analyticsData == null || _analyticsData!['player_analysis'] == null) {
      return const SizedBox();
    }
    
    final playerAnalysis = _analyticsData!['player_analysis'] as Map<String, dynamic>;
    final players = playerAnalysis['players'] as Map<String, dynamic>?;
    final theme = Theme.of(context);
    
    if (players == null || players.isEmpty) {
      return const SizedBox();
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Player Performance (${playerAnalysis['min_possessions_threshold']}+ possessions)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...players.entries.map((entry) {
            final player = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      player['player_name'][0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['player_name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${player['possessions']} possessions',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${player['ppp']} PPP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedBreakdownSection() {
    if (_analyticsData == null || _analyticsData!['detailed_breakdown'] == null) {
      return const SizedBox();
    }
    
    final breakdown = _analyticsData!['detailed_breakdown'] as Map<String, dynamic>;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Detailed Breakdown',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (breakdown['quarter_breakdown'] != null && breakdown['quarter_breakdown'].isNotEmpty)
            _buildEnhancedBreakdownSubsection('Quarter Breakdown', breakdown['quarter_breakdown'], Colors.blue),
          
          if (breakdown['home_away_breakdown'] != null && breakdown['home_away_breakdown'].isNotEmpty)
            _buildEnhancedBreakdownSubsection('Home/Away Breakdown', breakdown['home_away_breakdown'], Colors.purple),
        ],
      ),
    );
  }

  Widget _buildEnhancedAnalysisSubsection(String title, Map<String, dynamic> data, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            
            if (value is Map<String, dynamic>) {
              return _EnhancedAnalysisChip(
                label: key,
                value: value,
                color: color,
              );
            } else {
              return _EnhancedAnalysisChip(
                label: key,
                value: {'value': value},
                color: color,
              );
            }
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEnhancedBreakdownSubsection(String title, Map<String, dynamic> data, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        ...data.entries.map((entry) {
          final period = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${stats['possessions']} possessions',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${stats['ppp']} PPP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
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

      final lastGamesToUse = _selectedLastGames == -1 ? _customLastGames : _selectedLastGames;

      final reportData = await sl<GameRepository>().exportAnalyticsPDF(
        token: token,
        teamId: _selectedTeamId,
        quarter: _selectedQuarter,
        lastGames: lastGamesToUse,
        outcome: _selectedOutcome,
        homeAway: _selectedHomeAway,
        opponent: _selectedOpponentId,
        minPossessions: 10, // Fixed minimum possessions
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report "${reportData['title']}" saved to Scouting Reports'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Reports',
            textColor: Colors.white,
            onPressed: () {
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

class _EnhancedSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _EnhancedSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
                // Font suggestions: 'Poppins', 'Inter', 'Roboto'
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
                // Font suggestions: 'Inter', 'Roboto', 'SF Pro Text'
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedAnalysisChip extends StatelessWidget {
  final String label;
  final Map<String, dynamic> value;
  final Color color;
  
  const _EnhancedAnalysisChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String displayValue = '';
    if (value.containsKey('ppp')) {
      displayValue = '${value['ppp']} PPP';
    } else if (value.containsKey('possessions')) {
      displayValue = '${value['possessions']} pos';
    } else if (value.containsKey('value')) {
      displayValue = value['value'].toString();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              // Font suggestions: 'Inter', 'Roboto', 'SF Pro Text'
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              // Font suggestions: 'Inter', 'Roboto', 'SF Pro Text'
            ),
          ),
        ],
      ),
    );
  }
}
