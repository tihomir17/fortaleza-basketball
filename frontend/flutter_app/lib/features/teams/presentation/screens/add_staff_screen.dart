// lib/features/teams/presentation/screens/add_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/team_repository.dart';

class AddStaffScreen extends StatefulWidget {
  final int teamId;
  const AddStaffScreen({super.key, required this.teamId});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedStaffType = 'PHYSIO';
  bool _isLoading = false;

  final List<Map<String, String>> _staffTypes = [
    {'value': 'PHYSIO', 'label': 'Physiotherapist'},
    {'value': 'STRENGTH_CONDITIONING', 'label': 'Strength & Conditioning'},
    {'value': 'MANAGEMENT', 'label': 'Management'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await sl<TeamRepository>().createAndAddStaff(
        token: token,
        teamId: widget.teamId,
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text.isNotEmpty ? _firstNameController.text : null,
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        staffType: _selectedStaffType,
      );
      if (mounted) {
        sl<RefreshSignal>().notify();
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
      appBar: AppBar(
        title: const Text('Add Staff Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStaffType,
                decoration: const InputDecoration(
                  labelText: 'Staff Type',
                  border: OutlineInputBorder(),
                ),
                items: _staffTypes.map((staffType) {
                  return DropdownMenuItem<String>(
                    value: staffType['value'],
                    child: Text(staffType['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStaffType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Staff Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
