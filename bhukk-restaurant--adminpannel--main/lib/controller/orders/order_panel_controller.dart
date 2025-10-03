// controller/orders/order_panel_controller.dart
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/order_model.dart';
import 'orders_controller.dart';

class OrderSidePanelController extends GetxController {
  final panelOpen = false.obs;
  final incoming = <OrderModel>[].obs; // newest first
  final _actedIds = <String>{}.obs; // remember items user accepted/rejected
  DateTime? _snoozeUntil; // prevents auto-open when user dismissed

  @override
  void onInit() {
    super.onInit();
    // Watch orders list and feed pending items
    if (Get.isRegistered<OrdersController>()) {
      final oc = Get.find<OrdersController>();
      // seed from current
      final pending = oc.orders.where((o) => o.status == OrderStatus.pending).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      incoming.assignAll(pending);
      _autoToggle();

      ever<List<OrderModel>>(oc.orders, (list) {
        final currentIds = incoming.map((o) => o.id).toSet();
        // add new pending not acted and not already present
        final newOnes = list.where((o) => o.status == OrderStatus.pending && !_actedIds.contains(o.id) && !currentIds.contains(o.id)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        if (newOnes.isNotEmpty) {
          // haptic on first add
          HapticFeedback.mediumImpact();
          incoming.insertAll(0, newOnes);
          _open();
        }
        // Remove those that are no longer pending
        incoming.removeWhere((o) => list.firstWhereOrNull((x) => x.id == o.id)?.status != OrderStatus.pending);
        _autoToggle();
      });
    }
  }

  void _autoToggle() {
    if (incoming.isEmpty) {
      panelOpen.value = false;
    } else {
      panelOpen.value = true;
    }
  }

  void _open() => panelOpen.value = true;
  void close() => panelOpen.value = false;

  // Expose opening for reminder nudges
  void open() => panelOpen.value = true;

  bool get isSnoozed => _snoozeUntil != null && DateTime.now().isBefore(_snoozeUntil!);
  void clearSnooze() => _snoozeUntil = null;
  void closeAndSnooze([Duration d = const Duration(seconds: 60)]) {
    panelOpen.value = false;
    _snoozeUntil = DateTime.now().add(d);
  }

  void addIncoming(OrderModel o) {
    if (_actedIds.contains(o.id)) return;
    if (incoming.any((e) => e.id == o.id)) return;
    HapticFeedback.selectionClick();
    incoming.insert(0, o);
  // a real incoming item should override any snooze
  clearSnooze();
    _open();
  }

  void accept(String id) {
    final oc = Get.find<OrdersController>();
    // mimic earlier behavior: log accepted in timeline
    oc.timelines[id] = ([...(oc.timelines[id] ?? []), {'label': 'Accepted', 'time': DateTime.now()}]);
    _actedIds.add(id);
    incoming.removeWhere((e) => e.id == id);
    _autoToggle();
  }

  void reject(String id) {
    final oc = Get.find<OrdersController>();
    oc.updateStatus(id, OrderStatus.cancelled);
    _actedIds.add(id);
    incoming.removeWhere((e) => e.id == id);
    _autoToggle();
  }
}
