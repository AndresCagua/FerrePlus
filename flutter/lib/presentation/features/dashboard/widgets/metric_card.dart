import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_component_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class MetricCardData {
  const MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String route;
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.data, super.key});
  final MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final AppComponentTheme components =
        Theme.of(context).extension<AppComponentTheme>() ??
        AppComponentTheme.standard;
    return Semantics(
      button: true,
      label: '${data.label}: ${data.value}',
      hint: 'Abrir ${data.label.toLowerCase()}',
      child: Card(
        elevation: components.cardElevation,
        child: InkWell(
          borderRadius: BorderRadius.circular(components.cardRadius),
          onTap: () => context.go(data.route),
          child: Padding(
            padding: components.cardPadding,
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.space48,
                  height: AppSpacing.space48,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(components.cardRadius),
                  ),
                  child: Icon(data.icon, color: data.color),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        data.value,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: AppTypography.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
