// screens/dashboard/widgets/ads_carousel.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import '../../../controller/dashboard/dashboard_controller.dart';

class AdsCarousel extends StatelessWidget {
	const AdsCarousel({super.key});

	@override
	Widget build(BuildContext context) {
		final controller = Get.find<DashboardController>();
		return Card(
			elevation: 3,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			clipBehavior: Clip.antiAlias,
			child: Padding(
				padding: const EdgeInsets.all(8.0),
				child: CarouselSlider(
					options: CarouselOptions(
						height: 160,
						autoPlay: true,
						viewportFraction: 0.92,
						enlargeCenterPage: true,
					),
					items: controller.ads.map((ad) {
						return Builder(builder: (context) {
							return ClipRRect(
								borderRadius: BorderRadius.circular(12),
								child: Stack(
									fit: StackFit.expand,
									children: [
										Image.network(
											ad,
											fit: BoxFit.cover,
											loadingBuilder: (context, child, progress) {
												if (progress == null) return child;
												return Container(
													color: Colors.grey.shade200,
													child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
												);
											},
											errorBuilder: (context, error, stackTrace) => Container(
												color: Colors.grey.shade200,
												child: const Center(child: Icon(Icons.broken_image, size: 42, color: Colors.grey)),
											),
										),
										Positioned(
											left: 12,
											bottom: 12,
											child: Container(
												padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
												decoration: BoxDecoration(
													color: Colors.black54,
													borderRadius: BorderRadius.circular(8),
												),
												child: const Text('Sponsored', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
											),
										)
									],
								),
							);
						});
					}).toList(),
				),
			),
		);
	}
}
// This file was intentionally cleared. Dashboard will be rebuilt from scratch.
