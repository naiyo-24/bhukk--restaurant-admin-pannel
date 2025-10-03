// test/earnings/earnings_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/screens/earnings/earnings_screen.dart';

void main() {
  testWidgets('EarningsScreen builds and shows range selector', (WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(home: EarningsScreen()));
    await tester.pumpAndSettle();

  // title and possibly card text — allow multiple occurrences
  expect(find.text('Earnings'), findsWidgets);
    expect(find.text('Range:'), findsOneWidget);
  // look for download action labels rather than button type to be robust
  expect(find.text('Download PDF'), findsOneWidget);
  expect(find.text('Download Excel'), findsOneWidget);
  });
}
