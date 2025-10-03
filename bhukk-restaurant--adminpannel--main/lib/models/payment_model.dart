// models/payment_model.dart
class PaymentModel {
  final String table;
  final int? bill; // subtotal before discount and taxes
  final String status; // Pending / Paid / Cancelled
  final int? discount; // flat amount discount
  final double? taxRate; // percentage e.g. 0.05 for 5%
  final DateTime? createdAt;
  final List<LineItem>? items;

  PaymentModel({
    required this.table,
    required this.bill,
    required this.status,
    this.discount,
    this.taxRate,
    this.createdAt,
    this.items,
  });

  // Safe accessors with defaults
  List<LineItem> get itemsSafe => items ?? const [];
  int get billSafe => bill ?? 0;
  int get discountSafe => discount ?? 0;
  double get taxRateSafe => taxRate ?? 0.05;
  DateTime get createdAtSafe => createdAt ?? DateTime.now();

  int get subtotal => itemsSafe.isNotEmpty ? itemsSafe.fold(0, (s, i) => s + i.total) : billSafe;
  int get discountApplied => discountSafe.clamp(0, subtotal);
  int get taxable => (subtotal - discountApplied).clamp(0, 1 << 31);
  int get tax => (taxable * taxRateSafe).round();
  int get total => taxable + tax;

  PaymentModel copyWith({
    String? table,
    int? bill,
    String? status,
    int? discount,
    double? taxRate,
    DateTime? createdAt,
    List<LineItem>? items,
  }) {
    return PaymentModel(
      table: table ?? this.table,
      bill: bill ?? this.bill,
      status: status ?? this.status,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}

class LineItem {
  final String name;
  final int qty;
  final int price; // per unit
  const LineItem({required this.name, required this.qty, required this.price});
  int get total => qty * price;
}
