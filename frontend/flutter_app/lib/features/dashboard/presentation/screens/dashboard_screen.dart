// lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserProfileAppBar(title: 'DASHBOARD'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            final user = state.user!;
            if (user.role == 'ADMIN') {
              return _buildAdminDashboard(context);
            } else if (user.role == 'COACH') {
              return _buildCoachDashboard(context);
            } else {
              // 'PLAYER'
              return _buildPlayerDashboard(context);
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _DashboardCard(
          title: 'Manage Competitions',
          icon: Icons.emoji_events_outlined,
          onTap: () {},
        ),
        _DashboardCard(
          title: 'Manage All Teams',
          icon: Icons.group_work_outlined,
          onTap: () => context.go('/teams'),
        ),
        _DashboardCard(
          title: 'Manage All Users',
          icon: Icons.people_outline,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCoachDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _DashboardCard(
          title: 'Team Management',
          subtitle: 'Manage rosters and teams',
          icon: Icons.group_outlined,
          onTap: () => context.go('/teams'),
        ),
        _DashboardCard(
          title: 'Playbook Editor',
          subtitle: 'Create and edit plays',
          icon: Icons.menu_book_outlined,
          onTap: () => context.go('/playbook'),
        ),
        _DashboardCard(
          title: 'Game Analysis',
          subtitle: 'View game stats and possessions',
          icon: Icons.analytics_outlined,
          onTap: () => context.go('/games'),
        ),
      ],
    );
  }

  Widget _buildPlayerDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _DashboardCard(
          title: 'My Teams',
          subtitle: 'View your team roster and playbook',
          icon: Icons.group_outlined,
          onTap: () => context.go('/teams'),
        ),
        _DashboardCard(
          title: 'Game Schedule',
          subtitle: 'View upcoming and past games',
          icon: Icons.calendar_today_outlined,
          onTap: () => context.go('/games'),
        ),
        _DashboardCard(
          title: 'Scouting Reports',
          subtitle: 'Preparation materials from your coach',
          icon: Icons.video_library_outlined,
          onTap: () => context.go('/scouting-reports'),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
