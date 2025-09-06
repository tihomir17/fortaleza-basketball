// lib/features/teams/presentation/screens/select_existing_user_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/data/repositories/user_repository.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/team_repository.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart';

class SelectExistingUserScreen extends StatefulWidget {
  final int teamId;
  final String role; // 'player', 'coach', or 'staff'
  final String? staffType; // Required if role is 'staff'
  
  const SelectExistingUserScreen({
    super.key, 
    required this.teamId, 
    required this.role,
    this.staffType,
  });

  @override
  State<SelectExistingUserScreen> createState() => _SelectExistingUserScreenState();
}

class _SelectExistingUserScreenState extends State<SelectExistingUserScreen> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await sl<UserRepository>().searchUsers(
        token: token,
        query: query,
        role: widget.role.toUpperCase(),
      );
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addUserToTeam(User user) async {
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await sl<TeamRepository>().addMemberToTeam(
        token: token,
        teamId: widget.teamId,
        userId: user.id,
        role: widget.role,
        staffType: user.staffType, // Pass the user's existing staffType
      );
      
      if (mounted) {
        sl<RefreshSignal>().notify();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} added to team successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding user: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Existing ${widget.role.toUpperCase()}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for ${widget.role}s...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Start typing to search for ${widget.role}s'
                                  : 'No ${widget.role}s found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                                child: Icon(
                                  widget.role == 'player' 
                                      ? Icons.sports_basketball
                                      : widget.role == 'coach'
                                          ? Icons.sports
                                          : Icons.work,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('@${user.username}'),
                                  if (user.role == 'COACH' && user.coachType != null)
                                    Text('Coach Type: ${user.coachType}'),
                                  if (user.role == 'STAFF' && user.staffType != null)
                                    Text('Staff Type: ${user.staffType}'),
                                  if (user.role == 'PLAYER' && user.jerseyNumber != null)
                                    Text('Jersey #${user.jerseyNumber}'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: _isLoading ? null : () => _addUserToTeam(user),
                                child: const Text('Add'),
                              ),
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
