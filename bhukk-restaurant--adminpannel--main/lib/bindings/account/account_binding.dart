// bindings/account/account_binding.dart
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/controller/account/account_controller.dart';

class AccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountController>(() => AccountController());
  }
}
// bindings/account_binding.dart
