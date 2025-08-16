// lib/features/plays/presentation/screens/create_play_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/teams/data/models/team_model.dart';
import '../cubit/create_play_cubit.dart';
import '../cubit/create_play_state.dart';

class CreatePlayScreen extends StatefulWidget {
  final Team team;
  const CreatePlayScreen({super.key, required this.team});

  @override
  State<CreatePlayScreen> createState() => _CreatePlayScreenState();
}

class _CreatePlayScreenState extends State<CreatePlayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 'OFFENSIVE' or 'DEFENSIVE'
  String _selectedPlayType = 'OFFENSIVE';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    // Validate the form before submitting
    if (_formKey.currentState!.validate()) {
      // Access the cubit from the context and call the submit method
      context.read<CreatePlayCubit>().submitPlay(
            // We'll get the token from the AuthCubit in the final step
            token: '', // Placeholder for now
            name: _nameController.text,
            description: _descriptionController.text,
            playType: _selectedPlayType,
            teamId: widget.team.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Play for ${widget.team.name}'),
      ),
      body: BlocListener<CreatePlayCubit, CreatePlayState>(
        listener: (context, state) {
          if (state.status == CreatePlayStatus.success) {
            // Show a success message and pop the screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Play created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Pop with a 'true' result to indicate success
          }
          if (state.status == CreatePlayStatus.failure) {
            // Show an error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An unknown error occurred.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Play Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Play Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for the play.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Play Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedPlayType,
                  decoration: const InputDecoration(labelText: 'Play Type'),
                  items: const [
                    DropdownMenuItem(value: 'OFFENSIVE', child: Text('Offensive')),
                    DropdownMenuItem(value: 'DEFENSIVE', child: Text('Defensive')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPlayType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                // Submit Button
                ElevatedButton(
                  onPressed: () => _submitForm(context),
                  child: BlocBuilder<CreatePlayCubit, CreatePlayState>(
                    builder: (context, state) {
                      // Show a loading indicator on the button when submitting
                      if (state.status == CreatePlayStatus.loading) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }
                      return const Text('Create Play');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}