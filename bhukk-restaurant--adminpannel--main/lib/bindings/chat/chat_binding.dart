// bindings/chat/chat_binding.dart
import 'package:get/get.dart';
import '../../controller/chat/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
