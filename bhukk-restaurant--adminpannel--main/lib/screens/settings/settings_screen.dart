// screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// theme is available via Theme.of(context)
import '../../controller/settings/settings_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/main_scaffold.dart';
import 'package:bhukk_resturant_admin/controller/notification/notification_controller.dart';
import 'package:bhukk_resturant_admin/models/notification_item.dart';
import 'package:bhukk_resturant_admin/controller/auth/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  // Single instance for this screen's lifecycle
  final SettingsController ctl = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Settings',
      child: Column(children: [
        _header(context),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 980;
            final left = _preferencesCard(context);
            final right = _aboutCard(context);
            if (wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left]))),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: SingleChildScrollView(child: right)),
                ]),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 12), right]),
            );
          }),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context) {
    final notifCtrl = Get.put(NotificationPanelController());
    if (!Get.isRegistered<AuthController>()) Get.put(AuthController());
    final auth = Get.find<AuthController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
  const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        const Spacer(),
        Obx(() {
          final unread = notifCtrl.notifications.where((n) => !n.read).length;
          return Stack(children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _openNotificationsPanel(context),
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFD2042D), borderRadius: BorderRadius.circular(10)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ]);
        }),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Logout'),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                ],
              ),
            );
            if (confirm == true) auth.logout();
          },
        ),
      ]),
    );
  }

  Widget _preferencesCard(BuildContext context) {
    // Main settings card with modern hierarchy and chip-based categories
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Obx(() {
          final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
          final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0x1AD2042D), child: Icon(Icons.tune, color: Color(0xFFD2042D))),
                const SizedBox(width: 10),
                Text('Preferences', style: labelStyle),
              ]),
              const SizedBox(height: 16),

              // Notifications master switch
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: Text('Receive important updates about orders, delivery and payments', style: subStyle),
                trailing: Switch(value: ctl.notificationsEnabled.value, onChanged: ctl.toggleNotifications),
              ),
              const Divider(height: 24),

              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Notification categories', style: Theme.of(context).textTheme.labelLarge),
              ),

              Wrap(spacing: 10, runSpacing: 10, children: [
                FilterChip(
                  label: const Text('Order updates'),
                  avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                  selected: ctl.notificationPrefs['order_updates'] ?? true,
                  onSelected: (v) => ctl.toggleNotificationPref('order_updates', v),
                ),
                FilterChip(
                  label: const Text('Delivery updates'),
                  avatar: const Icon(Icons.delivery_dining_outlined, size: 18),
                  selected: ctl.notificationPrefs['delivery_updates'] ?? true,
                  onSelected: (v) => ctl.toggleNotificationPref('delivery_updates', v),
                ),
                FilterChip(
                  label: const Text('Promotions'),
                  avatar: const Icon(Icons.campaign_outlined, size: 18),
                  selected: ctl.notificationPrefs['promotions'] ?? false,
                  onSelected: (v) => ctl.toggleNotificationPref('promotions', v),
                ),
              ]),

              const SizedBox(height: 20),
              const Divider(height: 24),

              // Account section
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Account', style: Theme.of(context).textTheme.labelLarge),
              ),
              Row(children: [
                FilledButton.icon(
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Account Settings'),
                  onPressed: () => Get.toNamed(AppRoutes.ACCOUNT),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                  onPressed: ctl.resetDefaults,
                ),
              ]),
            ],
          );
        }),
      ),
    );
  }

  void _openNotificationsPanel(BuildContext context) {
    final ctrl = Get.put(NotificationPanelController());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final w = MediaQuery.of(ctx).size.width;
        final width = w > 480 ? 420.0 : w * 0.9;
        return Stack(children: [
          Opacity(opacity: anim.value * 0.3, child: const ModalBarrier(dismissible: true, color: Colors.black)),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(1,0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: SizedBox(
                  width: width,
                  height: MediaQuery.of(ctx).size.height,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Spacer(),
                          IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                        ]),
                        const SizedBox(height: 8),
                        Expanded(child: Obx(() {
                          if (ctrl.notifications.isEmpty) return const Center(child: Text('No notifications'));
                          final unread = ctrl.notifications.where((n) => !n.read).toList();
                          final read = ctrl.notifications.where((n) => n.read).toList();
                          return SingleChildScrollView(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              if (unread.isNotEmpty) ...[Text('Unread', style: Theme.of(ctx).textTheme.titleMedium), const SizedBox(height: 8), ...unread.map((n) => _notifCard(n, ctrl))],
                              if (read.isNotEmpty) ...[const SizedBox(height: 12), Text('Read', style: Theme.of(ctx).textTheme.titleMedium), const SizedBox(height: 8), ...read.map((n) => _notifCard(n, ctrl))],
                            ]),
                          );
                        }))
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _notifCard(NotificationItem n, NotificationPanelController ctrl) {
    return Dismissible(
      key: ValueKey(n.id),
      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete, color: Colors.white)),
      secondaryBackground: Container(color: Colors.orangeAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.archive, color: Colors.white)),
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          ctrl.archive(n.id);
          Get.snackbar('Archived', n.title, snackPosition: SnackPosition.BOTTOM, mainButton: TextButton(onPressed: () { ctrl.undoLast(); }, child: const Text('Undo')));
        } else {
          ctrl.delete(n.id);
          Get.snackbar('Deleted', n.title, snackPosition: SnackPosition.BOTTOM, mainButton: TextButton(onPressed: () { ctrl.undoLast(); }, child: const Text('Undo')));
        }
      },
      child: GestureDetector(
        onTap: () => ctrl.markAsRead(n.id),
        child: Builder(builder: (c) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(c).cardColor),
          child: Row(children: [
            _typeChip(n.type),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.title, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(n.description, maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text(n.timeAgo(), style: Theme.of(c).textTheme.bodySmall?.copyWith(color: Colors.grey))])),
            if (!n.read) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFD2042D), borderRadius: BorderRadius.circular(8)), child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 12))),
          ]),
        )),
      ),
    );
  }

  Widget _typeChip(NotificationType t) {
    switch (t) {
      case NotificationType.info:
        return const CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: Icon(Icons.info, color: Colors.white, size: 16));
      case NotificationType.orderUpdate:
        return const CircleAvatar(backgroundColor: Colors.green, radius: 18, child: Icon(Icons.shopping_bag, color: Colors.white, size: 16));
      case NotificationType.payment:
        return const CircleAvatar(backgroundColor: Colors.purple, radius: 18, child: Icon(Icons.payment, color: Colors.white, size: 16));
    }
  }

  Widget _aboutCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(radius: 18, backgroundColor: Color(0x112196F3), child: Icon(Icons.info_outline, color: Color(0xFF2196F3))),
              const SizedBox(width: 10),
              Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps_outlined),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Terms & Privacy'),
              subtitle: const Text('Read our terms of service and privacy policy'),
              onTap: () {
                Get.dialog(AlertDialog(
                  title: const Text('Terms & Privacy'),
                  content: const Text('Terms and privacy placeholder'),
                  actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
                ));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.article_outlined),
              title: const Text('Open Source Licenses'),
              subtitle: const Text('Packages used by this application'),
              onTap: () => showLicensePage(
                context: context,
                applicationVersion: '1.0.0',
                applicationName: 'Bhukk Restaurant Admin',
              ),
            ),
            const SizedBox(height: 8),
            Text('Legal', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Licenses'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
