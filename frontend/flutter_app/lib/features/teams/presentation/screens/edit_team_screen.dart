// lib/features/teams/presentation/screens/edit_team_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart'; // For Service Locator (sl)
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import 'manage_roster_screen.dart';

class EditTeamScreen extends StatefulWidget {
  final Team team;
  const EditTeamScreen({super.key, required this.team});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Authentication Error.')));
        setState(() => _isLoading = false);
        return;
      }

      try {
        await sl<TeamRepository>().updateTeam(
          token: token,
          teamId: widget.team.id,
          newName: _nameController.text,
        );

        if (!mounted) return;
        Navigator.of(
          context,
        ).pop(true); // Pop with 'true' to signal a refresh is needed
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Team')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Manage Roster'),
              onPressed: () async {
                // Navigate to the roster screen and wait for it to pop
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ManageRosterScreen(team: widget.team),
                  ),
                );
                // When we return, we pop this screen with 'true' to signal that
                // the main detail screen should refresh its data.
                if (mounted) {
                  sl<RefreshSignal>().notify();
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
