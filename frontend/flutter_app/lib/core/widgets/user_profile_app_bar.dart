// lib/core/widgets/user_profile_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';
import 'package:flutter_app/core/theme/theme_cubit.dart';

class UserProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onRefresh; // Optional refresh callback

  const UserProfileAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // These are the default action buttons that will appear on the far right.
    final List<Widget> defaultActions = [
      IconButton(
        icon: const Icon(Icons.brightness_6_outlined),
        tooltip: 'Toggle Theme',
        onPressed: () => context.read<ThemeCubit>().toggleTheme(),
      ),
      BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            final user = state.user!;
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthCubit>().logout();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 16,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
              ),
            );
          }
          return IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          );
        },
      ),
    ];

    // Build the final list of actions for the AppBar
    final List<Widget> allActions = [];

    // If an onRefresh callback was provided, add the refresh button first.
    if (onRefresh != null) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
          onPressed: onRefresh,
        ),
      );
    }
    // Add any other custom actions passed from the screen
    allActions.addAll(actions ?? []);
    // Add the default actions at the very end
    allActions.addAll(defaultActions);

    return AppBar(title: Text(title.toUpperCase()), actions: allActions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
