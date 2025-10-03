// controller/delivery/delivery_controller.dart
import 'package:get/get.dart';
import '../../models/delivery_partner_model.dart';

class DeliveryController extends GetxController {
  final partner = DeliveryPartnerModel(
    id: 'p1',
    name: 'Ramesh Kumar',
    phone: '+919900112233',
    email: 'ramesh@example.com',
    isOnline: true,
    vehicleType: 'Bike',
    vehicleNumber: 'KA-05 AB 1234',
    rating: 4.7,
    completedDeliveries: 128,
    cancellations: 3,
  ).obs;

  // full list of partners for dashboard metrics
  final partners = <DeliveryPartnerModel>[].obs;
  final showOnlyOnline = false.obs;
  final partnerSearch = ''.obs; // search query for partners
  final _debounceMs = 250;
  Worker? _searchWorker;

  final activeAssignments = <DeliveryAssignment>[].obs;
  final pastAssignments = <DeliveryAssignment>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    partners.addAll([
      partner.value,
      DeliveryPartnerModel(id: 'p2', name: 'Sita Verma', phone: '+919955667788', isOnline: true, vehicleType: 'Scooter', vehicleNumber: 'KA-03 CD 7788', rating: 4.9, completedDeliveries: 210, cancellations: 2),
      DeliveryPartnerModel(id: 'p3', name: 'Aman Singh', phone: '+919912345678', isOnline: false, vehicleType: 'Car', vehicleNumber: 'KA-01 EF 9090', rating: 4.2, completedDeliveries: 89, cancellations: 5),
      DeliveryPartnerModel(id: 'p4', name: 'John David', phone: '+919900000001', isOnline: true, vehicleType: 'Bike', vehicleNumber: 'KA-02 ZZ 3322', rating: 4.5, completedDeliveries: 54, cancellations: 1),
    ]);

    activeAssignments.addAll([
      DeliveryAssignment(
        id: 'a1',
        orderId: 'ORD-1001',
  partnerId: 'p2',
        pickup: 'Restaurant',
        drop: '12, Market Road',
        status: AssignmentStatus.inProgress,
        items: [DeliveredItem(name: 'Burger', quantity: 2), DeliveredItem(name: 'Fries', quantity: 1)],
      ),
      DeliveryAssignment(
        id: 'a2',
        orderId: 'ORD-1002',
  partnerId: 'p4',
        pickup: 'Warehouse',
        drop: '45, Lake View',
        status: AssignmentStatus.pending,
        items: [DeliveredItem(name: 'Pizza', quantity: 1)],
      ),
    ]);

    pastAssignments.addAll([
      DeliveryAssignment(
        id: 'p1',
        orderId: 'ORD-0999',
        pickup: 'Restaurant',
        drop: '9, Hill St',
        status: AssignmentStatus.completed,
        assignedAt: DateTime.now().subtract(const Duration(days: 2)),
        items: [DeliveredItem(name: 'Pasta', quantity: 1)],
      ),
      DeliveryAssignment(
        id: 'p2',
        orderId: 'ORD-0998',
        pickup: 'Restaurant',
        drop: '77, River Road',
        status: AssignmentStatus.cancelled,
        assignedAt: DateTime.now().subtract(const Duration(days: 5)),
        cancelledBy: 'Customer',
        cancelReason: 'Changed mind',
        items: [DeliveredItem(name: 'Salad', quantity: 2)],
      ),
    ]);

