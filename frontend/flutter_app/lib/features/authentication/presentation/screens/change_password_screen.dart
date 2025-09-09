import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../cubit/password_change_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../../data/repositories/password_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authCubit = context.read<AuthCubit>();
        final token = authCubit.state.token;
        if (token == null) {
          throw Exception('User not authenticated');
        }
        return PasswordChangeCubit(
          PasswordRepository(http.Client()),
          token,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: BlocListener<PasswordChangeCubit, PasswordChangeState>(
          listener: (context, state) {
            if (state is PasswordChangeSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else if (state is PasswordChangeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Change Your Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Old Password Field
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: _obscureOldPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureOldPassword = !_obscureOldPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters long';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Change Password Button
                  BlocBuilder<PasswordChangeCubit, PasswordChangeState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is PasswordChangeLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<PasswordChangeCubit>().changePassword(
                                    oldPassword: _oldPasswordController.text,
                                    newPassword: _newPasswordController.text,
                                    confirmPassword: _confirmPasswordController.text,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: state is PasswordChangeLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Change Password',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Requirements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• At least 8 characters long\n• Must be different from your current password',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
