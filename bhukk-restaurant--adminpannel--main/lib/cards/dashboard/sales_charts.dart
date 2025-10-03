// cards/dashboard/sales_charts.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controller/dashboard/dashboard_controller.dart';

class SalesCharts extends StatelessWidget {
	const SalesCharts({super.key});

	@override
	Widget build(BuildContext context) {
		final controller = Get.find<DashboardController>();

			Widget buildHeader() {
			return LayoutBuilder(builder: (ctx, bc) {
				final narrow = bc.maxWidth < 520;
				return Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Expanded(
										child: Text('Sales Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
								if (!narrow) const SizedBox(width: 12),
								Obx(() => DropdownButton<String>(
											value: controller.selectedRange.value,
											items: controller.ranges.map((r) => DropdownMenuItem<String>(value: r, child: Text(r))).toList(),
											onChanged: (v) => v != null ? controller.changeRange(v) : null,
										)),
									const SizedBox(width: 8),
									// Export buttons directly in header (no external container)
									IconButton(
										tooltip: 'Export PDF',
										onPressed: () async {
											await _exportPdf(controller);
										},
										icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD2042D)),
									),
									IconButton(
										tooltip: 'Export Excel',
										onPressed: () async {
											await _exportExcel(controller);
										},
										icon: const Icon(Icons.table_chart, color: Colors.green),
									),
							],
						),
						const SizedBox(height: 8),
					],
				);
			});
		}

		Widget buildBarChart() {
			return Obx(() {
				final data = controller.barData;
				final n = data.length;
				final step = n <= 8
					? 1
					: n <= 12
						? 2
						: n <= 20
							? 3
							: n <= 30
								? 4
								: 5;
				final maxVal = (data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b)).toDouble();
				double computeInterval(double m) {
					if (m <= 5) return 1;
					if (m <= 10) return 2;
					if (m <= 50) return 10;
					if (m <= 100) return 20;
					if (m <= 500) return 100;
					if (m <= 1000) return 200;
					return (m / 5).ceilToDouble();
				}
				String fmt(num v) {
					final av = v.abs();
					if (av >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
					if (av >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
					if (av >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
					return v.toStringAsFixed(0);
				}
				final yInterval = computeInterval(maxVal);
				final maxY = data.isEmpty ? 1.0 : (((maxVal / yInterval).ceil()) * yInterval).toDouble();
				return BarChart(BarChartData(
					borderData: FlBorderData(show: false),
					gridData: FlGridData(
						show: true,
						drawVerticalLine: false,
						horizontalInterval: yInterval,
						getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x11000000), strokeWidth: 1),
					),
					titlesData: FlTitlesData(
						leftTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 44,
								interval: yInterval,
								getTitlesWidget: (value, meta) => Text(fmt(value), style: const TextStyle(fontSize: 11, color: Colors.black54)),
							),
						),
						bottomTitles: AxisTitles(
							sideTitles: SideTitles(
								showTitles: true,
								reservedSize: 26,
								getTitlesWidget: (value, meta) {
									final idx = value.toInt();
									if (idx < 0 || idx >= n || idx % step != 0) return const SizedBox.shrink();
									return Padding(
										padding: const EdgeInsets.only(top: 6.0),
										child: Transform.rotate(
											angle: -0.4,
											child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
										),
									);
								},
							),
						),
						rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
						topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					),
					maxY: maxY <= 0 ? 1 : maxY,
					barTouchData: BarTouchData(
						enabled: true,
						touchTooltipData: BarTouchTooltipData(
							getTooltipItem: (group, groupIndex, rod, rodIndex) {
									return BarTooltipItem(fmt(rod.toY), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700));
							},
						),
					),
					barGroups: [
						for (int i = 0; i < data.length; i++)
							BarChartGroupData(x: i, barRods: [
								BarChartRodData(
									toY: data[i].toDouble(),
									width: 16,
									gradient: const LinearGradient(colors: [Color(0xFFD8757A), Color(0xFFD2042D)]),
									borderRadius: BorderRadius.circular(10),
								),
							])
					],
				));
			});
		}

		Widget buildPieChart() {
			return Obx(() {
				final items = controller.pieSegments;
				final double total = items.fold(0.0, (p, e) => p + e.value);
				return Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						SizedBox(
							width: 180,
							height: 180,
							child: PieChart(PieChartData(
								sectionsSpace: 6,
								centerSpaceRadius: 28,
								sections: [
									for (final seg in items)
										PieChartSectionData(
											value: seg.value,
											color: seg.color,
											// hide labels on very small slices to avoid overlap
											title: () {
												final pct = ((seg.value / (total > 0 ? total : 1)) * 100);
												return pct < 8 ? '' : '${pct.toStringAsFixed(0)}%';
											}(),
											titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
											titlePositionPercentageOffset: 0.6,
										)
								],
							)),
						),
						const SizedBox(width: 18),
						// Legend
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									for (final seg in items)
										Padding(
											padding: const EdgeInsets.only(bottom: 8.0),
											child: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Container(width: 12, height: 12, decoration: BoxDecoration(color: seg.color, borderRadius: BorderRadius.circular(3))),
													const SizedBox(width: 8),
													Text(seg.label, style: const TextStyle(fontWeight: FontWeight.w600)),
												],
											),
										),
								],
							),
						)
					],
				);
			});
		}

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Card(
					elevation: 3,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
					child: Padding(
						padding: const EdgeInsets.all(16.0),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								buildHeader(),
								const SizedBox(height: 16),
								LayoutBuilder(builder: (context, constraints) {
									final isWide = constraints.maxWidth > 700;
									return isWide
											? Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Expanded(flex: 3, child: SizedBox(height: 260, child: buildBarChart())),
														const SizedBox(width: 18),
														Expanded(flex: 2, child: buildPieChart()),
													],
												)
											: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														SizedBox(height: 220, child: buildBarChart()),
														const SizedBox(height: 16),
														buildPieChart(),
													],
												);
								})
							],
						),
					),
				),
						// Removed separate export container; exports available via header icons.
			],
		);
	}
}

		// --- helper export functions ---
		Future<void> _exportPdf(DashboardController controller) async {
			try {
				final pdf = pw.Document();

				// simple table with bar data
				final headers = ['Index', 'Value'];
				final rows = <List<String>>[];
				for (var i = 0; i < controller.barData.length; i++) {
					rows.add(['${i + 1}', controller.barData[i].toString()]);
				}

				pdf.addPage(pw.Page(build: (pw.Context ctx) {
					return pw.Column(children: [
						pw.Text('Sales Analytics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
						pw.SizedBox(height: 12),
						pw.TableHelper.fromTextArray(context: ctx, headers: headers, data: rows),
					]);
				}));

				final bytes = await pdf.save();
				final dir = await getApplicationDocumentsDirectory();
				final file = File('${dir.path}${Platform.pathSeparator}sales_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf');
				await file.writeAsBytes(bytes);

				Get.snackbar('Exported', 'PDF saved to: ${file.path}', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
				// try to open the file if possible
				try {
					final uri = Uri.file(file.path);
					if (await canLaunchUrl(uri)) {
						await launchUrl(uri);
					}
				} catch (_) {}
			} catch (e) {
				Get.snackbar('Error', 'Failed to export PDF: $e', snackPosition: SnackPosition.BOTTOM);
			}
		}

		Future<void> _exportExcel(DashboardController controller) async {
			try {
				final excel = Excel.createExcel();
				final sheet = excel[excel.getDefaultSheet()!];

				// Header
				sheet.appendRow(['Index', 'Value']);
				for (var i = 0; i < controller.barData.length; i++) {
					sheet.appendRow(['${i + 1}', controller.barData[i].toString()]);
				}

				final bytes = excel.encode();
				if (bytes == null) throw 'Failed to encode excel';

				final dir = await getApplicationDocumentsDirectory();
				final file = File('${dir.path}${Platform.pathSeparator}sales_analytics_${DateTime.now().millisecondsSinceEpoch}.xlsx');
				await file.writeAsBytes(bytes, flush: true);

				Get.snackbar('Exported', 'Excel saved to: ${file.path}', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
				try {
					final uri = Uri.file(file.path);
					if (await canLaunchUrl(uri)) {
						await launchUrl(uri);
					}
				} catch (_) {}
			} catch (e) {
				Get.snackbar('Error', 'Failed to export Excel: $e', snackPosition: SnackPosition.BOTTOM);
			}
		}
