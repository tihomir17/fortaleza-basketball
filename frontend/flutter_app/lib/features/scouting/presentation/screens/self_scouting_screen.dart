// lib/features/scouting/presentation/screens/self_scouting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/user_profile_app_bar.dart';
import '../cubit/self_scouting_cubit.dart';
import '../widgets/stat_card.dart';
import '../widgets/progress_indicator.dart';
import '../../data/models/self_scouting_data.dart';
import '../../../../core/services/api_service.dart';
import '../../data/services/self_scouting_service.dart';

class SelfScoutingScreen extends StatefulWidget {
  const SelfScoutingScreen({super.key});

  @override
  State<SelfScoutingScreen> createState() => _SelfScoutingScreenState();
}

class _SelfScoutingScreenState extends State<SelfScoutingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Try to load real data first, fall back to mock if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfScoutingCubit>().loadSelfScoutingData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserProfileAppBar(title: 'SELF SCOUTING'),
      body: BlocBuilder<SelfScoutingCubit, SelfScoutingState>(
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
                      context.read<SelfScoutingCubit>().loadMockSelfScoutingData();
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
      ),
    );
  }

  Widget _buildContent(BuildContext context, SelfScoutingData data) {
    return Column(
      children: [
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
          // Player Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      data.playerProfile.jerseyNumber.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.playerProfile.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.playerProfile.position} • ${data.playerProfile.team}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatChip('${data.playerProfile.gamesPlayed} GP'),
                            const SizedBox(width: 8),
                            _buildStatChip('${data.playerProfile.minutesPerGame.toStringAsFixed(1)} MPG'),
                            const SizedBox(width: 8),
                            _buildStatChip('${data.playerProfile.pointsPerGame.toStringAsFixed(1)} PPG'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Key Stats Grid
          Text(
            'Key Statistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StatCardGrid(
            crossAxisCount: 4,
            cards: [
              StatCard(
                title: 'Points Per Game',
                value: data.playerProfile.pointsPerGame.toStringAsFixed(1),
                subtitle: 'Total: ${data.playerProfile.totalPoints}',
                icon: Icons.sports_basketball,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Assists Per Game',
                value: data.playerProfile.assistsPerGame.toStringAsFixed(1),
                subtitle: 'Total: ${data.playerProfile.totalAssists}',
                icon: Icons.handshake,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Rebounds Per Game',
                value: data.playerProfile.reboundsPerGame.toStringAsFixed(1),
                subtitle: 'Total: ${data.playerProfile.totalRebounds}',
                icon: Icons.vertical_align_top,
                color: Colors.green,
              ),
              StatCard(
                title: 'Field Goal %',
                value: '${(data.playerProfile.fieldGoalPercentage * 100).toStringAsFixed(1)}%',
                subtitle: '3PT: ${(data.playerProfile.threePointPercentage * 100).toStringAsFixed(1)}%',
                icon: Icons.track_changes,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Games
          Text(
            'Recent Games',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentGamesList(data.recentGames.lastFiveGames),
          
          const SizedBox(height: 24),
          
          // Next Game
          Text(
            'Next Game',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNextGameCard(data.recentGames.nextGame),
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
          // Player Comparison
          Text(
            'League Comparison',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.playerComparison.metrics.map((metric) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ComparisonProgressIndicator(
                label: metric.metric,
                playerValue: metric.playerValue,
                leagueAverage: metric.leagueAverage,
                leaguePercentile: metric.leaguePercentile,
                trend: metric.trend,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Strengths & Areas for Improvement
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strengths',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.playerProfile.strengths.map((strength) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strength,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Areas for Improvement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.playerProfile.areasForImprovement.map((area) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    area,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          // Team Record
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    data.teamPerformance.teamName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeamStat('Wins', data.teamPerformance.wins.toString(), Colors.green),
                      _buildTeamStat('Losses', data.teamPerformance.losses.toString(), Colors.red),
                      _buildTeamStat('Win %', '${(data.teamPerformance.winPercentage * 100).toStringAsFixed(1)}%', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Team Stats Grid
          Text(
            'Team Statistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StatCardGrid(
            crossAxisCount: 2,
            cards: [
              StatCard(
                title: 'Points Per Game',
                value: data.teamPerformance.pointsPerGame.toStringAsFixed(1),
                subtitle: 'Allowed: ${data.teamPerformance.pointsAllowedPerGame.toStringAsFixed(1)}',
                icon: Icons.sports_basketball,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Rebounds Per Game',
                value: data.teamPerformance.reboundsPerGame.toStringAsFixed(1),
                subtitle: 'Total: ${data.teamPerformance.totalRebounds}',
                icon: Icons.vertical_align_top,
                color: Colors.green,
              ),
              StatCard(
                title: 'Assists Per Game',
                value: data.teamPerformance.assistsPerGame.toStringAsFixed(1),
                subtitle: 'Total: ${data.teamPerformance.totalAssists}',
                icon: Icons.handshake,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Field Goal %',
                value: '${(data.teamPerformance.fieldGoalPercentage * 100).toStringAsFixed(1)}%',
                subtitle: 'Allowed: ${(data.teamPerformance.fieldGoalPercentageAllowed * 100).toStringAsFixed(1)}%',
                icon: Icons.track_changes,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Team Style & Strengths
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Style',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Style: ${data.teamPerformance.teamStyle}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Strength: ${data.teamPerformance.teamStrength}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Offensive Rating: ${data.teamPerformance.offensiveRating}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Defensive Rating: ${data.teamPerformance.defensiveRating}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Strengths',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.teamPerformance.teamStrengths.take(3).map((strength) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strength,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          // Season Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Season ${data.seasonStats.currentSeason}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeamStat('Games', data.seasonStats.totalGames.toString(), Colors.blue),
                      _buildTeamStat('Wins', data.seasonStats.totalWins.toString(), Colors.green),
                      _buildTeamStat('Losses', data.seasonStats.totalLosses.toString(), Colors.red),
                      _buildTeamStat('Win %', '${(data.seasonStats.overallWinPercentage * 100).toStringAsFixed(1)}%', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Monthly Performance
          Text(
            'Monthly Performance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStats.monthlyPerformance.map((month) => 
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          month.month,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(month.winPercentage * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: month.winPercentage >= 0.5 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Games: ${month.gamesPlayed}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Record: ${month.wins}-${month.losses}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PPG: ${month.averagePointsPerGame.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'RPG: ${month.averageReboundsPerGame.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Opponent Performance
          Text(
            'Opponent Performance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStats.opponentPerformance.map((opponent) => 
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent.opponentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Games: ${opponent.gamesPlayed}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Record: ${opponent.wins}-${opponent.losses}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Points For: ${opponent.averagePointsFor.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Points Against: ${opponent.averagePointsAgainst.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
          // Best Lineups
          Text(
            'Best Lineups',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.teamChemistry.bestLineups.map((lineup) => 
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lineup: ${lineup.players.join(", ")}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minutes: ${lineup.minutesPlayed}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Net Rating: ${lineup.netRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offensive: ${lineup.offensiveRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Defensive: ${lineup.defensiveRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Top Partnerships
          Text(
            'Top Partnerships',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.teamChemistry.topPartnerships.map((partnership) => 
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${partnership.player1} + ${partnership.player2}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSynergyColor(partnership.synergy),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            partnership.synergy,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minutes: ${partnership.minutesPlayed}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Plus/Minus: ${partnership.plusMinus.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offensive: ${partnership.offensiveRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Defensive: ${partnership.defensiveRating.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Team Analysis
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team Strengths',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.teamChemistry.teamStrengths.take(3).map((strength) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strength,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Improvement Areas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.teamChemistry.improvementAreas.take(3).map((area) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    area,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          // Player Storylines
          Text(
            'Player Storylines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStorylines.playerStorylines.map((storyline) => 
            _buildStorylineCard(storyline, _getStorylineColor(storyline.impact)),
          ),
          
          const SizedBox(height: 24),
          
          // Team Storylines
          Text(
            'Team Storylines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStorylines.teamStorylines.map((storyline) => 
            _buildStorylineCard(storyline, _getStorylineColor(storyline.impact)),
          ),
          
          const SizedBox(height: 24),
          
          // Rivalry Storylines
          Text(
            'Rivalry Storylines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStorylines.rivalryStorylines.map((storyline) => 
            _buildRivalryStorylineCard(storyline),
          ),
          
          const SizedBox(height: 24),
          
          // Season Highlights
          Text(
            'Season Highlights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStorylines.seasonHighlights.map((highlight) => 
            _buildHighlightCard(highlight),
          ),
          
          const SizedBox(height: 24),
          
          // Season Challenges
          Text(
            'Season Challenges',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...data.seasonStorylines.seasonChallenges.map((challenge) => 
            _buildChallengeCard(challenge),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTeamStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGamesList(List<GameResult> games) {
    return Column(
      children: games.map((game) => 
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: game.result == 'W' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      game.result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${game.opponent}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${game.teamScore} - ${game.opponentScore}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      game.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${game.playerPoints} pts, ${game.playerRebounds} reb, ${game.playerAssists} ast',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildNextGameCard(GameResult nextGame) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_basketball, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Next Game',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'vs ${nextGame.opponent}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${nextGame.date}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Venue: ${nextGame.venue}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorylineCard(dynamic storyline, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storyline.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  storyline.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              storyline.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRivalryStorylineCard(RivalryStoryline storyline) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${storyline.opponent} - ${storyline.title}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(storyline.intensity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    storyline.intensity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              storyline.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'History: ${storyline.history}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(SeasonHighlight highlight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highlight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              highlight.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Impact: ${highlight.impact}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(SeasonChallenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(challenge.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.severity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Status: ${challenge.status}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  challenge.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Color _getStorylineColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getSynergyColor(String synergy) {
    switch (synergy.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
