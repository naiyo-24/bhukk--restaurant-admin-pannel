// screens/orders/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/orders/orders_controller.dart';
import '../../models/order_model.dart';
// Removed unused import of OrdersScreen

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrdersController controller;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    // Acquire existing controller if registered, otherwise create one for this screen.
    controller = Get.isRegistered<OrdersController>() ? Get.find<OrdersController>() : Get.put(OrdersController());
    _searchCtrl = TextEditingController(text: controller.search.value);
    // keep controller.search in sync with the text field
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text;
      if (v != controller.search.value) controller.setSearch(v);
    });
  }

  @override
  void dispose() {
  _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Order History',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          // small in-content back button (no AppBar change requested) - nudged up slightly
          Transform.translate(
            offset: const Offset(0, -6),
            child: Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: _searchField()),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.download), onPressed: _exportCsv),
          ]),
          const SizedBox(height: 16),
          Expanded(child: _twoColumnHistory(context)),
        ]),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search orders...'),
    );
  }

  Widget _twoColumnHistory(BuildContext context) {
    return Obx(() {
      final delivered = controller.orders.where((o) => o.status == OrderStatus.delivered).toList();
      final cancelled = controller.orders.where((o) => o.status == OrderStatus.cancelled).toList();
      if (delivered.isEmpty && cancelled.isEmpty) return const Center(child: Text('No delivered or cancelled orders'));
      return LayoutBuilder(builder: (ctx, cons) {
        final wide = cons.maxWidth > 900;
        final deliveredList = _statusList('Delivered', delivered, Colors.green.shade50, context);
        final cancelledList = _statusList('Cancelled', cancelled, Colors.red.shade50, context);
        if (wide) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: deliveredList),
            const SizedBox(width: 20),
            Expanded(child: cancelledList),
          ]);
        }
        return ListView(padding: const EdgeInsets.only(bottom: 12), children: [deliveredList, const SizedBox(height: 24), cancelledList]);
      });
    });
  }

  Widget _statusList(String title, List<OrderModel> list, Color bg, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Text('${list.length}', style: const TextStyle(fontWeight: FontWeight.w600)))
          ]),
          const SizedBox(height: 12),
          if (list.isEmpty) const Text('None') else ...list.map((o) => _orderRow(o, context)),
        ]),
      ),
    );
  }

  Widget _orderRow(OrderModel m, BuildContext context) {
    return InkWell(
      onTap: () => _openDetails(context, m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(m.customerName),
            const SizedBox(height: 4),
            Text('${m.items.length} items', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${m.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Chip(label: Text(m.status.name.toUpperCase())),
          ])
        ]),
      ),
    );
  }

  void _openDetails(BuildContext context, OrderModel m) {
    // Reuse OrdersScreen detail logic by instantiating a temporary OrdersScreen and calling its method via a helper
    // Simpler: replicate small quick sheet
    final oc = controller; // same instance
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
            initialChildSize: 0.8,
          builder: (_, scroll) {
            return Obx(() {
              final current = oc.orders.firstWhereOrNull((o) => o.id == m.id) ?? m;
              return SingleChildScrollView(
                controller: scroll,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(current.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Chip(label: Text(current.status.name.toUpperCase())),
                    ]),
                    const SizedBox(height: 8),
                    Text(current.customerName),
                    Text(current.phone, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Items', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    ...current.items.map((it) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(it.name)),
                          Text('x${it.qty}'),
                          const SizedBox(width: 8),
                          Text('${it.price < 0 ? '−' : ''}₹${(it.price * it.qty).abs().toStringAsFixed(2)}'),
                        ])),
                    const Divider(height: 24),
                    Align(alignment: Alignment.centerRight, child: Text('Total: ₹${current.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 12),
                  ]),
                ),
              );
            });
          },
        );
      },
    );
  }

  // Removed old grid card method

  void _exportCsv() {
    final list = controller.all;
    final buffer = StringBuffer();
    buffer.writeln('ID,Customer,Phone,Date,Amount,Status,Source');
    for (final o in list) {
      final date = o.dateTime.toIso8601String();
      buffer.writeln('${o.id},${o.customerName},${o.phone},$date,${o.total},${o.status.name},${o.source.name}');
    }
    final csv = buffer.toString();
    // copy to clipboard for now
  Clipboard.setData(ClipboardData(text: csv));
    Get.snackbar('Export', 'CSV copied to clipboard', snackPosition: SnackPosition.BOTTOM);
  }
}
