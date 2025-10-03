// models/refund_model.dart
enum RefundStatus { pending, inProgress, completed }

enum RefundMode { original, wallet, coupon }

String _toSnake(String s) {
  return s.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
}

class RefundModel {
  final String id;
  final String orderId;
  final String reason;
  final double amount;
  final RefundMode mode;
  final RefundStatus status;
  final DateTime date;

  RefundModel({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.amount,
    this.mode = RefundMode.original,
    this.status = RefundStatus.pending,
    required this.date,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      reason: json['reason'] as String,
      amount: (json['amount'] as num).toDouble(),
      mode: RefundMode.values.firstWhere((e) {
        final val = (json['mode'] as String? ?? 'original');
        return e.name == val || _toSnake(e.name) == val;
      }),
      status: RefundStatus.values.firstWhere((e) {
        final val = (json['status'] as String? ?? 'pending');
        return e.name == val || _toSnake(e.name) == val;
      }),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'reason': reason,
        'amount': amount,
  'mode': _toSnake(mode.name),
  'status': _toSnake(status.name),
        'date': date.toIso8601String(),
      };
}
