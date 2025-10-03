// bindings/liquor/liquor_binding.dart
import 'package:get/get.dart';
import '../../controller/liquor/liquor_controller.dart';

class LiquorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiquorController>(() => LiquorController());
  }
}
