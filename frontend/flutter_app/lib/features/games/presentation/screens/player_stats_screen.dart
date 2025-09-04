import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/game_model.dart';
import '../../../possessions/data/models/possession_model.dart';
import '../../data/models/game_roster_model.dart';
import '../../data/models/player_minutes_tracker.dart';
import '../../data/repositories/game_repository.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../teams/data/models/team_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';

class PlayerStatsScreen extends StatefulWidget {
  final int gameId;

  const PlayerStatsScreen({super.key, required this.gameId});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Game? _game;
  List<Possession> _possessions = [];
  final Map<String, PlayerStats> _playerStats = {};
  final Map<String, GameRoster> _gameRoster = {}; // teamId -> GameRoster
  final Map<String, PlayerMinutesTracker> _minutesTrackers = {}; // teamId -> PlayerMinutesTracker
  bool _isLoading = true;
  String? _selectedQuarter;
  String? _sortBy;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadGameData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    
    try {
      final gameRepo = GameRepository();
      final token = context.read<AuthCubit>().state.token!;
      final game = await gameRepo.getGameDetails(token: token, gameId: widget.gameId);
      final possessionsJson = await gameRepo.getAllGamePossessions(token: token, gameId: widget.gameId);
      final possessions = possessionsJson.map((e) => Possession.fromJson(e)).toList();
      
      setState(() {
        _game = game;
        _possessions = possessions;
        _isLoading = false;
      });
      
      _computePlayerStats();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading game data: $e')),
        );
      }
    }
  }

  void _computePlayerStats() {
    print('🔍 [PlayerStats] Starting _computePlayerStats');
    print('🔍 [PlayerStats] Total possessions: ${_possessions.length}');
    
    _playerStats.clear();
    _gameRoster.clear();
    _minutesTrackers.clear();
    
    if (_game == null) return;
    
    // Step 1: Create game rosters (12 players per team)
    _createGameRosters();
    
    // Step 2: Initialize player stats from rosters (not from possessions)
    _initializePlayerStatsFromRosters();
    
    // Step 3: Process possessions to add stats
    _processPossessionsForStats();
    
    // Step 4: Calculate minutes and validate time
    _calculateAndValidateMinutes();
    
    // Step 5: Calculate totals and mark starting five
    _finalizeStats();
    
    setState(() {});
    }
  
  void _createGameRosters() {
    print('🔍 [PlayerStats] Creating game rosters from backend data...');
    
    if (_game == null) return;
    
    // Get unique teams from possessions
    final Set<String> teamIds = {};
    for (final possession in _possessions) {
      if (possession.team != null) {
        teamIds.add(possession.team!.team.id.toString());
      }
      if (possession.opponent != null) {
        teamIds.add(possession.opponent!.team.id.toString());
      }
    }
    
    print('🔍 [PlayerStats] Found team IDs: $teamIds');
    
    // Create rosters from the actual GameRoster data in possessions
    for (final teamId in teamIds) {
      // Find the first possession for this team to get the roster
      final teamPossession = _possessions.firstWhere(
        (p) => p.team?.team.id.toString() == teamId || p.opponent?.team.id.toString() == teamId,
        orElse: () => _possessions.first,
      );
      
      if (teamPossession.team?.team.id.toString() == teamId) {
        // This team was the offensive team
        final roster = teamPossession.team!;
        _gameRoster[teamId] = roster;
        print('🔍 [PlayerStats] Added roster for ${roster.team.name}: ${roster.players.length} players');
      } else if (teamPossession.opponent?.team.id.toString() == teamId) {
        // This team was the defensive team
        final roster = teamPossession.opponent!;
        _gameRoster[teamId] = roster;
        print('🔍 [PlayerStats] Added roster for ${roster.team.name}: ${roster.players.length} players');
      }
    }
  }
  
  void _initializePlayerStatsFromRosters() {
    print('🔍 [PlayerStats] Initializing player stats from rosters...');
    
    for (final entry in _gameRoster.entries) {
      final teamId = entry.key;
      final roster = entry.value;
      
      // Create PlayerStats for this team
      _playerStats[teamId] = PlayerStats(team: roster.team);
      
      // Initialize stats for all 12 players in roster
      for (final player in roster.players) {
        final playerStat = IndividualPlayerStats(player: player);
        playerStat.isStartingFive = roster.isStartingFive(player.id);
        _playerStats[teamId]!.playerStats[player.id] = playerStat;
      }
      
      print('🔍 [PlayerStats] Initialized stats for ${roster.team.name}: ${roster.players.length} players');
    }
  }
  
  void _processPossessionsForStats() {
    print('🔍 [PlayerStats] Processing possessions for stats...');
    
    // Process each possession for both offensive and defensive teams
    for (final possession in _possessions) {
      if (possession.team == null) continue;
      
      final offensiveTeamId = possession.team!.team.id.toString();
      final defensiveTeamId = possession.opponent?.team.id.toString();
      
      // Process offensive team stats
      if (_playerStats.containsKey(offensiveTeamId)) {
        _processOffensiveTeamStats(possession, offensiveTeamId);
      }
      
      // Process defensive team stats
      if (defensiveTeamId != null && _playerStats.containsKey(defensiveTeamId)) {
        _processDefensiveTeamStats(possession, defensiveTeamId);
      }
    }
  }
  
  void _processOffensiveTeamStats(Possession possession, String teamId) {
    final stats = _playerStats[teamId]!;
    
    // Update quarter stats
    final quarter = possession.quarter.toString();
    if (!stats.quarterStats.containsKey(quarter)) {
      stats.quarterStats[quarter] = QuarterStats();
    }
    final quarterStats = stats.quarterStats[quarter]!;
    quarterStats.possessions++;
    quarterStats.points += possession.pointsScored;
    
    // Process offensive stats (scoring, assists, etc.)
    if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
      _updatePlayerStat(stats, possession.scorer!, 'points', possession.pointsScored);
      
      if (possession.outcome == 'MADE_2PTS') {
        _updatePlayerStat(stats, possession.scorer!, 'twoPointsMade', 1);
        _updatePlayerStat(stats, possession.scorer!, 'twoPointsAttempted', 1);
      } else if (possession.outcome == 'MADE_3PTS') {
        _updatePlayerStat(stats, possession.scorer!, 'threePointsMade', 1);
        _updatePlayerStat(stats, possession.scorer!, 'threePointsAttempted', 1);
      } else if (possession.outcome == 'MADE_FTS') {
        _updatePlayerStat(stats, possession.scorer!, 'freeThrowsMade', 1);
        _updatePlayerStat(stats, possession.scorer!, 'freeThrowsAttempted', 1);
      }
    }
    
    if (possession.assistedBy != null && _isPlayerInRoster(teamId, possession.assistedBy!.id)) {
      _updatePlayerStat(stats, possession.assistedBy!, 'assists', 1);
    }
    
    // Handle missed shots and turnovers
    if (possession.outcome == 'MISSED_2PTS') {
      if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
        _updatePlayerStat(stats, possession.scorer!, 'twoPointsAttempted', 1);
      }
    } else if (possession.outcome == 'MISSED_3PTS') {
      if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
        _updatePlayerStat(stats, possession.scorer!, 'threePointsAttempted', 1);
      }
    } else if (possession.outcome == 'MISSED_FTS') {
      if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
        _updatePlayerStat(stats, possession.scorer!, 'freeThrowsAttempted', 1);
      }
    } else if (possession.outcome == 'TURNOVER') {
      if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
        _updatePlayerStat(stats, possession.scorer!, 'turnovers', 1);
      }
    }
    
    // Handle offensive rebounds
    if (possession.isOffensiveRebound == true && possession.offensiveReboundCount > 0) {
      if (possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
        _updatePlayerStat(stats, possession.scorer!, 'offensiveRebounds', possession.offensiveReboundCount);
      }
    }
    
    // Handle fouls committed
    if (possession.outcome == 'FOUL' && possession.scorer != null && _isPlayerInRoster(teamId, possession.scorer!.id)) {
      _updatePlayerStat(stats, possession.scorer!, 'personalFouls', 1);
    }
    
    // Calculate +/- (hardcoded to 0 for now)
    for (final player in possession.playersOnCourt) {
      if (_isPlayerInRoster(teamId, player.id)) {
        _updatePlayerStat(stats, player, 'plusMinus', 0); // Hardcoded as requested
      }
    }
  }
  
  void _processDefensiveTeamStats(Possession possession, String teamId) {
    final stats = _playerStats[teamId]!;
    
    // Handle defensive rebounds
    if ((possession.outcome == 'MISSED_2PTS' || possession.outcome == 'MISSED_3PTS') && !possession.isOffensiveRebound) {
      if (possession.defensivePlayersOnCourt.isNotEmpty) {
        final rebounder = possession.defensivePlayersOnCourt.first;
        if (_isPlayerInRoster(teamId, rebounder.id)) {
          _updatePlayerStat(stats, rebounder, 'defensiveRebounds', 1);
        }
      }
    }
    
    // Handle blocks
    if (possession.blockedBy != null && _isPlayerInRoster(teamId, possession.blockedBy!.id)) {
      _updatePlayerStat(stats, possession.blockedBy!, 'blocks', 1);
    }
    
    // Handle steals
    if (possession.stolenBy != null && _isPlayerInRoster(teamId, possession.stolenBy!.id)) {
      _updatePlayerStat(stats, possession.stolenBy!, 'steals', 1);
    }
    
    // Handle fouls drawn
    if (possession.fouledBy != null && _isPlayerInRoster(teamId, possession.fouledBy!.id)) {
      _updatePlayerStat(stats, possession.fouledBy!, 'fouls', 1);
    }
  }
  
  void _calculateAndValidateMinutes() {
    print('🔍 [PlayerStats] Calculating and validating minutes...');
    
    for (final entry in _gameRoster.entries) {
      final teamId = entry.key;
      final roster = entry.value;
      
      // Create minutes tracker for this team
      final tracker = PlayerMinutesTracker();
      _minutesTrackers[teamId] = tracker;
      
      // Process possessions to build time tracking for this specific team
      tracker.processPossessionsForTeam(_possessions, teamId);
      
      // Update player stats with calculated minutes
      if (_playerStats.containsKey(teamId)) {
        final stats = _playerStats[teamId]!;
        
        for (final player in roster.players) {
          final minutes = tracker.getPlayerMinutes(player.id);
          _updatePlayerStat(stats, player, 'seconds', minutes);
        }
        
        // Validate total team time
        final overtimePeriods = _getOvertimePeriods();
        final isValid = tracker.validateTeamTime(overtimePeriods);
        final totalTime = tracker.getTotalTeamTimeFormatted();
        
        print('🔍 [PlayerStats] ${roster.team.name} total time: $totalTime (valid: $isValid)');
        print('🔍 [PlayerStats] Expected: ${roster.getTotalTeamMinutes(overtimePeriods)}:00');
      }
    }
  }
  
  void _finalizeStats() {
    print('🔍 [PlayerStats] Finalizing stats...');
    
    for (final stats in _playerStats.values) {
      stats.calculateTotals();
      
      print('🔍 [PlayerStats] Team: ${stats.team.name}');
      print('🔍 [PlayerStats] Total players in stats: ${stats.playerStats.length}');
      print('🔍 [PlayerStats] Player IDs: ${stats.playerStats.keys.toList()}');
      print('🔍 [PlayerStats] Total players in stats: ${stats.playerStats.values.map((p) => p.player.username).toList()}');
    }
  }
  
  // Helper method to check if a player is in a team's roster
  bool _isPlayerInRoster(String teamId, int playerId) {
    return _gameRoster[teamId]?.isPlayerInRoster(playerId) ?? false;
  }
  
  // Helper method to get overtime periods
  int _getOvertimePeriods() {
    if (_game == null) return 0;
    
    // Count quarters beyond 4
    final maxQuarter = _possessions.fold<int>(1, (max, p) => p.quarter > max ? p.quarter : max);
    return maxQuarter > 4 ? maxQuarter - 4 : 0;
  }

  void _updatePlayerStat(PlayerStats teamStats, User player, String statType, int value) {
    // Stats are now initialized from rosters, so we just need to update them
    if (!teamStats.playerStats.containsKey(player.id)) {
      print('🔍 [PlayerStats] _updatePlayerStat: Creating new stats for ${player.username} (${player.id}) in team ${teamStats.team.name}');
      teamStats.playerStats[player.id] = IndividualPlayerStats(player: player);
    }
    
    final playerStat = teamStats.playerStats[player.id]!;
    print('🔍 [PlayerStats] _updatePlayerStat: Updating ${player.username} (${player.id}) in team ${teamStats.team.name} - $statType: $value');
    
    switch (statType) {
      case 'points':
        playerStat.points += value;
        break;
      case 'seconds':
        playerStat.secondsPlayed += value;
        break;
      case 'assists':
        playerStat.assists += value;
        break;
      case 'blocks':
        playerStat.blocks += value;
        break;
      case 'steals':
        playerStat.steals += value;
        break;
      case 'turnovers':
        playerStat.turnovers += value;
        break;
      case 'twoPointsMade':
        playerStat.twoPointsMade += value;
        break;
      case 'twoPointsAttempted':
        playerStat.twoPointsAttempted += value;
        break;
      case 'threePointsMade':
        playerStat.threePointsMade += value;
        break;
      case 'threePointsAttempted':
        playerStat.threePointsAttempted += value;
        break;
      case 'freeThrowsMade':
        playerStat.freeThrowsMade += value;
        break;
      case 'freeThrowsAttempted':
        playerStat.freeThrowsAttempted += value;
        break;
      case 'offensiveRebounds':
        playerStat.offensiveRebounds += value;
        break;
      case 'defensiveRebounds':
        playerStat.defensiveRebounds += value;
        break;
      case 'fouls':
        playerStat.fouls += value;
        break;
      case 'personalFouls':
        playerStat.personalFouls += value;
        break;
      case 'plusMinus':
        playerStat.plusMinus += value;
        break;
    }
  }

  void _onQuarterChanged(String? quarter) {
    setState(() {
      _selectedQuarter = quarter;
    });
  }

  void _onSortChanged(String? sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = false;
      }
    });
  }

  List<IndividualPlayerStats> _getSortedPlayerStats(String teamId) {
    final stats = _playerStats[teamId];
    if (stats == null) return [];
    
    var playerList = stats.playerStats.values.toList();
    
    if (_sortBy != null) {
      playerList.sort((a, b) {
        int comparison = 0;
        switch (_sortBy!) {
          case 'points':
            comparison = a.points.compareTo(b.points);
            break;
          case 'assists':
            comparison = a.assists.compareTo(b.assists);
            break;
          case 'rebounds':
            comparison = (a.offensiveRebounds + a.defensiveRebounds).compareTo(
              b.offensiveRebounds + b.defensiveRebounds);
            break;
          case 'steals':
            comparison = a.steals.compareTo(b.steals);
            break;
          case 'blocks':
            comparison = a.blocks.compareTo(b.blocks);
            break;
          case 'turnovers':
            comparison = a.turnovers.compareTo(b.turnovers);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
    
    return playerList;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_game == null) {
      return const Scaffold(
        body: Center(child: Text('Game not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Player Stats - ${_game!.homeTeam.name} vs ${_game!.awayTeam.name}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'OVERALL'),
            Tab(text: '1ST'),
            Tab(text: '2ND'),
            Tab(text: '3RD'),
            Tab(text: '4TH'),
            Tab(text: 'OT'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverallTab(),
                _buildQuarterTab('1'),
                _buildQuarterTab('2'),
                _buildQuarterTab('3'),
                _buildQuarterTab('4'),
                _buildQuarterTab('5'), // OT
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedQuarter,
              decoration: const InputDecoration(
                labelText: 'Filter by Quarter',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Quarters')),
                const DropdownMenuItem(value: '1', child: Text('1st Quarter')),
                const DropdownMenuItem(value: '2', child: Text('2nd Quarter')),
                const DropdownMenuItem(value: '3', child: Text('3rd Quarter')),
                const DropdownMenuItem(value: '4', child: Text('4th Quarter')),
                const DropdownMenuItem(value: '5', child: Text('Overtime')),
              ],
              onChanged: _onQuarterChanged,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Sort')),
                const DropdownMenuItem(value: 'points', child: Text('Points')),
                const DropdownMenuItem(value: 'assists', child: Text('Assists')),
                const DropdownMenuItem(value: 'rebounds', child: Text('Rebounds')),
                const DropdownMenuItem(value: 'steals', child: Text('Steals')),
                const DropdownMenuItem(value: 'blocks', child: Text('Blocks')),
                const DropdownMenuItem(value: 'turnovers', child: Text('Turnovers')),
              ],
              onChanged: _onSortChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallTab() {
    return _buildTeamStats(_game!.homeTeam.id.toString(), _game!.awayTeam.id.toString());
  }

  Widget _buildQuarterTab(String quarter) {
    return _buildTeamStats(
      _game!.homeTeam.id.toString(),
      _game!.awayTeam.id.toString(),
      quarter: quarter,
    );
  }

  Widget _buildTeamStats(String homeTeamId, String awayTeamId, {String? quarter}) {
    final homeStats = _playerStats[homeTeamId];
    final awayStats = _playerStats[awayTeamId];
    
    if (homeStats == null || awayStats == null) {
      return const Center(child: Text('No stats available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeamHeader(homeStats.team, homeStats, quarter),
          const SizedBox(height: 16),
          _buildPlayerStatsTable(homeStats, quarter),
          const SizedBox(height: 32),
          _buildTeamHeader(awayStats.team, awayStats, quarter),
          const SizedBox(height: 16),
          _buildPlayerStatsTable(awayStats, quarter),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(Team team, PlayerStats stats, String? quarter) {
    final quarterStats = quarter != null ? stats.quarterStats[quarter] : null;
    final totalPoints = quarterStats?.points ?? stats.totalPoints;
    final totalPossessions = quarterStats?.possessions ?? stats.totalPossessions;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              team.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: team.id == _game!.homeTeam.id ? Colors.blue : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip('Points', totalPoints.toString()),
                _buildStatChip('Possessions', totalPossessions.toString()),
                if (quarter != null) _buildStatChip('Quarter', quarter),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPlayerStatsTable(PlayerStats teamStats, String? quarter) {
    final playerList = _getSortedPlayerStats(teamStats.team.id.toString());
    
    if (playerList.isEmpty) {
      return const Center(child: Text('No player stats available'));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Player')),
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('ST')),
            const DataColumn(label: Text('MIN')),
            const DataColumn(label: Text('PTS')),
            const DataColumn(label: Text('2PM/A')),
            const DataColumn(label: Text('3PM/A')),
            const DataColumn(label: Text('FTM/A')),
            const DataColumn(label: Text('ORB')),
            const DataColumn(label: Text('DRB')),
            const DataColumn(label: Text('AST')),
            const DataColumn(label: Text('STL')),
            const DataColumn(label: Text('BLK')),
            const DataColumn(label: Text('TOV')),
            const DataColumn(label: Text('PF')),
            const DataColumn(label: Text('+/-')),
          ],
          rows: playerList.map((player) {
            return DataRow(
              cells: [
                DataCell(Text(player.player.displayName)),
                DataCell(Text(player.player.jerseyNumber?.toString() ?? '--')),
                DataCell(Text(player.isStartingFive ? 'ST' : '')),
                DataCell(Text(_formatSeconds(player.secondsPlayed))),
                DataCell(Text(player.points.toString())),
                DataCell(Text('${player.twoPointsMade}/${player.twoPointsAttempted}')),
                DataCell(Text('${player.threePointsMade}/${player.threePointsAttempted}')),
                DataCell(Text('${player.freeThrowsMade}/${player.freeThrowsAttempted}')),
                DataCell(Text(player.offensiveRebounds.toString())),
                DataCell(Text(player.defensiveRebounds.toString())),
                DataCell(Text(player.assists.toString())),
                DataCell(Text(player.steals.toString())),
                DataCell(Text(player.blocks.toString())),
                DataCell(Text(player.turnovers.toString())),
                DataCell(Text(player.personalFouls.toString())),
                DataCell(Text(player.plusMinus >= 0 ? '+${player.plusMinus}' : '${player.plusMinus}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString();
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

// Data classes for player statistics
class PlayerStats {
  final Team team;
  final Map<String, QuarterStats> quarterStats = {};
  final Map<int, IndividualPlayerStats> playerStats = {};
  int totalPoints = 0;
  int totalPossessions = 0;

  PlayerStats({required this.team});

  void calculateTotals() {
    totalPoints = 0;
    totalPossessions = 0;
    
    for (final quarter in quarterStats.values) {
      totalPoints += quarter.points;
      totalPossessions += quarter.possessions;
    }
  }
}

class QuarterStats {
  int possessions = 0;
  int points = 0;
}

class IndividualPlayerStats {
  final User player;
  int points = 0;
  int assists = 0;
  int blocks = 0;
  int steals = 0;
  int turnovers = 0;
  int twoPointsMade = 0;
  int twoPointsAttempted = 0;
  int threePointsMade = 0;
  int threePointsAttempted = 0;
  int freeThrowsMade = 0;
  int freeThrowsAttempted = 0;
  int offensiveRebounds = 0;
  int defensiveRebounds = 0;
  int fouls = 0;
  int personalFouls = 0;
  int secondsPlayed = 0;
  int plusMinus = 0;
  bool isStartingFive = false;

  IndividualPlayerStats({required this.player});
}
