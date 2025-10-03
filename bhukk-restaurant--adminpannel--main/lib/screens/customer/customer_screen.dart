// screens/customer/customer_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/main_scaffold.dart';
import '../../routes/app_routes.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> customers = [
      {
        'name': 'Asha Patel',
        'last': 'I didn\'t get my fries, please help.',
        'time': '15m',
        'phone': '+91 90000 00001',
        'orderId': 'ORD-1001'
      },
      {
        'name': 'Rahul Singh',
        'last': 'Thanks, got it now!',
        'time': '2h',
        'phone': '+91 90000 00002',
        'orderId': 'ORD-1002'
      },
      {
        'name': 'Sana Khan',
        'last': 'Can I change the delivery address?',
        'time': 'Yesterday',
        'phone': '+91 90000 00003',
        'orderId': 'ORD-1003'
      },
    ];

    return MainScaffold(
      title: 'Customers',
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (ctx, i) {
                  final c = customers[i];
                  return ListTile(
                    // allow slightly more vertical room so trailing column won't overflow
                    dense: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: () => Get.toNamed(AppRoutes.CUSTOMER_CHAT, arguments: {'customerName': c['name'], 'orderId': c['orderId'], 'phone': c['phone']}),
                    leading: CircleAvatar(radius: 20, child: Text(c['name']!.isNotEmpty ? c['name']![0] : 'C')),
                    title: Text(c['name'] ?? 'Customer'),
                    subtitle: Text(c['last'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.15)),
                    trailing: SizedBox(
                      width: 68,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                              tooltip: 'Chat',
                              onPressed: () => Get.toNamed(AppRoutes.CUSTOMER_CHAT, arguments: {'customerName': c['name'], 'orderId': c['orderId'], 'phone': c['phone']}),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
