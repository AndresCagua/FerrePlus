import 'package:flutter/material.dart';

import '../../../theme/app_semantic_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../../domain/models/admin_models.dart';
import 'metric_card.dart';

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({required this.metrics, super.key});
  final List<MetricCardData> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int columns = constraints.maxWidth >= AppSpacing.space360 ? 2 : 1;
      final double textScale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1, 1.5).toDouble();
      return GridView.custom(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.space12,
          mainAxisSpacing: AppSpacing.space12,
          mainAxisExtent: AppSpacing.metricCardHeight * textScale,
        ),
        childrenDelegate: SliverChildListDelegate(
          metrics
              .map((MetricCardData metric) => MetricCard(data: metric))
              .toList(),
        ),
      );
    },
  );

  static List<MetricCardData> fromReport(
    BuildContext context,
    ReporteDashboard report,
  ) {
    final AppSemanticColors colors = AppSemanticColors.of(context);
    return <MetricCardData>[
      MetricCardData(
        label: 'Total Productos',
        value: '${report.totalProductos}',
        icon: Icons.inventory_2,
        color: colors.primary,
        route: '/productos',
      ),
      MetricCardData(
        label: 'Stock Bajo',
        value: '${report.productosStockBajo}',
        icon: Icons.warning_amber,
        color: colors.error,
        route: '/productos',
      ),
      MetricCardData(
        label: 'Ventas Hoy',
        value: _money(report.ventasHoy),
        icon: Icons.today,
        color: colors.success,
        route: '/ventas',
      ),
      MetricCardData(
        label: 'Ventas del Mes',
        value: _money(report.ventasMes),
        icon: Icons.date_range,
        color: colors.kpiAmber,
        route: '/ventas',
      ),
      MetricCardData(
        label: 'Total Clientes',
        value: '${report.totalClientes}',
        icon: Icons.people,
        color: colors.kpiPurple,
        route: '/clientes',
      ),
      MetricCardData(
        label: 'Proveedores',
        value: '${report.totalProveedores}',
        icon: Icons.local_shipping,
        color: colors.kpiTeal,
        route: '/proveedores',
      ),
    ];
  }

  static String _money(num value) => '\$${value.toStringAsFixed(2)}';
}
