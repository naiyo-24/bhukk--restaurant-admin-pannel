// controller/dashboard/dashboard_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class DashboardController extends GetxController {
	// Ads URLs (could be remote later)
	final ads = <String>[
		'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1200&auto=format&fit=crop',
		'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200&auto=format&fit=crop',
		'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?q=80&w=1200&auto=format&fit=crop',
	].obs;

	// Quick actions
	final quickActions = <QuickAction>[
		QuickAction(label: 'Menu', icon: Icons.restaurant_menu, color: Colors.red.shade600, route: '/menu'),
		QuickAction(label: 'Dining', icon: Icons.restaurant, color: Colors.orange.shade600, route: AppRoutes.DINING),
		QuickAction(label: 'Orders', icon: Icons.receipt_long, color: Colors.blue.shade600, route: '/orders'),
		QuickAction(label: 'Earnings', icon: Icons.attach_money, color: Colors.green.shade600, route: '/earnings'),
	].obs;

	// Sales ranges
	final ranges = const ['Weekly', 'Monthly', 'Yearly'];
	final selectedRange = 'Weekly'.obs;

	// Analytics data (mock)
	// Bar chart data represented as 7, 4, or 12 points depending on range
	final barData = <double>[12, 18, 14, 20, 16, 22, 26].obs; // weekly default

	// Pie chart categories
	final pieSegments = <PieSegment>[
		PieSegment('Dine-in', 40, Colors.blue),
		PieSegment('Takeaway', 30, Colors.orange),
		PieSegment('Delivery', 30, Colors.green),
	].obs;

	void changeRange(String value) {
		selectedRange.value = value;
		switch (value) {
			case 'Weekly':
				barData.assignAll([12, 18, 14, 20, 16, 22, 26]);
				pieSegments.assignAll([
					PieSegment('Dine-in', 40, Colors.blue),
					PieSegment('Takeaway', 30, Colors.orange),
					PieSegment('Delivery', 30, Colors.green),
				]);
				break;
			case 'Monthly':
				barData.assignAll([220, 180, 260, 240, 300, 280]);
				pieSegments.assignAll([
					PieSegment('Dine-in', 35, Colors.blue),
					PieSegment('Takeaway', 25, Colors.orange),
					PieSegment('Delivery', 40, Colors.green),
				]);
				break;
			case 'Yearly':
				barData.assignAll([2.2, 1.8, 2.6, 2.4, 3.0, 2.8, 3.2, 3.0, 2.6, 2.4, 2.9, 3.1]);
				pieSegments.assignAll([
					PieSegment('Dine-in', 30, Colors.blue),
					PieSegment('Takeaway', 20, Colors.orange),
					PieSegment('Delivery', 50, Colors.green),
				]);
				break;
		}
	}

	// Navigation with safe fallback
	void goTo(String route) {
		try {
			Get.toNamed(route);
		} catch (e) {
			Get.snackbar('Navigation', 'Screen not available yet', snackPosition: SnackPosition.BOTTOM);
		}
	}

	// Download stubs
	void downloadPdf() {
		Get.snackbar('Download', 'PDF report generation started', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade50);
	}

	void downloadExcel() {
		Get.snackbar('Download', 'Excel report generation started', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade50);
	}
}

class QuickAction {
	final String label;
	final IconData icon;
	final Color color;
	final String route;
	QuickAction({required this.label, required this.icon, required this.color, required this.route});
}

class PieSegment {
	final String label;
	final double value; // percentage
	final Color color;
	PieSegment(this.label, this.value, this.color);
}

