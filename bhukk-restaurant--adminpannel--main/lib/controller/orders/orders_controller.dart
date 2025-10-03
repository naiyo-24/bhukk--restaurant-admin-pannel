// controller/orders/orders_controller.dart
import 'package:get/get.dart';
import 'dart:async';
import '../../models/order_model.dart';

class DeliveryPartner {
  final String name;
  final String phone;
  final double lat;
  final double lng;
  DeliveryPartner({required this.name, required this.phone, required this.lat, required this.lng});
}

enum OrderSort { newest, oldest, amountHigh, amountLow }

class OrdersController extends GetxController {
  final orders = <OrderModel>[].obs;
  Timer? _autoGenTimer; // periodically simulate incoming orders
  int _autoCounter = 2000; // id suffix base

  // delivery partner mapping: orderId -> partner name
  final deliveryPartners = <String, String>{}.obs;

  // timeline events mapping: orderId -> list of (label, datetime)
  final timelines = <String, List<Map<String, dynamic>>>{}.obs;

  // delivery partner details: orderId -> partner object
  final partners = <String, DeliveryPartner>{}.obs;

  // pool of available partners (mock)
  final availablePartners = <DeliveryPartner>[].obs;

  // UI state
  final Rxn<OrderStatus> statusFilter = Rxn<OrderStatus>(); // null = all
  final search = ''.obs;
  final filtersVisible = true.obs;
  final sort = OrderSort.newest.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMock();
    _startAutoGeneration();
  }

  void _startAutoGeneration() {
    _autoGenTimer?.cancel();
    _autoGenTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // 25% chance to simulate a new pending order to avoid spamming
      final now = DateTime.now();
      if (now.second % 4 != 0) return; // simple pseudo randomness without math import
      final id = 'ORD-A${_autoCounter++}';
      // ensure id uniqueness
      if (orders.any((o) => o.id == id)) return;
      final newOrder = OrderModel(
        id: id,
        customerName: 'Auto User ${_autoCounter % 50}',
        phone: '555-${1000 + (_autoCounter % 900)}',
        address: 'Auto Street ${(10 + _autoCounter) % 99}',
        dateTime: DateTime.now(),
        items: [OrderItem(name: 'Item ${_autoCounter % 7}', qty: 1, price: 4.0 + (_autoCounter % 5))],
        status: OrderStatus.pending,
        source: OrderSource.food,
      );
      addOrder(newOrder);
    });
  }

  @override
  void onClose() {
    _autoGenTimer?.cancel();
    super.onClose();
  }

  void _loadMock() {
    orders.assignAll([
      OrderModel(
        id: 'ORD-1001',
        customerName: 'Alice Cooper',
        phone: '555-1111',
        address: '12 Baker St.',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        items: [OrderItem(name: 'Burger', qty: 2, price: 5.99), OrderItem(name: 'Fries', qty: 1, price: 2.99)],
        status: OrderStatus.delivered,
        source: OrderSource.food,
      ),
      OrderModel(
        id: 'ORD-1002',
        customerName: 'Cara Lane',
        phone: '555-2222',
        address: '88 Ocean Ave',
        dateTime: DateTime.now().subtract(const Duration(hours: 6)),
        items: [OrderItem(name: 'Steak', qty: 1, price: 19.99)],
        status: OrderStatus.pending,
        source: OrderSource.dining,
      ),
      OrderModel(
        id: 'ORD-1003',
        customerName: 'Bob Marley',
        phone: '555-3333',
        address: '3 Reggae Rd',
        dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        items: [OrderItem(name: 'Salad', qty: 1, price: 7.5)],
        status: OrderStatus.cancelled,
        source: OrderSource.liquor,
      ),
      OrderModel(
        id: 'ORD-1004',
        customerName: 'Dana Scully',
        phone: '555-4444',
        address: '9 Mystery Ln',
        dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
        items: [OrderItem(name: 'Pizza', qty: 1, price: 12.99), OrderItem(name: 'Soda', qty: 2, price: 1.99)],
        status: OrderStatus.pending,
        source: OrderSource.food,
      ),
    ]);

    // mock timeline & partner
    timelines['ORD-1001'] = [
      {'label': 'Placed', 'time': DateTime.now().subtract(const Duration(hours: 2, minutes: 5))},
      {'label': 'Accepted', 'time': DateTime.now().subtract(const Duration(hours: 2))},
      {'label': 'Out for Delivery', 'time': DateTime.now().subtract(const Duration(hours: 1, minutes: 30))},
      {'label': 'Delivered', 'time': DateTime.now().subtract(const Duration(hours: 1))},
    ];

    timelines['ORD-1002'] = [
      {'label': 'Placed', 'time': DateTime.now().subtract(const Duration(hours: 6, minutes: 10))},
      {'label': 'Preparing', 'time': DateTime.now().subtract(const Duration(hours: 5, minutes: 50))},
    ];

    timelines['ORD-1003'] = [
      {'label': 'Placed', 'time': DateTime.now().subtract(const Duration(days: 1, hours: 3, minutes: 5))},
      {'label': 'Cancelled', 'time': DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 50))},
    ];

    timelines['ORD-1004'] = [
      {'label': 'Placed', 'time': DateTime.now().subtract(const Duration(minutes: 50))},
      {'label': 'Accepted', 'time': DateTime.now().subtract(const Duration(minutes: 48))},
    ];

    deliveryPartners['ORD-1004'] = 'Partner Alpha';
    partners['ORD-1004'] = DeliveryPartner(name: 'Partner Alpha', phone: '+91-99999-00004', lat: 12.934, lng: 77.610);
    partners['ORD-1001'] = DeliveryPartner(name: 'Partner Beta', phone: '+91-99999-00001', lat: 12.940, lng: 77.615);

    // populate available partners pool
    availablePartners.assignAll([
      DeliveryPartner(name: 'Partner Alpha', phone: '+91-99999-00004', lat: 12.934, lng: 77.610),
      DeliveryPartner(name: 'Partner Beta', phone: '+91-99999-00001', lat: 12.940, lng: 77.615),
      DeliveryPartner(name: 'Partner Gamma', phone: '+91-99999-00002', lat: 12.935, lng: 77.600),
    ]);
  }

  List<OrderModel> filteredBySource(OrderSource s) {
    return filteredOrders.where((o) => o.source == s).toList();
  }

  List<OrderModel> get all => orders;

  List<OrderModel> get filteredOrders {
    final s = search.value.trim().toLowerCase();
    final list = orders.where((o) {
      if (statusFilter.value != null && o.status != statusFilter.value) return false;
      if (s.isEmpty) return true;
      return o.id.toLowerCase().contains(s) || o.customerName.toLowerCase().contains(s) || o.phone.toLowerCase().contains(s);
    }).toList();

    // apply sorting
    switch (sort.value) {
      case OrderSort.oldest:
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case OrderSort.amountHigh:
        list.sort((a, b) => b.total.compareTo(a.total));
        break;
      case OrderSort.amountLow:
        list.sort((a, b) => a.total.compareTo(b.total));
        break;
      case OrderSort.newest:
        list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
    }

    return list;
  }

  void setFilter(OrderStatus? s) => statusFilter.value = s;
  void setSearch(String q) => search.value = q;

  void toggleFilters() => filtersVisible.value = !filtersVisible.value;
  void setSort(OrderSort s) => sort.value = s;

  void clearFilters() {
    statusFilter.value = null;
    search.value = '';
    sort.value = OrderSort.newest;
  }

  void updateStatus(String id, OrderStatus s) {
    final i = orders.indexWhere((o) => o.id == id);
    if (i >= 0) orders[i] = orders[i].copyWith(status: s);
    // add timeline entry
    timelines[id] = ([...(timelines[id] ?? []), {
      'label': _statusToLabel(s),
      'time': DateTime.now(),
    }]);
    orders.refresh();
  }

  // Convenience: add a new order (e.g., from API), triggers immediate popup via NotificationController worker
  void addOrder(OrderModel o) {
    orders.insert(0, o);
  }

  String _statusToLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Updated';
    }
  }

  void assignPartner(String orderId, String partnerName) {
    deliveryPartners[orderId] = partnerName;
    // also create a partner entry with a placeholder phone
  final found = availablePartners.firstWhereOrNull((p) => p.name == partnerName);
  partners[orderId] = found ?? DeliveryPartner(name: partnerName, phone: '+91-99999-00000', lat: 12.93, lng: 77.61);
    Get.snackbar('Partner assigned', '$partnerName assigned to $orderId', snackPosition: SnackPosition.BOTTOM);
  }

  // Tracking simulation - returns a stream of mock locations (lat,lng,eta)
  Stream<Map<String, dynamic>> trackPartner(String orderId) async* {
    final p = partners[orderId];
    if (p == null) {
      yield {'error': 'No partner'};
      return;
    }

    // simple simulated movement: yield 6 updates with decreasing ETA
    for (var i = 6; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      yield {
        'lat': p.lat + (6 - i) * 0.00012,
        'lng': p.lng + (6 - i) * 0.00009,
        'eta_seconds': i * 120,
        'speed_kmph': (20 + (6 - i) * 2),
        'heading': (90 + (6 - i) * 5),
      };
    }
  }

  String partnerStatus(String orderId) {
    final p = partners[orderId];
    if (p == null) return 'Unassigned';
    // mock networked status
    return 'Online';
  }

  void cancelWithReason(String orderId, String reason) {
    updateStatus(orderId, OrderStatus.cancelled);
    Get.snackbar('Order cancelled', 'Reason: $reason', snackPosition: SnackPosition.BOTTOM);
  }

  void processRefund(String orderId, double amount) {
    if (amount <= 0) return;
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = orders[i];
    // Insert a negative line item so model recomputes totals (tax excluded for negative items per model logic)
    final adj = OrderItem(name: 'Refund Adjustment', qty: 1, price: -amount);
    orders[i] = o.copyWith(items: [...o.items, adj]);
    orders.refresh();
    timelines[orderId] = ([...(timelines[orderId] ?? []), {
      'label': 'Refunded',
      'time': DateTime.now(),
      'amount': amount,
    }]);
    Get.snackbar('Refund', 'Refunded ₹${amount.toStringAsFixed(0)} on $orderId', snackPosition: SnackPosition.BOTTOM);
  }

  void applyDiscount(String orderId, double amount) {
    if (amount <= 0) return;
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = orders[i];
    final adj = OrderItem(name: 'Discount', qty: 1, price: -amount);
    orders[i] = o.copyWith(items: [...o.items, adj]);
    orders.refresh();
    timelines[orderId] = ([...(timelines[orderId] ?? []), {
      'label': 'Discount Applied',
      'time': DateTime.now(),
      'amount': amount,
    }]);
    Get.snackbar('Discount', 'Discount ₹${amount.toStringAsFixed(0)} added to $orderId', snackPosition: SnackPosition.BOTTOM);
  }

  void editOrder(String id, {String? customerName, String? phone, String? address}) {
    final i = orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    final o = orders[i];
    orders[i] = o.copyWith(
      customerName: customerName ?? o.customerName,
      phone: phone ?? o.phone,
      address: address ?? o.address,
    );
  }

  void updateItemQuantity(String orderId, int index, int qty) {
    if (qty < 1) return; // do not allow zero; use remove instead
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = orders[i];
    if (index < 0 || index >= o.items.length) return;
    final newItems = [...o.items];
    final it = newItems[index];
    newItems[index] = OrderItem(name: it.name, qty: qty, price: it.price);
    orders[i] = o.copyWith(items: newItems);
    orders.refresh();
    timelines[orderId] = ([...(timelines[orderId] ?? []), {
      'label': 'Item qty updated (${it.name} → $qty)',
      'time': DateTime.now(),
    }]);
  }

  void removeItem(String orderId, int index) {
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = orders[i];
    if (index < 0 || index >= o.items.length) return;
    final newItems = [...o.items]..removeAt(index);
    orders[i] = o.copyWith(items: newItems);
    orders.refresh();
    timelines[orderId] = ([...(timelines[orderId] ?? []), {
      'label': 'Item removed',
      'time': DateTime.now(),
    }]);
  }

  void addItem(String orderId, {required String name, required int qty, required double price}) {
    if (qty < 1 || price < 0) return;
    final i = orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = orders[i];
    final newItems = [...o.items, OrderItem(name: name, qty: qty, price: price)];
    orders[i] = o.copyWith(items: newItems);
    orders.refresh();
    timelines[orderId] = ([...(timelines[orderId] ?? []), {
      'label': 'Item added ($name x$qty)',
      'time': DateTime.now(),
      'amount': price * qty,
    }]);
  }

  void deleteOrder(String id) => orders.removeWhere((o) => o.id == id);
}
