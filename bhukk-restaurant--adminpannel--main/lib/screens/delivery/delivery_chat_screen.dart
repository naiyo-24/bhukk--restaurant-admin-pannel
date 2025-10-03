// screens/delivery/delivery_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatMessage {
  final String from; // 'me' or partner id
  final String text;
  final DateTime at;

  ChatMessage({required this.from, required this.text, DateTime? at}) : at = at ?? DateTime.now();
}

class DeliveryChatController extends GetxController {
  final partnerId = ''.obs;
  final partnerName = ''.obs;
  final messages = <ChatMessage>[].obs;

  void initFor(String id, String name) {
    partnerId.value = id;
    partnerName.value = name;
    messages.clear();
    // seed with a greeting
    messages.add(ChatMessage(from: id, text: 'Hi, I am on my way.'));
  }

  void send(String text) {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage(from: 'me', text: text.trim()));
    // simulate partner reply for demo
    Future.delayed(const Duration(milliseconds: 700), () {
      messages.add(ChatMessage(from: partnerId.value, text: 'Got it: "${text.trim()}"'));
    });
  }
}

class DeliveryChatScreen extends StatelessWidget {
  DeliveryChatScreen({super.key});

  final DeliveryChatController c = Get.put(DeliveryChatController());
  final TextEditingController input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['partnerId'] ?? '';
    final name = Get.parameters['partnerName'] ?? 'Partner';
    if (c.partnerId.value != id) c.initFor(id, name);

    return Scaffold(
      appBar: AppBar(title: Obx(() => Text('Chat with ${c.partnerName.value}'))),
      body: Column(children: [
        Expanded(child: Obx(() {
          final list = c.messages;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              final mine = m.from == 'me';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(color: mine ? Colors.blue.shade600 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.text, style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                    const SizedBox(height: 6),
                    Text(
                      '${m.at.hour.toString().padLeft(2, '0')}:${m.at.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : Colors.black45),
                    ),
                  ]),
                ),
              );
            },
          );
        })),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(children: [
              Expanded(child: TextField(controller: input, decoration: const InputDecoration(hintText: 'Type a message...'))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = input.text;
                  input.clear();
                  c.send(text);
                },
                child: const Icon(Icons.send),
              )
            ]),
          ),
        )
      ]),
    );
  }
}
