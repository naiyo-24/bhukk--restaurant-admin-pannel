// models/account_model.dart
enum DocumentStatus { verified, pending, rejected }

class DocumentModel {
  final String id;
  final String name;
  DocumentStatus status;

  DocumentModel({required this.id, required this.name, this.status = DocumentStatus.pending});
  
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
      };
  
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = DocumentStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => DocumentStatus.pending,
    );
    return DocumentModel(id: json['id'] as String, name: json['name'] as String, status: status);
  }
}

class AccountModel {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String operatingHours;
  String? logoPath;
  // Banking & settlement
  String bankAccountNo;
  String bankIfsc;
  String bankName;
  String? upiId;
  SettlementCycle settlementCycle;

  AccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.operatingHours,
    this.logoPath,
  this.bankAccountNo = '',
  this.bankIfsc = '',
  this.bankName = '',
  this.upiId,
  this.settlementCycle = SettlementCycle.weekly,
  });

  AccountModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? operatingHours,
    String? logoPath,
    String? bankAccountNo,
    String? bankIfsc,
    String? bankName,
    String? upiId,
    SettlementCycle? settlementCycle,
  }) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      logoPath: logoPath ?? this.logoPath,
      bankAccountNo: bankAccountNo ?? this.bankAccountNo,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      upiId: upiId ?? this.upiId,
      settlementCycle: settlementCycle ?? this.settlementCycle,
    );
  }
  
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'operatingHours': operatingHours,
        'logoPath': logoPath,
        'bankAccountNo': bankAccountNo,
        'bankIfsc': bankIfsc,
        'bankName': bankName,
        'upiId': upiId,
        'settlementCycle': settlementCycle.name,
      };
  
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      operatingHours: json['operatingHours'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      bankAccountNo: json['bankAccountNo'] as String? ?? '',
      bankIfsc: json['bankIfsc'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      upiId: json['upiId'] as String?,
      settlementCycle: _settlementFromString(json['settlementCycle'] as String?),
    );
  }
}

enum SettlementCycle { daily, weekly, monthly }

SettlementCycle _settlementFromString(String? v) {
  switch ((v ?? 'weekly').toLowerCase()) {
    case 'daily':
      return SettlementCycle.daily;
    case 'monthly':
      return SettlementCycle.monthly;
    default:
      return SettlementCycle.weekly;
  }
}

class TransactionModel {
  final String id;
  final DateTime date;
  final double amount;
  final String method; // UPI/Card/COD/Wallet
  final String status; // success/failed/refund
  final String description;
  final String invoiceId;

  TransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
    required this.description,
    required this.invoiceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'method': method,
        'status': status,
        'description': description,
        'invoiceId': invoiceId,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        method: json['method'] as String? ?? 'UPI',
        status: json['status'] as String? ?? 'success',
        description: json['description'] as String? ?? '',
        invoiceId: json['invoiceId'] as String? ?? '',
      );
}

class PayoutModel {
  final String id;
  final DateTime scheduledOn;
  final double amount;
  final String status; // pending/processing/paid/failed
  final String reference;

  PayoutModel({required this.id, required this.scheduledOn, required this.amount, required this.status, required this.reference});

  PayoutModel copyWith({
    String? id,
    DateTime? scheduledOn,
    double? amount,
    String? status,
    String? reference,
  }) {
    return PayoutModel(
      id: id ?? this.id,
      scheduledOn: scheduledOn ?? this.scheduledOn,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      reference: reference ?? this.reference,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduledOn': scheduledOn.toIso8601String(),
        'amount': amount,
        'status': status,
        'reference': reference,
      };

  factory PayoutModel.fromJson(Map<String, dynamic> json) => PayoutModel(
        id: json['id'] as String,
        scheduledOn: DateTime.tryParse(json['scheduledOn'] as String? ?? '') ?? DateTime.now(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'pending',
        reference: json['reference'] as String? ?? '',
      );
}

class DocumentApplicationModel {
  final String id;
  final String documentName; // which document to build/apply
  final String applicantName;
  final String email;
  final String phone;
  final String notes;
  final DateTime createdAt;
  final String status; // submitted, in_review, completed

  DocumentApplicationModel({
    required this.id,
    required this.documentName,
    required this.applicantName,
    required this.email,
    required this.phone,
    this.notes = '',
    required this.createdAt,
    this.status = 'submitted',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentName': documentName,
        'applicantName': applicantName,
        'email': email,
        'phone': phone,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory DocumentApplicationModel.fromJson(Map<String, dynamic> json) => DocumentApplicationModel(
        id: json['id'] as String,
        documentName: json['documentName'] as String? ?? '',
        applicantName: json['applicantName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        status: json['status'] as String? ?? 'submitted',
      );
}
