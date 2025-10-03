// controller/common/layout_controller.dart
import 'package:get/get.dart';

/// Controls responsive layout chrome (e.g. persistent sidebar) for desktop widths.
/// Allows toggling collapse/expand so sidebar width shrinks but remains visible.
class LayoutController extends GetxController {
  static LayoutController get to => Get.find<LayoutController>();

  /// Whether the sidebar is collapsed (icon-only) on wide screens.
  final collapsed = false.obs;

  void toggleSidebar() => collapsed.toggle();
  void setCollapsed(bool value) => collapsed.value = value;
}
