// lib/features/scouting/presentation/screens/coach_self_scouting_screen.dart

import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/self_scouting_cubit.dart';
import '../widgets/stat_card.dart';
import '../../data/models/self_scouting_data.dart';
import '../../../teams/data/repositories/team_repository.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../games/presentation/screens/upload_scouting_report_screen.dart';

class CoachSelfScoutingScreen extends StatefulWidget {
  const CoachSelfScoutingScreen({super.key});

  @override
  State<CoachSelfScoutingScreen> createState() => _CoachSelfScoutingScreenState();
}

class _CoachSelfScoutingScreenState extends State<CoachSelfScoutingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _selectedPlayer;
  List<User> _teamPlayers = [];
  bool _isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTeamPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamPlayers() async {
    try {
      setState(() {
        _isLoadingPlayers = true;
      });

      // Get the current user's team players
      final teamRepository = sl<TeamRepository>();
      final token = context.read<AuthCubit>().state.token;
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Get teams and extract players from all teams
      final teams = await teamRepository.getMyTeams(token: token);
      final allPlayers = <User>[];
      
      for (final team in teams) {
        allPlayers.addAll(team.players);
      }
      
      // Remove duplicates based on user ID
      final uniquePlayers = <int, User>{};
      for (final player in allPlayers) {
        uniquePlayers[player.id] = player;
      }
      
      _teamPlayers = uniquePlayers.values.toList();

      setState(() {
        _isLoadingPlayers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlayers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load team players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPlayer(User player) {
    setState(() {
      _selectedPlayer = player;
    });
    
    // Load self-scouting data for the selected player
    context.read<SelfScoutingCubit>().loadSelfScoutingDataForPlayer(player.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLAYER SELF-SCOUTING'),
        actions: [
          if (_selectedPlayer != null)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UploadScoutingReportScreen(),
                  ),
                );
              },
              tooltip: 'Upload Scouting Report',
            ),
        ],
      ),
      body: Column(
        children: [
          // Player Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Player to View Self-Scouting Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingPlayers)
                  const Center(child: CircularProgressIndicator())
                else if (_teamPlayers.isEmpty)
                  Text(
                    'No players found in your team',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  )
                else
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _teamPlayers.length,
                      itemBuilder: (context, index) {
                        final player = _teamPlayers[index];
                        final isSelected = _selectedPlayer?.id == player.id;
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              '${player.firstName} ${player.lastName}',
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _selectPlayer(player);
                              }
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Self-Scouting Content
          Expanded(
            child: _selectedPlayer == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a player to view their self-scouting data',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildSelfScoutingContent(),
          ),
        ],
      ),
      floatingActionButton: _selectedPlayer != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UploadScoutingReportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Report'),
              tooltip: 'Upload scouting report for ${_selectedPlayer?.firstName} ${_selectedPlayer?.lastName}',
            )
          : null,
    );
  }

  Widget _buildSelfScoutingContent() {
    return BlocBuilder<SelfScoutingCubit, SelfScoutingState>(
      builder: (context, state) {
        if (state is SelfScoutingLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SelfScoutingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedPlayer != null) {
                      context.read<SelfScoutingCubit>().loadSelfScoutingDataForPlayer(_selectedPlayer!.id);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is SelfScoutingLoaded) {
          return _buildContent(context, state.data);
        }
        
        return const Center(
          child: Text('No data available'),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SelfScoutingData data) {
    return Column(
      children: [
        // Player Info Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${_selectedPlayer?.firstName.substring(0, 1) ?? ''}${_selectedPlayer?.lastName.substring(0, 1) ?? ''}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedPlayer?.firstName} ${_selectedPlayer?.lastName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Jersey #${_selectedPlayer?.jerseyNumber ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Tab Bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'PLAYER'),
              Tab(text: 'TEAM'),
              Tab(text: 'SEASON'),
              Tab(text: 'CHEMISTRY'),
              Tab(text: 'STORYLINES'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, data),
              _buildPlayerTab(context, data),
              _buildTeamTab(context, data),
              _buildSeasonTab(context, data),
              _buildChemistryTab(context, data),
              _buildStorylinesTab(context, data),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Key Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                title: 'Games Played',
                value: data.playerProfile.gamesPlayed.toString(),
                icon: Icons.sports_basketball,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Points Per Game',
                value: data.playerProfile.pointsPerGame.toStringAsFixed(1),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              StatCard(
                title: 'Rebounds Per Game',
                value: data.playerProfile.reboundsPerGame.toStringAsFixed(1),
                icon: Icons.sports,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Assists Per Game',
                value: data.playerProfile.assistsPerGame.toStringAsFixed(1),
                icon: Icons.share,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player Performance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Player stats would go here
          Text(
            'Detailed player statistics and performance metrics will be displayed here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Performance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Team performance metrics and statistics will be displayed here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season Statistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Season-long statistics and trends will be displayed here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildChemistryTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Chemistry',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Team chemistry metrics and player interactions will be displayed here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStorylinesTab(BuildContext context, SelfScoutingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season Storylines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Key storylines and narrative elements from the season will be displayed here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
