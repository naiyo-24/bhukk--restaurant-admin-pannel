// bindings/support/support_binding.dart
import 'package:get/get.dart';
import '../../controller/support/support_controller.dart';

class SupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportController>(() => SupportController());
  }
}
