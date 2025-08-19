// lib/core/widgets/user_profile_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:flutter_app/features/authentication/presentation/cubit/auth_state.dart';
import 'package:flutter_app/core/theme/theme_cubit.dart';

class UserProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const UserProfileAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title.toUpperCase()),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6_outlined),
          tooltip: 'Toggle Theme',
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.authenticated &&
                state.user != null) {
              final user = state.user!;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    context.read<AuthCubit>().logout();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false, // Make it not tappable
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
                // Use a CircleAvatar as the button
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(
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
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
