// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/app_pages.dart';
import 'controller/notification_controller.dart';
import 'controller/orders/orders_controller.dart';
import 'utils/app_globals.dart';
import 'controller/orders/order_panel_controller.dart';
import 'controller/account/account_controller.dart';
import 'controller/common/layout_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bhukk Admin',
      theme: AppTheme.themeData,
      initialRoute: AppRoutes.splash,
  scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey,
      initialBinding: BindingsBuilder(() {
        Get.put(OrdersController(), permanent: true);
        Get.put(NotificationController(), permanent: true);
        Get.put(OrderSidePanelController(), permanent: true);
  Get.put(AccountController(), permanent: true);
        Get.put(LayoutController(), permanent: true);
      }),
      getPages: AppPages.pages,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
