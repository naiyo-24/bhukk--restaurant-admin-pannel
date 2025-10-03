// controller/account/account_controller.dart
import 'dart:convert';
import 'dart:io' show Directory, File; // conditional web guard
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/account_model.dart';

class AccountController extends GetxController {
  final account = AccountModel(
    id: 'acct_1',
    name: 'Bhukk Restaurant',
    email: 'contact@bhukk.example',
    phone: '+18001234567',
    address: '123 Food Street, City',
    operatingHours: 'Mon-Sun: 10:00 - 22:00',
  logoPath: null,
  bankAccountNo: '123456789012',
  bankIfsc: 'HDFC0001234',
  bankName: 'HDFC Bank',
  upiId: 'bhukk@hdfc',
  settlementCycle: SettlementCycle.weekly,
  ).obs;

  final documents = <DocumentModel>[].obs;
  final isSaving = false.obs;
  final applications = <DocumentApplicationModel>[].obs;
  final hasMissingDocs = false.obs; // drives sidebar indicator
  final transactions = <TransactionModel>[].obs;
  final payouts = <PayoutModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final acctJson = sp.getString('account_model');
      if (acctJson != null) {
        final map = jsonDecode(acctJson) as Map<String, dynamic>;
        account.value = AccountModel.fromJson(map);
      }

  final docsJson = sp.getStringList('account_documents');
      if (docsJson != null) {
        documents.clear();
        for (final d in docsJson) {
          final map = jsonDecode(d) as Map<String, dynamic>;
          documents.add(DocumentModel.fromJson(map));
        }
      } else {
        // seed defaults if none stored
        documents.addAll([
          DocumentModel(id: 'd1', name: 'Business License', status: DocumentStatus.verified),
          DocumentModel(id: 'd2', name: 'GST Certificate', status: DocumentStatus.pending),
          DocumentModel(id: 'd3', name: 'FSSAI', status: DocumentStatus.rejected),
        ]);
      }
      // load applications
      final appsJson = sp.getStringList('document_applications');
      if (appsJson != null) {
        applications.clear();
        for (final a in appsJson) {
          final map = jsonDecode(a) as Map<String, dynamic>;
          applications.add(DocumentApplicationModel.fromJson(map));
        }
      }

      // load transactions
      final txJson = sp.getStringList('account_transactions');
      if (txJson != null) {
        transactions.clear();
        for (final t in txJson) {
          final map = jsonDecode(t) as Map<String, dynamic>;
          transactions.add(TransactionModel.fromJson(map));
        }
      } else {
        transactions.addAll(List.generate(10, (i) => TransactionModel(
              id: 'tx_${1000 + i}',
              date: DateTime.now().subtract(Duration(days: i)),
              amount: 500 + i * 37.5,
              method: i.isEven ? 'UPI' : 'Card',
              status: 'success',
              description: 'Order #${2000 + i}',
              invoiceId: 'INV-${2000 + i}',
            )));
      }

      // load payouts
      final poJson = sp.getStringList('account_payouts');
      if (poJson != null) {
        payouts.clear();
        for (final p in poJson) {
          final map = jsonDecode(p) as Map<String, dynamic>;
          payouts.add(PayoutModel.fromJson(map));
        }
      } else {
        payouts.addAll([
          PayoutModel(id: 'po_1', scheduledOn: DateTime.now().add(const Duration(days: 1)), amount: 3250.0, status: 'pending', reference: 'SET-001'),
          PayoutModel(id: 'po_2', scheduledOn: DateTime.now().subtract(const Duration(days: 2)), amount: 2890.0, status: 'paid', reference: 'SET-000'),
        ]);
      }

