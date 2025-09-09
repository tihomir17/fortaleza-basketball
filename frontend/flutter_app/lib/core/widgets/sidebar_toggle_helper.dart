// lib/core/widgets/sidebar_toggle_helper.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';

/// Helper class to easily add sidebar toggle functionality to any screen
class SidebarToggleHelper {
  /// Add a floating sidebar toggle button to any widget
  static Widget wrapWithSidebarToggle(
    Widget child, {
    bool showFloatingButton = true,
    EdgeInsetsGeometry? margin,
    double? size,
  }) {
    if (!showFloatingButton) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 20,
          top: 20,
          child: SidebarToggleButton(
            showAsFloatingButton: true,
            size: size ?? 56,
            margin: margin,
            elevation: 4,
          ),
        ),
      ],
    );
  }

  /// Add sidebar toggle to an AppBar as a leading widget
  static PreferredSizeWidget addSidebarToggleToAppBar(
    PreferredSizeWidget appBar,
  ) {
    if (appBar is AppBar) {
      return AppBar(
        leading: const SidebarToggleAppBarButton(),
        automaticallyImplyLeading: false, // Disable auto-leading since we're providing our own
        title: appBar.title,
        actions: appBar.actions,
        backgroundColor: appBar.backgroundColor,
        foregroundColor: appBar.foregroundColor,
        elevation: appBar.elevation,
        shadowColor: appBar.shadowColor,
        surfaceTintColor: appBar.surfaceTintColor,
        iconTheme: appBar.iconTheme,
        actionsIconTheme: appBar.actionsIconTheme,
        centerTitle: appBar.centerTitle,
        titleSpacing: appBar.titleSpacing,
        toolbarHeight: appBar.toolbarHeight,
        leadingWidth: appBar.leadingWidth,
        systemOverlayStyle: appBar.systemOverlayStyle,
        bottom: appBar.bottom,
        flexibleSpace: appBar.flexibleSpace,
      );
    }
    return appBar;
  }

  /// Create a simple AppBar with sidebar toggle
  static PreferredSizeWidget createAppBarWithSidebarToggle(
    String title, {
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppBar(
      leading: const SidebarToggleAppBarButton(),
      title: Text(title),
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Extension to easily add sidebar toggle to any Scaffold
extension ScaffoldSidebarToggle on Scaffold {
  static Widget withSidebarToggle({
    Key? key,
    PreferredSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    FloatingActionButtonAnimator? floatingActionButtonAnimator,
    List<Widget>? persistentFooterButtons,
    Widget? drawer,
    DrawerCallback? onDrawerChanged,
    Widget? endDrawer,
    DrawerCallback? onEndDrawerChanged,
    Widget? bottomNavigationBar,
    Widget? bottomSheet,
    Color? backgroundColor,
    bool? resizeToAvoidBottomInset,
    bool primary = true,
    DragStartBehavior drawerDragStartBehavior = DragStartBehavior.start,
    bool extendBody = false,
    bool extendBodyBehindAppBar = false,
    Color? drawerScrimColor,
    double? drawerEdgeDragWidth,
    bool drawerEnableOpenDragGesture = true,
    bool endDrawerEnableOpenDragGesture = true,
    String? restorationId,
    bool showSidebarToggle = true,
  }) {
    Widget scaffoldBody = body ?? const SizedBox.shrink();
    
    if (showSidebarToggle) {
      scaffoldBody = SidebarToggleHelper.wrapWithSidebarToggle(scaffoldBody);
    }

    return Scaffold(
      key: key,
      appBar: appBar,
      body: scaffoldBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      onDrawerChanged: onDrawerChanged,
      endDrawer: endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
