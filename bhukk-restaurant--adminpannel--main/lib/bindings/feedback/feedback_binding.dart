// bindings/feedback/feedback_binding.dart
import 'package:get/get.dart';
import '../../controller/feedback/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    // Use a tag to avoid clashing with Dining's FeedbackController
    if (!Get.isRegistered<FeedbackAdminController>(tag: 'feedback')) {
      Get.put(FeedbackAdminController(), tag: 'feedback');
    }
  }
}
