// models/table_model.dart
class TableModel {
  final int tableNumber;
  final int capacity;
  final String status; // Available, Occupied, Reserved
  final String waiter;
  final String orderId; // linked order/reservation id
  final String? notes; // nullable for backward compatibility
  final int? currentGuests; // nullable for backward compatibility
  final DateTime? occupiedSince; // timestamp when became Occupied
  TableModel({
    required this.tableNumber,
    required this.capacity,
    required this.status,
    required this.waiter,
    required this.orderId,
  this.notes = '',
  this.currentGuests = 0,
  this.occupiedSince,
  });
  TableModel copyWith({
    int? tableNumber,
    int? capacity,
    String? status,
    String? waiter,
    String? orderId,
    String? notes,
    int? currentGuests,
    DateTime? occupiedSince,
  }) {
    return TableModel(
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      waiter: waiter ?? this.waiter,
      orderId: orderId ?? this.orderId,
      notes: notes ?? this.notes,
      currentGuests: currentGuests ?? this.currentGuests,
      occupiedSince: occupiedSince ?? this.occupiedSince,
    );
  }

  // Safe getters for nullable legacy handling
  String get notesSafe => notes ?? '';
  int get currentGuestsSafe => currentGuests ?? 0;
  bool get isOccupied => status == 'Occupied';
}
