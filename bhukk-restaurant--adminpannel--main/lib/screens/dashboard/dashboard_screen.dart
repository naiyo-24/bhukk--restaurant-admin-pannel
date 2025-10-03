// screens/dashboard/dashboard_screen.dart
// This file was intentionally cleared. Dashboard will be rebuilt from scratch.
// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/main_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../controller/dashboard/dashboard_controller.dart';
import 'package:bhukk_resturant_admin/cards/dashboard/ads_carousel.dart';
import 'package:bhukk_resturant_admin/cards/dashboard/quick_actions.dart';
import 'package:bhukk_resturant_admin/cards/dashboard/sales_charts.dart';

class DashboardScreen extends StatelessWidget {
	DashboardScreen({super.key});

	final DashboardController _controller = Get.put(DashboardController(), permanent: true);

	@override
	Widget build(BuildContext context) {
			return MainScaffold(
				title: 'Dashboard',
				child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: SingleChildScrollView(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const AdsCarousel(),
							const SizedBox(height: 16),
							const QuickActions(),
							const SizedBox(height: 16),
								const SalesCharts(),
							const SizedBox(height: 16),
							Card(
								elevation: 3,
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
								child: Padding(
									padding: const EdgeInsets.all(16.0),
									child: Wrap(
										spacing: 12,
										runSpacing: 12,
										children: [
											FilledButton.icon(
												style: FilledButton.styleFrom(backgroundColor: AppTheme.cherryRed, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
												onPressed: _controller.downloadPdf,
												icon: const Icon(Icons.picture_as_pdf),
												label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w700)),
											),
											FilledButton.icon(
												style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
												onPressed: _controller.downloadExcel,
												icon: const Icon(Icons.table_chart),
												label: const Text('Download Excel', style: TextStyle(fontWeight: FontWeight.w700)),
											),
										],
									),
								),
							),
							const SizedBox(height: 24),
						],
					),
				),
			),
		);
	}
}
