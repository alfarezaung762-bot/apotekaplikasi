import 'package:flutter_test/flutter_test.dart';
import 'package:fluter_apotek/main.dart';

void main() {
  testWidgets('MedConnect app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MedConnectApp());
    // Verify the app loads without error
    expect(find.byType(MedConnectApp), findsOneWidget);
  });
}
