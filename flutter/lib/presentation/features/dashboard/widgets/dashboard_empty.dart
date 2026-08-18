import 'package:flutter/material.dart';

import '../../../shared/widgets/app_empty_state.dart';

class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({super.key});
  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.dashboard_outlined,
    title: 'Bienvenido a FerrePlus',
    subtitle:
        'Los datos de tu negocio aparecerán aquí cuando registres actividad.',
  );
}
