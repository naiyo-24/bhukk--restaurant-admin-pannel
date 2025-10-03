// controller/payment/payment_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/payment_transaction_model.dart';
import '../../models/settlement_model.dart';
import '../../models/refund_model.dart';
import 'dart:typed_data';
import '../../utils/download_helper.dart';

class PaymentRecord {
  final String orderId;
  final String customerName;
  final DateTime dateTime;
  final double gross;
  final double commission;
  final double net;
  final String paymentMethod;
  final String paymentStatus;
  final String settlementStatus;

  PaymentRecord({
    required this.orderId,
    required this.customerName,
    required this.dateTime,
    required this.gross,
    required this.commission,
    required this.net,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.settlementStatus,
  });
}


class BankDetailsModel {
  String accountHolder;
  String bankName;
  String accountNumber;
  String ifsc;
  String upi;

  BankDetailsModel({this.accountHolder = '', this.bankName = '', this.accountNumber = '', this.ifsc = '', this.upi = ''});
}

class PaymentController extends GetxController {
  final RxList<PaymentTransactionModel> transactions = <PaymentTransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<BankDetailsModel> bankDetails = BankDetailsModel().obs;
  
  // Payment records (order-wise)
  static const double defaultCommissionPercent = 10.0;
  final RxDouble commissionPercent = defaultCommissionPercent.obs;
  final RxList<PaymentRecord> allPayments = <PaymentRecord>[].obs; // master list
  final RxList<PaymentRecord> payments = <PaymentRecord>[].obs;
  final pagePayments = 1.obs;
  final pageSizePayments = 25.obs;
  final hasMorePayments = true.obs;
  final isLoadingPayments = false.obs;

  // settlements & refunds stored here for the payments screen
  final RxList<SettlementModel> settlements = <SettlementModel>[].obs;
  final RxList<RefundModel> refunds = <RefundModel>[].obs;

  // filters
  final paymentSearch = ''.obs;
  final paymentMethodFilter = Rxn<String>();
  final paymentStatusFilter = Rxn<String>();
  final filterFrom = Rxn<DateTime>();
  final filterTo = Rxn<DateTime>();

  // Selection for bulk actions
  final RxBool selectionMode = false.obs;
  final RxSet<String> selectedOrderIds = <String>{}.obs;
  // UI flags
  final RxBool showCommissionOnly = false.obs;
  // Transactions filter ("7", "30", "all")
  final RxString transactionDaysFilter = '7'.obs;

  // Commission payments tracking
  // We treat any transaction with type 'debit' and note starting with 'Commission' as a commission payment to Bhukk.
  // Helper getters compute totals and dues for the current filtered window.

  // Static Bhukk receiving details (can be moved to remote config later)
  static const String bhukkBeneficiary = 'Bhukk Technologies Pvt Ltd';
  static const String bhukkUpiId = 'bhukk@upi';
  static const String bhukkBankName = 'HDFC Bank';
  static const String bhukkAccountNumber = '000111222333';
  static const String bhukkIfsc = 'HDFC0001234';

  @override
  void onInit() {
    super.onInit();
  // seed with dummy transactions
    transactions.addAll([
      PaymentTransactionModel(id: 't1', date: DateTime.now().subtract(const Duration(days: 1)), amount: 250.0, type: 'credit', status: 'success', note: 'Payout'),
      PaymentTransactionModel(id: 't2', date: DateTime.now().subtract(const Duration(days: 3)), amount: 120.5, type: 'debit', status: 'failed', note: 'Refund'),
      PaymentTransactionModel(id: 't3', date: DateTime.now().subtract(const Duration(days: 10)), amount: 560.0, type: 'credit', status: 'pending', note: 'Scheduled Payout'),
    ]);

  // load persisted bank details
  _loadBankDetails();

  // seed payments/settlements/refunds with some mock data for the screen
  _seedPayments();
  // populate first page
  refreshPayments();
  }

