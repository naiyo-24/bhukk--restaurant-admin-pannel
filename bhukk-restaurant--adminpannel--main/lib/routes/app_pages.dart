// routes/app_pages.dart
import 'package:get/get.dart';
import 'app_routes.dart';
import '../widgets/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dining/dining_screen.dart';
import '../screens/liquor/liquor_screen.dart';
import '../screens/auth/phno_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/payments/payment_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/edit_account_screen.dart';
import '../screens/delivery/delivery_screen.dart';
import '../screens/delivery/delivery_chat_screen.dart';
import '../screens/delivery/driver_history_screen.dart';
import '../screens/chat/customer_chat_screen.dart';
import '../bindings/chat/chat_binding.dart';
import '../screens/customer/customer_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/settings/settings_screen.dart';
// Profile screen removed
import '../bindings/menu/menu_binding.dart';
import '../bindings/earnings/earnings_binding.dart';
import '../bindings/feedback/feedback_binding.dart';
import '../bindings/auth/auth_bindings.dart';
import '../bindings/account/account_binding.dart';
import '../bindings/delivery/delivery_binding.dart';
import '../bindings/liquor/liquor_binding.dart';
import '../bindings/support/support_binding.dart';

class AppPages {
	static final pages = [
		GetPage(
			name: AppRoutes.TRANSACTIONS,
			page: () => const TransactionsScreen(),
			binding: AccountBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.splash,
			page: () => const SplashScreen(),
			binding: AuthBindings(),
		),
		GetPage(
			name: AppRoutes.login,
			page: () => const PhnoScreen(),
			binding: AuthBindings(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 500),
		),
		GetPage(
			name: AppRoutes.signup,
			page: () => const SignupScreen(),
			binding: AuthBindings(),
			transition: Transition.rightToLeft,
			transitionDuration: Duration(milliseconds: 500),
		),
		GetPage(
			name: AppRoutes.dashboard,
			page: () => DashboardScreen(),
			binding: AuthBindings(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.MENU,
			page: () => const MenuScreen(),
			binding: MenuBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 500),
		),
		GetPage(
			name: AppRoutes.DINING,
			page: () => DiningScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.LIQUOR,
			page: () => const LiquorScreen(),
			binding: LiquorBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 300),
		),

		// Profile route removed
		GetPage(
			name: AppRoutes.EARNINGS,
			page: () => const EarningsScreen(),
			binding: EarningsBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.PAYMENT,
			page: () => const PaymentScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.DELIVERY,
			page: () => DeliveryScreen(),
			binding: DeliveryBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.CUSTOMER,
			page: () => const CustomerScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.DELIVERY_CHAT,
			page: () => DeliveryChatScreen(),
			transition: Transition.rightToLeft,
			transitionDuration: Duration(milliseconds: 300),
		),
		GetPage(
			name: AppRoutes.DRIVER_HISTORY,
			page: () => DriverHistoryScreen(),
			transition: Transition.rightToLeft,
			transitionDuration: Duration(milliseconds: 300),
		),
		GetPage(
			name: AppRoutes.CUSTOMER_CHAT,
			page: () => CustomerChatScreen(),
			binding: ChatBinding(),
			transition: Transition.rightToLeft,
			transitionDuration: Duration(milliseconds: 300),
		),
		GetPage(
			name: AppRoutes.SETTINGS,
			page: () => SettingsScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 300),
		),
		GetPage(
			name: AppRoutes.FEEDBACK,
			page: () => const FeedbackScreen(),
			binding: FeedbackBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.SUPPORT,
			page: () => const SupportScreen(),
			binding: SupportBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.ACCOUNT,
			page: () => AccountScreen(),
			binding: AccountBinding(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.EDIT_ACCOUNT,
			page: () => EditAccountScreen(),
			binding: AccountBinding(),
			transition: Transition.rightToLeft,
			transitionDuration: Duration(milliseconds: 350),
		),
		GetPage(
			name: AppRoutes.ORDERS,
			page: () => OrdersScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 400),
		),
		GetPage(
			name: AppRoutes.ORDER_HISTORY,
			page: () => OrderHistoryScreen(),
			transition: Transition.fadeIn,
			transitionDuration: Duration(milliseconds: 300),
		),
	];
}
