// widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'notification_panel.dart';
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/controller/notification/notification_controller.dart';
// Adds a small-screen AppBar with a leading icon to open the sidebar drawer

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showNotificationIcon;
  final bool showBack;
  final bool hideSidebar;
  // Sidebar embedding (reverted): always render on wide screens; flag kept for compatibility
  final bool embedSidebar;
  final Widget? floatingActionButton;
  const MainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showNotificationIcon = true,
    this.showBack = false,
    this.hideSidebar = false,
  this.embedSidebar = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
  final notifCtrl = Get.isRegistered<NotificationPanelController>() ? Get.find<NotificationPanelController>() : Get.put(NotificationPanelController(), permanent: true);
    return Stack(
      children: [
        Scaffold(
          drawer: isWide ? null : const Sidebar(),
          appBar: (!isWide && !hideSidebar)
              ? AppBar(
                  title: Text(title),
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.cookie_outlined),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  actions: [
                    if (showNotificationIcon)
                      IconButton(
                        // tooltip removed to prevent missing overlay issues if context changes
                        icon: Obx(() {
                          final count = notifCtrl.notifications.where((n) => !n.read).length;
                          if (count == 0) return const Icon(Icons.notifications_none_outlined);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_active_outlined),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                            ],
                          );
                        }),
                        onPressed: notifCtrl.togglePanel,
                      ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (isWide && !hideSidebar) const Sidebar(),
              if (isWide && !hideSidebar) const SizedBox(width: 20),
              Expanded(child: SafeArea(child: child)),
            ],
          ),
          floatingActionButton: floatingActionButton,
        ),
        const NotificationPanel(),
      ],
    );
  }
}
