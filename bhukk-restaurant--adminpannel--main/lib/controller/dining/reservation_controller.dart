// controller/dining/reservation_controller.dart
import 'package:get/get.dart';
import '../../models/reservation_model.dart';

class ReservationController extends GetxController {
  var reservations = <ReservationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    reservations.value = List.generate(5, (i) => ReservationModel(
      id: '#R00$i',
      customer: 'Customer $i',
      dateTime: DateTime.now().add(Duration(hours: i)),
      guests: 4,
      tables: ['Table ${i+1}'],
      status: ['Pending','Confirmed','Cancelled','Completed','No-Show'][i%5],
    ));
  }

  void addReservation(ReservationModel reservation) {
    reservations.add(reservation);
  }

  void updateReservation(int index, ReservationModel updated) {
    reservations[index] = updated;
  }

  void deleteReservation(int index) {
    reservations.removeAt(index);
  }
}
