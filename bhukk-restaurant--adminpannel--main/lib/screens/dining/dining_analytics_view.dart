// screens/dining/dining_analytics_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/analytics_controller.dart';

class DiningAnalyticsView extends StatelessWidget {
  DiningAnalyticsView({super.key});
  final AnalyticsController controller = Get.put(AnalyticsController());

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dining Analytics & Reports', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Today: ₹${controller.revenueToday.value}'),
                SizedBox(height: 8),
                Text('Revenue This Week: ₹${controller.revenueWeek.value}'),
                SizedBox(height: 8),
                Text('Revenue This Month: ₹${controller.revenueMonth.value}'),
                SizedBox(height: 8),
                Text('Peak Occupancy: ${controller.peakOccupancy.value}'),
                SizedBox(height: 8),
                Text('Reservation Stats: ${controller.reservationStats.value}'),
                SizedBox(height: 8),
                Text('Popular Dishes: ${controller.popularDishes.join(", ")}'),
                SizedBox(height: 8),
                Text('Staff Performance: ${controller.staffPerformance.value}'),
                SizedBox(height: 8),
                Text('Export: Excel, CSV, PDF'),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
