import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/admin_models.dart';
import '../../../domain/models/commercial_models.dart';
import '../admin_providers.dart';
import 'dashboard_period.dart';

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodNotifier, DashboardPeriod>(
      DashboardPeriodNotifier.new,
    );

class DashboardPeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.month;

  void select(DashboardPeriod period) => state = period;
}

final dashboardSalesProvider = FutureProvider<List<ChartPoint>>((
  Ref ref,
) async {
  final DashboardPeriod period = ref.watch(dashboardPeriodProvider);
  final DateRange range = dashboardDateRange(period, DateTime.now());
  final ReporteDashboard dashboard = await ref.watch(dashboardProvider.future);
  if (chartCoversRange(dashboard.ventasPorDia, period, range)) {
    return completeChartPoints(dashboard.ventasPorDia, period, range);
  }

  final List<Venta> sales = await ref.watch(reportSalesProvider(range).future);
  return completeChartPoints(
    sales.map(
      (Venta sale) =>
          ChartPoint(fecha: sale.fechaCreacion, total: sale.total.toDouble()),
    ),
    period,
    range,
  );
});
