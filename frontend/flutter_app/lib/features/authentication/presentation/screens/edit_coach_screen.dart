// lib/features/authentication/presentation/screens/edit_coach_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import '../cubit/auth_cubit.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart'; // We'll update this next

class EditCoachScreen extends StatefulWidget {
  final User coach;
  const EditCoachScreen({super.key, required this.coach});

  @override
  State<EditCoachScreen> createState() => _EditCoachScreenState();
}

class _EditCoachScreenState extends State<EditCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late String _selectedCoachType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    logger.d('EditCoachScreen: initState for coach: ${widget.coach.username}');
    _firstNameController = TextEditingController(text: widget.coach.firstName);
    _lastNameController = TextEditingController(text: widget.coach.lastName);
    _selectedCoachType = widget.coach.coachType ?? 'ASSISTANT_COACH';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
    logger.d('EditCoachScreen: dispose called.');
  }

  Future<void> _submitForm() async {
    logger.d('EditCoachScreen: Submit form called.');
    if (!_formKey.currentState!.validate()) {
      logger.w('EditCoachScreen: Form validation failed.');
      return;
    }
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      /* handle error */
      setState(() => _isLoading = false);
      logger.e('EditCoachScreen: Authentication token is null during form submission.');
      return;
    }

    try {
      // We will create this repository method next
      logger.i('EditCoachScreen: Attempting to update coach ${widget.coach.id}.');
      await sl<UserRepository>().updateCoach(
        token: token,
        userId: widget.coach.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        coachType: _selectedCoachType,
      );
      if (mounted) {
        sl<RefreshSignal>().notify();
        Navigator.of(context).pop();
        logger.i('EditCoachScreen: Coach ${widget.coach.id} updated successfully.');
      }
    } catch (e) {
      logger.e('EditCoachScreen: Error updating coach ${widget.coach.id}: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.coach.displayName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCoachType,
              items: const [
                DropdownMenuItem(
                  value: 'HEAD_COACH',
                  child: Text('Head Coach'),
                ),
                DropdownMenuItem(
                  value: 'ASSISTANT_COACH',
                  child: Text('Assistant Coach'),
                ),
                DropdownMenuItem(
                  value: 'SCOUTING_COACH',
                  child: Text('Scouting Coach'),
                ),
                DropdownMenuItem(
                  value: 'ANALYTIC_COACH',
                  child: Text('Analytic Coach'),
                ),
              ],
              onChanged: (value) {
                logger.d('EditCoachScreen: Coach type changed to $value.');
                if (value != null) setState(() => _selectedCoachType = value);
              },
              decoration: const InputDecoration(labelText: 'Coach Type'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
