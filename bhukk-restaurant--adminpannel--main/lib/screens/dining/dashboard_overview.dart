// screens/dining/dashboard_overview.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/table_controller.dart';
import '../../controller/dining/reservation_controller.dart';
import '../../controller/dining/order_controller.dart';
import '../../controller/dining/payment_controller.dart';

class DiningDashboardOverview extends StatelessWidget {
  const DiningDashboardOverview({super.key});

  T _ensure<T extends GetxController>(T Function() builder) {
    if (Get.isRegistered<T>()) return Get.find<T>();
    return Get.put<T>(builder(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are available even though other sections appear later in the column
    final tableCtrl = _ensure<TableController>(() => TableController());
    final resCtrl = _ensure<ReservationController>(() => ReservationController());
  // Ensure order controller exists for potential future metrics (not currently used for headline KPIs)
  _ensure<OrderController>(() => OrderController());
    final payCtrl = _ensure<PaymentController>(() => PaymentController());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          final activeReservations = resCtrl.reservations
              .where((r) => r.status == 'Pending' || r.status == 'Confirmed')
              .length;
          final availableTables = tableCtrl.tables.where((t) => t.status == 'Available').length;
            final occupiedTables = tableCtrl.tables.where((t) => t.status == 'Occupied').length;
          final reservedTables = tableCtrl.tables.where((t) => t.status == 'Reserved').length;
          // Guests dining = capacity of occupied tables + guests of confirmed reservations happening now (simplified)
          final guestsDining = tableCtrl.tables
                  .where((t) => t.status == 'Occupied')
                  .fold<int>(0, (p, t) => p + t.capacity) +
              resCtrl.reservations
                  .where((r) => r.status == 'Confirmed')
                  .fold<int>(0, (p, r) => p + r.guests);
          final pendingBills = payCtrl.payments.where((p) => p.status != 'Paid').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dining Dashboard Overview', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _DashboardCard(title: 'Active Reservations', value: activeReservations.toString(), color: Colors.indigo),
                  _DashboardCard(title: 'Available Tables', value: availableTables.toString(), color: Colors.green),
                  _DashboardCard(title: 'Occupied Tables', value: occupiedTables.toString(), color: Colors.red),
                  _DashboardCard(title: 'Reserved Tables', value: reservedTables.toString(), color: Colors.orange),
                  _DashboardCard(title: 'Guests Dining', value: guestsDining.toString(), color: Colors.teal),
                  _DashboardCard(title: 'Pending Bills', value: pendingBills.toString(), color: Colors.purple),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _DashboardCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
  border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    return card;
  }
}
