// screens/dining/dining_payment_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/payment_controller.dart';
import '../../models/payment_model.dart';

class DiningPaymentView extends StatelessWidget {
  DiningPaymentView({super.key});
  final PaymentController controller = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dining Payments', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: controller.payments.length,
              itemBuilder: (_, i) {
                final payment = controller.payments[i];
                return ListTile(
                  title: Text(payment.table),
                  subtitle: Text('Subtotal: ₹${payment.subtotal}  •  Discount: ₹${payment.discountApplied}  •  Tax: ₹${payment.tax}  •  Total: ₹${payment.total}  •  Status: ${payment.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.payment, color: Colors.green),
                        onPressed: () {
                          // Example: Mark as paid
                          controller.markPaid(i);
                        },
                        tooltip: 'Mark Paid',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.receipt, color: Colors.blue),
                        onPressed: () {
                          _showReceiptDialog(context, payment);
                        },
                        tooltip: 'Receipt',
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.discount, color: Colors.orange),
                        onPressed: () async {
                          final amount = await _askDiscountAmount(context, payment);
                          if (amount != null) controller.applyDiscount(i, amount);
                        },
                        tooltip: 'Discount',
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

  Future<int?> _askDiscountAmount(BuildContext context, PaymentModel payment) async {
    final controller = TextEditingController(text: payment.discount.toString());
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Discount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Discount Amount',
            helperText: 'Max ₹${payment.subtotal}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null) return;
              final clamped = v.clamp(0, payment.subtotal);
              Navigator.pop<int>(context, clamped);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, PaymentModel p) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Table: ${p.table}'),
                Text('Date: ${p.createdAtSafe}'),
                const Divider(height: 24),
                if (p.itemsSafe.isNotEmpty) ...[
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...p.itemsSafe.map((it) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${it.name}  x${it.qty}')),
                          Text('₹${it.total}'),
                        ],
                      )),
                  const Divider(height: 24),
                ],
                _row('Subtotal', '₹${p.subtotal}'),
                _row('Discount', '- ₹${p.discountApplied}'),
                _row('Tax (${(p.taxRateSafe * 100).toStringAsFixed(0)}%)', '₹${p.tax}'),
                const Divider(height: 24),
                _row('Total', '₹${p.total}', isBold: true),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print / Share'),
                    onPressed: () {
                      // TODO: integrate with printing/sharing plugins
                      Navigator.pop(context);
                      Get.snackbar('Receipt', 'Pretend printing...');
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String k, String v, {bool isBold = false}) {
    final style = TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k, style: style), Text(v, style: style)],
      ),
    );
  }
}
