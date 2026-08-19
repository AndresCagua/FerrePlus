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
  DashboardPeriod period, {
  DateRange? range,
}) {
  final Map<DateTime, double> grouped = <DateTime, double>{};
  for (final ChartPoint point in points) {
    final DateTime? date = point.fecha;
    if (date == null) continue;
    if (range != null && !_isWithinRange(date, range)) continue;
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

/// Completes the selected period so the chart has one point per interval.
List<ChartPoint> completeChartPoints(
  Iterable<ChartPoint> points,
  DashboardPeriod period,
  DateRange range,
) {
  final List<ChartPoint> grouped = groupChartPoints(
    points,
    period,
    range: range,
  );
  final Map<DateTime, double> totals = <DateTime, double>{
    for (final ChartPoint point in grouped) point.fecha!: point.total,
  };
  final List<ChartPoint> completed = <ChartPoint>[];
  DateTime cursor = _firstInterval(range.desde, period);
  final DateTime lastInterval = _firstInterval(range.hasta, period);
  while (!cursor.isAfter(lastInterval)) {
    completed.add(ChartPoint(fecha: cursor, total: totals[cursor] ?? 0));
    cursor = _nextInterval(cursor, period);
  }
  return completed;
}

bool chartCoversRange(
  Iterable<ChartPoint> points,
  DashboardPeriod period,
  DateRange range,
) {
  final Set<DateTime> intervals = groupChartPoints(
    points,
    period,
    range: range,
  ).map((ChartPoint point) => point.fecha!).toSet();
  DateTime cursor = _firstInterval(range.desde, period);
  final DateTime lastInterval = _firstInterval(range.hasta, period);
  while (!cursor.isAfter(lastInterval)) {
    if (!intervals.contains(cursor)) return false;
    cursor = _nextInterval(cursor, period);
  }
  return true;
}

DateTime _firstInterval(DateTime date, DashboardPeriod period) =>
    period == DashboardPeriod.year
    ? DateTime(date.year, date.month)
    : DateTime(date.year, date.month, date.day);

DateTime _nextInterval(DateTime date, DashboardPeriod period) =>
    period == DashboardPeriod.year
    ? DateTime(date.year, date.month + 1)
    : date.add(const Duration(days: 1));

bool _isWithinRange(DateTime date, DateRange range) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  return !day.isBefore(range.desde) && !day.isAfter(range.hasta);
}