  void _seedPayments() {
    final now = DateTime.now();
    final seed = List.generate(120, (i) {
      final idx = 1000 + i;
      final gross = 100 + (i * 5) + (i % 3 == 0 ? 120 : 0);
      final commission = (commissionPercent.value / 100) * gross;
      final net = gross - commission;
      final method = (i % 4 == 0) ? 'UPI' : (i % 4 == 1 ? 'Card' : (i % 4 == 2 ? 'Wallet' : 'COD'));
      final status = (i % 10 == 0) ? 'failed' : (i % 6 == 0 ? 'pending' : 'success');
      final settlement = (i % 7 == 0) ? SettlementStatus.pending.name : SettlementStatus.completed.name;
      return PaymentRecord(
        orderId: 'ORD-$idx',
        customerName: 'Customer $idx',
        dateTime: now.subtract(Duration(hours: i * 2)),
        gross: gross.toDouble(),
        commission: commission.toDouble(),
        net: net.toDouble(),
        paymentMethod: method,
        paymentStatus: status,
        settlementStatus: settlement,
      );
  });
  allPayments.assignAll(seed);

    settlements.assignAll([
      SettlementModel(id: 'SET-001', date: now.subtract(const Duration(days: 3)), orderIds: ['ORD-1001', 'ORD-1002'], grossAmount: 5000, commission: 500, payoutAmount: 4500, paymentMethod: 'Bank Transfer', status: SettlementStatus.completed),
      SettlementModel(id: 'SET-002', date: now.subtract(const Duration(days: 1)), orderIds: ['ORD-1003'], grossAmount: 1200, commission: 120, payoutAmount: 1080, paymentMethod: 'UPI', status: SettlementStatus.pending),
    ]);

    refunds.assignAll([
      RefundModel(id: 'REF-01', orderId: 'ORD-1003', reason: 'Cancelled', amount: 99.0, mode: RefundMode.original, status: RefundStatus.completed, date: now.subtract(const Duration(days: 2))),
    ]);
  }

  // pagination-aware fetch for payments (stubbed)
  Future<void> fetchPayments({int page = 1, int pageSize = 25, Map<String, dynamic>? filters, bool reset = false}) async {
    if (isLoadingPayments.value) return;
    isLoadingPayments.value = true;
    try {
      if (reset) {
        pagePayments.value = 1;
        payments.clear();
        hasMorePayments.value = true;
      }

      // In real app call API with page/pageSize/filters. Here we simulate delay and slice the seeded list
      await Future.delayed(const Duration(milliseconds: 200));
      final all = allPayments;
      final start = (page - 1) * pageSize;
      final end = (start + pageSize).clamp(0, all.length);
      final slice = all.sublist(start, end);
      if (reset) {
        payments.assignAll(slice);
      } else {
        payments.addAll(slice);
      }
      if (end >= all.length) hasMorePayments.value = false;
    } finally {
      isLoadingPayments.value = false;
    }
  }

  void loadMorePayments() async {
    if (!hasMorePayments.value) return;
    if (isLoadingPayments.value) return;
    pagePayments.value++;
    await fetchPayments(page: pagePayments.value, pageSize: pageSizePayments.value, reset: false);
  }

