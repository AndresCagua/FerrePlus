import 'package:flutter/material.dart';

import '../../../../domain/models/admin_models.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../theme/app_component_theme.dart';
import '../../../theme/app_semantic_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../dashboard_period.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({
    required this.period,
    required this.points,
    required this.onPeriodChanged,
    super.key,
  });
  final DashboardPeriod period;
  final List<ChartPoint> points;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final AppComponentTheme components =
        Theme.of(context).extension<AppComponentTheme>() ??
        AppComponentTheme.standard;
    final AppSemanticColors semanticColors = AppSemanticColors.of(context);
    return Card(
      child: Padding(
        padding: components.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ventas por periodo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.space8),
            SegmentedButton<DashboardPeriod>(
              segments: const <ButtonSegment<DashboardPeriod>>[
                ButtonSegment(
                  value: DashboardPeriod.week,
                  label: Text('Semana'),
                ),
                ButtonSegment(value: DashboardPeriod.month, label: Text('Mes')),
                ButtonSegment(value: DashboardPeriod.year, label: Text('Ano')),
              ],
              selected: <DashboardPeriod>{period},
              onSelectionChanged: (Set<DashboardPeriod> selected) =>
                  onPeriodChanged(selected.first),
            ),
            const SizedBox(height: AppSpacing.space16),
            if (points.isEmpty)
              const AppEmptyState(
                title: 'Sin ventas registradas',
                subtitle: 'No hay ventas en el periodo seleccionado.',
                icon: Icons.bar_chart,
              )
            else
              SizedBox(
                height: AppSpacing.chartHeight,
                child: Semantics(
                  label: _chartSemanticsLabel(points),
                  child: CustomPaint(
                    painter: _SalesChartPainter(
                      points: points,
                      color: semanticColors.primary,
                      textColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _chartSemanticsLabel(List<ChartPoint> values) {
    final String pointsLabel = values
        .map(
          (ChartPoint point) =>
              '${point.fecha?.day ?? ''}: ${point.total.toStringAsFixed(2)}',
        )
        .join(', ');
    return 'Grafico de ventas con ${values.length} periodos. Valores: $pointsLabel';
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({
    required this.points,
    required this.color,
    required this.textColor,
  });
  final List<ChartPoint> points;
  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double max = points
        .map((ChartPoint point) => point.total)
        .reduce((double a, double b) => a > b ? a : b);
    final double slot = size.width / points.length;
    final Paint bar = Paint()..color = color;
    final TextPainter text = TextPainter(textDirection: TextDirection.ltr);
    for (int index = 0; index < points.length; index++) {
      final ChartPoint point = points[index];
      final double height = max == 0
          ? 0
          : (point.total / max) * (size.height - AppSpacing.space32);
      final Rect rect = Rect.fromLTWH(
        index * slot + slot * .2,
        size.height - height - AppSpacing.space20,
        slot * .6,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppSpacing.space4)),
        bar,
      );
      text.text = TextSpan(
        text: _label(point.fecha),
        style: AppTypography.textTheme.bodySmall!.copyWith(color: textColor),
      );
      text.layout(maxWidth: slot);
      text.paint(
        canvas,
        Offset(
          index * slot + (slot - text.width) / 2,
          size.height - AppSpacing.space16,
        ),
      );
    }
  }

  String _label(DateTime? date) =>
      date == null ? '' : '${date.day}/${date.month}';

  @override
  bool shouldRepaint(_SalesChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
