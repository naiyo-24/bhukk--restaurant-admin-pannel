// screens/dining/dining_order_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/order_controller.dart';
import '../../models/order_model.dart'; // Import the file where OrderStatus is defined
import '../../controller/dining/table_controller.dart';

class DiningOrderView extends StatelessWidget {
  DiningOrderView({super.key});
  final OrderController controller = Get.put(OrderController());

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('In-Dining Orders', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: controller.orders.length,
              itemBuilder: (_, i) {
                final order = controller.orders[i];
                return ListTile(
                  title: Text(order.id),
                  subtitle: Text('Customer: ${order.customerName} | Status: ${order.status.name}${order.tableNumber != null ? ' | Table: ${order.tableNumber}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (order.status == OrderStatus.pending && order.tableNumber == null)
                        IconButton(
                          icon: Icon(Icons.event_seat, color: Colors.indigo),
                          onPressed: () => _assignTable(context, i, order),
                          tooltip: 'Assign Table',
                        ),
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.blue),
                        onPressed: () {
                          // Mark as delivered and free table if any
                          controller.updateOrder(i, order.copyWith(status: OrderStatus.delivered));
                          if (order.tableNumber != null && Get.isRegistered<TableController>()) {
                            Get.find<TableController>().freeTablesByOrderId(order.id);
                          }
                        },
                        tooltip: 'Mark Delivered',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          controller.deleteOrder(i);
                          if (order.tableNumber != null && Get.isRegistered<TableController>()) {
                            Get.find<TableController>().freeTablesByOrderId(order.id);
                          }
                        },
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTable(BuildContext context, int index, OrderModel order) async {
    final tableCtrl = Get.isRegistered<TableController>() ? Get.find<TableController>() : Get.put(TableController(), permanent: true);
    final available = tableCtrl.tables.where((t) => t.status == 'Available' || t.status == 'Reserved').map((t) => t.tableNumber).toList();
    int? chosen = available.isNotEmpty ? available.first : tableCtrl.firstAvailableTable();
    final txtNew = TextEditingController();
    bool useCustom = available.isEmpty; // if no available, default to custom
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Assign Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (available.isNotEmpty)
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: useCustom ? null : chosen,
                      decoration: const InputDecoration(labelText: 'Available Tables'),
                      items: available.map((e) => DropdownMenuItem(value: e, child: Text('Table $e'))).toList(),
                      onChanged: (v) => setState(() { useCustom = false; chosen = v; }),
                    ),
                  ),
                  TextButton(onPressed: () => setState(() { useCustom = true; }), child: const Text('New')),
                ]),
              if (useCustom)
                TextField(
                  controller: txtNew,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'New Table Number'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                int? num;
                if (useCustom) {
                  num = int.tryParse(txtNew.text.trim());
                } else {
                  num = chosen;
                }
                if (num == null) return;
                Navigator.pop<int?>(ctx, num);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      }),
    );
    if (result != null) {
      tableCtrl.ensureTable(result, status: 'Occupied', orderId: order.id);
      controller.updateOrder(index, order.copyWith(tableNumber: result));
      Get.snackbar('Table Assigned', 'Order ${order.id} -> Table $result', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
