// controller/earnings/earnings_controller.dart
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../../utils/download_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../models/order_model.dart';
import '../../models/settlement_model.dart';
import '../../models/refund_model.dart';

// Simple service stub - replace with actual API client
class EarningsService {
  Future<List<OrderModel>> fetchOrders({int page = 1, int pageSize = 50, Map<String, dynamic>? filters}) async {
    // TODO: replace with API call
    await Future.delayed(const Duration(milliseconds: 200));
    // generate mock orders for now
    final now = DateTime.now();
    return List.generate(20, (i) {
      final idx = i + (page - 1) * pageSize + 1;
      return OrderModel(
        id: 'ORD-${1000 + idx}',
        customerName: 'Customer $idx',
        phone: '+91-90000-${(1000 + idx).toString().padLeft(4, '0')}',
        address: 'Some address $idx',
        dateTime: now.subtract(Duration(hours: idx * 2)),
        items: [OrderItem(name: 'Item A', qty: 1 + (i % 3), price: 99.0 + i)],
        status: i % 3 == 0 ? OrderStatus.delivered : (i % 3 == 1 ? OrderStatus.pending : OrderStatus.cancelled),
        source: i % 2 == 0 ? OrderSource.food : OrderSource.dining,
      );
    });
  }

  Future<List<SettlementModel>> fetchSettlements({int page = 1, int pageSize = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      SettlementModel(id: 'SET-001', date: DateTime.now().subtract(const Duration(days: 3)), orderIds: ['ORD-1001', 'ORD-1002'], grossAmount: 5000, commission: 500, payoutAmount: 4500, paymentMethod: 'Bank Transfer', status: SettlementStatus.completed),
      SettlementModel(id: 'SET-002', date: DateTime.now().subtract(const Duration(days: 1)), orderIds: ['ORD-1003'], grossAmount: 1200, commission: 120, payoutAmount: 1080, paymentMethod: 'UPI', status: SettlementStatus.pending),
    ];
  }

  Future<List<RefundModel>> fetchRefunds({int page = 1, int pageSize = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      RefundModel(id: 'REF-01', orderId: 'ORD-1003', reason: 'Cancelled', amount: 99.0, mode: RefundMode.original, status: RefundStatus.completed, date: DateTime.now().subtract(const Duration(days: 2))),
    ];
  }
}

class EarningsController extends GetxController {
  final service = EarningsService();

  // UI range selector
  final selectedRange = 'Weekly'.obs;

  // chart series
  final weekData = <double>[1200, 1500, 1100, 1700, 1400, 1900, 2100].obs;
  final monthData = <double>[22000, 18000, 26000, 24000, 30000, 28000].obs;
  final yearData = <double>[240000, 260000, 280000, 300000, 320000, 340000].obs;

  // orders and pagination
  final orders = <OrderModel>[].obs;
  final page = 1.obs;
  final pageSize = 20.obs;
  final hasMore = true.obs;
  final isLoadingOrders = false.obs;

  // settlements & refunds
  final settlements = <SettlementModel>[].obs;
  final refunds = <RefundModel>[].obs;

  // summary cards
  final totalEarnings = 0.0.obs;
  final ordersCount = 0.obs;
  final avgOrder = 0.0.obs;

  // filters
  final search = ''.obs;
  final statusFilter = Rxn<OrderStatus>();
  final paymentModeFilter = Rxn<String>();
  final settlementFilter = Rxn<SettlementStatus>();

  @override
  void onInit() {
    super.onInit();
    // initial load
    fetchSummaryAndData();
  }

  void setRange(String r) {
    selectedRange.value = r;
    // update charts & summary
    _computeSummary();
  }

  Future<void> fetchSummaryAndData({bool reset = true}) async {
    if (isLoadingOrders.value) return; // prevent concurrent fetches
    isLoadingOrders.value = true;
    try {
      if (reset) {
        page.value = 1;
        orders.clear();
        hasMore.value = true;
      }

      final o = await service.fetchOrders(page: page.value, pageSize: pageSize.value);
      if (o.length < pageSize.value) hasMore.value = false;
      orders.addAll(o);
    } finally {
      isLoadingOrders.value = false;
    }

    final s = await service.fetchSettlements();
    settlements.assignAll(s);

    final r = await service.fetchRefunds();
    refunds.assignAll(r);

    _computeSummary();
  }

  Future<void> loadMore() async {
  if (!hasMore.value) return;
  if (isLoadingOrders.value) return;
  page.value++;
  await fetchSummaryAndData(reset: false);
  }

  List<OrderModel> get filteredOrders {
    final s = search.value.trim().toLowerCase();
    var list = orders;
    if (statusFilter.value != null) list = list.where((o) => o.status == statusFilter.value).toList().obs;
    if (paymentModeFilter.value != null) {
      // payment mode not currently on OrderModel; placeholder for when API provides it
    }
    if (s.isNotEmpty) {
      list = list.where((o) => o.id.toLowerCase().contains(s) || o.customerName.toLowerCase().contains(s) || o.phone.toLowerCase().contains(s)).toList().obs;
    }
    return list;
  }

  void _computeSummary() {
    // compute based on current orders
    final total = orders.fold(0.0, (p, o) => p + o.total);
    totalEarnings.value = total;
    ordersCount.value = orders.length;
    avgOrder.value = orders.isEmpty ? 0.0 : total / orders.length;
  }

