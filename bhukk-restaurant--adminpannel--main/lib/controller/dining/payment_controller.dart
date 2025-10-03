// controller/dining/payment_controller.dart
import 'package:get/get.dart';
import '../../models/payment_model.dart';

class PaymentController extends GetxController {
  var payments = <PaymentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    payments.value = [
      PaymentModel(
        table: 'Table 1',
        bill: 1200,
        status: 'Pending',
        discount: 0,
        taxRate: 0.05,
        createdAt: DateTime.now(),
        items: const [
          LineItem(name: 'Paneer Tikka', qty: 2, price: 250),
          LineItem(name: 'Butter Naan', qty: 4, price: 50),
        ],
      ),
      PaymentModel(
        table: 'Table 2',
        bill: 800,
        status: 'Paid',
        discount: 0,
        taxRate: 0.05,
        createdAt: DateTime.now(),
        items: const [
          LineItem(name: 'Chicken Biryani', qty: 2, price: 300),
          LineItem(name: 'Cola', qty: 2, price: 100),
        ],
      ),
    ];
  }

  void addPayment(PaymentModel payment) {
    payments.add(payment);
  }

  void updatePayment(int index, PaymentModel updated) {
    payments[index] = updated;
  }

  void deletePayment(int index) {
    payments.removeAt(index);
  }

  void applyDiscount(int index, int amount) {
    final p = payments[index];
    payments[index] = p.copyWith(discount: amount);
  }

  void markPaid(int index) {
    final p = payments[index];
    payments[index] = p.copyWith(status: 'Paid');
  }

  // Split a table's bill into two new PaymentModel entries (e.g., even split or by item selection)
  void splitBill(String table, {bool even = true, List<LineItem>? firstItems}) {
    final idx = payments.indexWhere((p) => p.table == table);
    if (idx == -1) return;
    final original = payments[idx];
    if (original.itemsSafe.isEmpty && original.billSafe == 0) return;
    List<LineItem> aItems;
    List<LineItem> bItems;
    if (even) {
      // naive even split by value: assign alternating items
      aItems = [];
      bItems = [];
      for (var i = 0; i < original.itemsSafe.length; i++) {
        (i % 2 == 0 ? aItems : bItems).add(original.itemsSafe[i]);
      }
      if (aItems.isEmpty) aItems = original.itemsSafe.take((original.itemsSafe.length/2).ceil()).toList();
      if (bItems.isEmpty) bItems = original.itemsSafe.skip(aItems.length).toList();
    } else if (firstItems != null && firstItems.isNotEmpty) {
      aItems = firstItems;
      final set = firstItems.toSet();
      bItems = original.itemsSafe.where((e) => !set.contains(e)).toList();
    } else {
      return; // nothing to split
    }
    // Replace original with first part; add second part as new payment record with incremented suffix
    final base = table;
  payments[idx] = original.copyWith(table: '${base}A', items: aItems);
  payments.insert(idx+1, original.copyWith(table: '${base}B', items: bItems));
  }

  // Merge two table bills (by table names) into the first one's record
  void mergeBills(String primaryTable, String secondaryTable) {
    final aIdx = payments.indexWhere((p) => p.table == primaryTable);
    final bIdx = payments.indexWhere((p) => p.table == secondaryTable);
    if (aIdx == -1 || bIdx == -1 || aIdx == bIdx) return;
    final a = payments[aIdx];
    final b = payments[bIdx];
    final mergedItems = [...a.itemsSafe, ...b.itemsSafe];
    payments[aIdx] = a.copyWith(items: mergedItems, discount: (a.discountSafe + b.discountSafe));
    payments.removeAt(bIdx > aIdx ? bIdx : bIdx); // remove secondary
  }
}
