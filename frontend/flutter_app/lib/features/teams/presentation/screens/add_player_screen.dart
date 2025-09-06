// lib/features/teams/presentation/screens/add_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fortaleza_basketball_analytics/main.dart';
import 'package:fortaleza_basketball_analytics/core/navigation/refresh_signal.dart'; // Import the signal
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/team_repository.dart';

class AddPlayerScreen extends StatefulWidget {
  final int teamId;
  const AddPlayerScreen({super.key, required this.teamId});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _numberController =
      TextEditingController(); // Controller for the number
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      // Handle error
      setState(() => _isLoading = false);
      return;
    }

    try {
      await sl<TeamRepository>().createAndAddPlayer(
        token: token,
        teamId: widget.teamId,
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        jerseyNumber: int.tryParse(_numberController.text),
      );
      if (mounted) {
        sl<RefreshSignal>().notify(); // Fire the global refresh signal
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
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
      appBar: AppBar(title: const Text('Add New Player')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username *'),
              validator: (v) => v!.isEmpty ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty || !v.contains('@')
                  ? 'A valid email is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name (Optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name (Optional)',
              ),
            ),
            const SizedBox(height: 16),

            // --- THIS IS THE JERSEY NUMBER FIELD ---
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Jersey Number (Optional)',
              ),
              keyboardType: TextInputType.number,
              // Only allow up to 2 digits
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              // Add validation logic
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // It's optional, so empty is fine
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Invalid number';
                }
                // Note: MaxLength already prevents numbers > 99
                // This validator is here as an extra safeguard.
                if (number < 0 || number > 99) {
                  return 'Enter a number 0-99';
                }
                return null; // Input is valid
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Create and Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}