  // commission calculation - supports percent or flat
  double commissionFor(OrderModel o, {double percent = 10.0, double flat = 0.0, bool usePercent = true}) {
    if (usePercent) return (percent / 100.0) * o.total;
    return flat;
  }

  double netFor(OrderModel o, {double percent = 10.0, double flat = 0.0, bool usePercent = true}) {
    final c = commissionFor(o, percent: percent, flat: flat, usePercent: usePercent);
    return o.total - c;
  }

  SettlementStatus? settlementStatusFor(String orderId) {
    for (final s in settlements) {
      if (s.orderIds.contains(orderId)) return s.status;
    }
    return null;
  }

  List<RefundModel> refundsFor(String orderId) => refunds.where((r) => r.orderId == orderId).toList();

  // simulate realtime updates - callers can subscribe to this stream
  Stream<OrderModel> realtimeOrderStream() async* {
    // placeholder: emit nothing for now; replace with WebSocket/Realtime subscription
    await Future.delayed(const Duration(seconds: 1));
  }

  // export wrappers
  void downloadPdf() {
    Get.snackbar('Download', 'PDF generation started', snackPosition: SnackPosition.BOTTOM);
    _generateAndSharePdf();
  }

  void downloadExcel() {
    Get.snackbar('Download', 'Excel generation started', snackPosition: SnackPosition.BOTTOM);
    _generateExcel();
  }

  Future<void> _generateAndSharePdf({Uint8List? lineChartPng, Uint8List? pieChartPng}) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        final fmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
        final widgets = <pw.Widget>[];

        widgets.add(pw.Text('Earnings Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)));
        widgets.add(pw.SizedBox(height: 12));
        widgets.add(pw.Text('Range: ${selectedRange.value}'));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Text('Total: ${fmt.format(totalEarnings.value)}'));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('Orders: ${ordersCount.value}'));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('Avg Order: ${fmt.format(avgOrder.value)}'));
        widgets.add(pw.SizedBox(height: 12));

        // Orders table header
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Container(
            child: pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Order ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Gross', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Commission', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('Net', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            for (final o in orders)
              pw.TableRow(children: [
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(o.id)),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(o.customerName)),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(o.dateTime.toIso8601String())),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(fmt.format(o.total))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(fmt.format(commissionFor(o)))),
                pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(fmt.format(o.total - commissionFor(o)))),
              ]),
          ],
        )));

        if (lineChartPng != null) {
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Text('Trend'));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Center(child: pw.Image(pw.MemoryImage(lineChartPng), width: 420)));
          widgets.add(pw.SizedBox(height: 12));
        }

        if (pieChartPng != null) {
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Text('Breakdown'));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Center(child: pw.Image(pw.MemoryImage(pieChartPng), width: 220)));
          widgets.add(pw.SizedBox(height: 12));
        }

        return widgets;
      },
    ));

    try {
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'earnings_report.pdf');
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate PDF: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Public wrapper used by UI
  Future<void> generateAndSharePdf({Uint8List? lineChartPng, Uint8List? pieChartPng}) async {
    await _generateAndSharePdf(lineChartPng: lineChartPng, pieChartPng: pieChartPng);
  }

  Future<void> _generateExcel() async {
    try {
      if (kIsWeb) {
        final fmt = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
        final buffer = StringBuffer();
        buffer.writeln('Range,${selectedRange.value}');
        buffer.writeln('Total,${fmt.format(totalEarnings.value)}');
        buffer.writeln('Orders,${ordersCount.value}');
        buffer.writeln('Avg Order,${fmt.format(avgOrder.value)}');
        buffer.writeln();
        buffer.writeln('Order ID,Customer,Date,Gross,Commission,Net');
        for (final o in orders) {
          buffer.writeln('${o.id},"${o.customerName}",${o.dateTime.toIso8601String()},${o.total},${commissionFor(o)},${o.total - commissionFor(o)}');
        }

        final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
        try {
          final saved = await saveFile(bytes, 'earnings_report.csv');
          Get.snackbar('Export', 'CSV downloaded: ${saved ?? 'downloaded'}', snackPosition: SnackPosition.BOTTOM);
        } catch (e) {
          Get.snackbar('Error', 'Failed to download CSV: $e', snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }

      final excel = Excel.createExcel();
      final Sheet sheet = excel['Sheet1'];
      final fmt = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);
      sheet.appendRow(['Range', selectedRange.value]);
      sheet.appendRow(['Total Earnings', fmt.format(totalEarnings.value)]);
      sheet.appendRow(['Orders', ordersCount.value]);
      sheet.appendRow(['Avg Order', fmt.format(avgOrder.value)]);
      sheet.appendRow([]);

      sheet.appendRow(['Order ID', 'Customer', 'Date', 'Gross', 'Commission', 'Net']);
      for (final o in orders) {
        sheet.appendRow([o.id, o.customerName, o.dateTime.toIso8601String(), o.total, commissionFor(o), (o.total - commissionFor(o))]);
      }

      final raw = excel.encode();
      if (raw == null) throw Exception('Failed to encode Excel');
      final bytes = Uint8List.fromList(raw);

      try {
        final saved = await saveFile(bytes, 'earnings_report.xlsx');
        Get.snackbar('Export', 'Excel saved: ${saved ?? 'downloaded'}', snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        Get.snackbar('Error', 'Failed to generate Excel: $e', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate Excel: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
