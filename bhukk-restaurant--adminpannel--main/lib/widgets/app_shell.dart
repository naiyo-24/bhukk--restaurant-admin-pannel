// widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/orders/order_panel_controller.dart';
import '../routes/app_routes.dart';
import 'order_side_panel.dart';
import 'sidebar.dart';
import '../controller/common/layout_controller.dart';

/// Wraps the whole app to support a responsive right-side panel that
/// pushes content on wide screens and overlays on small screens.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
  final ctrl = Get.isRegistered<OrderSidePanelController>()
    ? Get.find<OrderSidePanelController>()
    : Get.put(OrderSidePanelController(), permanent: true);
    return LayoutBuilder(builder: (context, cons) {
      final width = cons.maxWidth;
      final isDesktop = width >= 900;
      final panelWidth = isDesktop ? 420.0 : width; // push on desktop, overlay on small

      return Obx(() {
        final route = Get.currentRoute;
  // Routes where the sidebar should NOT be shown (auth/onboarding flows)
        const sidebarSuppressedRoutes = <String>{
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.signup,
        };
        final showSidebar = !sidebarSuppressedRoutes.contains(route) && width >= 800;
        // Only show the order side panel on routes that are available via the sidebar
        const allowedRoutes = <String>{
          AppRoutes.dashboard,
          AppRoutes.MENU,
          AppRoutes.DINING,
          AppRoutes.LIQUOR,
          AppRoutes.ORDERS,
          AppRoutes.EARNINGS,
          AppRoutes.PAYMENT,
          AppRoutes.DELIVERY,
          AppRoutes.CUSTOMER,
          AppRoutes.FEEDBACK,
          AppRoutes.SUPPORT,
          AppRoutes.SETTINGS,
          AppRoutes.ACCOUNT,
        };
        final suppressed = !allowedRoutes.contains(route);
        if (suppressed && ctrl.panelOpen.value) ctrl.close();
        final open = suppressed ? false : ctrl.panelOpen.value;
  final layout = Get.isRegistered<LayoutController>() ? LayoutController.to : Get.put(LayoutController(), permanent: true);
  return Stack(children: [
          // Base content row with persistent left sidebar (desktop only)
          Row(children: [
            if (showSidebar)
              Obx(() {
                final collapsed = layout.collapsed.value;
                return SizedBox(
                  width: (collapsed ? 72 : 220) + 18, // reserve space for toggle
                  child: Stack(children: [
                    Positioned.fill(
                      right: 18,
                      child: const Material(
                        type: MaterialType.transparency,
                        child: Sidebar(),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 5, // shifted slightly left for better alignment
                      child: Material(
                        color: const Color(0xFFD32F2F), // cherry red
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: layout.toggleSidebar,
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 250),
                            turns: collapsed ? 0.5 : 0,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                collapsed ? Icons.chevron_right : Icons.chevron_left,
                                size: 20,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              }),
            if (showSidebar) const SizedBox(width: 8),
            Expanded(child: child),
            if (open && isDesktop) SizedBox(width: panelWidth),
          ]),
          if (open && !isDesktop)
            Positioned.fill(
              child: GestureDetector(
                onTap: ctrl.close,
                child: Container(color: Colors.black45),
              ),
            ),

          // Overlay the side panel
          Positioned.fill(
            child: IgnorePointer(ignoring: !open, child: const SizedBox.shrink()),
          ),

          // Right side animated panel
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: panelWidth,
            child: suppressed ? const SizedBox.shrink() : OrderSidePanel(panelWidth: panelWidth, isDesktop: isDesktop),
          ),
        ]);
      });
    });
  }
}
