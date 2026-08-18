import 'package:flutter/material.dart';

import '../../theme/app_component_theme.dart';
import '../../theme/app_spacing.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({required this.title, required this.child, this.actions, this.showAppBar = true, super.key});
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final AppComponentTheme components = Theme.of(context).extension<AppComponentTheme>()!;
    return Scaffold(
      appBar: showAppBar ? AppBarBuilder(title: title, actions: actions) : null,
      body: SafeArea(
        child: Padding(
          padding: components.cardPadding.copyWith(
            left: AppSpacing.space16,
            right: AppSpacing.space16,
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppBarBuilder extends StatelessWidget implements PreferredSizeWidget {
  const AppBarBuilder({required this.title, this.actions, super.key});
  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AppBar(title: Text(title), actions: actions);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
