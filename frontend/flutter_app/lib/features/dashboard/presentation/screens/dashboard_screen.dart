// lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';
import 'package:fortaleza_basketball_analytics/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/dashboard/data/models/dashboard_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/user_profile_app_bar.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:go_router/go_router.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/upcoming_games_list.dart';
import '../widgets/recent_games_list.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/upcoming_events_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _refreshSubscription = _refreshSignal.stream.listen((_) => _refreshDashboard());
    
    // Load dashboard data when screen initializes - always force refresh for latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardCubit>().loadDashboardData(forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  void _refreshDashboard() {
    if (mounted) {
      context.read<DashboardCubit>().loadDashboardData(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserProfileAppBar(
        title: 'DASHBOARD',
        onRefresh: () => context.read<DashboardCubit>().loadDashboardData(forceRefresh: true),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.authenticated && authState.user != null) {
            final isPlayer = authState.status == AuthStatus.authenticated && 
                            authState.user != null && 
                            authState.user!.role == 'PLAYER';
            final isStaff = authState.status == AuthStatus.authenticated && 
                           authState.user != null && 
                           authState.user!.role == 'STAFF';
            
            // Non-management staff users should only have calendar access - redirect them
            if (isStaff && authState.user?.staffType != 'MANAGEMENT') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.go('/calendar');
                }
              });
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // Update the app bar title based on user role
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final appBar = context.findAncestorWidgetOfExactType<AppBar>();
                if (appBar != null) {
                  // This approach won't work well, let's use a different strategy
                }
              }
            });
            
            return BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, dashboardState) {
                if (dashboardState is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (dashboardState is DashboardError) {
                  return _buildErrorState(dashboardState.message);
                } else if (dashboardState is DashboardLoaded) {
                  final isStaff = authState.user?.role == 'STAFF';
                  final staffType = authState.user?.staffType;
                  return _buildDashboardContent(dashboardState.dashboardData, isPlayer, isStaff, staffType);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
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
            'Error loading dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<DashboardCubit>().loadDashboardData(forceRefresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(dynamic dashboardData, bool isPlayer, bool isStaff, String? staffType) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardCubit>().loadDashboardData(forceRefresh: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // For coaches: Show full dashboard (not for management staff)
            if (!isPlayer && !isStaff) ...[
              // Quick Stats Card
              QuickStatsCard(stats: dashboardData.quickStats ?? QuickStats(totalGames: 0, totalPossessions: 0, recentPossessions: 0, avgPossessionsPerGame: 0.0)),
              const SizedBox(height: 12),
              
              // Quick Actions Grid
              QuickActionsGrid(actions: dashboardData.quickActions ?? []),
              const SizedBox(height: 12),
            ],
            
            // For players: Show upcoming events for today (filtered with attendeeIds like calendar)
            if (isPlayer) ...[
              Builder(
                builder: (context) {
                  final authUser = context.read<AuthCubit>().state.user;
                  final calendarState = context.read<CalendarCubit>().state;
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);

                  // Source of truth: calendar events (have attendeeIds)
                  final filteredCalendarEvents = calendarState.events.where((e) {
                    // Only upcoming from today forward
                    final eDate = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
                    if (eDate.isBefore(today)) return false;

                    if (e.eventType == 'PRACTICE_INDIVIDUAL') {
                      if (authUser == null) return false;
                      if (authUser.role == 'COACH') return true;
                      // PLAYER: must be assigned
                      return e.attendeeIds.contains(authUser.id);
                    }
                    // All other event types visible
                    return true;
                  }).toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  // Map to UpcomingEvent model used by the widget
                  final List<UpcomingEvent> upcoming = filteredCalendarEvents.map((e) => UpcomingEvent(
                    id: e.id,
                    title: e.title,
                    eventType: e.eventType,
                    startTime: e.startTime,
                    endTime: e.endTime,
                    location: null,
                    description: e.description,
                  )).toList();

                  return UpcomingEventsList(events: upcoming);
                },
              ),
              const SizedBox(height: 12),
            ],
            
            // For staff: Show staff-specific content
            if (isStaff) ...[
              _buildStaffDashboardContent(context, staffType),
              const SizedBox(height: 12),
            ],
            
            // Upcoming Games - Visible for coaches and players (not management staff)
            if (!isStaff) ...[
              UpcomingGamesList(games: dashboardData.upcomingGames ?? []),
              const SizedBox(height: 12),
              
              // Recent Games - Visible for coaches and players (not management staff)
              RecentGamesList(games: dashboardData.recentGames ?? []),
              const SizedBox(height: 12),
            ],
            
            // For coaches: Show additional sections (not for management staff)
            if (!isPlayer && !isStaff) ...[
              // Recent Activity
              RecentActivityList(activities: dashboardData.recentActivity ?? []),
              const SizedBox(height: 12),
              
              // Recent Reports (if any)
              if ((dashboardData.recentReports ?? []).isNotEmpty) ...[
                _buildRecentReportsCard(dashboardData.recentReports ?? []),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsCard(dynamic recentReports) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentReports.length,
              itemBuilder: (context, index) {
                final report = recentReports[index];
                return _ReportCard(report: report);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffDashboardContent(BuildContext context, String? staffType) {
    switch (staffType) {
      case 'PHYSIO':
        return _buildPhysioDashboard(context);
      case 'STRENGTH_CONDITIONING':
        return _buildSCDashboard(context);
      case 'MANAGEMENT':
        return _buildManagementDashboard(context);
      default:
        return _buildGenericStaffDashboard(context);
    }
  }

  Widget _buildPhysioDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Physio Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStaffCard(
                context: context,
                title: 'Injured Players',
                count: 3, // Mock data
                icon: Icons.medical_services_outlined,
                color: Colors.red,
                onTap: () => context.go('/player-health'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStaffCard(
                context: context,
                title: 'Recovery Progress',
                count: 5, // Mock data
                icon: Icons.trending_up_outlined,
                color: Colors.green,
                onTap: () => context.go('/injury-reports'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInjuredPlayersList(context),
      ],
    );
  }

  Widget _buildSCDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Strength & Conditioning Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStaffCard(
                context: context,
                title: 'Active Programs',
                count: 8, // Mock data
                icon: Icons.fitness_center_outlined,
                color: Colors.blue,
                onTap: () => context.go('/training-programs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStaffCard(
                context: context,
                title: 'Performance Metrics',
                count: 12, // Mock data
                icon: Icons.analytics_outlined,
                color: Colors.purple,
                onTap: () => context.go('/performance-metrics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPerformanceOverview(context),
      ],
    );
  }

  Widget _buildManagementDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Event Management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can manage the following event types:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEventTypeCard(
                context: context,
                title: 'Travel Bus',
                icon: Icons.directions_bus_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEventTypeCard(
                context: context,
                title: 'Travel Plane',
                icon: Icons.flight_outlined,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEventTypeCard(
                context: context,
                title: 'Team Building',
                icon: Icons.group_outlined,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Management Access',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You can create, edit, and delete Travel Bus, Travel Plane, and Team Building events from both the Calendar and Dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericStaffDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Staff Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Welcome to the staff dashboard. Your specific role will determine what information is displayed here.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInjuredPlayersList(BuildContext context) {
    // Mock data for injured players
    final injuredPlayers = [
      {'name': 'John Smith', 'injury': 'Ankle Sprain', 'status': 'Recovering'},
      {'name': 'Mike Johnson', 'injury': 'Knee Strain', 'status': 'Monitoring'},
      {'name': 'Alex Brown', 'injury': 'Shoulder Pain', 'status': 'Treatment'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Injured Players',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...injuredPlayers.map((player) => ListTile(
              leading: const Icon(Icons.person, color: Colors.red),
              title: Text(player['name']!),
              subtitle: Text('${player['injury']} - ${player['status']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go('/player-health'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.trending_up, color: Colors.green),
              title: Text('Average Fitness Score'),
              subtitle: Text('85% - Above target'),
            ),
            const ListTile(
              leading: Icon(Icons.fitness_center, color: Colors.blue),
              title: Text('Training Completion'),
              subtitle: Text('92% - Excellent'),
            ),
            const ListTile(
              leading: Icon(Icons.schedule, color: Colors.orange),
              title: Text('Next Assessment'),
              subtitle: Text('Due in 3 days'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${report.fileSizeMb} MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            report.team,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'By ${report.createdBy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(report.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

}