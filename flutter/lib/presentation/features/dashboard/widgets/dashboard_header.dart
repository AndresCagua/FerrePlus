import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space16),
    child: Text(
      'Resumen de tu negocio',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
  );
}
