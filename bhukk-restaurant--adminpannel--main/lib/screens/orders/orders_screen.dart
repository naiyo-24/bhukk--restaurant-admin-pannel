// screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/orders/orders_controller.dart';
import '../../controller/support/support_controller.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class OrdersScreen extends StatelessWidget {
  OrdersScreen({super.key});
  final OrdersController controller = Get.isRegistered<OrdersController>() ? Get.find<OrdersController>() : Get.put(OrdersController());

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Orders',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopRow(context),
            const SizedBox(height: 12),
            // Stable boxed filters (non-floating)
            _filtersBox(context),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by ID, customer or phone',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: controller.setSearch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      final wide = MediaQuery.of(context).size.width > 1000;
      // split by source
      final food = controller.filteredBySource(OrderSource.food);
      final dining = controller.filteredBySource(OrderSource.dining);
      final liquor = controller.filteredBySource(OrderSource.liquor);

      if (!wide) {
        // narrow: tabs for three sources
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(labelColor: AppTheme.cherryRed, tabs: const [Tab(text: 'Food'), Tab(text: 'Dining'), Tab(text: 'Liquor')]),
              Expanded(
                child: TabBarView(children: [
                  _sourceListView(food),
                  _sourceListView(dining),
                  _sourceListView(liquor),
                ]),
              )
            ],
          ),
        );
      }

      // wide: three columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _sourceColumn('Food', food, context)),
          const SizedBox(width: 12),
          Expanded(child: _sourceColumn('Dining', dining, context)),
          const SizedBox(width: 12),
          Expanded(child: _sourceColumn('Liquor', liquor, context)),
        ],
      );
    });
  }

  Widget _sourceListView(List<OrderModel> items) {
    if (items.isEmpty) return const Center(child: Text('No orders'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (c, i) => _buildCard(items[i], c),
    );
  }

  Widget _sourceColumn(String title, List<OrderModel> items, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        Expanded(child: items.isEmpty ? const Center(child: Text('No orders')) : ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (c, i) => _buildCard(items[i], context),
        )),
      ],
    );
  }

  Widget _buildCard(OrderModel m, BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context, m),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(m.customerName, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(DateFormat.yMMMd().add_jm().format(m.dateTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${m.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(label: Text(_labelForStatus(m.status)), backgroundColor: _colorForStatus(m.status)),
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showEditDialog(context, m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                    tooltip: 'Chat with customer',
                    onPressed: () => Get.toNamed(AppRoutes.CUSTOMER_CHAT, arguments: {'customerName': m.customerName, 'orderId': m.id, 'phone': m.phone}),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => controller.updateStatus(m.id, OrderStatus.cancelled),
                  ),
                ])
              ])
            ],
          ),
        ),
      ),
    );
  }

  // legacy table view removed in favor of per-source columns

  // floating filters removed; filters are now stable and rendered via _filtersBox

  Widget _filtersBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(children: [
            IconButton(onPressed: () => Get.toNamed(AppRoutes.ORDER_HISTORY), icon: const Icon(Icons.history)),
            TextButton.icon(onPressed: controller.clearFilters, icon: const Icon(Icons.clear), label: const Text('Clear all'))
          ])
        ]),
        const SizedBox(height: 8),
        _filtersWidget(),
        const SizedBox(height: 12),
        _sortControls(),
      ]),
    );
  }

  Widget _sortControls() {
    return Obx(() {
      final s = controller.sort.value;
      return Row(children: [
        const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        DropdownButton<OrderSort>(
          value: s,
          items: const [
            DropdownMenuItem(value: OrderSort.newest, child: Text('Newest')),
            DropdownMenuItem(value: OrderSort.oldest, child: Text('Oldest')),
            DropdownMenuItem(value: OrderSort.amountHigh, child: Text('Amount (High)')),
            DropdownMenuItem(value: OrderSort.amountLow, child: Text('Amount (Low)')),
          ],
          onChanged: (v) {
            if (v != null) controller.setSort(v);
          },
        ),
      ]);
    });
  }

  Widget _filtersWidget() {
    return Obx(() {
      final active = controller.statusFilter.value;
      final total = controller.orders.length;
      final pendingCount = controller.orders.where((o) => o.status == OrderStatus.pending).length;
      final deliveredCount = controller.orders.where((o) => o.status == OrderStatus.delivered).length;
      final cancelledCount = controller.orders.where((o) => o.status == OrderStatus.cancelled).length;

      final pills = [
        _FilterPill(
          label: 'All',
          icon: Icons.list_alt,
          count: total,
          selected: active == null,
          onTap: () => controller.setFilter(null),
        ),
        _FilterPill(
          label: 'Pending',
          icon: Icons.hourglass_bottom,
          count: pendingCount,
          selected: active == OrderStatus.pending,
          onTap: () => controller.setFilter(OrderStatus.pending),
        ),
        _FilterPill(
          label: 'Delivered',
          icon: Icons.check_circle_outline,
          count: deliveredCount,
          selected: active == OrderStatus.delivered,
          onTap: () => controller.setFilter(OrderStatus.delivered),
        ),
        _FilterPill(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          count: cancelledCount,
          selected: active == OrderStatus.cancelled,
          onTap: () => controller.setFilter(OrderStatus.cancelled),
        ),
      ];

      return LayoutBuilder(builder: (context, bc) {
        final narrow = bc.maxWidth < 520;
        if (narrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              const SizedBox(width: 4),
              ...pills.map((w) => Padding(padding: const EdgeInsets.only(right: 8.0), child: w)),
              const SizedBox(width: 8),
            ]),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: pills,
        );
      });
    });
  }

