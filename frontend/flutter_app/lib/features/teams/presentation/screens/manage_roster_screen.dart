// lib/features/teams/presentation/screens/manage_roster_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/features/teams/presentation/screens/add_player_screen.dart';
import 'package:flutter_app/main.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import 'add_coach_screen.dart';

class ManageRosterScreen extends StatefulWidget {
  final Team team;
  const ManageRosterScreen({super.key, required this.team});

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  late List<User> _coaches;
  late List<User> _players;
  bool _isLoading = false;
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();

  @override
  void initState() {
    super.initState();
    _coaches = List.from(widget.team.coaches);
    _players = List.from(widget.team.players);
    _refreshSignal.addListener(_refreshLocalRoster);
  }

  @override
  void dispose() {
    _refreshSignal.removeListener(_refreshLocalRoster); // UNSUBSCRIBE
    super.dispose();
  }

  // Helper method to show a loading overlay
  void _setLoading(bool loading) => setState(() => _isLoading = loading);

  Future<void> _removeMember(User user, String role) async {
    _setLoading(true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      _setLoading(false);
      return;
    }

    try {
      await sl<TeamRepository>().removeMemberFromTeam(
        token: token,
        teamId: widget.team.id,
        userId: user.id,
        role: role,
      );
      setState(() {
        if (role == 'coach') _coaches.remove(user);
        if (role == 'player') _players.remove(user);
      });
      sl<RefreshSignal>().notify(); // Fire global refresh signal
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  void _navigateToAddPlayer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddPlayerScreen(teamId: widget.team.id),
      ),
    );

    if (result == true && mounted) {
      // The refresh signal from AddPlayerScreen will have already fired,
      // but we need to refresh THIS screen's local state.
      _refreshLocalRoster();
    }
  }

  void _navigateToAddCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddCoachScreen(teamId: widget.team.id)),
    );
  }

  // New method to refresh just this screen's data
  Future<void> _refreshLocalRoster() async {
    _setLoading(true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      _setLoading(false);
      return;
    }
    try {
      // Re-fetch the full team details to get the latest roster
      final updatedTeam = await sl<TeamRepository>().getTeamDetails(
        token: token,
        teamId: widget.team.id,
      );
      if (mounted) {
        setState(() {
          _coaches = updatedTeam.coaches;
          _players = updatedTeam.players;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing roster: $e')));
    } finally {
      if (mounted) _setLoading(false);
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
            tooltip: 'Add New Player',
            onPressed: _navigateToAddPlayer,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_moderator_outlined,
            ), // A different icon for coaches
            tooltip: 'Add New Coach',
            onPressed: _navigateToAddCoach,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
