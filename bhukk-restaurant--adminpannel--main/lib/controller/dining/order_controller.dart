// controller/dining/order_controller.dart
import 'package:get/get.dart';
import '../../models/order_model.dart';

class OrderController extends GetxController {
  var orders = <OrderModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    orders.value = List.generate(3, (i) => OrderModel(
      id: '#${1000+i}',
      customerName: 'Customer $i',
      dateTime: DateTime.now().add(Duration(hours: i)),
      items: [
        OrderItem(name: 'Paneer Tikka', qty: 2, price: 250),
        OrderItem(name: 'Biryani', qty: 1, price: 300),
      ],
      status: OrderStatus.pending,
      source: OrderSource.dining,
    ));
  }

  void addOrder(OrderModel order) {
    orders.add(order);
  }

  void updateOrder(int index, OrderModel updated) {
    orders[index] = updated;
  }

  void deleteOrder(int index) {
    orders.removeAt(index);
  }
}
