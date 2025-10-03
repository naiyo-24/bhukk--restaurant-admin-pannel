// screens/delivery/driver_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/delivery/delivery_controller.dart';
import '../../models/delivery_partner_model.dart';

class DriverHistoryScreen extends StatelessWidget {
  DriverHistoryScreen({super.key});
  final DeliveryController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Driver History',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button row (no AppBar override)
            Row(children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Text('Driver History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 20),
            _summaryRow(),
            const SizedBox(height: 20),
            Expanded(child: _historyList()),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow() {
    return Obx(() {
      final completed = controller.pastAssignments.where((a) => a.status == AssignmentStatus.completed).length;
      final cancelled = controller.pastAssignments.where((a) => a.status == AssignmentStatus.cancelled).length;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metricCard('Completed', completed.toString(), Colors.green),
          _metricCard('Cancelled', cancelled.toString(), Colors.red),
          _metricCard('Total Past', controller.pastAssignments.length.toString(), Colors.blueGrey),
        ],
      );
    });
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)) ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _historyList() {
    return Obx(() {
      final items = controller.pastAssignments.where((a) => a.status == AssignmentStatus.completed).toList();
      if (items.isEmpty) return const Center(child: Text('No completed deliveries yet'));
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final a = items[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(a.orderId),
              subtitle: Text('${a.pickup} → ${a.drop}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(a),
            ),
          );
        },
      );
    });
  }

  void _showDetails(DeliveryAssignment a) {
    Get.dialog(AlertDialog(
      title: Text('Order ${a.orderId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Pickup', a.pickup),
          _detailRow('Drop', a.drop),
          _detailRow('Status', a.statusLabel),
          _detailRow('Assigned', a.assignedAt?.toString() ?? '-'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Close')),
      ],
    ));
  }

  Widget _detailRow(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(child: Text(v)),
    ]),
  );
}
