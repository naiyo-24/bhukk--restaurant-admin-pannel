// test/earnings/earnings_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bhukk_resturant_admin/controller/earnings/earnings_controller.dart';

void main() {
  test('EarningsController computes summary for weekly', () {
    final c = EarningsController();
    c.setRange('Weekly');
    final total = c.weekData.fold(0.0, (p, e) => p + e);
    expect(c.totalEarnings.value, total);
    expect(c.ordersCount.value, (total / 150).round());
  });

  test('EarningsController computes summary for monthly', () {
    final c = EarningsController();
    c.setRange('Monthly');
    final total = c.monthData.fold(0.0, (p, e) => p + e);
    expect(c.totalEarnings.value, total);
  });
}
