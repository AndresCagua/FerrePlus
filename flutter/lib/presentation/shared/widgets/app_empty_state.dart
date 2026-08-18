import 'package:flutter/material.dart';

import '../../theme/app_component_theme.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final AppComponentTheme components =
        Theme.of(context).extension<AppComponentTheme>() ??
        AppComponentTheme.standard;
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Padding(
        padding: components.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppDurations.iconLarge),
            const SizedBox(height: AppSpacing.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null && actionLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space16),
              FilledButton(onPressed: action, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
