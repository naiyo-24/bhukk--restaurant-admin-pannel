// models/payment_transaction_model.dart
import 'dart:typed_data';

class PaymentTransactionModel {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String status; // 'success'|'pending'|'failed'
  final String note;
  // Optional proof attachment (e.g., screenshot/receipt). Stored in-memory for simplicity.
  final Uint8List? proofBytes;
  final String? proofName;

  PaymentTransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
    this.note = '',
    this.proofBytes,
    this.proofName,
  });
}
