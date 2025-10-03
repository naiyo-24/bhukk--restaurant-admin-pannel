// controller/liquor/liquor_controller.dart
import 'dart:math';
import 'package:get/get.dart';
import '../../models/liquor_model.dart';

class LiquorController extends GetxController {
  static LiquorController get to => Get.find();

  final liquors = <LiquorModel>[].obs;

  String _genId() {
    final rnd = Random();
    final t = DateTime.now().microsecondsSinceEpoch;
    final r = rnd.nextInt(1000000);
    return '\$${t}_$r';
  }

  @override
  void onInit() {
    super.onInit();
    _loadMock();
  }

  void _loadMock() {
    liquors.assignAll([
  LiquorModel(id: _genId(), name: 'Royal Whiskey', type: 'Whiskey', price: 59.99, age: '21+', imageUrl: null, description: 'Aged 12 years', available: true, volumeMl: 750, quantity: 8),
  LiquorModel(id: _genId(), name: 'Ocean Vodka', type: 'Vodka', price: 29.99, age: '21+', imageUrl: null, description: 'Smooth and clear', available: false, volumeMl: 700, quantity: 0),
  LiquorModel(id: _genId(), name: 'Garden Beer', type: 'Beer', price: 4.99, age: '18+', imageUrl: null, description: 'Crisp lager', available: true, volumeMl: 330, quantity: 42),
    ]);
  }

  void addLiquor(LiquorModel item) {
    liquors.insert(0, item);
    Get.snackbar('Liquor', 'Added ${item.name}', snackPosition: SnackPosition.BOTTOM);
    Get.log('LiquorController.addLiquor id=${item.id} names=${liquors.map((e) => e.id).toList()}');
  }

  void editLiquor(String id, LiquorModel updated) {
    final idx = liquors.indexWhere((e) => e.id == id);
    if (idx >= 0) liquors[idx] = updated;
    Get.snackbar('Liquor', 'Updated ${updated.name}', snackPosition: SnackPosition.BOTTOM);
    Get.log('LiquorController.editLiquor id=$id idx=$idx names=${liquors.map((e) => e.id).toList()}');
  }

  void deleteLiquor(String id) {
    final idx = liquors.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final removed = liquors.removeAt(idx);
      Get.snackbar('Liquor', 'Deleted ${removed.name}', snackPosition: SnackPosition.BOTTOM);
      Get.log('LiquorController.deleteLiquor id=$id idx=$idx names=${liquors.map((e) => e.id).toList()}');
    } else {
      Get.snackbar('Liquor', 'Item removed', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void toggleAvailability(String id) {
    final idx = liquors.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final item = liquors[idx];
      liquors[idx] = item.copyWith(available: !item.available);
      Get.log('LiquorController.toggleAvailability id=$id idx=$idx available=${liquors[idx].available}');
    }
  }

  /// Set availability explicitly (reactive-friendly)
  void setAvailability(String id, bool available) {
    final idx = liquors.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final item = liquors[idx];
      if (item.available != available) liquors[idx] = item.copyWith(available: available);
      Get.snackbar('Liquor', '${item.name} is now ${available ? 'available' : 'unavailable'}', snackPosition: SnackPosition.BOTTOM);
      Get.log('LiquorController.setAvailability id=$id idx=$idx available=$available');
    }
  }

  void updateStock(String id, {int? quantity, int? volumeMl}) {
    final idx = liquors.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final item = liquors[idx];
      liquors[idx] = item.copyWith(
        quantity: quantity ?? item.quantity,
        volumeMl: volumeMl ?? item.volumeMl,
      );
      Get.log('LiquorController.updateStock id=$id qty=${liquors[idx].quantity} ml=${liquors[idx].volumeMl}');
    }
  }
}
