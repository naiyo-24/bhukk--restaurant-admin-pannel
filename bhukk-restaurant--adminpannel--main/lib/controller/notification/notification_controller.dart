// controller/notification/notification_controller.dart
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/models/notification_item.dart';

class NotificationPanelController extends GetxController {
  final notifications = <NotificationItem>[].obs;
  final archived = <NotificationItem>[].obs;
  final panelOpen = false.obs;
  final query = ''.obs;
  final showUnreadOnly = false.obs;
  final typeFilter = Rxn<NotificationType>();
  NotificationItem? _lastRemoved;
  bool _lastWasArchived = false;

  @override
  void onInit() {
    super.onInit();
    _loadMock();
  }

  void _loadMock() {
    notifications.assignAll([
      NotificationItem(id: 'n1', title: 'Order Received', description: 'New order #101', type: NotificationType.orderUpdate, timestamp: DateTime.now().subtract(Duration(minutes: 2)), read: false),
      NotificationItem(id: 'n2', title: 'Menu Updated', description: 'Special added to menu', type: NotificationType.info, timestamp: DateTime.now().subtract(Duration(hours: 1)), read: true),
      NotificationItem(id: 'n3', title: 'Payment Failed', description: 'Payment for #99 failed', type: NotificationType.payment, timestamp: DateTime.now().subtract(Duration(days: 1)), read: false),
    ]);
  }

  void openPanel() => panelOpen.value = true;
  void closePanel() => panelOpen.value = false;
  void togglePanel() => panelOpen.value = !panelOpen.value;

  void markAsRead(String id) {
    final i = notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      notifications[i].read = true;
      notifications.refresh();
    }
  }

  void markAllRead() {
    for (var n in notifications) {
      n.read = true;
    }
    notifications.refresh();
  }

  void delete(String id) {
    final i = notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      _lastRemoved = notifications[i];
      _lastWasArchived = false;
      notifications.removeAt(i);
    }
  }

  void archive(String id) {
    final i = notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      _lastRemoved = notifications[i];
      _lastWasArchived = true;
      archived.insert(0, notifications.removeAt(i));
    }
  }

  /// Undo last delete or archive (if exists)
  void undoLast() {
    if (_lastRemoved == null) return;
    if (_lastWasArchived) {
      // remove from archived if present and restore to main list
      archived.removeWhere((n) => n.id == _lastRemoved!.id);
      notifications.insert(0, _lastRemoved!);
    } else {
      // restore deletion
      notifications.insert(0, _lastRemoved!);
    }
    _lastRemoved = null;
    _lastWasArchived = false;
  }

  void clearAll() {
    notifications.clear();
  }

  // UI helpers
  void setQuery(String q) => query.value = q.trim();
  void toggleUnreadOnly() => showUnreadOnly.value = !showUnreadOnly.value;
  void setTypeFilter(NotificationType? t) => typeFilter.value = t;

  List<NotificationItem> get filtered {
    return notifications.where((n) {
      if (showUnreadOnly.value && n.read) return false;
      if (typeFilter.value != null && n.type != typeFilter.value) return false;
      final q = query.value.toLowerCase();
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) || n.description.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Map<String, List<NotificationItem>> groupedByDay(List<NotificationItem> list) {
    final map = <String, List<NotificationItem>>{};
    for (final n in list) {
      final key = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day).toIso8601String();
      map.putIfAbsent(key, () => []).add(n);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }
}
