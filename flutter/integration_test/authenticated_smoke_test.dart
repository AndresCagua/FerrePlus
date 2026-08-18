import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ferreplus/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the public login screen without backend credentials', (WidgetTester tester) async {
    await tester.pumpWidget(const FerrePlusApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('FerrePlus'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
