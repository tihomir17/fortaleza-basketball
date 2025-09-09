// lib/core/widgets/user_profile_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:fortaleza_basketball_analytics/features/authentication/presentation/cubit/auth_state.dart';
import 'package:fortaleza_basketball_analytics/main.dart'; // Import for global logger
import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';

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
    logger.d('UserProfileAppBar: Building app bar with title: $title');
    // These are the default action buttons that will appear on the far right.
    final List<Widget> defaultActions = [
      // IconButton(
      //   icon: const Icon(Icons.brightness_6_outlined),
      //   tooltip: 'Toggle Theme',
      //   onPressed: () => context.read<ThemeCubit>().toggleTheme(),
      // ),
      BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            final user = state.user!;
            return PopupMenuButton<String>(
              onSelected: (value) {
                logger.d('UserProfileAppBar: User selected $value from menu.');
                if (value == 'logout') {
                  context.read<AuthCubit>().logout();
                  logger.i('UserProfileAppBar: Initiating logout.');
                } else if (value == 'change_password') {
                  // Add a small delay to ensure popup menu is closed before navigation
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      context.push('/change-password');
                      logger.i('UserProfileAppBar: Navigating to change password screen.');
                    }
                  });
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
                  value: 'change_password',
                  child: ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('Change Password'),
                  ),
                ),
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
            onPressed: () {
              logger.i('UserProfileAppBar: Initiating logout via button.');
              context.read<AuthCubit>().logout();
            },
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

    return AppBar(
      // Only show sidebar toggle for desktop, no button for mobile (positioned button handles mobile)
      leading: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= 1024;
          if (isMobile) {
            return const SizedBox.shrink(); // No button on mobile - positioned button handles it
          } else {
            return const SidebarToggleAppBarButton();
          }
        },
      ),
      automaticallyImplyLeading:
          false, // We handle the leading widget manually
      title: Text(title.toUpperCase()),
      actions: allActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
