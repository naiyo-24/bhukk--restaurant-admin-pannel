// models/settlement_model.dart
enum SettlementStatus { pending, processing, completed }

class SettlementModel {
  final String id;
  final DateTime date;
  final List<String> orderIds;
  final double grossAmount;
  final double commission;
  final double payoutAmount;
  final String paymentMethod;
  final SettlementStatus status;

  SettlementModel({
    required this.id,
    required this.date,
    this.orderIds = const [],
    required this.grossAmount,
    required this.commission,
    required this.payoutAmount,
    this.paymentMethod = 'Bank Transfer',
    this.status = SettlementStatus.pending,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      orderIds: List<String>.from(json['orderIds'] ?? []),
      grossAmount: (json['grossAmount'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      payoutAmount: (json['payoutAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? 'Bank Transfer',
      status: SettlementStatus.values.firstWhere((e) => e.name == (json['status'] as String? ?? 'pending')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'orderIds': orderIds,
        'grossAmount': grossAmount,
        'commission': commission,
        'payoutAmount': payoutAmount,
        'paymentMethod': paymentMethod,
        'status': status.name,
      };
}
