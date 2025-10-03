// bindings/menu/menu_binding.dart
import 'package:get/get.dart';
import '../../controller/menu/menu_controller.dart';

class MenuBinding extends Bindings {
	@override
	void dependencies() {
		Get.lazyPut<MenuController>(() => MenuController());
	}
}
