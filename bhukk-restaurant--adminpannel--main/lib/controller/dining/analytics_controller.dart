// controller/dining/analytics_controller.dart
import 'package:get/get.dart';

class AnalyticsController extends GetxController {
  var revenueToday = 12000.obs;
  var revenueWeek = 65000.obs;
  var revenueMonth = 210000.obs;
  var peakOccupancy = '7-9pm'.obs;
  var reservationStats = '80% confirmed, 10% no-show'.obs;
  var popularDishes = ['Paneer Tikka', 'Biryani'].obs;
  var staffPerformance = 'Avg serving time 12min'.obs;
}
