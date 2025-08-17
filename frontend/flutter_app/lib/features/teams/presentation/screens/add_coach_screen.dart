// lib/features/teams/presentation/screens/add_coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/team_repository.dart';

class AddCoachScreen extends StatefulWidget {
  final int teamId;
  const AddCoachScreen({super.key, required this.teamId});

  @override
  State<AddCoachScreen> createState() => _AddCoachScreenState();
}

class _AddCoachScreenState extends State<AddCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedCoachType = 'ASSISTANT_COACH';
  bool _isLoading = false;

  @override
  void dispose() {
    // ... dispose all controllers
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) { /* ... handle error ... */ return; }

    try {
      await sl<TeamRepository>().createAndAddCoach(
        token: token,
        teamId: widget.teamId,
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        coachType: _selectedCoachType,
      );
      if (mounted) {
        sl<RefreshSignal>().notify();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Coach')),
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
              validator: (v) => v!.isEmpty || !v.contains('@') ? 'A valid email is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name (Optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name (Optional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCoachType,
              items: const [
                DropdownMenuItem(value: 'HEAD_COACH', child: Text('Head Coach')),
                DropdownMenuItem(value: 'ASSISTANT_COACH', child: Text('Assistant Coach')),
                DropdownMenuItem(value: 'SCOUTING_COACH', child: Text('Scouting Coach')),
                DropdownMenuItem(value: 'ANALYTIC_COACH', child: Text('Analytic Coach')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedCoachType = value);
              },
              decoration: const InputDecoration(labelText: 'Coach Type'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Create and Add Coach'),
            ),
          ],
        ),
      ),
    );
  }
}