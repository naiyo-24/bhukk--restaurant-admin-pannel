// widgets/order_side_panel.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/orders/order_panel_controller.dart';
import '../controller/orders/orders_controller.dart';
import '../models/order_model.dart';

class OrderSidePanel extends StatelessWidget {
  final double panelWidth;
  final bool isDesktop;
  const OrderSidePanel({super.key, required this.panelWidth, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
  final ctrl = Get.isRegistered<OrderSidePanelController>()
    ? Get.find<OrderSidePanelController>()
    : Get.put(OrderSidePanelController(), permanent: true);
    return Obx(() {
      final open = ctrl.panelOpen.value;
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        right: open ? 0 : -panelWidth,
        top: 0,
        bottom: 0,
        width: panelWidth,
        child: ClipRRect(
          borderRadius: isDesktop ? const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)) : const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 22,
            shadowColor: Colors.black26,
            child: SafeArea(
            child: Obx(() {
              final list = ctrl.incoming;
              return Column(
                children: [
                  // Stylish header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Row(children: [
                      Expanded(child: Text('Incoming Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                      if (list.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                          child: Text('${list.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(
                        onPressed: () => ctrl.closeAndSnooze(const Duration(minutes: 2)),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),

                  // Clean list (no overlapping), rounded cards, smooth scrolling
                  if (list.isEmpty)
                    const Expanded(child: _EmptyState())
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OrderCard(order: list[i], depth: i > 3 ? 3 : i),
                      ),
                    ),
                ],
              );
            }),
          ),
          ),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No incoming orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('The panel will close automatically', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final int depth;
  const _OrderCard({required this.order, required this.depth});

  @override
  Widget build(BuildContext context) {
    final oc = Get.find<OrdersController>();
    final panel = Get.find<OrderSidePanelController>();
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.receipt_long, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Expanded(child: Text('New order • ${order.id}', style: const TextStyle(fontWeight: FontWeight.w900))),
            Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text('${order.customerName} • ${order.phone}', style: Theme.of(context).textTheme.bodySmall),
          Text(order.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
          const SizedBox(height: 10),
          Row(children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
              onPressed: () => panel.reject(order.id),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => panel.accept(order.id),
              child: const Text('Accept'),
            ),
            const Spacer(),
            TextButton(onPressed: () => _showDetails(context, oc, order), child: const Text('Details')),
          ]),
        ]),
      ),
    );
  }

  void _showDetails(BuildContext context, OrdersController oc, OrderModel o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: Text('Order ${o.id}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 8),
            Text('${o.customerName} • ${o.phone}'),
            Text(o.address),
            const SizedBox(height: 12),
            ...o.items.map((it) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${it.qty} × ${it.name}'),
                  trailing: Text('₹${(it.price * it.qty).toStringAsFixed(0)}'),
                )),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Subtotal'),
              trailing: Text('₹${o.subtotal.toStringAsFixed(0)}'),
            ),
            ListTile(dense: true, contentPadding: EdgeInsets.zero, title: const Text('Tax'), trailing: Text('₹${o.tax.toStringAsFixed(0)}')),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ],
        ),
      ),
    );
  }
}
