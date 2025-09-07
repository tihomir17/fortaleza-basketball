// lib/core/widgets/sidebar_toggle_button.dart

import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class SidebarToggleButton extends StatelessWidget {
  final bool showAsFloatingButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? elevation;

  const SidebarToggleButton({
    super.key,
    this.showAsFloatingButton = false,
    this.margin,
    this.padding,
    this.size,
    this.backgroundColor,
    this.iconColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSidebarVisible,
      builder: (context, sidebarVisible, _) {
        final buttonSize = size ?? (showAsFloatingButton ? 56.0 : 40.0);
        final iconSize = buttonSize * 0.4;
        
        Widget button = Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            boxShadow: elevation != null ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation!,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                isSidebarVisible.value = !isSidebarVisible.value;
                logger.i('SidebarToggleButton: Toggled sidebar visibility to ${isSidebarVisible.value}');
              },
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Container(
                padding: padding ?? EdgeInsets.all(buttonSize * 0.2),
                child: Icon(
                  sidebarVisible
                      ? Icons.menu_open
                      : Icons.menu,
                  size: iconSize,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );

        if (showAsFloatingButton) {
          return Positioned(
            left: sidebarVisible ? 260 : 20,
            top: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: margin,
              child: button,
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: margin,
          child: button,
        );
      },
    );
  }
}

// Convenience widget for AppBar actions
class SidebarToggleAppBarButton extends StatelessWidget {
  const SidebarToggleAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SidebarToggleButton(
      size: 36,
      padding: EdgeInsets.all(8),
    );
  }
}

// Convenience widget for floating action button
class SidebarToggleFloatingButton extends StatelessWidget {
  const SidebarToggleFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SidebarToggleButton(
      showAsFloatingButton: true,
      size: 56,
      elevation: 4,
    );
  }
}
