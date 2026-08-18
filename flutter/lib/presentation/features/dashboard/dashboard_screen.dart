import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/admin_models.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/page_scaffold.dart';
import '../../theme/app_spacing.dart';
import '../admin_providers.dart';
import 'dashboard_provider.dart';
import 'dashboard_period.dart';
import 'widgets/dashboard_empty.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/metrics_grid.dart';
import 'widgets/month_summary.dart';
import 'widgets/quick_actions.dart';
import 'widgets/sales_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReporteDashboard> state = ref.watch(dashboardProvider);
    return PageScaffold(
      title: 'Dashboard',
      showAppBar: false,
      child: state.when(
        loading: () => const AppLoadingIndicator(
          message: 'Cargando dashboard',
          showSkeleton: true,
        ),
        error: (Object error, StackTrace stack) => AppErrorView(
          message: 'No se pudo cargar el dashboard: $error',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (ReporteDashboard report) => _DashboardContent(report: report),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.report});
  final ReporteDashboard report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isEmpty(report)) return const DashboardEmpty();
    final DashboardPeriod period = ref.watch(dashboardPeriodProvider);
    final AsyncValue<List<ChartPoint>> sales = ref.watch(
      dashboardSalesProvider,
    );
    return ListView(
      children: <Widget>[
        const DashboardHeader(),
        MetricsGrid(metrics: MetricsGrid.fromReport(context, report)),
        const SizedBox(height: AppSpacing.space24),
        sales.when(
          loading: () => const AppLoadingIndicator(
            message: 'Cargando grafico',
            showSkeleton: true,
          ),
          error: (Object error, StackTrace stack) => const AppEmptyState(
            title: 'Grafico no disponible',
            subtitle: 'No se pudieron cargar las ventas del periodo.',
            icon: Icons.bar_chart_outlined,
          ),
          data: (List<ChartPoint> points) => SalesChart(
            period: period,
            points: points,
            onPeriodChanged: (DashboardPeriod next) =>
                ref.read(dashboardPeriodProvider.notifier).select(next),
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        const QuickActions(),
        const SizedBox(height: AppSpacing.space24),
        MonthSummary(report: report),
      ],
    );
  }

  bool _isEmpty(ReporteDashboard value) =>
      value.totalProductos == 0 &&
      value.productosStockBajo == 0 &&
      value.ventasHoy == 0 &&
      value.ventasMes == 0 &&
      value.totalClientes == 0 &&
      value.totalProveedores == 0 &&
      value.ventasPorDia.isEmpty;
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
     appBar: AppBarBuilder(title: title),
     body: const AppEmptyState(
       title: 'Disponible pronto',
       subtitle: 'Disponible en un proximo slice.',
     ),
  );
}
