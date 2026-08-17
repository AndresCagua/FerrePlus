import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ferreplus/main.dart';

void main() {
  testWidgets('renders the FerrePlus login shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FerrePlusApp()));
    await tester.pump();

    expect(find.text('FerrePlus'), findsOneWidget);
  });
}
