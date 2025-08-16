// lib/features/teams/presentation/screens/manage_roster_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/teams/presentation/screens/user_search_screen.dart';
import 'package:flutter_app/main.dart'; // For Service Locator (sl)
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import '../cubit/team_detail_cubit.dart';
import 'add_player_screen.dart';

class ManageRosterScreen extends StatefulWidget {
  final Team team;
  const ManageRosterScreen({super.key, required this.team});

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  // We use local state here to avoid re-fetching the whole team on every change
  late List<User> _coaches;
  late List<User> _players;

  @override
  void initState() {
    super.initState();
    _coaches = List.from(widget.team.coaches);
    _players = List.from(widget.team.players);
  }

  Future<void> _removeMember(User user, String role) async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null) return;

    try {
      await sl<TeamRepository>().removeMemberFromTeam(
        token: token,
        teamId: widget.team.id,
        userId: user.id,
        role: role,
      );
      // Update local state on success
      setState(() {
        if (role == 'coach') _coaches.remove(user);
        if (role == 'player') _players.remove(user);
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addMember(User user) async {
    final token = context.read<AuthCubit>().state.token;
    if (token == null) return;

    // Determine role from the user object
    final role = user.role.toLowerCase();

    try {
      await sl<TeamRepository>().addMemberToTeam(
        token: token,
        teamId: widget.team.id,
        userId: user.id,
        role: role,
      );
      // Update local state on success
      setState(() {
        if (role == 'coach' && !_coaches.any((c) => c.id == user.id))
          _coaches.add(user);
        if (role == 'player' && !_players.any((p) => p.id == user.id))
          _players.add(user);
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _navigateToAddMember() async {
    final selectedUser = await Navigator.of(context).push<User>(
      MaterialPageRoute(
        // We no longer pass the teamId, as the backend handles filtering
        builder: (_) => const UserSearchScreen(),
      ),
    );

    if (selectedUser != null) {
      // The addMember logic will check the user's role and add them correctly.
      _addMember(selectedUser);
    }
  }

  void _navigateToAddPlayer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddPlayerScreen(teamId: widget.team.id),
      ),
    );

    // If the form returns true, we need to refresh the main detail screen
    // So we pop the roster screen as well to trigger the refresh there.
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Member',
            onPressed: _navigateToAddMember,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add New Player',
            onPressed: _navigateToAddPlayer, // Call the updated method
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Coaches', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          for (final coach in _coaches)
            ListTile(
              title: Text(coach.displayName),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _removeMember(coach, 'coach'),
              ),
            ),
          const SizedBox(height: 24),
          Text('Players', style: Theme.of(context).textTheme.headlineSmall),
          const Divider(),
          for (final player in _players)
            ListTile(
              title: Text(player.displayName),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _removeMember(player, 'player'),
              ),
            ),
        ],
      ),
    );
  }
}
