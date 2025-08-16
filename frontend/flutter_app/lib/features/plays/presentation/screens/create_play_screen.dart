// lib/features/plays/presentation/screens/create_play_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../main.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/play_repository.dart';

class CreatePlayScreen extends StatefulWidget {
  final int teamId; // The constructor ONLY requires teamId.

  const CreatePlayScreen({super.key, required this.teamId});

  @override
  State<CreatePlayScreen> createState() => _CreatePlayScreenState();
}

class _CreatePlayScreenState extends State<CreatePlayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPlayType = 'OFFENSIVE';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final token = context.read<AuthCubit>().state.token;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please log in again.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        await sl<PlayRepository>().createPlay(
          token: token,
          name: _nameController.text,
          description: _descriptionController.text,
          playType: _selectedPlayType,
          teamId: widget.teamId,
        );

        if (!mounted) return;
        Navigator.of(context).pop(true); // Pop with 'true' to signal refresh
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Play')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Play Name'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlayType,
              items: const [
                DropdownMenuItem(value: 'OFFENSIVE', child: Text('Offensive')),
                DropdownMenuItem(value: 'DEFENSIVE', child: Text('Defensive')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedPlayType = value);
              },
              decoration: const InputDecoration(labelText: 'Play Type'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Save Play'),
            ),
          ],
        ),
      ),
    );
  }
}
