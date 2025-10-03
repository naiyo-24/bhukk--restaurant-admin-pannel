// widgets/sidebar.dart
// widgets/sidebar.dart (clean implementation)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../controller/account/account_controller.dart';
import '../controller/common/layout_controller.dart';

class Sidebar extends StatelessWidget {
	final Function(String route)? onNavigate;
	const Sidebar({super.key, this.onNavigate});

	@override
	Widget build(BuildContext context) {
		final layout = Get.isRegistered<LayoutController>() ? LayoutController.to : Get.put(LayoutController(), permanent: true);
		final isSmall = MediaQuery.of(context).size.width < 800;

		final items = <_SidebarItem>[
			_SidebarItem('Dashboard', Icons.dashboard, AppRoutes.dashboard),
			_SidebarItem('Menu', Icons.menu_book, AppRoutes.MENU),
			_SidebarItem('Dining', Icons.restaurant_menu, AppRoutes.DINING),
			_SidebarItem('Liquor', Icons.local_bar, AppRoutes.LIQUOR),
			_SidebarItem('Orders', Icons.receipt_long, AppRoutes.ORDERS),
			_SidebarItem('Earnings', Icons.attach_money, AppRoutes.EARNINGS),
			_SidebarItem('Payments', Icons.payment, AppRoutes.PAYMENT),
			_SidebarItem('Transactions', Icons.swap_horiz, AppRoutes.TRANSACTIONS),
			_SidebarItem('Delivery', Icons.delivery_dining, AppRoutes.DELIVERY),
			_SidebarItem('Customers', Icons.people, AppRoutes.CUSTOMER),
			_SidebarItem('Feedback', Icons.feedback, AppRoutes.FEEDBACK),
			_SidebarItem('Support', Icons.headset_mic, AppRoutes.SUPPORT),
			_SidebarItem('Settings', Icons.settings, AppRoutes.SETTINGS),
			_SidebarItem('Account', Icons.account_circle, AppRoutes.ACCOUNT),
		];

		return Obx(() {
			final collapsed = layout.collapsed.value;
			final current = Get.currentRoute;
			final accountCtrl = Get.isRegistered<AccountController>() ? Get.find<AccountController>() : null;
			final hasMissingDocs = accountCtrl?.hasMissingDocs.value ?? false;

			List<Widget> buildTiles() => items.map((item) {
						final selected = current == item.route;
						return Tooltip(
							message: collapsed ? item.label : '',
							waitDuration: const Duration(milliseconds: 300),
							child: ListTile(
								contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
								leading: Icon(item.icon, color: selected ? Colors.white : Colors.white70),
								title: collapsed
										? null
										: Text(
												item.label,
												style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 16),
											),
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
								hoverColor: Colors.white10,
								selected: selected,
								selectedTileColor: Colors.white12,
								onTap: () {
									if (onNavigate != null) {
										onNavigate!(item.route);
									} else {
										if (isSmall) Navigator.of(context).pop();
										Get.toNamed(item.route);
									}
								},
							),
						);
					}).toList();

			Widget buildHeader() {
				Widget logoImage({double padding = 6, double size = 44}) {
					return Container(
						width: size,
						height: size,
						decoration: BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.circular(10),
							boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
						),
						child: AnimatedScale(
							scale: collapsed ? 0.92 : 1.05, // slight zoom when expanded
							duration: const Duration(milliseconds: 280),
							curve: Curves.easeInOut,
							child: Padding(
								padding: EdgeInsets.all(padding),
								child: Image.asset(
									'assets/icons/logo.png',
									fit: BoxFit.contain,
									errorBuilder: (_, __, ___) => const FlutterLogo(),
								),
							),
						),
					);
				}
				final logo = logoImage();
				if (collapsed) {
					return Padding(
						padding: const EdgeInsets.only(top: 12, bottom: 8, left: 8, right: 8),
						child: Stack(
							clipBehavior: Clip.none,
							children: [
								logo,
								if (hasMissingDocs)
									Positioned(
										right: -2,
										top: -2,
										child: GestureDetector(
											onTap: () {
												if (onNavigate != null) {
													onNavigate!(AppRoutes.ACCOUNT);
												} else {
													if (isSmall) Navigator.of(context).pop();
													Get.toNamed(AppRoutes.ACCOUNT);
												}
											},
											child: Tooltip(
												message: 'Documents pending. Tap to manage.',
												child: Container(
													padding: const EdgeInsets.all(2),
													decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle),
													child: const Icon(Icons.assignment_late, size: 14, color: Colors.black87),
												),
											),
										),
									),
							],
						),
					);
				}
				return Padding(
					padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
					child: Row(
						children: [
							logo,
							const SizedBox(width: 12),
							const Expanded(
								child: Text('Bhukk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
							),
							if (hasMissingDocs)
								Tooltip(
									message: 'Documents pending. Tap to manage.',
									child: IconButton(
										icon: const Icon(Icons.assignment_late, color: Colors.yellowAccent),
										onPressed: () {
											if (onNavigate != null) {
												onNavigate!(AppRoutes.ACCOUNT);
											} else {
												if (isSmall) Navigator.of(context).pop();
												Get.toNamed(AppRoutes.ACCOUNT);
											}
										},
									),
								),
						],
					),
				);
			}

			return AnimatedContainer(
				duration: const Duration(milliseconds: 220),
				curve: Curves.easeInOut,
				width: collapsed ? 72 : 220,
				decoration: BoxDecoration(
					gradient: LinearGradient(
						begin: Alignment.topCenter,
						end: Alignment.bottomCenter,
						colors: [AppTheme.cherryRed, AppTheme.cherryRed.withAlpha(230)],
					),
					borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
					boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(2, 0))],
				),
				child: Column(
					children: [
						buildHeader(),
						Expanded(
							child: Theme(
								data: Theme.of(context).copyWith(
									dividerColor: AppTheme.cherryRed,
									listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),
								),
								child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: buildTiles()),
							),
						),
						const SizedBox(height: 20),
					],
				),
			);
		});
	}
}

class _SidebarItem {
	final String label;
	final IconData icon;
	final String route;
	_SidebarItem(this.label, this.icon, this.route);
}

