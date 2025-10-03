// controller/support/support_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import '../../models/support_request_model.dart';
import '../../routes/app_routes.dart';

class SupportController extends GetxController {
  final supportRequests = <SupportRequest>[].obs;
  final isSubmitting = false.obs;
  // Form fields
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final Rx<SupportCategory> formCategory = SupportCategory.general.obs;
  final attachments = <String>[].obs;
  // Simple filters
  final query = ''.obs;
  final Rxn<SupportCategory> categoryFilter = Rxn<SupportCategory>();
  final Rxn<SupportStatus> statusFilter = Rxn<SupportStatus>();

  @override
  void onInit() {
    super.onInit();
    // Add sample tickets
    supportRequests.addAll(List.generate(3, (i) {
      return SupportRequest(
        id: 'TKT${DateTime.now().millisecondsSinceEpoch + i}',
        fullName: 'Customer ${i + 1}',
        email: 'user${i + 1}@example.com',
        category: SupportCategory.general,
        description: 'Sample request #${i + 1}',
        status: SupportStatus.open,
        createdAt: DateTime.now().subtract(Duration(days: i)),
      );
    }));
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    descriptionCtrl.dispose();
    super.onClose();
  }

  void addRequest(SupportRequest req) {
    supportRequests.insert(0, req);
  }

  Future<void> createAndAdd({
    required String fullName,
    required String email,
    required SupportCategory category,
    required String description,
    List<String>? attachments,
  }) async {
    isSubmitting.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    final id = 'TKT${DateTime.now().millisecondsSinceEpoch}';
    final r = SupportRequest(
      id: id,
      fullName: fullName,
      email: email,
      category: category,
      description: description,
      attachments: attachments ?? [],
    );
    addRequest(r);
    isSubmitting.value = false;
  }

  void updateStatus(String id, SupportStatus status) {
    final idx = supportRequests.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    supportRequests[idx].status = status;
    supportRequests.refresh();
  }

  void deleteRequest(String id) {
    supportRequests.removeWhere((s) => s.id == id);
  }

  // Helpers
  void setCategory(SupportCategory? c) => categoryFilter.value = c;
  void setStatus(SupportStatus? s) => statusFilter.value = s;
  void setQuery(String q) => query.value = q;
  void clearFilters() {
    query.value = '';
    categoryFilter.value = null;
    statusFilter.value = null;
  }

  /// Try to open the phone dialer with [number]. If it fails, copy number to clipboard and inform user.
  Future<void> callSupport(String number) async {
    final uri = 'tel:$number';
    try {
      await launchUrlString(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: number));
      Get.snackbar('Dialer', 'Could not open dialer. Number copied to clipboard.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Try to open email client with [to] and [subject]. On failure show snackbar.
  Future<void> emailSupport(String to, String subject) async {
    final mail = Uri.encodeComponent(to);
    final subj = Uri.encodeComponent(subject);
    final uri = 'mailto:$mail?subject=$subj';
    try {
      await launchUrlString(uri);
    } catch (_) {
      Get.snackbar('Email', 'Could not open email client.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Open an in-app live chat. Uses GetX routing to navigate to the chat screen.
  void openLiveChat({String customerName = 'Support', String orderId = '', String phone = ''}) {
    Get.toNamed(AppRoutes.CUSTOMER_CHAT, arguments: {'customerName': customerName, 'orderId': orderId, 'phone': phone});
  }
}
