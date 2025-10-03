// widgets/notification_panel.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/controller/notification/notification_controller.dart';
import 'package:bhukk_resturant_admin/models/notification_item.dart';
import 'package:bhukk_resturant_admin/controller/orders/orders_controller.dart';
import 'package:bhukk_resturant_admin/models/order_model.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  late final NotificationPanelController ctrl;

  @override
  void initState() {
    super.initState();
  // obtain existing controller (created in main_scaffold / initialBinding)
  ctrl = Get.isRegistered<NotificationPanelController>() ? Get.find<NotificationPanelController>() : Get.put(NotificationPanelController());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final panelWidth = isDesktop ? 380.0 : width; // side drawer on large screens, full screen on small

    return Obx(() {
      final open = ctrl.panelOpen.value;
      if (!open) return const SizedBox.shrink();

      final filtered = ctrl.filtered;
      final grouped = ctrl.groupedByDay(filtered);

      return Stack(children: [
        GestureDetector(
          onTap: ctrl.closePanel,
          child: AnimatedOpacity(
            opacity: open ? 1 : 0,
            duration: const Duration(milliseconds: 280),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black38),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
          right: 0,
          top: 0,
          bottom: 0,
          left: isDesktop ? (width - panelWidth) : 0,
          child: Material(
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            borderRadius: isDesktop ? const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)) : null,
            color: Theme.of(context).cardColor,
            child: SafeArea(
              child: Column(children: [
                _header(context, ctrl, filtered.length),
                _filtersBar(context, ctrl),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No notifications'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: grouped.length,
                          itemBuilder: (c, i) {
                            final dayKey = grouped.keys.elementAt(i);
                            final dayList = grouped[dayKey]!;
                            final date = DateTime.parse(dayKey);
                            final label = _friendlyDayLabel(date);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54)),
                                ),
                                ...dayList.map((n) => _card(context, ctrl, n)),
                              ]),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ),
      ]);
    });
  }

  String _friendlyDayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _header(BuildContext context, NotificationPanelController ctrl, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(children: [
        Expanded(
          child: Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text('$count', key: ValueKey(count), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
        ),
        IconButton(onPressed: ctrl.closePanel, icon: const Icon(Icons.close)),
      ]),
    );
  }

  Widget _filtersBar(BuildContext context, NotificationPanelController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notifications',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.withAlpha(30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: ctrl.setQuery,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => FilterChip(
                label: const Text('Unread'),
                selected: ctrl.showUnreadOnly.value,
                onSelected: (_) => ctrl.toggleUnreadOnly(),
              )),
          const SizedBox(width: 8),
          _typeMenu(ctrl),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          TextButton(onPressed: ctrl.markAllRead, child: const Text('Mark all read')),
          TextButton(onPressed: ctrl.clearAll, child: const Text('Clear all')),
          if (ctrl.typeFilter.value != null)
            TextButton(
              onPressed: () => ctrl.setTypeFilter(null),
              child: const Text('Reset type'),
            ),
        ])
      ]),
    );
  }

  Widget _typeMenu(NotificationPanelController ctrl) {
    return Obx(() => PopupMenuButton<NotificationType>(
          tooltip: 'Filter type',
          onSelected: (v) => ctrl.setTypeFilter(v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: NotificationType.info, child: Text('Info')),
            PopupMenuItem(value: NotificationType.orderUpdate, child: Text('Order')),
            PopupMenuItem(value: NotificationType.payment, child: Text('Payment')),
          ],
          child: CircleAvatar(
            radius: 20,
            backgroundColor: ctrl.typeFilter.value == null ? Colors.grey.shade300 : Colors.redAccent,
            child: Icon(Icons.filter_list, color: ctrl.typeFilter.value == null ? Colors.black54 : Colors.white),
          ),
        ));
  }

  Widget _card(BuildContext context, NotificationPanelController ctrl, NotificationItem n) {
    return Dismissible(
      key: ValueKey(n.id),
      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete, color: Colors.white)),
      secondaryBackground: Container(color: Colors.orangeAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.archive, color: Colors.white)),
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          ctrl.archive(n.id);
          Get.snackbar('Archived', n.title, snackPosition: SnackPosition.BOTTOM, mainButton: TextButton(onPressed: () { ctrl.undoLast(); }, child: const Text('Undo')));
        } else {
          ctrl.delete(n.id);
          Get.snackbar('Deleted', n.title, snackPosition: SnackPosition.BOTTOM, mainButton: TextButton(onPressed: () { ctrl.undoLast(); }, child: const Text('Undo')));
        }
      },
      child: GestureDetector(
        onTap: () {
          ctrl.markAsRead(n.id);
          if (n.type == NotificationType.orderUpdate) {
            _handleOrderNotificationTap(n);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _typeChip(n.type),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(n.description, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Text(n.timeAgo(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ]),
                ),
                const SizedBox(width: 12),
                if (!n.read) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFD2042D), borderRadius: BorderRadius.circular(10)), child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(NotificationType t) {
    switch (t) {
      case NotificationType.info:
        return const CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: Icon(Icons.info, color: Colors.white, size: 16));
      case NotificationType.orderUpdate:
        return const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.shopping_bag, color: Colors.white, size: 16));
      case NotificationType.payment:
        return const CircleAvatar(backgroundColor: Colors.purple, radius: 18, child: Icon(Icons.payment, color: Colors.white, size: 16));
    }
  }

  void _handleOrderNotificationTap(NotificationItem n) {
    // Try to extract an order id pattern like ORD-1234 from title or description
    final pattern = RegExp(r'(ORD-\d{3,})');
    final match = pattern.firstMatch(n.title) ?? pattern.firstMatch(n.description);
    if (match == null) return; // nothing to do
    final orderId = match.group(1)!;
    if (!Get.isRegistered<OrdersController>()) return;
    final oc = Get.find<OrdersController>();
    final order = oc.orders.firstWhereOrNull((o) => o.id == orderId);
    if (order == null) return;
    _showOrderQuickView(order);
  }

  void _showOrderQuickView(OrderModel o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: Text(o.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Chip(label: Text(o.status.name.toUpperCase())),
                ]),
                const SizedBox(height: 8),
                Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(o.customerName),
                Text(o.phone),
                const SizedBox(height: 8),
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(it.name)),
                        Text('x${it.qty}'),
                        const SizedBox(width: 8),
                        Text('₹${(it.price * it.qty).toStringAsFixed(2)}'),
                      ]),
                    )),
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Total: ₹${o.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Full Order'),
                    onPressed: () {
                      Navigator.pop(context); // close quick view
                      // Optionally navigate to orders section – assumes a sidebar route or similar
                      // If existing UI shows OrdersScreen already, user can locate; we mainly wanted quick preview.
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        );
      },
    );
  }
}
