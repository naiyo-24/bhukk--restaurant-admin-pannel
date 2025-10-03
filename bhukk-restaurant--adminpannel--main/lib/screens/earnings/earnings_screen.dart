// screens/earnings/earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/earnings/earnings_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/order_model.dart';
import '../../models/settlement_model.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late final EarningsController controller;
  final GlobalKey _lineKey = GlobalKey();
  final GlobalKey _pieKey = GlobalKey();
  late final TextEditingController _ordersSearchCtrl;
  Timer? _searchDebounce;

  Future<Uint8List?> _capturePng(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject();
      if (boundary == null) return null;
      final image = await (boundary as RenderRepaintBoundary).toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // compute adaptive height for the tab content so the screen works on short viewports
    final screenH = MediaQuery.of(context).size.height;
  final tabHeight = (screenH * 0.72).clamp(420.0, 1000.0);

    return MainScaffold(
      title: 'Earnings',
      child: DefaultTabController(
        length: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(labelColor: Theme.of(context).colorScheme.primary, unselectedLabelColor: Colors.grey.shade600, tabs: const [Tab(text: 'Overview'), Tab(text: 'Orders'), Tab(text: 'Settlements'), Tab(text: 'Refunds')]),
                const SizedBox(height: 12),
                SizedBox(
                  height: tabHeight,
                  child: TabBarView(children: [
                    // Overview
                    SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _topRow(controller),
                      const SizedBox(height: 16),
                      _summaryCards(controller),
                      const SizedBox(height: 16),
                      _charts(controller),
                      const SizedBox(height: 16),
                      _actionsRow(controller),
                    ])),
                    // Orders tab
                    _ordersTab(),
                    // Settlements tab
                    _settlementsTab(),
                    // Refunds tab
                    _refundsTab(),
                  ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  // controller initialization happens in initState
  }

  @override
  void initState() {
    super.initState();
    // Acquire controller from binding if available, otherwise put a new one
    controller = Get.isRegistered<EarningsController>() ? Get.find<EarningsController>() : Get.put(EarningsController());

    _ordersSearchCtrl = TextEditingController(text: controller.search.value);
    _ordersSearchCtrl.addListener(() {
      final v = _ordersSearchCtrl.text;
      // debounce to avoid thrashing on large lists
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 250), () {
        if (v != controller.search.value) controller.search.value = v;
      });
    });
  }

  @override
  void dispose() {
  _searchDebounce?.cancel();
    _ordersSearchCtrl.dispose();
    super.dispose();
  }

  Widget _topRow(EarningsController controller) {
    return Row(
      children: [
        const Text('Range:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Obx(() => SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                ButtonSegment(value: 'Monthly', label: Text('Monthly')),
                ButtonSegment(value: 'Yearly', label: Text('Yearly')),
              ],
              selected: {controller.selectedRange.value},
              onSelectionChanged: (s) => controller.setRange(s.first),
            )),
      ],
    );
  }

  Widget _summaryCards(EarningsController controller) {
    return Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card('Total Earnings', '\u20B9${controller.totalEarnings.value.toStringAsFixed(0)}', Colors.green),
            _card('Orders', controller.ordersCount.value.toString(), Colors.blue),
            _card('Avg Order', '\u20B9${controller.avgOrder.value.toStringAsFixed(0)}', Colors.orange),
          ],
        ));
  }

  Widget _card(String title, String value, Color color) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  Icon(Icons.trending_up, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _charts(EarningsController controller) {
    return Obx(() {
      final data = controller.selectedRange.value == 'Weekly'
          ? controller.weekData
          : (controller.selectedRange.value == 'Monthly' ? controller.monthData : controller.yearData);

      return LayoutBuilder(builder: (context, constraints) {
        final chartHeight = constraints.maxWidth > 800 ? 340.0 : 240.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(height: chartHeight, child: _lineChartWidget(controller, data)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(height: chartHeight, child: _pieChartWidget()),
                ),
              ),
            ),
          ],
        );
      });
    });
  }

  Widget _lineChartWidget(EarningsController controller, List<double> data) {
    return RepaintBoundary(
      key: _lineKey,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                final label = controller.selectedRange.value == 'Weekly'
                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][idx % 7]
                    : 'P${idx + 1}';
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 12)));
              }),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 56, getTitlesWidget: (v, meta) {
                final fmt = NumberFormat.compactCurrency(symbol: '\u20B9', decimalDigits: 0);
                return Text(fmt.format(v), style: const TextStyle(fontSize: 12));
              }),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) {
              return spots.map((s) => LineTooltipItem('\u20B9${s.y.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
            }),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
              isCurved: true,
              color: Colors.green.shade700,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.green.shade100.withAlpha((0.6 * 255).toInt())),
            )
          ],
        ),
      ),
    );
  }

  Widget _pieChartWidget() {
    return RepaintBoundary(
      key: _pieKey,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 40, color: Colors.blue, title: 'Dine-in', radius: 50, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
            PieChartSectionData(value: 30, color: Colors.orange, title: 'Takeaway', radius: 45, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
            PieChartSectionData(value: 30, color: Colors.green, title: 'Delivery', radius: 45, titleStyle: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
          sectionsSpace: 4,
          centerSpaceRadius: 28,
          pieTouchData: PieTouchData(touchCallback: (event, response) {
            if (response != null && response.touchedSection != null) {
              final idx = response.touchedSection!.touchedSectionIndex;
              final labels = ['Dine-in', 'Takeaway', 'Delivery'];
              Get.snackbar('Segment', labels[idx], snackPosition: SnackPosition.BOTTOM);
            }
          }),
        ),
      ),
    );
  }

  Widget _actionsRow(EarningsController controller) {
    return Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      FilledButton.icon(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Download PDF'),
        onPressed: () async {
          final line = await _capturePng(_lineKey);
          final pie = await _capturePng(_pieKey);
          await controller.generateAndSharePdf(lineChartPng: line, pieChartPng: pie);
        },
      ),
      FilledButton.icon(
        icon: const Icon(Icons.table_chart),
        label: const Text('Download Excel'),
        onPressed: controller.downloadExcel,
      ),
    ]);
  }

  Widget _ordersTab() {
    return LayoutBuilder(builder: (ctx, cons) {
      final narrow = cons.maxWidth < 700;
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: TextField(controller: _ordersSearchCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search orders...'))),
            const SizedBox(width: 12),
            // On narrow screens place the button as smaller icon and allow wrapping
            if (narrow)
              IconButton(onPressed: controller.downloadExcel, icon: const Icon(Icons.download))
            else
              FilledButton.icon(icon: const Icon(Icons.download), label: const Text('Export CSV'), onPressed: controller.downloadExcel),
          ]),
          const SizedBox(height: 12),
          Expanded(child: Obx(() {
            final list = controller.filteredOrders;
            if (list.isEmpty) return const Center(child: Text('No orders'));
            // Use a virtualized ListView for both narrow and wide to avoid DataTable freezes
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (c, i) {
                final o = list[i];
                final comm = controller.commissionFor(o);
                if (narrow) {
                  return ListTile(
                    title: Text(o.id),
                    subtitle: Text('${o.customerName} • ${DateFormat.yMd().add_jm().format(o.dateTime)}'),
                    trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('\u20B9${o.total.toStringAsFixed(0)}'), Text(o.status.name.toUpperCase())]),
                    onTap: () => _showOrderDetail(o),
                  );
                }

                // wide row with inline columns
                return InkWell(
                  onTap: () => _showOrderDetail(o),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(children: [
                      SizedBox(width: 140, child: Text(o.id, style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(width: 16),
                      Expanded(child: Text(o.customerName)),
                      const SizedBox(width: 16),
                      SizedBox(width: 180, child: Text(DateFormat.yMd().add_jm().format(o.dateTime))),
                      const SizedBox(width: 16),
                      SizedBox(width: 90, child: Text('\u20B9${o.total.toStringAsFixed(0)}', textAlign: TextAlign.right)),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: Text('\u20B9${comm.toStringAsFixed(0)}', textAlign: TextAlign.right)),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: Text('\u20B9${(o.total - comm).toStringAsFixed(0)}', textAlign: TextAlign.right)),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: Text(o.status.name.toUpperCase(), textAlign: TextAlign.right)),
                    ]),
                  ),
                );
              },
            );
          })),
          const SizedBox(height: 8),
          Obx(() => Visibility(visible: controller.hasMore.value, child: Align(alignment: Alignment.center, child: TextButton(onPressed: controller.loadMore, child: const Text('Load more'))))),
        ]),
      );
    });
  }

  void _showOrderDetail(OrderModel order) {
    // Re-fetch latest instance from controller list (in case refreshed)
    final current = controller.orders.firstWhereOrNull((o) => o.id == order.id) ?? order;
    final commission = controller.commissionFor(current);
    final net = current.total - commission;
    final refunds = controller.refundsFor(current.id);
    final settlementStatus = controller.settlementStatusFor(current.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, scrollCtl) {
            return SingleChildScrollView(
              controller: scrollCtl,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(current.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Chip(label: Text(current.status.name.toUpperCase())),
                  ]),
                  const SizedBox(height: 8),
                  Text(DateFormat.yMMMd().add_jm().format(current.dateTime), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  // Full-width customer & address card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(builder: (c, cs) {
                          final wide = cs.maxWidth > 580;
                          Widget customer() => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(current.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(current.phone),
                                ],
                              );
                          Widget address() => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Address', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(current.address),
                                ],
                              );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: customer()),
                                    const SizedBox(width: 32),
                                    Expanded(child: address()),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    customer(),
                                    const SizedBox(height: 14),
                                    address(),
                                  ],
                                );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  // Full-width items card
                  SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: [
                        ...current.items.map((it) {
                          final isAdj = it.price < 0;
                          final lineTotal = it.price * it.qty;
                          return ListTile(
                            dense: true,
                            title: Text(it.name, style: isAdj ? TextStyle(color: Colors.red.shade700, fontStyle: FontStyle.italic) : null),
                            subtitle: Text(isAdj ? 'Adjustment' : 'Qty ${it.qty} • ₹${it.price.toStringAsFixed(2)}'),
                            trailing: Text(
                              '${isAdj ? '−' : ''}₹${lineTotal.abs().toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: isAdj ? Colors.red.shade700 : null),
                            ),
                          );
                        }),
                      ]),
                    ),
                  ),
                  ),
                  const SizedBox(height: 16),
                  // Full-width financials card
                  SizedBox(width: double.infinity, child: _totalsSection(current, commission, net, refunds, settlementStatus)),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('Close')),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _totalsSection(OrderModel o, double commission, double net, List<dynamic> refunds, SettlementStatus? settlementStatus) {
    final styleLabel = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54);
    final styleValue = const TextStyle(fontWeight: FontWeight.w600);
    double adjustments = o.items.where((i) => i.price < 0).fold(0.0, (p, i) => p + i.price * i.qty);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Financials', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _rowKV('Subtotal', '₹${o.subtotal.toStringAsFixed(2)}', styleLabel, styleValue),
          _rowKV('Adjustments', adjustments == 0 ? '₹0.00' : '₹${adjustments.toStringAsFixed(2)}', styleLabel, styleValue.copyWith(color: adjustments < 0 ? Colors.red : Colors.black)),
          _rowKV('Tax', '₹${o.tax.toStringAsFixed(2)}', styleLabel, styleValue),
          const Divider(),
          _rowKV('Gross Total', '₹${o.total.toStringAsFixed(2)}', styleLabel, styleValue),
          _rowKV('Commission (est.)', '₹${commission.toStringAsFixed(2)}', styleLabel, styleValue),
          _rowKV('Net', '₹${net.toStringAsFixed(2)}', styleLabel, styleValue),
          if (refunds.isNotEmpty) ...[
            const Divider(),
            Text('Refunds', style: Theme.of(context).textTheme.titleSmall),
            ...refunds.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${r.id}: ₹${r.amount.toStringAsFixed(0)} (${r.status.name})', style: const TextStyle(fontSize: 12)),
                )),
          ],
          if (settlementStatus != null) ...[
            const Divider(),
            _rowKV('Settlement', settlementStatus.name.toUpperCase(), styleLabel, styleValue),
          ],
        ]),
      ),
    );
  }

  Widget _rowKV(String k, String v, TextStyle? labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(k, style: labelStyle)), Text(v, style: valueStyle)]),
    );
  }

  Widget _settlementsTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Obx(() {
        final s = controller.settlements;
        if (s.isEmpty) return const Center(child: Text('No settlements'));
        return ListView.builder(
          itemCount: s.length,
          itemBuilder: (ctx, i) {
            final e = s[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(e.id),
                subtitle: Text('${DateFormat.yMd().format(e.date)} • Orders: ${e.orderIds.length}'),
                trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('\u20B9${e.payoutAmount.toStringAsFixed(0)}'), Text(e.status.toString().split('.').last.toUpperCase())]),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _refundsTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Obx(() {
        final r = controller.refunds;
        if (r.isEmpty) return const Center(child: Text('No refunds'));
        return ListView.builder(
          itemCount: r.length,
          itemBuilder: (ctx, i) {
            final f = r[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(f.id),
                subtitle: Text('${f.orderId} • ${f.reason}'),
                trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('\u20B9${f.amount.toStringAsFixed(0)}'), Text(f.status.toString().split('.').last.toUpperCase())]),
              ),
            );
          },
        );
      }),
    );
  }
}
