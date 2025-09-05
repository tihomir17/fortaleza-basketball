// lib/features/games/presentation/screens/starting_five_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import 'package:flutter_app/features/authentication/data/models/user_model.dart';
import 'package:flutter_app/features/games/data/models/game_model.dart';
import 'package:flutter_app/features/games/data/repositories/game_repository.dart';

class StartingFiveScreen extends StatefulWidget {
  final Game game;
  final Team team;
  final List<User> rosterPlayers; // The 10-12 players selected for the game
  
  const StartingFiveScreen({
    super.key,
    required this.game,
    required this.team,
    required this.rosterPlayers,
  });

  @override
  State<StartingFiveScreen> createState() => _StartingFiveScreenState();
}

class _StartingFiveScreenState extends State<StartingFiveScreen> {
  List<User> _startingFive = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with first 5 players if available
    if (widget.rosterPlayers.length >= 5) {
      _startingFive = List.from(widget.rosterPlayers.take(5));
    }
  }

  void _togglePlayer(User player) {
    setState(() {
      if (_startingFive.contains(player)) {
        _startingFive.remove(player);
      } else {
        if (_startingFive.length < 5) {
          _startingFive.add(player);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exactly 5 players required for starting five'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _saveStartingFive() async {
    if (_startingFive.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exactly 5 players required for starting five'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await sl<GameRepository>().updateStartingFive(
        token: token,
        gameId: widget.game.id,
        teamId: widget.team.id,
        startingFiveIds: _startingFive.map((p) => p.id).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting five saved for ${widget.team.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving starting five: $e'),
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
        title: Text('${widget.team.name} Starting Five'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStartingFive,
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
                  'Select Starting Five',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: ${_startingFive.length}/5 players',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_startingFive.length != 5)
                  Text(
                    '⚠️ Exactly 5 players required',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          // Starting five display
          if (_startingFive.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starting Five:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _startingFive.map((player) => Chip(
                      label: Text(
                        '${player.jerseyNumber ?? '?'} ${player.displayName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => _togglePlayer(player),
                    )).toList(),
                  ),
                ],
              ),
            ),
          
          // Available players list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.rosterPlayers.length,
              itemBuilder: (context, index) {
                final player = widget.rosterPlayers[index];
                final isSelected = _startingFive.contains(player);
                final canSelect = !isSelected && _startingFive.length < 5;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? theme.colorScheme.primary
                          : canSelect
                              ? theme.colorScheme.surfaceVariant
                              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
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
                        color: canSelect ? null : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    subtitle: Text(
                      '${player.firstName} ${player.lastName}',
                      style: TextStyle(
                        color: canSelect ? null : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            color: canSelect 
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                    onTap: canSelect || isSelected ? () => _togglePlayer(player) : null,
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
