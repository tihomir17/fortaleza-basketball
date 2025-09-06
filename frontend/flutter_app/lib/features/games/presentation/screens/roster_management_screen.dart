// lib/features/games/presentation/screens/roster_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/teams/data/models/team_model.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/data/models/user_model.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/models/game_model.dart';
import 'package:fortaleza_basketball_analytics/features/games/data/repositories/game_repository.dart';

class RosterManagementScreen extends StatefulWidget {
  final Game game;
  final Team team;
  
  const RosterManagementScreen({
    super.key,
    required this.game,
    required this.team,
  });

  @override
  State<RosterManagementScreen> createState() => _RosterManagementScreenState();
}

class _RosterManagementScreenState extends State<RosterManagementScreen> {
  List<User> _selectedPlayers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with empty selection - user must pick 10-12 players
    _selectedPlayers = [];
  }

  void _togglePlayer(User player) {
    setState(() {
      if (_selectedPlayers.contains(player)) {
        _selectedPlayers.remove(player);
      } else {
        if (_selectedPlayers.length < 12) {
          _selectedPlayers.add(player);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 12 players allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _saveRoster() async {
    print('DEBUG: _saveRoster - starting with ${_selectedPlayers.length} players');
    if (_selectedPlayers.length < 10) {
      print('DEBUG: _saveRoster - not enough players selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 10 players required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      print('DEBUG: _saveRoster - no token available');
      setState(() => _isLoading = false);
      return;
    }

    print('DEBUG: _saveRoster - calling createGameRoster API');
    try {
      await sl<GameRepository>().createGameRoster(
        token: token,
        gameId: widget.game.id,
        teamId: widget.team.id,
        playerIds: _selectedPlayers.map((p) => p.id).toList(),
      );

      print('DEBUG: _saveRoster - API call successful');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roster saved for ${widget.team.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('DEBUG: _saveRoster - API call failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving roster: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} Roster'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRoster,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with selection info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Players for Game Roster',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: ${_selectedPlayers.length}/12 players (minimum 10)',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_selectedPlayers.length < 10)
                  Text(
                    '⚠️ Need at least 10 players',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Players list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.team.players.length,
              itemBuilder: (context, index) {
                final player = widget.team.players[index];
                final isSelected = _selectedPlayers.contains(player);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      child: Text(
                        player.jerseyNumber?.toString() ?? '?',
                        style: TextStyle(
                          color: isSelected 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('${player.firstName} ${player.lastName}'),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () => _togglePlayer(player),
                    selected: isSelected,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
