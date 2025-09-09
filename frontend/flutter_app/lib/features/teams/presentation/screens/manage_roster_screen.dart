// lib/features/teams/presentation/screens/manage_roster_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';
import 'package:fortaleza_basketball_analytics/features/teams/presentation/screens/add_player_screen.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/widgets/reset_password_dialog.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import 'add_coach_screen.dart';
import 'add_staff_screen.dart';
import 'select_existing_user_screen.dart';

class ManageRosterScreen extends StatefulWidget {
  final Team team;
  const ManageRosterScreen({super.key, required this.team});

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  late List<User> _coaches;
  late List<User> _players;
  late List<User> _staff;
  bool _isLoading = false;
  final RefreshSignal _refreshSignal = sl<RefreshSignal>();
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    // Sort coaches so HEAD_COACH appears first, then ASSISTANT_COACH
    _coaches = widget.team.coaches
        .where((user) => user.role == 'COACH')
        .toList()
      ..sort((a, b) {
        // HEAD_COACH comes first, then ASSISTANT_COACH
        if (a.coachType == 'HEAD_COACH' && b.coachType != 'HEAD_COACH') return -1;
        if (a.coachType != 'HEAD_COACH' && b.coachType == 'HEAD_COACH') return 1;
        return 0; // Keep original order for same coach types
      });
    _players = List.from(widget.team.players);
    _staff = List.from(widget.team.staff);
    _refreshSubscription = _refreshSignal.stream.listen((_) => _refreshLocalRoster());
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
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
        if (role == 'staff') _staff.remove(user);
      });
      sl<RefreshSignal>().notify(); // Fire global refresh signal
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

  void _navigateToAddStaff() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddStaffScreen(teamId: widget.team.id)),
    );
  }

  void _navigateToSelectExistingPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectExistingUserScreen(
          teamId: widget.team.id,
          role: 'player',
        ),
      ),
    );
  }

  void _navigateToSelectExistingCoach() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectExistingUserScreen(
          teamId: widget.team.id,
          role: 'coach',
        ),
      ),
    );
  }

  void _navigateToSelectExistingStaff() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectExistingUserScreen(
          teamId: widget.team.id,
          role: 'staff',
        ),
      ),
    );
  }

  String _getStaffTypeLabel(String? staffType) {
    switch (staffType) {
      case 'PHYSIO':
        return 'Physiotherapist';
      case 'STRENGTH_CONDITIONING':
        return 'Strength & Conditioning';
      case 'MANAGEMENT':
        return 'Management';
      default:
        return 'Staff';
    }
  }

  bool _canResetPassword(User user) {
    final currentUser = context.read<AuthCubit>().state.user;
    if (currentUser == null) return false;
    
    // Superuser can reset anyone's password
    if (currentUser.role == 'ADMIN') return true;
    
    // Coach can reset player and staff passwords
    if (currentUser.role == 'COACH' && 
        (user.role == 'PLAYER' || user.role == 'STAFF')) {
      return true;
    }
    
    return false;
  }

  void _showResetPasswordDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => ResetPasswordDialog(
        userId: user.id,
        username: user.username,
      ),
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
          // Sort coaches so HEAD_COACH appears first, then ASSISTANT_COACH
          _coaches = updatedTeam.coaches
              .where((user) => user.role == 'COACH')
              .toList()
            ..sort((a, b) {
              // HEAD_COACH comes first, then ASSISTANT_COACH
              if (a.coachType == 'HEAD_COACH' && b.coachType != 'HEAD_COACH') return -1;
              if (a.coachType != 'HEAD_COACH' && b.coachType == 'HEAD_COACH') return 1;
              return 0; // Keep original order for same coach types
            });
          _players = updatedTeam.players;
          _staff = updatedTeam.staff;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing roster: $e')));
      }
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Members',
            onSelected: (value) {
              switch (value) {
                case 'new_player':
                  _navigateToAddPlayer();
                  break;
                case 'existing_player':
                  _navigateToSelectExistingPlayer();
                  break;
                case 'new_coach':
                  _navigateToAddCoach();
                  break;
                case 'existing_coach':
                  _navigateToSelectExistingCoach();
                  break;
                case 'new_staff':
                  _navigateToAddStaff();
                  break;
                case 'existing_staff':
                  _navigateToSelectExistingStaff();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'new_player',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add New Player'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'existing_player',
                child: ListTile(
                  leading: Icon(Icons.person_search),
                  title: Text('Select Existing Player'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'new_coach',
                child: ListTile(
                  leading: Icon(Icons.add_moderator_outlined),
                  title: Text('Add New Coach'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'existing_coach',
                child: ListTile(
                  leading: Icon(Icons.person_search),
                  title: Text('Select Existing Coach'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'new_staff',
                child: ListTile(
                  leading: Icon(Icons.medical_services_outlined),
                  title: Text('Add New Staff'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'existing_staff',
                child: ListTile(
                  leading: Icon(Icons.person_search),
                  title: Text('Select Existing Staff'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canResetPassword(coach))
                        IconButton(
                          icon: const Icon(
                            Icons.lock_reset,
                            color: Colors.orange,
                          ),
                          onPressed: () => _showResetPasswordDialog(coach),
                          tooltip: 'Reset Password',
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeMember(coach, 'coach'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text('Staff', style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              for (final staff in _staff)
                ListTile(
                  title: Text(staff.displayName),
                  subtitle: Text(_getStaffTypeLabel(staff.staffType)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canResetPassword(staff))
                        IconButton(
                          icon: const Icon(
                            Icons.lock_reset,
                            color: Colors.orange,
                          ),
                          onPressed: () => _showResetPasswordDialog(staff),
                          tooltip: 'Reset Password',
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeMember(staff, 'staff'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text('Players', style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              for (final player in _players)
                ListTile(
                  title: Text(player.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canResetPassword(player))
                        IconButton(
                          icon: const Icon(
                            Icons.lock_reset,
                            color: Colors.orange,
                          ),
                          onPressed: () => _showResetPasswordDialog(player),
                          tooltip: 'Reset Password',
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeMember(player, 'player'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
