import 'package:flutter/material.dart';

import '../../../../domain/models/admin_models.dart';
import '../../../theme/app_spacing.dart';

class MonthSummary extends StatelessWidget {
  const MonthSummary({required this.report, super.key});
  final ReporteDashboard report;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Text(
        'Este mes: ${report.totalComprasMes.toStringAsFixed(2)} en compras y ${report.totalGastosMes.toStringAsFixed(2)} en gastos.',
      ),
    ),
  );
}
