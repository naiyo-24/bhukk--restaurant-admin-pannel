// bindings/earnings/earnings_binding.dart
import 'package:get/get.dart';
import '../../controller/earnings/earnings_controller.dart';

class EarningsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EarningsController>(() => EarningsController());
  }
}
