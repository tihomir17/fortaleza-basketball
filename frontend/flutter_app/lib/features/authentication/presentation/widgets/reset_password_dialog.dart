import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../cubit/password_change_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../../data/repositories/password_repository.dart';

class ResetPasswordDialog extends StatefulWidget {
  final int userId;
  final String username;

  const ResetPasswordDialog({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
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
      child: BlocListener<PasswordChangeCubit, PasswordChangeState>(
        listener: (context, state) {
          if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Password reset successfully! New password: ${state.newPassword}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
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
        child: AlertDialog(
          title: Text('Reset Password for ${widget.username}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
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
                const Text(
                  'This will reset the password for this user. They will need to use this new password to log in.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            BlocBuilder<PasswordChangeCubit, PasswordChangeState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state is PasswordChangeLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<PasswordChangeCubit>().resetPassword(
                              userId: widget.userId,
                              newPassword: _passwordController.text,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: state is PasswordChangeLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Reset Password'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
