import '../../../domain/models/admin_models.dart';

enum DashboardPeriod { week, month, year }

class DateRange {
  const DateRange(this.desde, this.hasta);
  final DateTime desde;
  final DateTime hasta;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(desde, hasta);
}

DateRange dashboardDateRange(DashboardPeriod period, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  return switch (period) {
    DashboardPeriod.week => DateRange(
      today.subtract(Duration(days: today.weekday - DateTime.monday)),
      today,
    ),
    DashboardPeriod.month => DateRange(
      DateTime(today.year, today.month),
      today,
    ),
    DashboardPeriod.year => DateRange(DateTime(today.year), today),
  };
}

List<ChartPoint> groupChartPoints(
  Iterable<ChartPoint> points,
  DashboardPeriod period,
) {
  final Map<DateTime, double> grouped = <DateTime, double>{};
  for (final ChartPoint point in points) {
    final DateTime? date = point.fecha;
    if (date == null) continue;
    final DateTime key = period == DashboardPeriod.year
        ? DateTime(date.year, date.month)
        : DateTime(date.year, date.month, date.day);
    grouped[key] = (grouped[key] ?? 0) + point.total;
  }
  return grouped.entries
      .map(
        (MapEntry<DateTime, double> entry) =>
            ChartPoint(fecha: entry.key, total: entry.value),
      )
      .toList(growable: false)
    ..sort((ChartPoint a, ChartPoint b) => a.fecha!.compareTo(b.fecha!));
}
