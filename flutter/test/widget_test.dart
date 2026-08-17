import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/main.dart';

void main() {
  testWidgets('renders the FerrePlus placeholder home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FerrePlusApp());

    expect(find.text('FerrePlus'), findsOneWidget);
  });
}
