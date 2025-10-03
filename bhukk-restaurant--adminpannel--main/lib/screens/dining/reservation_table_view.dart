// screens/dining/reservation_table_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/reservation_controller.dart';
import '../../controller/dining/table_controller.dart';

class ReservationTableView extends StatelessWidget {
  final ReservationController controller = Get.put(ReservationController());

  ReservationTableView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table Booking / Reservation System', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, cons) {
                final isNarrow = cons.maxWidth < 720;
                return Obx(() {
                  if (isNarrow) {
                    return _buildCardList(context);
                  }
                  return _buildDataTable(context);
                });
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Reservation ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Date & Time')),
          DataColumn(label: Text('Guests')),
          DataColumn(label: Text('Table(s)')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: controller.reservations.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return DataRow(cells: [
            DataCell(Text(r.id)),
            DataCell(Text(r.customer)),
            DataCell(Text('${r.dateTime.day}/${r.dateTime.month}/${r.dateTime.year} ${r.dateTime.hour}:${r.dateTime.minute.toString().padLeft(2, '0')}')),
            DataCell(Text(r.guests.toString())),
            DataCell(Text(r.tables.join(', '))),
            DataCell(_statusChip(r.status)),
            DataCell(Row(children:[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _approve(i, r),
                tooltip: 'Approve',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _reject(i, r),
                tooltip: 'Reject',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () => _cancel(i, r),
                tooltip: 'Cancel',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.blue),
                onPressed: () => _complete(i, r),
                tooltip: 'Complete',
              ),
            ])),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = controller.reservations[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(r.id, style: const TextStyle(fontWeight: FontWeight.w800))),
                  _statusChip(r.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customer: ${r.customer}'),
              const SizedBox(height: 4),
              Text('When: ${r.dateTime.day}/${r.dateTime.month}/${r.dateTime.year} ${r.dateTime.hour}:${r.dateTime.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 4),
              Text('Guests: ${r.guests}'),
              const SizedBox(height: 4),
              Text('Tables: ${r.tables.join(', ')}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _approve(i, r),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _reject(i, r),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _cancel(i, r),
                    icon: const Icon(Icons.cancel, color: Colors.orange),
                    label: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _complete(i, r),
                    icon: const Icon(Icons.done_all, color: Colors.blue),
                    label: const Text('Complete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _approve(int index, dynamic r) {
    controller.updateReservation(index, r.copyWith(status: 'Confirmed'));
    // Add/update tables in table management
    final tableCtrl = Get.isRegistered<TableController>() ? Get.find<TableController>() : Get.put(TableController(), permanent: true);
    for (final t in r.tables) {
      final num = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null) {
        tableCtrl.ensureTable(num, status: 'Reserved', orderId: r.id);
      }
    }
    Get.snackbar('Reservation approved', 'Reservation ${r.id} confirmed', snackPosition: SnackPosition.BOTTOM);
  }

  void _reject(int index, dynamic r) async {
  final ok = await Get.dialog<bool>(
    Builder(builder: (dCtx) => AlertDialog(
        title: const Text('Reject Reservation?'),
        content: Text('Reject ${r.id} for ${r.customer}?'),
        actions: [
      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('No')),
      ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Yes, reject')),
        ],
    )),
    );
    if (ok == true) {
      controller.updateReservation(index, r.copyWith(status: 'Cancelled'));
  final tableCtrl = Get.isRegistered<TableController>() ? Get.find<TableController>() : Get.put(TableController(), permanent: true);
  tableCtrl.removeTablesByReservation(r.id);
      Get.snackbar('Reservation rejected', 'Reservation ${r.id} cancelled', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _cancel(int index, dynamic r) async {
  final ok = await Get.dialog<bool>(
    Builder(builder: (dCtx) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: Text('Cancel ${r.id} for ${r.customer}?'),
        actions: [
      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('No')),
      ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Yes, cancel')),
        ],
    )),
    );
    if (ok == true) {
      controller.updateReservation(index, r.copyWith(status: 'Cancelled'));
  final tableCtrl = Get.isRegistered<TableController>() ? Get.find<TableController>() : Get.put(TableController(), permanent: true);
  tableCtrl.removeTablesByReservation(r.id);
      Get.snackbar('Reservation cancelled', 'Reservation ${r.id} cancelled', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _complete(int index, dynamic r) async {
    controller.updateReservation(index, r.copyWith(status: 'Completed'));
    final tableCtrl = Get.isRegistered<TableController>() ? Get.find<TableController>() : Get.put(TableController(), permanent: true);
    // When completed we free the tables back to available state
    for (final t in r.tables) {
      final num = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null) {
        tableCtrl.ensureTable(num, status: 'Available', orderId: '');
      }
    }
    Get.snackbar('Reservation completed', 'Reservation ${r.id} completed, tables freed', snackPosition: SnackPosition.BOTTOM);
  }

  Widget _statusChip(String status) {
    final color = {
      'Pending': Colors.orange,
      'Confirmed': Colors.green,
      'Cancelled': Colors.red,
      'Completed': Colors.blue,
      'No-Show': Colors.grey,
    }[status] ?? Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
  color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
  border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
