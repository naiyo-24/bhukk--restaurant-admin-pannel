// controller/dining/feedback_controller.dart
import 'package:get/get.dart';
import '../../models/feedback_model.dart';

class FeedbackController extends GetxController {
  var feedbacks = <FeedbackModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    feedbacks.value = [
      FeedbackModel(
        id: 'F001',
        date: DateTime.now(),
        customerName: 'Customer 1',
        dishName: 'Paneer Tikka',
        rating: 4,
        review: 'Great food!',
      ),
      FeedbackModel(
        id: 'F002',
        date: DateTime.now(),
        customerName: 'Customer 2',
        dishName: 'Biryani',
        rating: 5,
        review: 'Excellent service!',
      ),
    ];
  }

  void addFeedback(FeedbackModel feedback) {
    feedbacks.add(feedback);
  }
}