      _recomputeMissingDocs();
    } catch (_) {
      documents.addAll([
        DocumentModel(id: 'd1', name: 'Business License', status: DocumentStatus.verified),
        DocumentModel(id: 'd2', name: 'GST Certificate', status: DocumentStatus.pending),
        DocumentModel(id: 'd3', name: 'FSSAI', status: DocumentStatus.rejected),
      ]);
    }
  }

  void updateProfile(AccountModel updated) {
    account.value = updated;
  }

  /// Public method used by UI to update whole account model
  void updateAccount(AccountModel updatedAccount) {
    account.value = updatedAccount;
    // persist immediately
    save();
  }

  void updateDocumentStatus(String id, DocumentStatus status) {
    final idx = documents.indexWhere((d) => d.id == id);
    if (idx != -1) {
      documents[idx].status = status;
      documents.refresh();
  _recomputeMissingDocs();
    }
  }

  /// Stub for uploading documents; stores a placeholder DocumentModel and marks pending
  Future<void> uploadDocument(String docName, dynamic file) async {
    // file is dynamic for now — UI passes a File or platform-specific object
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newDoc = DocumentModel(id: id, name: docName, status: DocumentStatus.pending);
    documents.add(newDoc);
    documents.refresh();
    _recomputeMissingDocs();
    await save();
  }

  void _recomputeMissingDocs() {
    // Missing if any not verified
    hasMissingDocs.value = documents.any((d) => d.status != DocumentStatus.verified);
  }

  Future<void> applyForDocument({required String documentName, required String applicantName, required String email, required String phone, String notes = ''}) async {
    final id = 'app_${DateTime.now().microsecondsSinceEpoch}';
    final app = DocumentApplicationModel(
      id: id,
      documentName: documentName,
      applicantName: applicantName,
      email: email,
      phone: phone,
      notes: notes,
      createdAt: DateTime.now(),
    );
    applications.add(app);
    await _persistApplications();
    Get.snackbar('Application submitted', 'Applied for $documentName', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _persistApplications() async {
    final sp = await SharedPreferences.getInstance();
    final list = applications.map((e) => jsonEncode(e.toJson())).toList();
    await sp.setStringList('document_applications', list);
  }

  Future<void> _persistTransactions() async {
    final sp = await SharedPreferences.getInstance();
    final list = transactions.map((e) => jsonEncode(e.toJson())).toList();
    await sp.setStringList('account_transactions', list);
  }

  Future<void> _persistPayouts() async {
    final sp = await SharedPreferences.getInstance();
    final list = payouts.map((e) => jsonEncode(e.toJson())).toList();
    await sp.setStringList('account_payouts', list);
  }

  Future<void> save() async {
    isSaving.value = true;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('account_model', jsonEncode(account.value.toJson()));
      final docsJson = documents.map((d) => jsonEncode(d.toJson())).toList();
      await sp.setStringList('account_documents', docsJson);
  await _persistApplications();
  await _persistTransactions();
  await _persistPayouts();
      await Future.delayed(const Duration(milliseconds: 400));
      Get.snackbar('Account', 'Profile saved', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Account', 'Save failed: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  // Helpers for UI
  void setSettlementCycle(SettlementCycle cycle) {
    account.value = account.value.copyWith(settlementCycle: cycle);
    account.refresh();
  }

  void updateBankDetails({String? accNo, String? ifsc, String? bank, String? upi}) {
    account.value = account.value.copyWith(bankAccountNo: accNo, bankIfsc: ifsc, bankName: bank, upiId: upi);
    account.refresh();
  }

  List<TransactionModel> get transactionsSorted => [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  List<PayoutModel> get pendingPayouts => payouts.where((p) => p.status == 'pending' || p.status == 'processing').toList();

  // Summaries used by UI/exports
  double get totalSales => transactions.fold<double>(0, (s, t) => s + (t.status == 'success' ? t.amount : 0));
  double get totalPayoutsPaid => payouts.where((p) => p.status == 'paid').fold<double>(0, (s, p) => s + p.amount);
  double get pendingSettlementAmount => pendingPayouts.fold<double>(0, (s, p) => s + p.amount);

  /// Mark a payout as paid and persist
  Future<void> markPayoutPaid(String payoutId) async {
    final idx = payouts.indexWhere((p) => p.id == payoutId);
    if (idx == -1) return;
    payouts[idx] = payouts[idx].copyWith(status: 'paid');
    payouts.refresh();
    await _persistPayouts();
    Get.snackbar('Payout', 'Marked as paid', snackPosition: SnackPosition.BOTTOM);
  }

  /// Generate payouts according to the current settlement cycle using existing transactions
  /// This is a local simulator: it groups recent successful transactions and schedules a payout entry.
  Future<void> generateNextPayout() async {
    final tx = transactionsSorted.where((t) => t.status == 'success').toList();
    if (tx.isEmpty) return;
    DateTime start;
    final now = DateTime.now();
    switch (account.value.settlementCycle) {
      case SettlementCycle.daily:
        start = DateTime(now.year, now.month, now.day);
        break;
      case SettlementCycle.weekly:
        final weekday = now.weekday; // 1..7
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        break;
      case SettlementCycle.monthly:
        start = DateTime(now.year, now.month, 1);
        break;
    }
    final periodTx = tx.where((t) => t.date.isAfter(start) || t.date.isAtSameMomentAs(start)).toList();
    if (periodTx.isEmpty) {
      Get.snackbar('Payouts', 'No transactions in current settlement window', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final amt = periodTx.fold<double>(0, (s, t) => s + t.amount);
    final id = 'po_${DateTime.now().millisecondsSinceEpoch}';
    final ref = 'SET-${(payouts.length + 1).toString().padLeft(3, '0')}';
    final scheduled = now.add(const Duration(days: 1));
    payouts.add(PayoutModel(id: id, scheduledOn: scheduled, amount: amt, status: 'pending', reference: ref));
    payouts.refresh();
    await _persistPayouts();
  final scheduledStr = scheduled.toLocal().toString().split(' ').first;
  Get.snackbar('Payouts', 'Scheduled new payout ₹${amt.toStringAsFixed(2)} for $scheduledStr', snackPosition: SnackPosition.BOTTOM);
  }

  // Export helpers (non-web: save to temp dir and return path)
  Future<String> exportTransactionsCsv({List<TransactionModel>? list, String fileName = 'transactions.csv'}) async {
    final items = (list ?? transactionsSorted);
    final buf = StringBuffer('id,date,amount,method,status,description,invoiceId\n');
    for (final t in items) {
      buf.writeln('${t.id},${t.date.toIso8601String()},${t.amount.toStringAsFixed(2)},${t.method},${t.status},"${t.description}",${t.invoiceId}');
    }
    return _saveTextToTemp(buf.toString(), fileName);
  }

  Future<String> exportPayoutsCsv({List<PayoutModel>? list, String fileName = 'payouts.csv'}) async {
    final items = (list ?? payouts);
    final buf = StringBuffer('id,scheduledOn,amount,status,reference\n');
    for (final p in items) {
      buf.writeln('${p.id},${p.scheduledOn.toIso8601String()},${p.amount.toStringAsFixed(2)},${p.status},${p.reference}');
    }
    return _saveTextToTemp(buf.toString(), fileName);
  }

  /// Export most recent 20 transactions as CSV; convenience for the UI list.
  Future<String> exportRecentTransactionsCsv({int take = 20}) {
    final list = transactionsSorted.take(take).toList();
    return exportTransactionsCsv(list: list, fileName: 'transactions_recent.csv');
  }

  Future<String> exportInvoiceText(TransactionModel t, {String? fileName}) async {
  final inv = t.invoiceId.isNotEmpty ? t.invoiceId : t.id;
  final name = fileName ?? 'invoice_$inv.txt';
  final content = 'Invoice $inv\nDate: ${t.date}\nAmount: ₹${t.amount.toStringAsFixed(2)}\nMethod: ${t.method}\nStatus: ${t.status}\nDescription: ${t.description}\n';
    return _saveTextToTemp(content, name);
  }

  Future<String> _saveTextToTemp(String content, String fileName) async {
    try {
      if (kIsWeb) {
        // On web: prompt user to save via file selector (downloads folder, etc.)
        final location = await getSaveLocation(suggestedName: fileName);
        if (location == null) throw 'Save cancelled';
        final data = XFile.fromData(
          Uint8List.fromList(content.codeUnits),
          name: fileName,
          mimeType: 'text/plain',
        );
        await data.saveTo(location.path);
        return location.path;
      } else {
        final tmp = Directory.systemTemp;
        final file = File('${tmp.path}/$fileName');
        await file.writeAsString(content);
        return file.path;
      }
    } catch (e) {
      rethrow;
    }
  }
}
