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
        
        // Determine the appropriate tooltip message based on device type - match JavaScript logic
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenWidth <= 768 || screenHeight <= 600; // Conservative mobile detection to match JS
        final tooltipMessage = isMobile 
            ? 'Open menu' 
            : (sidebarVisible ? 'Hide sidebar' : 'Show sidebar');
        
        Widget button = Tooltip(
          message: tooltipMessage,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              border: isMobile ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ) : null, // Add border on mobile for visibility
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
                // Check if we're on a mobile device (narrow screen) - match JavaScript logic
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final isMobile = screenWidth <= 1200 || screenHeight <= 700;
                
                logger.d('SidebarToggleButton: Screen width: $screenWidth, height: $screenHeight, isMobile: $isMobile');
                
                if (isMobile) {
                  // On mobile, open the drawer instead of toggling sidebar state
                  logger.d('SidebarToggleButton: Attempting to open drawer on mobile');
                  
                  try {
                    // Try multiple approaches to find and open the drawer
                    final scaffoldState = Scaffold.maybeOf(context);
                    logger.d('SidebarToggleButton: Scaffold.maybeOf result: $scaffoldState');
                    
                    if (scaffoldState != null) {
                      logger.d('SidebarToggleButton: Found scaffold, attempting to open drawer');
                      scaffoldState.openDrawer();
                      logger.i('SidebarToggleButton: Successfully opened drawer via Scaffold.maybeOf');
                    } else {
                      logger.w('SidebarToggleButton: Scaffold.maybeOf returned null, trying Scaffold.of');
                      // Try alternative approach
                      final scaffoldState2 = Scaffold.of(context);
                      scaffoldState2.openDrawer();
                      logger.i('SidebarToggleButton: Successfully opened drawer via Scaffold.of');
                    }
                  } catch (e) {
                    logger.e('SidebarToggleButton: Failed to open drawer: $e');
                    logger.e('SidebarToggleButton: Error type: ${e.runtimeType}');
                    logger.e('SidebarToggleButton: Stack trace: ${StackTrace.current}');
                    
                    // Try a different approach - use a global key or context
                    try {
                      logger.d('SidebarToggleButton: Trying alternative drawer opening method');
                      // Force a rebuild to ensure context is fresh
                      if (context.mounted) {
                        // Try to find the drawer using a different method
                        final navigator = Navigator.of(context);
                        logger.d('SidebarToggleButton: Found navigator: $navigator');
                      }
                    } catch (e2) {
                      logger.e('SidebarToggleButton: Alternative method also failed: $e2');
                    }
                    
                    // Final fallback: try to toggle sidebar state
                    logger.d('SidebarToggleButton: Using fallback - toggling sidebar state');
                    isSidebarVisible.value = !isSidebarVisible.value;
                  }
                } else {
                  // On desktop/tablet, toggle the sidebar state
                  isSidebarVisible.value = !isSidebarVisible.value;
                  logger.i('SidebarToggleButton: Toggled sidebar visibility to ${isSidebarVisible.value}');
                }
              },
                borderRadius: BorderRadius.circular(buttonSize / 2),
                splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: Container(
                  padding: padding ?? EdgeInsets.all(buttonSize * 0.2),
                  child: Icon(
                    isMobile 
                        ? Icons.menu_rounded  // Always show menu icon on mobile
                        : (sidebarVisible
                            ? Icons.menu_open_rounded
                            : Icons.menu_rounded),
                    size: iconSize,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                  ),
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
      size: 44, // Larger for better mobile touch target
      padding: EdgeInsets.all(10),
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