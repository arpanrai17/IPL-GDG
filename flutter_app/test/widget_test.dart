import 'package:flutter_test/flutter_test.dart';
import 'package:ipl_ai_suite/main.dart';

void main() {
  testWidgets('Splash screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const IPLAISuiteApp());
    expect(find.text('IPL AI Suite'), findsOneWidget);
  });
}
