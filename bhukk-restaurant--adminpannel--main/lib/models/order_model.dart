// models/order_model.dart

enum OrderStatus { pending, delivered, cancelled }

enum OrderSource { food, dining, liquor }

class OrderItem {
  final String name;
  final int qty;
  final double price;
  OrderItem({required this.name, required this.qty, required this.price});
}

class OrderModel {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final DateTime dateTime;
  final List<OrderItem> items;
  final OrderStatus status;
  final OrderSource source;
  final int? tableNumber; // for dining orders

  OrderModel({
    required this.id,
    required this.customerName,
    this.phone = '',
    this.address = '',
    required this.dateTime,
    this.items = const [],
  this.status = OrderStatus.pending,
  this.source = OrderSource.food,
  this.tableNumber,
  });

  double get _positiveSubtotal => items.where((e) => e.price >= 0).fold(0.0, (p, e) => p + e.price * e.qty);
  double get _adjustments => items.where((e) => e.price < 0).fold(0.0, (p, e) => p + e.price * e.qty);
  double get subtotal => _positiveSubtotal + _adjustments; // displayed raw subtotal including adjustments
  double get tax => _positiveSubtotal * 0.07; // tax only on positive line items
  double get total => _positiveSubtotal + tax + _adjustments;

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? address,
    DateTime? dateTime,
    List<OrderItem>? items,
    OrderStatus? status,
  OrderSource? source,
  int? tableNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      status: status ?? this.status,
  source: source ?? this.source,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }
}
