// bindings/delivery/delivery_binding.dart
import 'package:get/get.dart';
import '../../controller/delivery/delivery_controller.dart';

class DeliveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryController>(() => DeliveryController());
  }
}
