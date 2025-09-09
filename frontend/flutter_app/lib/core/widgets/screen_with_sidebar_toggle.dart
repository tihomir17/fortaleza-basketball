// lib/core/widgets/screen_with_sidebar_toggle.dart

import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';

/// A wrapper widget that adds a floating sidebar toggle button to any screen
/// Use this for screens that don't use UserProfileAppBar but still need sidebar toggle functionality
class ScreenWithSidebarToggle extends StatelessWidget {
  final Widget child;
  final bool showFloatingButton;
  final EdgeInsetsGeometry? floatingButtonMargin;
  final double? floatingButtonSize;

  const ScreenWithSidebarToggle({
    super.key,
    required this.child,
    this.showFloatingButton = true,
    this.floatingButtonMargin,
    this.floatingButtonSize,
  });

  @override
  Widget build(BuildContext context) {
    if (!showFloatingButton) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          left: 20,
          top: 20,
          child: SidebarToggleButton(
            showAsFloatingButton: true,
            size: floatingButtonSize ?? 56,
            margin: floatingButtonMargin,
            elevation: 4,
          ),
        ),
      ],
    );
  }
}

/// A Scaffold wrapper that includes sidebar toggle functionality
/// Use this for screens that need their own Scaffold but want sidebar toggle
class ScaffoldWithSidebarToggle extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showSidebarToggle;
  final EdgeInsetsGeometry? sidebarToggleMargin;

  const ScaffoldWithSidebarToggle({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showSidebarToggle = true,
    this.sidebarToggleMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: showSidebarToggle
          ? ScreenWithSidebarToggle(
              floatingButtonMargin: sidebarToggleMargin,
              child: body,
            )
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