// (moved _FilterPill to top-level below to avoid nested class definitions)

  String _labelForStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color _colorForStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return Colors.green.shade200;
      case OrderStatus.cancelled:
        return Colors.red.shade200;
      default:
        return Colors.orange.shade200;
    }
  }

  void _showDetails(BuildContext context, OrderModel m) {
    final oc = Get.find<OrdersController>();
    final orderId = m.id; // keep id, fetch reactive instance inside Obx
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, ctl) {
            return Obx(() {
              final current = oc.orders.firstWhereOrNull((o) => o.id == orderId) ?? m; // fallback
              return SingleChildScrollView(
                controller: ctl,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(current.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(current.status.name.toUpperCase()),
                        const SizedBox(height: 4),
                        Text(DateFormat.yMMMd().add_jm().format(current.dateTime), style: Theme.of(context).textTheme.bodySmall),
                      ])
                    ]),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: LayoutBuilder(builder: (c, size) {
                        final wideInfo = size.maxWidth > 600; // if enough horizontal space, split into columns
                        Widget customerBlock() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(current.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(current.phone),
                            ]);
                        Widget addressBlock() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Address', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(current.address, softWrap: true),
                            ]);
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: wideInfo
                              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(child: customerBlock()),
                                  const SizedBox(width: 32),
                                  Expanded(child: addressBlock()),
                                ])
                              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  customerBlock(),
                                  const SizedBox(height: 12),
                                  addressBlock(),
                                ]),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, cons) {
                      final isWide = cons.maxWidth > 700;
                      return isWide
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: _buildLeftColumn(context, current, oc)),
                              const SizedBox(width: 12),
                              SizedBox(width: 360, child: _buildRightColumn(context, current, oc)),
                            ])
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _buildRightColumn(context, current, oc),
                              const SizedBox(height: 12),
                              _buildLeftColumn(context, current, oc),
                            ]);
                    })
                  ]),
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildLeftColumn(BuildContext context, OrderModel item, OrdersController oc) {
    final timeline = oc.timelines[item.id] ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: timeline.isEmpty
                ? [const ListTile(title: Text('No events yet'))]
                : timeline.map<Widget>((e) => ListTile(
                      leading: const Icon(Icons.circle, size: 12),
                      title: Text(e['label'] ?? ''),
                      subtitle: e['time'] is DateTime ? Text(DateFormat.yMMMd().add_jm().format(e['time'])) : null,
                      trailing: e.containsKey('amount') ? Text('₹${(e['amount'] as double).toStringAsFixed(0)}') : null,
                    )).toList(),
          ),
        ),
      ),
      const SizedBox(height: 12),
  Text('Items', style: Theme.of(context).textTheme.titleMedium),
  const SizedBox(height: 6),
  _editableItemsList(context, item, oc),
      const SizedBox(height: 12),
      Text('Total: ₹${item.total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
    ]);
  }

  Widget _buildRightColumn(BuildContext context, OrderModel item, OrdersController oc) {
    return Obx(() {
      final partnerName = oc.deliveryPartners[item.id];
      final partnerObj = oc.partners[item.id];
      final canContact = partnerObj != null;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Delivery Partner', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(children: [
              ListTile(
                leading: CircleAvatar(child: Text(partnerName != null && partnerName.isNotEmpty ? partnerName[0] : '?')),
                title: Text(partnerName ?? 'Unassigned'),
                subtitle: Text(oc.partnerStatus(item.id)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Assign / Change Partner',
                  onPressed: () async {
                    final name = await _showAssignPartnerDialog(context, partnerName);
                    if (name != null && name.isNotEmpty) oc.assignPartner(item.id, name);
                  },
                ),
              ),
              Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                    child: DropdownButtonFormField<String>(
                      initialValue: partnerName,
                      hint: const Text('Assign partner'),
                      items: oc.availablePartners.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (v) {
                        if (v != null) oc.assignPartner(item.id, v);
                      },
                    ),
                  ),
                ),
                Tooltip(
                  message: canContact ? 'Call partner' : 'Assign a partner first',
                  child: IconButton(
                    icon: Icon(Icons.phone, color: canContact ? Colors.green : Colors.grey),
          onPressed: canContact
            ? () => Get.find<SupportController>().callSupport(partnerObj.phone)
                        : null,
                  ),
                ),
                Tooltip(
                  message: canContact ? 'Chat with partner' : 'Assign a partner first',
                  child: IconButton(
                    icon: Icon(Icons.chat, color: canContact ? Colors.blueAccent : Colors.grey),
                    onPressed: canContact
                        ? () => Get.find<SupportController>().openLiveChat(
                              customerName: partnerObj.name,
                              orderId: item.id,
                              phone: partnerObj.phone,
                            )
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Call customer',
                  icon: const Icon(Icons.person_pin_circle, color: Colors.orange),
                  onPressed: () => Get.find<SupportController>().callSupport(item.phone),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton.icon(
              icon: const Icon(Icons.assignment_return),
              label: const Text('Refund'),
              onPressed: () async {
                final amt = await _showAmountInput(context, 'Refund amount');
                if (amt != null) oc.processRefund(item.id, amt);
              }),
          OutlinedButton.icon(
              icon: const Icon(Icons.discount),
              label: const Text('Discount'),
              onPressed: () async {
                final amt = await _showAmountInput(context, 'Discount amount');
                if (amt != null) oc.applyDiscount(item.id, amt);
              }),
          OutlinedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              onPressed: () async {
                final reason = await _showTextInput(context, 'Cancellation reason');
                if (reason != null && reason.isNotEmpty) oc.cancelWithReason(item.id, reason);
              }),
          ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Mark Delivered'),
              onPressed: () => oc.updateStatus(item.id, OrderStatus.delivered)),
        ])
      ]);
    });
  }

  Future<String?> _showAssignPartnerDialog(BuildContext context, String? current) {
    final ctr = TextEditingController(text: current ?? '');
    return showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Assign Delivery Partner'), content: TextField(controller: ctr, decoration: const InputDecoration(labelText: 'Partner name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, ctr.text), child: const Text('Assign'))]));
  }

  Future<double?> _showAmountInput(BuildContext context, String title) {
    final ctr = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctr, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '₹')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctr.text)), child: const Text('OK'))],
      ),
    );
  }

  Future<String?> _showTextInput(BuildContext context, String title) {
    final ctr = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctr),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, ctr.text), child: const Text('OK'))],
      ),
    );
  }

  // Live tracking dialog removed per requirement

  void _showEditDialog(BuildContext context, OrderModel m) {
    final nameCtl = TextEditingController(text: m.customerName);
    final phoneCtl = TextEditingController(text: m.phone);
    final addrCtl = TextEditingController(text: m.address);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Order'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Customer')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextField(controller: addrCtl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.editOrder(m.id, customerName: nameCtl.text, phone: phoneCtl.text, address: addrCtl.text);
              Get.back();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _editableItemsList(BuildContext context, OrderModel order, OrdersController oc) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ...order.items.asMap().entries.map((e) {
              final idx = e.key;
              final it = e.value;
              final isAdjustment = it.price < 0; // negative line item (discount/refund)
              final lineTotal = it.price * it.qty;
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: idx == order.items.length - 1 ? 0 : 1)),
                  color: isAdjustment ? Colors.red.withValues(alpha: 0.05) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  title: Text(it.name, style: isAdjustment ? theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade700, fontStyle: FontStyle.italic) : null),
                  subtitle: Text(isAdjustment ? 'Adjustment: -₹${(it.price.abs()).toStringAsFixed(2)}' : '₹${it.price.toStringAsFixed(2)} each'),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease quantity',
                        onPressed: it.qty > 1 && !isAdjustment ? () => oc.updateItemQuantity(order.id, idx, it.qty - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: 28,
                        child: Center(
                          child: Text('${it.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Increase quantity',
                        onPressed: !isAdjustment ? () => oc.updateItemQuantity(order.id, idx, it.qty + 1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  trailing: isAdjustment
                      ? Text(
                          '−₹${lineTotal.abs().toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${lineTotal.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            IconButton(
                              tooltip: 'Remove item',
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => oc.removeItem(order.id, idx),
                            ),
                          ],
                        ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Item'),
                subtitle: const Text('Insert a new product line'),
                onTap: () async {
                  final added = await _showAddItemDialog(Get.context!, order.id);
                  if (added != null) {
                    oc.addItem(order.id, name: added.name, qty: added.qty, price: added.price);
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<OrderItem?> _showAddItemDialog(BuildContext context, String orderId) async {
    final nameCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '1');
    final priceCtl = TextEditingController(text: '0');
    return showDialog<OrderItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Item name')),
            const SizedBox(height: 12),
            TextField(controller: qtyCtl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtl.text) ?? 1;
              final price = double.tryParse(priceCtl.text) ?? 0;
              if (nameCtl.text.trim().isEmpty) return;
              Get.back(result: OrderItem(name: nameCtl.text.trim(), qty: qty, price: price));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// Modern pill-style filter button
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.icon, this.count = 0, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.cherryRed : Colors.white;
    final fg = selected ? Colors.white : Colors.black87;
  final border = selected ? Border.all(color: AppTheme.cherryRed.withAlpha((0.6 * 255).toInt()), width: 0) : Border.all(color: Colors.grey.shade200);

    return Semantics(
      button: true,
      label: '$label filter, $count items',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: border,
            boxShadow: selected ? [BoxShadow(color: AppTheme.cherryRed.withAlpha((0.12 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: selected ? Colors.white24 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text('$count', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ]
          ]),
        ),
      ),
    );
  }
}