  // Selection helpers
  void toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
    if (!selectionMode.value) selectedOrderIds.clear();
  }

  void toggleSelect(String orderId) {
    if (selectedOrderIds.contains(orderId)) {
      selectedOrderIds.remove(orderId);
    } else {
      selectedOrderIds.add(orderId);
    }
  }

  void clearSelection() => selectedOrderIds.clear();

  void selectAllFor(List<PaymentRecord> list) {
    selectedOrderIds.addAll(list.map((e) => e.orderId));
  }

  // Simple refresh hooks for UI
  Future<void> refreshPayments() async {
    // In a real app you would re-fetch from API. Here we just simulate.
    await fetchPayments(page: 1, pageSize: pageSizePayments.value, reset: true);
  }

  Future<void> fetchSettlements({bool force = false}) async {
    // Stub: simulate a network refresh
    if (!force) return;
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> fetchRefunds({bool force = false}) async {
    // Stub: simulate a network refresh
    if (!force) return;
    await Future.delayed(const Duration(milliseconds: 300));
  }

  double commissionForPayment(PaymentRecord p) => (defaultCommissionPercent / 100.0) * p.gross;
  double commissionForGross(double gross) => (commissionPercent.value / 100.0) * gross;

  void updateCommission(double percent) {
    commissionPercent.value = percent;
    _recalculateAll();
  }

  void _recalculateAll() {
    // Update allPayments based on new commission percent
    final updatedAll = allPayments.map((p) {
      final commission = commissionForGross(p.gross);
      final net = p.gross - commission;
      return PaymentRecord(
        orderId: p.orderId,
        customerName: p.customerName,
        dateTime: p.dateTime,
        gross: p.gross,
        commission: commission,
        net: net,
        paymentMethod: p.paymentMethod,
        paymentStatus: p.paymentStatus,
        settlementStatus: p.settlementStatus,
      );
    }).toList();
    allPayments.assignAll(updatedAll);

    // Update current page slice as well
    final updatedPage = payments.map((p) {
      final commission = commissionForGross(p.gross);
      final net = p.gross - commission;
      return PaymentRecord(
        orderId: p.orderId,
        customerName: p.customerName,
        dateTime: p.dateTime,
        gross: p.gross,
        commission: commission,
        net: net,
        paymentMethod: p.paymentMethod,
        paymentStatus: p.paymentStatus,
        settlementStatus: p.settlementStatus,
      );
    }).toList();
    payments.assignAll(updatedPage);
  }

  // Commission helpers
  double totalCommissionDue({DateTime? from, DateTime? to}) {
    final list = allPayments.where((p) {
      if (from != null && p.dateTime.isBefore(from)) return false;
      if (to != null && p.dateTime.isAfter(to)) return false;
      // consider only successful payments
      return p.paymentStatus == 'success';
    });
    return list.fold<double>(0, (s, p) => s + commissionForGross(p.gross));
  }

  double totalCommissionPaid({DateTime? from, DateTime? to}) {
    final list = transactions.where((t) {
      if (t.type != 'debit') return false;
      if (!t.note.toLowerCase().startsWith('commission')) return false;
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null && t.date.isAfter(to)) return false;
      return true;
    });
    return list.fold<double>(0, (s, t) => s + t.amount);
  }

  double commissionOutstanding({DateTime? from, DateTime? to}) {
    final due = totalCommissionDue(from: from, to: to);
    final paid = totalCommissionPaid(from: from, to: to);
    final out = due - paid;
    return out < 0 ? 0 : out;
  }

  Future<void> payCommission({required double amount, required String method, String? reference, DateTime? from, DateTime? to, Uint8List? proofBytes, String? proofName}) async {
    // Record as a debit transaction with a note including method and optional reference.
    final id = 'COMM-${DateTime.now().millisecondsSinceEpoch}';
    final note = 'Commission to Bhukk ($method)${reference != null && reference.isNotEmpty ? ' Ref: $reference' : ''}';
    final tx = PaymentTransactionModel(id: id, date: DateTime.now(), amount: amount, type: 'debit', status: 'success', note: note, proofBytes: proofBytes, proofName: proofName);
    transactions.insert(0, tx);
    // In a real app call API to process payment and persist; here we simulate short delay
    await Future.delayed(const Duration(milliseconds: 300));
    Get.snackbar('Commission', 'Paid ₹${amount.toStringAsFixed(2)} via $method', snackPosition: SnackPosition.BOTTOM);
  }

  List<PaymentTransactionModel> get commissionTransactions => transactions.where((t) => t.type == 'debit' && t.note.toLowerCase().startsWith('commission')).toList();

  // Refund operations
  Future<bool> triggerRefund(String refundId) async {
  final idx = refunds.indexWhere((r) => r.id == refundId);
  if (idx < 0) return false;
  final current = refunds[idx];
  refunds[idx] = RefundModel(id: current.id, orderId: current.orderId, reason: current.reason, amount: current.amount, mode: current.mode, status: RefundStatus.inProgress, date: current.date);
  await Future.delayed(const Duration(milliseconds: 400));
  final updated = refunds[idx];
  refunds[idx] = RefundModel(id: updated.id, orderId: updated.orderId, reason: updated.reason, amount: updated.amount, mode: updated.mode, status: RefundStatus.completed, date: updated.date);
    Get.snackbar('Refund', 'Refund $refundId completed', snackPosition: SnackPosition.BOTTOM);
    return true;
  }

  Future<bool> approveRefund(String refundId) async {
    // Alias for trigger in stub
    return triggerRefund(refundId);
  }

  /// Create a settlement covering multiple orders
  Future<void> initiatePayoutForOrders(List<PaymentRecord> records) async {
    if (records.isEmpty) return;
    try {
      final id = 'SET-${DateTime.now().millisecondsSinceEpoch}';
      final gross = records.fold<double>(0, (s, r) => s + r.gross);
      final commission = records.fold<double>(0, (s, r) => s + r.commission);
      final payout = records.fold<double>(0, (s, r) => s + r.net);
      final orderIds = records.map((e) => e.orderId).toList();
      final s = SettlementModel(
        id: id,
        date: DateTime.now(),
        orderIds: orderIds,
        grossAmount: gross,
        commission: commission,
        payoutAmount: payout,
        paymentMethod: 'Mixed',
        status: SettlementStatus.processing,
      );
      settlements.insert(0, s);
      for (final rec in records) {
        final idx = payments.indexWhere((p) => p.orderId == rec.orderId);
        if (idx >= 0) {
          final p = payments[idx];
          payments[idx] = PaymentRecord(
            orderId: p.orderId,
            customerName: p.customerName,
            dateTime: p.dateTime,
            gross: p.gross,
            commission: p.commission,
            net: p.net,
            paymentMethod: p.paymentMethod,
            paymentStatus: p.paymentStatus,
            settlementStatus: SettlementStatus.processing.name,
          );
        }
      }
      Get.snackbar('Payout', 'Bulk payout initiated for ${records.length} orders', snackPosition: SnackPosition.BOTTOM);
      await Future.delayed(const Duration(seconds: 1));
      await markSettlementPaid(id);
      clearSelection();
      selectionMode.value = false;
    } catch (e) {
      Get.snackbar('Payout Error', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Settlement exports
  Future<void> exportSettlementsCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('SettlementID,Date,Orders,Gross,Commission,Payout,Method,Status');
    for (final s in settlements) {
      buffer.writeln('${s.id},${s.date.toIso8601String()},"${s.orderIds.join('|')}",${s.grossAmount},${s.commission},${s.payoutAmount},${s.paymentMethod},${s.status.name}');
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    try {
      final saved = await saveFile(bytes, 'settlements.csv');
      Get.snackbar('Export', 'Settlements exported: ${saved ?? 'downloaded'}', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void updateBankDetails(BankDetailsModel details) {
    bankDetails.value = details;
  // persist
  _saveBankDetails(details);
  Get.snackbar('Saved', 'Bank/UPI details updated', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> fetchTransactions({int page = 1}) async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    // stub: in real app fetch from API and append/refresh
    isLoading.value = false;
  }

  void downloadReport(String format) {
    if (format.toLowerCase() == 'pdf') {
      _generatePdf();
    } else if (format.toLowerCase() == 'excel') {
      _generateExcel();
    } else {
      Get.snackbar('Download', '$format download is coming soon', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _saveBankDetails(BankDetailsModel details) async {
    try {
      // prefer secure storage
      final secure = FlutterSecureStorage();
      final json = jsonEncode({
        'accountHolder': details.accountHolder,
        'bankName': details.bankName,
        'accountNumber': details.accountNumber,
        'ifsc': details.ifsc,
        'upi': details.upi,
      });
      await secure.write(key: 'bank_details', value: json);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadBankDetails() async {
    try {
      final secure = FlutterSecureStorage();
      final s = await secure.read(key: 'bank_details');
      if (s == null || s.isEmpty) {
        // fallback
        final sp = await SharedPreferences.getInstance();
        final s2 = sp.getString('bank_details');
        if (s2 != null && s2.isNotEmpty) {
          final m2 = jsonDecode(s2) as Map<String, dynamic>;
          bankDetails.value = BankDetailsModel(
            accountHolder: (m2['accountHolder'] ?? '') as String,
            bankName: (m2['bankName'] ?? '') as String,
            accountNumber: (m2['accountNumber'] ?? '') as String,
            ifsc: (m2['ifsc'] ?? '') as String,
            upi: (m2['upi'] ?? '') as String,
          );
        }
      } else {
        final m = jsonDecode(s) as Map<String, dynamic>;
        bankDetails.value = BankDetailsModel(
          accountHolder: (m['accountHolder'] ?? '') as String,
          bankName: (m['bankName'] ?? '') as String,
          accountNumber: (m['accountNumber'] ?? '') as String,
          ifsc: (m['ifsc'] ?? '') as String,
          upi: (m['upi'] ?? '') as String,
        );
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _generatePdf() async {
    try {
      final doc = pw.Document();

      doc.addPage(pw.MultiPage(build: (pw.Context ctx) {
        return [
          pw.Header(level: 0, child: pw.Text('Transaction Report')),
          pw.SizedBox(height: 8),
          pw.Text('Bank/UPI Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: 'Account Holder: ${bankDetails.value.accountHolder}'),
          pw.Bullet(text: 'Bank: ${bankDetails.value.bankName}'),
          pw.Bullet(text: 'Account: ${bankDetails.value.accountNumber}'),
          pw.Bullet(text: 'IFSC: ${bankDetails.value.ifsc}'),
          pw.Bullet(text: 'UPI: ${bankDetails.value.upi}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            data: <List<String>>[
              ['ID', 'Date', 'Type', 'Amount', 'Status', 'Note'],
              ...transactions.map((t) => [t.id, t.date.toLocal().toString().split(' ')[0], t.type, t.amount.toStringAsFixed(2), t.status, t.note]),
            ],
          ),
        ];
      }));

      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'transactions_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      Get.snackbar('PDF Error', 'Could not generate PDF: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _generateExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow(['ID', 'Date', 'Type', 'Amount', 'Status', 'Note']);
      for (final t in transactions) {
        sheet.appendRow([t.id, t.date.toLocal().toString().split(' ')[0], t.type, t.amount.toStringAsFixed(2), t.status, t.note]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        Get.snackbar('Excel Error', 'Failed to encode Excel', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // try to open the file via url_launcher
      final uri = Uri.file(path);
      try {
        await launchUrl(uri);
        return;
      } catch (_) {
        // if cannot open, just show path
      }

      Get.snackbar('Saved', 'Excel saved to $path', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
    } catch (e) {
      Get.snackbar('Excel Error', 'Could not generate Excel: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Create a settlement/payout for a single payment record (stubbed).
  Future<void> initiatePayoutForOrder(PaymentRecord record) async {
    try {
      // create a settlement entry for this order
      final id = 'SET-${DateTime.now().millisecondsSinceEpoch}';
      final s = SettlementModel(
        id: id,
        date: DateTime.now(),
        orderIds: [record.orderId],
        grossAmount: record.gross,
        commission: record.commission,
        payoutAmount: record.net,
        paymentMethod: record.paymentMethod,
        status: SettlementStatus.processing,
      );
      settlements.insert(0, s);
      // mark the payment's settlementStatus locally
      final idx = payments.indexWhere((p) => p.orderId == record.orderId);
      if (idx >= 0) {
        final p = payments[idx];
        payments[idx] = PaymentRecord(
          orderId: p.orderId,
          customerName: p.customerName,
          dateTime: p.dateTime,
          gross: p.gross,
          commission: p.commission,
          net: p.net,
          paymentMethod: p.paymentMethod,
          paymentStatus: p.paymentStatus,
          settlementStatus: SettlementStatus.processing.name,
        );
      }
      Get.snackbar('Payout', 'Payout initiated for ${record.orderId}', snackPosition: SnackPosition.BOTTOM);
      // simulate async settlement completion
      await Future.delayed(const Duration(seconds: 1));
      await markSettlementPaid(id);
    } catch (e) {
      Get.snackbar('Payout Error', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> markSettlementPaid(String settlementId) async {
    final idx = settlements.indexWhere((s) => s.id == settlementId);
    if (idx < 0) return;
    final cur = settlements[idx];
    settlements[idx] = SettlementModel(id: cur.id, date: cur.date, orderIds: cur.orderIds, grossAmount: cur.grossAmount, commission: cur.commission, payoutAmount: cur.payoutAmount, paymentMethod: cur.paymentMethod, status: SettlementStatus.completed);
    Get.snackbar('Settlement', 'Settlement ${cur.id} marked completed', snackPosition: SnackPosition.BOTTOM);
  }
}
