// lib/features/teams/presentation/screens/add_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/main.dart';
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
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      /* handle error */
      return;
    }

    try {
      final newUser = await sl<TeamRepository>().createAndAddPlayer(
        token: token,
        teamId: widget.teamId,
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (mounted)
        Navigator.of(context).pop(true); // Pop with 'true' to signal refresh
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create and Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}
