// screens/payments/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/payment/payment_controller.dart';
import '../../models/refund_model.dart';
import '../../models/settlement_model.dart';
import 'package:file_selector/file_selector.dart';
import '../../controller/common/file_picker_controller.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
  // Use a tagged instance to avoid collision with Dining's similarly named controller
  final PaymentController pc = Get.put(PaymentController(), tag: 'payments');

  return MainScaffold(
      title: 'Payments',
      child: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (ctx, inner) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Obx(() {
                  // Build a filtered view over allPayments so the totals reflect actual restaurant income
                  final from = pc.filterFrom.value;
                  final to = pc.filterTo.value;
                  final statusFilter = pc.paymentStatusFilter.value; // null => default to success only
                  final methodFilter = pc.paymentMethodFilter.value; // null => all
                  final filtered = pc.allPayments.where((e) {
                    if (from != null && e.dateTime.isBefore(from)) return false;
                    if (to != null && e.dateTime.isAfter(to)) return false;
                    if (methodFilter != null && e.paymentMethod.toLowerCase() != methodFilter.toLowerCase()) return false;
                    if (statusFilter != null) {
                      return e.paymentStatus.toLowerCase() == statusFilter;
                    }
                    // When no status filter is set, only count successful payments as income
                    return e.paymentStatus.toLowerCase() == 'success';
                  }).toList();
                  final totalGross = filtered.fold<double>(0, (p, e) => p + e.gross);
                  final totalCommission = filtered.fold<double>(0, (p, e) => p + e.commission);
                  final totalNet = filtered.fold<double>(0, (p, e) => p + e.net);
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Row(children: [
                          Obx(() => Text('Bhukk commission: ${pc.commissionPercent.value.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.black54))),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Set commission %',
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () async {
                              final ctl = TextEditingController(text: pc.commissionPercent.value.toString());
                              final v = await showDialog<double>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Bhukk commission %'),
                                  content: TextField(
                                    controller: ctl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(helperText: 'Percent (e.g., 10 for 10%)'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () {
                                      final x = double.tryParse(ctl.text.trim());
                                      if (x != null) Navigator.pop(context, x.clamp(0, 100));
                                    }, child: const Text('Save')),
                                  ],
                                ),
                              );
                              if (v != null) pc.updateCommission(v);
                            },
                          ),
                        ])
                      ],
                    ),
                    const SizedBox(height: 8),
                    _responsiveSummaryGrid([
                      _summaryCard('Gross', totalGross, Colors.green.shade700),
                      _summaryCard('Commission', totalCommission, Colors.orange.shade700),
                      _summaryCard('Net Payout', totalNet, Colors.blue.shade700),
                    ], maxItemWidth: 280),
                    const SizedBox(height: 8),
                    _commissionCard(context, pc),
                  ]);
                }),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.black87,
                tabs: const [
                  Tab(text: 'Orders'),
                  Tab(text: 'Settlements'),
                  Tab(text: 'Refunds'),
                  Tab(text: 'Transactions'),
                ],
              )),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TabBarView(children: [
              _ordersTab(pc),
              _settlementsTab(pc),
              _refundsTab(pc),
              _transactionsPanel(pc),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _commissionCard(BuildContext context, PaymentController pc) {
  // Compute dues based on the same filters used for income overview
  final from = pc.filterFrom.value;
  final to = pc.filterTo.value;
  final due = pc.commissionOutstanding(from: from, to: to);
  final paid = pc.totalCommissionPaid(from: from, to: to);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Commission to Bhukk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: due <= 0 ? null : () => _showPayCommissionSheet(context, pc, due),
              icon: const Icon(Icons.account_balance),
              label: Text(due <= 0 ? 'No Due' : 'Pay ₹${due.toStringAsFixed(0)}'),
            )
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 8, children: [
            Chip(label: Text('Outstanding: ₹${due.toStringAsFixed(2)}'), avatar: const Icon(Icons.warning_amber_outlined, size: 18)),
            Chip(label: Text('Paid: ₹${paid.toStringAsFixed(2)}'), avatar: const Icon(Icons.check_circle_outline, size: 18)),
            Obx(() => Chip(label: Text('Rate: ${pc.commissionPercent.value.toStringAsFixed(1)}%'), avatar: const Icon(Icons.percent, size: 18))),
          ])
        ]),
      ),
    );
  }

  Future<void> _showPayCommissionSheet(BuildContext context, PaymentController pc, double defaultAmount) async {
    final amtCtl = TextEditingController(text: defaultAmount.toStringAsFixed(2));
    String method = 'UPI';
    final refCtl = TextEditingController();
  XFile? picked;
  Uint8List? proofBytes;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Pay Commission', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
              const Divider(),
              const Text('Bhukk beneficiary'),
              const SizedBox(height: 4),
              const Text('Bhukk Technologies Pvt Ltd • UPI: bhukk@upi'),
              const Text('Bank: HDFC Bank • A/C: 000111222333 • IFSC: HDFC0001234'),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '₹', labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Method:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: method,
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                  ],
                  onChanged: (v) => setModalState(() { method = v ?? 'UPI'; }),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Optional reference like UTR/Txn ID',
                  child: SizedBox(width: 180, child: TextField(controller: refCtl, decoration: const InputDecoration(labelText: 'Reference'))),
                )
              ]),
              const SizedBox(height: 8),
              // Method specific helper UI
              Builder(builder: (_) {
                Widget content;
                if (method == 'UPI') {
                  content = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    const Text('UPI ID:'),
                    SelectableText('bhukk@upi'),
                    OutlinedButton.icon(
                      onPressed: () async { await Clipboard.setData(const ClipboardData(text: 'bhukk@upi')); Get.snackbar('Copied', 'UPI ID copied', snackPosition: SnackPosition.BOTTOM); },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ]);
                } else if (method == 'Bank Transfer') {
                  content = Wrap(spacing: 8, runSpacing: 8, children: [
                    const Text('Bank:'), const Text('HDFC Bank'), const SizedBox(width: 8),
                    const Text('A/C:'), const SelectableText('000111222333'),
                    OutlinedButton.icon(onPressed: () async { await Clipboard.setData(const ClipboardData(text: '000111222333')); Get.snackbar('Copied', 'Account number copied', snackPosition: SnackPosition.BOTTOM); }, icon: const Icon(Icons.copy, size: 16), label: const Text('Copy A/C')),
                    const SizedBox(width: 8),
                    const Text('IFSC:'), const SelectableText('HDFC0001234'),
                    OutlinedButton.icon(onPressed: () async { await Clipboard.setData(const ClipboardData(text: 'HDFC0001234')); Get.snackbar('Copied', 'IFSC copied', snackPosition: SnackPosition.BOTTOM); }, icon: const Icon(Icons.copy, size: 16), label: const Text('Copy IFSC')),
                  ]);
                } else {
                  content = const Text('Use your card gateway to pay; record the reference/approval code.');
                }
                return Padding(padding: const EdgeInsets.only(top: 4), child: content);
              }),
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    if (!Get.isRegistered<FilePickerController>()) Get.put(FilePickerController());
                    final xf = await FilePickerController.to.pickImage();
                    if (xf != null) {
                      picked = xf;
                      proofBytes = await FilePickerController.to.readBytes(xf);
                      setModalState(() {});
                    }
                  },
                  icon: const Icon(Icons.attachment),
                  label: const Text('Upload proof (screenshot/receipt)'),
                ),
                const SizedBox(width: 8),
                if (picked != null)
                  Expanded(
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(child: Text(picked!.name, overflow: TextOverflow.ellipsis)),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close),
                        onPressed: () { picked = null; proofBytes = null; setModalState(() {}); },
                      )
                    ]),
                  )
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amtCtl.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    await pc.payCommission(amount: amount, method: method, reference: refCtl.text.trim(), from: pc.filterFrom.value, to: pc.filterTo.value, proofBytes: proofBytes, proofName: picked?.name);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Pay'),
                )
              ])
            ]),
          ),
        );
        });
      },
    );
  }


  Widget _transactionsPanel(PaymentController pc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Row(children: [
              Obx(() => DropdownButton<String>(
                    value: pc.transactionDaysFilter.value,
                    items: const [
                      DropdownMenuItem(value: '7', child: Text('Last 7 days')),
                      DropdownMenuItem(value: '30', child: Text('Last 30 days')),
                      DropdownMenuItem(value: 'all', child: Text('All')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      pc.transactionDaysFilter.value = v;
                    },
                  )),
              const SizedBox(width: 12),
              Obx(() => FilterChip(
                    label: const Text('Commission only'),
                    selected: pc.showCommissionOnly.value,
                    onSelected: (v) => pc.showCommissionOnly.value = v,
                  )),
              const SizedBox(width: 8),
              IconButton(onPressed: () => pc.fetchTransactions(), icon: const Icon(Icons.refresh)),
            ])
          ]),
          const SizedBox(height: 12),
          Obx(() {
            // Start from either commission-only or all transactions
            Iterable list = pc.showCommissionOnly.value ? pc.commissionTransactions : pc.transactions;
            // Apply days filter
            final sel = pc.transactionDaysFilter.value;
            if (sel != 'all') {
              final days = int.tryParse(sel) ?? 7;
              final cutoff = DateTime.now().subtract(Duration(days: days));
              list = list.where((t) => t.date.isAfter(cutoff));
            }
            final items = list.toList();
            if (pc.isLoading.value) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('No transactions'));
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final t = items[i];
                final isCredit = t.type == 'credit';
                Color statusColor;
                switch (t.status) {
                  case 'success':
                    statusColor = Colors.green.shade100;
                    break;
                  case 'pending':
                    statusColor = Colors.orange.shade100;
                    break;
                  default:
                    statusColor = Colors.red.shade100;
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(backgroundColor: statusColor, child: Text(t.id.substring(0, 1).toUpperCase())),
                  title: Text(t.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${t.date.toLocal()}'.split(' ')[0]),
                  trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${isCredit ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}', style: TextStyle(color: isCredit ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)), child: Text(t.status, style: const TextStyle(fontSize: 11))),
                    if (!isCredit && (t.proofBytes != null)) ...[
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: () => _showProofDialog(ctx, t),
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('Proof'),
                      ),
                    ],
                  ]),
                );
              },
            );
          })
        ]),
      ),
    ),
  );
  }

  void _showProofDialog(BuildContext context, dynamic tx) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Commission Proof', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (tx.proofBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(tx.proofBytes!, width: 360, height: 360, fit: BoxFit.contain),
              )
            else
              const Text('No proof attached'),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Responsive grid-like wrap for summary cards
  Widget _responsiveSummaryGrid(List<Widget> cards, {double maxItemWidth = 280, double spacing = 8}) {
    return LayoutBuilder(
      builder: (context, cons) {
        final maxW = cons.maxWidth;
        final perRow = (maxW / (maxItemWidth + spacing)).clamp(1, cards.length).floor();
        final itemWidth = ((maxW - spacing * (perRow - 1)) / perRow).clamp(160.0, maxItemWidth);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _ordersTab(PaymentController pc) {
    return Column(children: [
      Row(children: [
        Expanded(child: TextField(onChanged: (v) => pc.paymentSearch.value = v, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search orders...'))),
        const SizedBox(width: 8),
        IconButton(onPressed: () => pc.exportSettlementsCsv(), icon: const Icon(Icons.download)),
        Obx(() => IconButton(
              tooltip: pc.selectionMode.value ? 'Exit selection' : 'Select orders',
              onPressed: pc.toggleSelectionMode,
              icon: Icon(pc.selectionMode.value ? Icons.check_box : Icons.check_box_outline_blank),
            )),
      ]),
      const SizedBox(height: 8),
      // Filters bar (Status on the left as dropdown; Method + Date on the right)
      Obx(() {
        final status = pc.paymentStatusFilter.value; // null means All
        final method = pc.paymentMethodFilter.value; // null means All
        final from = pc.filterFrom.value; final to = pc.filterTo.value;
        return Row(children: [
          // Left: Status dropdown
          DropdownButton<String>(
            value: status ?? 'all',
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'success', child: Text('Success')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'failed', child: Text('Failed')),
            ],
            onChanged: (v) {
              if (v == null || v == 'all') {
                pc.paymentStatusFilter.value = null;
              } else {
                pc.paymentStatusFilter.value = v;
              }
            },
          ),
          const Spacer(),
          // Right: Method dropdown
          DropdownButton<String>(
            value: method ?? 'ALL',
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Methods')),
              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              DropdownMenuItem(value: 'Card', child: Text('Card')),
              DropdownMenuItem(value: 'Wallet', child: Text('Wallet')),
              DropdownMenuItem(value: 'COD', child: Text('COD')),
            ],
            onChanged: (v) {
              if (v == null || v == 'ALL') {
                pc.paymentMethodFilter.value = null;
              } else {
                pc.paymentMethodFilter.value = v;
              }
            },
          ),
          const SizedBox(width: 8),
          Builder(builder: (c) => OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_dateLabel(from, to)),
            onPressed: () => _showModernDateDialog(c, pc),
          )),
        ]);
      }),
      // Selection actions row (only when selection mode is on)
      Obx(() => pc.selectionMode.value
          ? Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(children: [
                ActionChip(
                  label: Text('Select all (${pc.payments.length})'),
                  onPressed: () => pc.selectAllFor(pc.payments),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: Text('Bulk payout (${pc.selectedOrderIds.length})'),
                  onPressed: () {
                    final records = pc.payments.where((e) => pc.selectedOrderIds.contains(e.orderId)).toList();
                    pc.initiatePayoutForOrders(records);
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
              ]),
            )
          : const SizedBox.shrink()),
      const SizedBox(height: 8),
      Expanded(child: Obx(() {
        if (pc.isLoadingPayments.value) return const Center(child: CircularProgressIndicator());
        final list = pc.payments.where((p) {
          final q = pc.paymentSearch.value.toLowerCase();
          if (q.isNotEmpty) return p.orderId.toLowerCase().contains(q) || p.customerName.toLowerCase().contains(q);
          // status filter
          final sf = pc.paymentStatusFilter.value;
          if (sf != null && p.paymentStatus.toLowerCase() != sf) return false;
          // method filter
          final mf = pc.paymentMethodFilter.value;
          if (mf != null && p.paymentMethod.toLowerCase() != mf.toLowerCase()) return false;
          // date filter
          final from = pc.filterFrom.value;
          final to = pc.filterTo.value;
          if (from != null && p.dateTime.isBefore(from)) return false;
          if (to != null && p.dateTime.isAfter(to)) return false;
          return true;
        }).toList();
        if (list.isEmpty) return const Center(child: Text('No payments'));
        return RefreshIndicator(
          onRefresh: () async => pc.refreshPayments(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (s) {
              if (s.metrics.pixels >= s.metrics.maxScrollExtent - 100 && !pc.isLoadingPayments.value && pc.hasMorePayments.value) {
                pc.loadMorePayments();
              }
              return false;
            },
            child: ListView.separated(
              itemCount: list.length + (pc.hasMorePayments.value ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= list.length) return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()));
                final p = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(() => pc.selectionMode.value
                          ? Checkbox(
                              value: pc.selectedOrderIds.contains(p.orderId),
                              onChanged: (_) => pc.toggleSelect(p.orderId),
                              visualDensity: VisualDensity.compact,
                            )
                          : const SizedBox.shrink()),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${p.orderId} — ${p.customerName}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${p.paymentMethod} • ${p.paymentStatus} • ${p.dateTime.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('₹${p.gross.toStringAsFixed(2)}'),
                        Text('Comm ₹${p.commission.toStringAsFixed(2)}'),
                        Text('Net ₹${p.net.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        PopupMenuButton<String>(
                          tooltip: 'Actions',
                          icon: const Icon(Icons.more_horiz),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (value) async {
                            if (value == 'payout') pc.initiatePayoutForOrder(p);
                            if (value == 'copy') {
                await Clipboard.setData(ClipboardData(text: p.orderId));
                Get.snackbar('Copied', 'Order ID ${p.orderId}', snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'payout',
                              child: Row(children: const [Icon(Icons.account_balance_wallet_outlined, size: 18), SizedBox(width: 8), Text('Payout')]),
                            ),
                            const PopupMenuDivider(height: 8),
                            PopupMenuItem(
                              value: 'copy',
                              child: Row(children: const [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Copy Order ID')]),
                            ),
                          ],
                        ),
                      ])
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }))
    ]);
  }

  Widget _settlementsTab(PaymentController pc) {
    return Obx(() {
      final s = pc.settlements;
      if (s.isEmpty) return const Center(child: Text('No settlements'));
      return RefreshIndicator(
        onRefresh: () async => pc.fetchSettlements(force: true),
        child: ListView.separated(
          itemCount: s.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final item = s[idx];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.id),
                    const SizedBox(height: 4),
                    Text('Orders: ${item.orderIds.join(', ')}\nDate: ${item.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Payout ₹${item.payoutAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  if (item.status != SettlementStatus.completed)
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), minimumSize: const Size(72, 32)),
                        onPressed: () => pc.markSettlementPaid(item.id),
                        child: const Text('Mark Paid'),
                      ),
                    )
                  else
                    const SizedBox.shrink()
                ]),
              ]),
            );
          },
        ),
      );
    });
  }

  Widget _refundsTab(PaymentController pc) {
    return Obx(() {
      final r = pc.refunds;
      if (r.isEmpty) return const Center(child: Text('No refunds'));
      return RefreshIndicator(
        onRefresh: () async => pc.fetchRefunds(force: true),
        child: ListView.separated(
          itemCount: r.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final item = r[idx];
            return ListTile(
              title: Text(item.id),
              subtitle: Text('Order: ${item.orderId}\nAmount: ₹${item.amount.toStringAsFixed(2)}'),
              trailing: Wrap(children: [
                Text(item.status.name),
                const SizedBox(width: 8),
                if (item.status == RefundStatus.pending)
                  ElevatedButton(onPressed: () => pc.approveRefund(item.id), child: const Text('Approve'))
                else
                  const SizedBox.shrink()
              ]),
            );
          },
        ),
      );
    });
  }

  String _dateLabel(DateTime? from, DateTime? to) {
    if (from == null && to == null) return 'Date';
    if (from != null && to != null) {
      final f = '${from.toLocal()}'.split(' ')[0];
      final t = '${to.toLocal()}'.split(' ')[0];
      return '$f → $t';
    }
    if (from != null) return '${from.toLocal()}'.split(' ')[0];
    return '${to!.toLocal()}'.split(' ')[0];
  }

  Future<void> _showModernDateDialog(BuildContext context, PaymentController pc) async {
    final now = DateTime.now();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Filter by date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Close')),
              ]),
              const Divider(),
              Wrap(runSpacing: 8, spacing: 8, children: [
                OutlinedButton(
                  onPressed: () {
                    final start = DateTime(now.year, now.month, now.day);
                    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    pc.filterFrom.value = start; pc.filterTo.value = end; Navigator.pop(ctx);
                  },
                  child: const Text('Today'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    pc.filterFrom.value = start; pc.filterTo.value = end; Navigator.pop(ctx);
                  },
                  child: const Text('Last 7 days'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final start = DateTime(now.year, now.month, 1);
                    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                    pc.filterFrom.value = start; pc.filterTo.value = end; Navigator.pop(ctx);
                  },
                  child: const Text('This month'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDialog<DateTimeRange>(
                      context: ctx,
                      builder: (dctx) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
                          child: DateRangePickerDialog(
                            firstDate: DateTime(now.year - 2),
                            lastDate: DateTime(now.year + 1),
                            initialDateRange: (pc.filterFrom.value != null && pc.filterTo.value != null)
                                ? DateTimeRange(start: pc.filterFrom.value!, end: pc.filterTo.value!)
                                : null,
                          ),
                        ),
                      ),
                    );
                    if (picked != null) {
                      pc.filterFrom.value = DateTime(picked.start.year, picked.start.month, picked.start.day);
                      pc.filterTo.value = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
                    }
                    if (Get.isOverlaysOpen) Get.back();
                  },
                  child: const Text('Custom range…'),
                ),
                TextButton.icon(
                  onPressed: () { pc.filterFrom.value = null; pc.filterTo.value = null; Navigator.pop(ctx); },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                )
              ])
            ]),
          ),
        );
      },
    );
  }

}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