  // Debounce search updates to avoid rebuild thrash
  _searchWorker = debounce(partnerSearch, (_) => partners.refresh(), time: Duration(milliseconds: _debounceMs));
  }

  void toggleOnline() {
    partner.update((p) {
      if (p != null) p.isOnline = !p.isOnline;
    });
  }

  void reassign(String assignmentId) {
    // simulate a reassign: set to pending and show feedback
    final idx = activeAssignments.indexWhere((a) => a.id == assignmentId);
    if (idx != -1) {
      activeAssignments[idx].status = AssignmentStatus.pending;
      activeAssignments.refresh();
      Get.snackbar('Reassign', 'Assignment ${activeAssignments[idx].orderId} marked for reassignment', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void track(String assignmentId) {
    try {
      final a = activeAssignments.firstWhere((e) => e.id == assignmentId);
      Get.snackbar('Track', 'Tracking ${a.orderId}', snackPosition: SnackPosition.BOTTOM);
    } catch (_) {}
  }

  void sortPast({bool newestFirst = true}) {
    pastAssignments.sort((a, b) {
      final aTime = a.assignedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.assignedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return newestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });
    pastAssignments.refresh();
  }

  // Derived metrics
  int get totalPartners => partners.length;
  int get onlinePartners => onlinePartnerList.length;
  int get offlinePartners => offlinePartnerList.length;
  int get suspendedPartners => suspendedPartnerList.length;

  // Helper to check if a DateTime falls on today (local)
  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  // Lists backing the metrics (used also for popups)
  List<DeliveryPartnerModel> get onlinePartnerList => partners.where((p) => p.isOnline && !p.isSuspended).toList();
  List<DeliveryPartnerModel> get offlinePartnerList => partners.where((p) => !p.isOnline).toList();
  List<DeliveryPartnerModel> get suspendedPartnerList => partners.where((p) => p.isSuspended).toList();

  List<DeliveryAssignment> get todayAssignments => [
        ...activeAssignments,
        ...pastAssignments.where((a) => a.assignedAt != null && _isToday(a.assignedAt!)),
      ];
  List<DeliveryAssignment> get deliveredTodayAssignments => pastAssignments
      .where((a) => a.status == AssignmentStatus.completed && a.assignedAt != null && _isToday(a.assignedAt!))
      .toList();
  List<DeliveryAssignment> get cancelledTodayAssignments => pastAssignments
      .where((a) => a.status == AssignmentStatus.cancelled && a.assignedAt != null && _isToday(a.assignedAt!))
      .toList();

  int get todayOrders => todayAssignments.length;
  int get deliveredToday => deliveredTodayAssignments.length;
  int get cancelledToday => cancelledTodayAssignments.length;

  void toggleFilterOnline() {
    showOnlyOnline.toggle();
    partners.refresh();
  }

  List<DeliveryPartnerModel> get filteredPartners => showOnlyOnline.value ? partners.where((p) => p.isOnline && !p.isSuspended).toList() : partners;

  // Partners currently delivering (have in-progress assignment)
  List<DeliveryPartnerModel> get deliveringPartners {
    final activePartnerIds = activeAssignments.where((a) => a.status == AssignmentStatus.inProgress && a.partnerId != null).map((a) => a.partnerId).toSet();
    return partners.where((p) => activePartnerIds.contains(p.id)).toList();
  }

  // Partners available (online & not suspended & not currently in-progress assignment)
  List<DeliveryPartnerModel> get availablePartnersForNew {
    final busy = activeAssignments.where((a) => a.status == AssignmentStatus.inProgress && a.partnerId != null).map((a) => a.partnerId).toSet();
    return partners.where((p) => p.isOnline && !p.isSuspended && !busy.contains(p.id)).toList();
  }
  
  List<DeliveryPartnerModel> get searchedPartners {
    final base = filteredPartners;
    final q = partnerSearch.value.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.phone.toLowerCase().contains(q) ||
      (p.vehicleNumber?.toLowerCase().contains(q) ?? false) ||
      (p.vehicleType?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  void setPartnerSearch(String value) {
    partnerSearch.value = value;
  }

  void suspendPartner(String id, {bool suspend = true}) {
    final idx = partners.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    partners[idx].isSuspended = suspend;
    partners.refresh();
    Get.snackbar('Partner', suspend ? 'Partner suspended' : 'Partner unsuspended', snackPosition: SnackPosition.BOTTOM);
  }

  void updatePartnerOnline(String id, bool online) {
    final idx = partners.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    partners[idx].isOnline = online;
    partners.refresh();
  }

  void completeAssignment(String assignmentId) {
    final idx = activeAssignments.indexWhere((a) => a.id == assignmentId);
    if (idx == -1) return;
    final a = activeAssignments.removeAt(idx);
    a.status = AssignmentStatus.completed;
    a.assignedAt = DateTime.now();
    pastAssignments.insert(0, a);
    activeAssignments.refresh();
    pastAssignments.refresh();
    Get.snackbar('Completed', '${a.orderId} marked as completed', snackPosition: SnackPosition.BOTTOM);
  }

  void cancelAssignment(String assignmentId) {
    final idx = activeAssignments.indexWhere((a) => a.id == assignmentId);
    if (idx == -1) return;
    final a = activeAssignments.removeAt(idx);
    a.status = AssignmentStatus.cancelled;
    a.assignedAt = DateTime.now();
    pastAssignments.insert(0, a);
    activeAssignments.refresh();
    pastAssignments.refresh();
    Get.snackbar('Cancelled', '${a.orderId} cancelled', snackPosition: SnackPosition.BOTTOM);
  }

  Map<String, dynamic> assignmentDetails(String id) {
    final a = getAssignment(id);
    if (a == null) return {};
    return {
      'orderId': a.orderId,
      'pickup': a.pickup,
      'drop': a.drop,
      'status': a.statusLabel,
      'items': a.items.map((e) => {'name': e.name, 'qty': e.quantity}).toList(),
      'cancelledBy': a.cancelledBy,
      'cancelReason': a.cancelReason,
    };
  }

  DeliveryAssignment? getAssignment(String id) {
    try {
      return activeAssignments.firstWhere((a) => a.id == id);
    } catch (_) {
      try {
        return pastAssignments.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void addAssignment(DeliveryAssignment a) {
    activeAssignments.insert(0, a);
    activeAssignments.refresh();
  }

  void filterPastByStatus(AssignmentStatus? status) {
    if (status == null) return;
    final filtered = pastAssignments.where((p) => p.status == status).toList();
    pastAssignments.assignAll(filtered);
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    isLoading.value = false;
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }
}
