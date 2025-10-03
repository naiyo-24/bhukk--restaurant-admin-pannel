// screens/dashboard/widgets/quick_actions.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/dashboard/dashboard_controller.dart';

class QuickActions extends StatelessWidget {
	const QuickActions({super.key});

	@override
	Widget build(BuildContext context) {
		final controller = Get.find<DashboardController>();

		int crossAxisCount(double width) {
			if (width >= 1000) return 4;
			if (width >= 700) return 4;
			return 2;
		}

		return Card(
			elevation: 3,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: LayoutBuilder(
					builder: (context, constraints) {
						final count = crossAxisCount(constraints.maxWidth);
						return Obx(() => GridView.builder(
									shrinkWrap: true,
									physics: const NeverScrollableScrollPhysics(),
									gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
										crossAxisCount: count,
										crossAxisSpacing: 12,
										mainAxisSpacing: 12,
										childAspectRatio: 2.6,
									),
									itemCount: controller.quickActions.length,
									itemBuilder: (_, i) {
										final action = controller.quickActions[i];
										return ElevatedButton(
											style: ElevatedButton.styleFrom(
												backgroundColor: action.color,
												foregroundColor: Colors.white,
												elevation: 2,
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
												padding: const EdgeInsets.symmetric(horizontal: 16),
											),
											onPressed: () => controller.goTo(action.route),
											child: Row(
												mainAxisAlignment: MainAxisAlignment.center,
												children: [
													Icon(action.icon, size: 24),
													const SizedBox(width: 10),
													Text(action.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
												],
											),
										);
									},
								));
					},
				),
			),
		);
	}
}
// This file was intentionally cleared. Dashboard will be rebuilt from scratch.
