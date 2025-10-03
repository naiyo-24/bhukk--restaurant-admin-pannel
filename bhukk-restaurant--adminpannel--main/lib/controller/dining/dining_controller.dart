// controller/dining/dining_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiningController extends GetxController {
  /// Add a new table (booking) with custom details from FAB/modal
  void addTable(int tableNumber, int capacity, String location, BookingStatus status, {String? waiter, String? notes}) {
    final id = 'T${tableNumber}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    bookings.add(Booking(
      id: id,
      time: now,
      capacity: capacity,
      location: location,
      status: status,
      waiter: waiter,
      notes: notes,
    ));
    Get.snackbar('Table Added', 'Table $tableNumber added', snackPosition: SnackPosition.BOTTOM);
  }
  final bookings = <Booking>[].obs;

  // Form controllers
  final dateTime = Rxn<DateTime>();
  final capacity = 2.obs;
  final location = ''.obs;
  final keepForm = false.obs; // when true, don't clear form after saving

  final formKey = GlobalKey<FormState>();

  void addBooking() {
    if (!(formKey.currentState?.validate() ?? false) || dateTime.value == null) {
      Get.snackbar('Invalid', 'Please fill all fields', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    bookings.add(Booking(
      id: id,
      time: dateTime.value!,
      capacity: capacity.value,
      location: location.value,
      status: BookingStatus.available,
    ));
  if (!keepForm.value) clearForm();
    Get.snackbar('Success', 'Booking added', snackPosition: SnackPosition.BOTTOM);
  }

  void editBooking(Booking booking) {
    dateTime.value = booking.time;
    capacity.value = booking.capacity;
    location.value = booking.location;
  }

  void updateBooking(String id) {
    final index = bookings.indexWhere((b) => b.id == id);
    if (index == -1) return;
    if (!(formKey.currentState?.validate() ?? false) || dateTime.value == null) {
      Get.snackbar('Invalid', 'Please fill all fields', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    bookings[index] = bookings[index].copyWith(
      time: dateTime.value!,
      capacity: capacity.value,
      location: location.value,
    );
    clearForm();
    Get.snackbar('Updated', 'Booking updated', snackPosition: SnackPosition.BOTTOM);
  }

  void cancelBooking(String id) {
    final index = bookings.indexWhere((b) => b.id == id);
    if (index == -1) return;
    bookings[index] = bookings[index].copyWith(status: BookingStatus.cancelled);
  }

  void deleteBooking(String id) {
    bookings.removeWhere((b) => b.id == id);
  }

  void cancelAll() {
    for (int i = 0; i < bookings.length; i++) {
      bookings[i] = bookings[i].copyWith(status: BookingStatus.cancelled);
    }
  }

  void deleteAll() {
    bookings.clear();
  }

  void clearForm() {
    dateTime.value = null;
    capacity.value = 2;
    location.value = '';
  }
}

enum BookingStatus { available, occupied, reserved, cleaning, cancelled }

class Booking {
  final String id;
  final DateTime time;
  final int capacity;
  final String location;
  final BookingStatus status;
  final String? waiter;
  final String? notes;
  final int? mergedWith; // table number if merged
  final int? splitFrom; // table number if split
  final int usageCount;
  final int turnoverCount;

  Booking({
    required this.id,
    required this.time,
    required this.capacity,
    required this.location,
    required this.status,
    this.waiter,
    this.notes,
    this.mergedWith,
    this.splitFrom,
    this.usageCount = 0,
    this.turnoverCount = 0,
  });

  Booking copyWith({
    DateTime? time,
    int? capacity,
    String? location,
    BookingStatus? status,
    String? waiter,
    String? notes,
    int? mergedWith,
    int? splitFrom,
    int? usageCount,
    int? turnoverCount,
  }) => Booking(
        id: id,
        time: time ?? this.time,
        capacity: capacity ?? this.capacity,
        location: location ?? this.location,
        status: status ?? this.status,
        waiter: waiter ?? this.waiter,
        notes: notes ?? this.notes,
        mergedWith: mergedWith ?? this.mergedWith,
        splitFrom: splitFrom ?? this.splitFrom,
        usageCount: usageCount ?? this.usageCount,
        turnoverCount: turnoverCount ?? this.turnoverCount,
      );
}
