// screens/dining/dining_feedback_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dining/feedback_controller.dart';

class DiningFeedbackView extends StatelessWidget {
  DiningFeedbackView({super.key});
  final FeedbackController controller = Get.put(FeedbackController());

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Feedback', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: controller.feedbacks.length,
              itemBuilder: (_, i) {
                final feedback = controller.feedbacks[i];
                return ListTile(
                  title: Text(feedback.customerName),
                  subtitle: Text('Rating: ${feedback.rating} | "${feedback.review}"'),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
