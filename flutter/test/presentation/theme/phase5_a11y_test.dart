import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/presentation/features/dashboard/widgets/metric_card.dart';
import 'package:ferreplus/presentation/features/dashboard/widgets/metrics_grid.dart';
import 'package:ferreplus/presentation/theme/app_semantic_colors.dart';
import 'package:ferreplus/presentation/theme/app_theme.dart';

double _contrast(Color foreground, Color background) {
  final double foregroundLuminance = foreground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final double darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('semantic text and KPI colors preserve contrast in both themes', () {
    for (final AppSemanticColors colors in <AppSemanticColors>[
      AppSemanticColors.light,
      AppSemanticColors.dark,
    ]) {
      expect(
        _contrast(colors.onSurface, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.textSecondary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.kpiPurple, colors.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(colors.kpiTeal, colors.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(colors.kpiAmber, colors.surface),
        greaterThanOrEqualTo(3),
      );
    }
  });

  testWidgets('metrics grid keeps content usable at large text scale', (
    WidgetTester tester,
  ) async {
    final List<MetricCardData> metrics = List<MetricCardData>.generate(
      6,
      (int index) => MetricCardData(
        label: 'Indicador $index',
        value: '$index',
        icon: Icons.analytics,
        color: AppSemanticColors.light.primary,
        route: '/',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(child: MetricsGrid(metrics: metrics)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
