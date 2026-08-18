import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/constants/permission_codes.dart';
import 'package:ferreplus/core/providers/auth_providers.dart';
import 'package:ferreplus/domain/models/admin_models.dart';
import 'package:ferreplus/domain/models/auth_state.dart';
import 'package:ferreplus/presentation/features/dashboard/dashboard_period.dart';
import 'package:ferreplus/presentation/features/dashboard/widgets/metric_card.dart';
import 'package:ferreplus/presentation/features/dashboard/widgets/metrics_grid.dart';
import 'package:ferreplus/presentation/features/dashboard/widgets/quick_actions.dart';
import 'package:ferreplus/presentation/features/dashboard/widgets/sales_chart.dart';
import 'package:ferreplus/presentation/theme/app_theme.dart';

class _AllDashboardPermissions extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    permisos: <String>{
      PermissionCodes.ventasCrear,
      PermissionCodes.productosCrear,
      PermissionCodes.gastosCrear,
      PermissionCodes.comprasCrear,
    },
  );
}

void main() {
  const List<MetricCardData> metrics = <MetricCardData>[
    MetricCardData(
      label: 'Total Productos',
      value: '10',
      icon: Icons.inventory_2,
      color: Colors.blue,
      route: '/productos',
    ),
    MetricCardData(
      label: 'Stock Bajo',
      value: '2',
      icon: Icons.warning_amber,
      color: Colors.red,
      route: '/productos',
    ),
    MetricCardData(
      label: 'Ventas Hoy',
      value: '\$20.00',
      icon: Icons.today,
      color: Colors.green,
      route: '/ventas',
    ),
    MetricCardData(
      label: 'Ventas del Mes',
      value: '\$100.00',
      icon: Icons.date_range,
      color: Colors.orange,
      route: '/ventas',
    ),
    MetricCardData(
      label: 'Total Clientes',
      value: '5',
      icon: Icons.people,
      color: Colors.purple,
      route: '/clientes',
    ),
    MetricCardData(
      label: 'Proveedores',
      value: '3',
      icon: Icons.local_shipping,
      color: Colors.teal,
      route: '/proveedores',
    ),
  ];

  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('MetricCard muestra icono, valor, label y semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(MetricCard(data: metrics.first)));
    expect(find.text('Total Productos'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    expect(find.bySemanticsLabel('Total Productos: 10'), findsOneWidget);
  });

  testWidgets('MetricsGrid renderiza seis tarjetas y se adapta a 320/400', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 320,
          height: 1000,
          child: MetricsGrid(metrics: metrics),
        ),
      ),
    );
    expect(find.byType(MetricCard), findsNWidgets(6));
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 400,
          height: 1000,
          child: MetricsGrid(metrics: metrics),
        ),
      ),
    );
    expect(find.byType(MetricCard), findsNWidgets(6));
  });

  testWidgets('SalesChart cambia de periodo y pinta datos', (
    WidgetTester tester,
  ) async {
    DashboardPeriod selected = DashboardPeriod.month;
    await tester.pumpWidget(
      harness(
        SalesChart(
          period: selected,
          points: <ChartPoint>[
            ChartPoint(fecha: DateTime(2026, 8, 1), total: 25),
          ],
          onPeriodChanged: (DashboardPeriod value) => selected = value,
        ),
      ),
    );
    expect(find.text('Ventas por periodo'), findsOneWidget);
    expect(find.text('Esta Semana'), findsOneWidget);
    expect(find.text('Este Mes'), findsOneWidget);
    expect(find.text('Este Año'), findsOneWidget);
    await tester.tap(find.text('Esta Semana'));
    expect(selected, DashboardPeriod.week);
  });

  testWidgets('QuickActions muestra el prefijo requerido en sus etiquetas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_AllDashboardPermissions.new),
        ],
        child: harness(const QuickActions()),
      ),
    );

    expect(find.text('+ Nueva venta'), findsOneWidget);
    expect(find.text('+ Nuevo producto'), findsOneWidget);
    expect(find.text('+ Registrar gasto'), findsOneWidget);
    expect(find.text('+ Registrar compra'), findsOneWidget);
  });
}
