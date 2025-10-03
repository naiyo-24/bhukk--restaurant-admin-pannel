// controller/chat/chat_controller.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../models/chat_message_model.dart';

class ChatController extends GetxController {
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool showEmojiPicker = false.obs;
  late final TextEditingController inputController;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    inputController = TextEditingController();
    // seed with a welcome message
    messages.addAll([
      ChatMessageModel(
        id: 'm1',
        senderId: 'cust',
        senderName: 'Customer',
        text: 'Hi, I have a question about my order.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isAdmin: false,
      ),
      ChatMessageModel(
        id: 'm2',
        senderId: 'admin',
        senderName: 'You',
        text: 'Sure — how can I help?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
        isAdmin: true,
      ),
      ChatMessageModel(
        id: 'm3',
        senderId: 'cust',
        senderName: 'Customer',
        text: 'I noticed an item is missing from my order. The fries are not included.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 11)),
        isAdmin: false,
      ),
      ChatMessageModel(
        id: 'm4',
        senderId: 'admin',
        senderName: 'You',
        text: 'I\'m sorry about that — we can either refund the item or send it right away. Which would you prefer?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        isAdmin: true,
      ),
      ChatMessageModel(
        id: 'm5',
        senderId: 'cust',
        senderName: 'Customer',
        text: 'Please send the fries. I\'m at the address provided.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        isAdmin: false,
      ),
      ChatMessageModel(
        id: 'm6',
        senderId: 'admin',
        senderName: 'You',
        text: 'Got it — I\'ll notify the kitchen and a delivery partner will bring it within 15 minutes.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isAdmin: true,
      ),
    ]);

    // Whenever messages change, scroll to bottom after frame.
    ever(messages, (_) => _scrollToEnd());
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'admin',
      senderName: 'You',
      text: trimmed,
      timestamp: DateTime.now(),
      isAdmin: true,
    );
    messages.add(msg);
    inputController.clear();

    // Simulate an automated customer reply after a short delay (UI demo only)
    Future.delayed(const Duration(seconds: 1), () {
      final reply = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        senderId: 'cust',
        senderName: 'Customer',
        text: 'Thank you — noted.',
        timestamp: DateTime.now(),
        isAdmin: false,
      );
      messages.add(reply);
    });
  }

  void attachFile() {
    // Stub: in a real app you'd open file picker / camera
    Get.snackbar('Attach', 'Attachment UI not implemented (stub)', snackPosition: SnackPosition.BOTTOM);
  }

  void toggleEmojiPicker() {
    showEmojiPicker.value = !showEmojiPicker.value;
    // When emoji picker shows, adjust scrolling so input is visible
    Future.delayed(const Duration(milliseconds: 120), () => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!scrollController.hasClients) return;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (_) {}
  }
}
