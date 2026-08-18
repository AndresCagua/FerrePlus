import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/domain/models/admin_models.dart';
import 'package:ferreplus/presentation/features/dashboard/dashboard_period.dart';

void main() {
  final DateTime now = DateTime(2026, 8, 19, 14);

  test('calcula semana desde lunes, mes y ano hasta hoy', () {
    expect(
      dashboardDateRange(DashboardPeriod.week, now).desde,
      DateTime(2026, 8, 17),
    );
    expect(
      dashboardDateRange(DashboardPeriod.month, now).desde,
      DateTime(2026, 8),
    );
    expect(dashboardDateRange(DashboardPeriod.year, now).desde, DateTime(2026));
    expect(
      dashboardDateRange(DashboardPeriod.year, now).hasta,
      DateTime(2026, 8, 19),
    );
  });

  test('agrupa por dia y por mes sin inventar puntos', () {
    final List<ChartPoint> points = <ChartPoint>[
      ChartPoint(fecha: DateTime(2026, 1, 2, 10), total: 10),
      ChartPoint(fecha: DateTime(2026, 1, 2, 18), total: 15),
      ChartPoint(fecha: DateTime(2026, 2, 1), total: 20),
    ];
    expect(groupChartPoints(points, DashboardPeriod.month), hasLength(2));
    expect(groupChartPoints(points, DashboardPeriod.month).first.total, 25);
    expect(groupChartPoints(points, DashboardPeriod.year), hasLength(2));
  });
}
