// screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/account/account_controller.dart';
import '../../models/account_model.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  AccountController get controller => Get.find<AccountController>();

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Transactions',
      child: LayoutBuilder(
  builder: (ctx, cons) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    final list = controller.transactionsSorted;
                    if (list.isEmpty) {
                      return const Center(child: Text('No transactions'));
                    }
        return Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = list[i];
                          return ListTile(
                            leading: CircleAvatar(radius: 18, child: Text(t.method.substring(0, 1).toUpperCase())),
                            title: Text('₹${t.amount.toStringAsFixed(2)} • ${t.description}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${t.method} • ${t.status} • ${t.date.toLocal().toString().split(' ').first}'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                  onPressed: () async {
                                    try {
                                      final path = await controller.exportInvoiceText(t);
                                      Get.snackbar('Invoice saved', path, snackPosition: SnackPosition.BOTTOM);
                                    } catch (e) {
                                      Get.snackbar('Invoice', 'Export failed: $e', snackPosition: SnackPosition.BOTTOM);
                                    }
                                  },
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Invoice'),
                                ),
                              ],
                            ),
          onTap: () => _openDetailDialog(t),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Obx(() => Chip(label: Text('Total: ₹${controller.totalSales.toStringAsFixed(2)}'))),
              Obx(() => Chip(label: Text('Successful: ${controller.transactions.where((t) => t.status == 'success').length}'))),
              Obx(() => Chip(label: Text('Payouts Pending: ₹${controller.pendingSettlementAmount.toStringAsFixed(2)}'))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final path = await controller.exportTransactionsCsv();
                  Get.snackbar('Exported', path, snackPosition: SnackPosition.BOTTOM);
                } catch (e) {
                  Get.snackbar('Export failed', '$e', snackPosition: SnackPosition.BOTTOM);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Export All'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final path = await controller.exportRecentTransactionsCsv();
                  Get.snackbar('Recent exported', path, snackPosition: SnackPosition.BOTTOM);
                } catch (e) {
                  Get.snackbar('Export failed', '$e', snackPosition: SnackPosition.BOTTOM);
                }
              },
              icon: const Icon(Icons.download_for_offline),
              label: const Text('Recent 20'),
            ),
          ],
        )
      ],
    );
  }
}

void _openDetailDialog(TransactionModel t) {
  Get.dialog(Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction #${t.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            _row('Date', t.date.toLocal().toString()),
            _row('Amount', '₹${t.amount.toStringAsFixed(2)}'),
            _row('Method', t.method),
            _row('Status', t.status),
            _row('Invoice', t.invoiceId.isEmpty ? '—' : t.invoiceId),
            const SizedBox(height: 8),
            Text('Description', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(t.description.isEmpty ? '—' : t.description),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Get.back(), child: const Text('Close')),
            ])
          ],
        ),
      ),
    ),
  ));
}

Widget _row(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(children: [SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(v))]),
  );
}
