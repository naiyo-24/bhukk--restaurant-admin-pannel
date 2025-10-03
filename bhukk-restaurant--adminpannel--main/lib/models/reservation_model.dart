// models/reservation_model.dart
class ReservationModel {
  final String id;
  final String customer;
  final DateTime dateTime;
  final int guests;
  final List<String> tables;
  final String status;
  ReservationModel({
    required this.id,
    required this.customer,
    required this.dateTime,
    required this.guests,
    required this.tables,
    required this.status,
  });
  ReservationModel copyWith({String? customer, DateTime? dateTime, int? guests, List<String>? tables, String? status}) {
    return ReservationModel(
      id: id,
      customer: customer ?? this.customer,
      dateTime: dateTime ?? this.dateTime,
      guests: guests ?? this.guests,
      tables: tables ?? this.tables,
      status: status ?? this.status,
    );
  }
}
