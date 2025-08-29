// lib/features/authentication/presentation/screens/edit_user_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/core/navigation/refresh_signal.dart';
import 'package:flutter_app/main.dart';
import '../cubit/auth_cubit.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class EditUserScreen extends StatefulWidget {
  final User user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _numberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    logger.d('EditUserScreen: initState for user: ${widget.user.username}');
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _numberController = TextEditingController(
      text: widget.user.jerseyNumber?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    super.dispose();
    logger.d('EditUserScreen: dispose called.');
  }

  Future<void> _submitForm() async {
    logger.d('EditUserScreen: Submit form called.');
    if (!_formKey.currentState!.validate()) {
      logger.w('EditUserScreen: Form validation failed.');
      return;
    }
    setState(() => _isLoading = true);
    final token = context.read<AuthCubit>().state.token;
    if (token == null) {
      // Handle error: show snackbar, set loading to false
      setState(() => _isLoading = false);
      logger.e('EditUserScreen: Authentication token is null during form submission.');
      return;
    }

    try {
      logger.i('EditUserScreen: Attempting to update user ${widget.user.id}.');
      await sl<UserRepository>().updateUser(
        token: token,
        userId: widget.user.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        jerseyNumber: int.tryParse(_numberController.text),
      );
      if (mounted) {
        sl<RefreshSignal>().notify(); // Fire global refresh
        Navigator.of(context).pop(); // Pop this screen
        logger.i('EditUserScreen: User ${widget.user.id} updated successfully.');
      }
    } catch (e) {
      logger.e('EditUserScreen: Error updating user ${widget.user.id}: $e');
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
      appBar: AppBar(title: Text('Edit ${widget.user.displayName}')),
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
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Jersey Number',
                counterText: "", // Hide the default counter
              ),
              keyboardType: TextInputType.number,
              maxLength: 2, // Limit to 2 digits
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Empty is allowed
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Invalid number';
                }
                if (number < 0 || number > 99) {
                  return 'Enter a number 0-99';
                }
                return null;
              },
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
