import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/presentation/shared/widgets/app_empty_state.dart';
import 'package:ferreplus/presentation/shared/widgets/app_error_view.dart';
import 'package:ferreplus/presentation/shared/widgets/app_loading_indicator.dart';
import 'package:ferreplus/presentation/shared/widgets/page_scaffold.dart';
import 'package:ferreplus/presentation/theme/app_theme.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('shared error view exposes retry action', (WidgetTester tester) async {
    bool retried = false;
    await tester.pumpWidget(harness(AppErrorView(message: 'Fallo de red', onRetry: () => retried = true)));
    expect(find.text('Fallo de red'), findsOneWidget);
    await tester.tap(find.text('Intentar nuevamente'));
    expect(retried, isTrue);
  });

  testWidgets('shared empty and loading views render accessible content', (WidgetTester tester) async {
    await tester.pumpWidget(
      harness(const Column(children: <Widget>[
        AppEmptyState(title: 'Sin productos', subtitle: 'Agrega el primero'),
        AppLoadingIndicator(),
      ])),
    );
    expect(find.text('Sin productos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('page scaffold renders contextual app bar', (WidgetTester tester) async {
    await tester.pumpWidget(harness(const PageScaffold(title: 'Productos', child: Text('Contenido'))));
    expect(find.text('Productos'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
