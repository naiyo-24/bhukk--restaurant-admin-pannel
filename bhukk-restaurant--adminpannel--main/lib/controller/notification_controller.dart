// controller/notification_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// removed scaffold messenger usage
import '../models/order_model.dart';
import 'orders/orders_controller.dart';
import '../routes/app_routes.dart';
import 'orders/order_panel_controller.dart';

/// Global controller that periodically checks for pending orders and
/// shows an accept/reject popup on top of any screen.
class NotificationController extends GetxController {
	Timer? _timer;
	DateTime _lastPopupAt = DateTime.fromMillisecondsSinceEpoch(0);
		final popupInterval = const Duration(seconds: 15);
	final _knownIds = <String>{};
	final _actedIds = <String>{}; // once accepted or rejected
		// popups now redirect to side panel; no local dialog state needed

	@override
	void onInit() {
		super.onInit();
			// watch for new orders to trigger immediate popup
			if (Get.isRegistered<OrdersController>()) {
				final oc = Get.find<OrdersController>();
				// prime known ids
				_knownIds.addAll(oc.orders.map((o) => o.id));
				ever<List<OrderModel>>(oc.orders, (list) {
					final currentIds = list.map((o) => o.id).toSet();
					final newIds = currentIds.difference(_knownIds);
					_knownIds
						..clear()
						..addAll(currentIds);

					// any new pending order not acted -> show immediately
					final newlyPending = list
							.where((o) => newIds.contains(o.id) && o.status == OrderStatus.pending && !_actedIds.contains(o.id))
							.toList()
						..sort((a, b) => b.dateTime.compareTo(a.dateTime));
										if (newlyPending.isNotEmpty && !_suppressPopups) {
												// feed the side panel queue
												final sp = Get.isRegistered<OrderSidePanelController>()
													? Get.find<OrderSidePanelController>()
													: Get.put(OrderSidePanelController(), permanent: true);
												for (final o in newlyPending) { sp.addIncoming(o); }
												_showOrderPopup(newlyPending.first);
										}

					// also mark as acted if an order transitions to non-pending
					for (final o in list) {
						if (o.status != OrderStatus.pending) {
							_actedIds.add(o.id);
						}
					}
				});
			}

			// periodic reminder every 5 minutes for any pending un-acted order
			_timer = Timer.periodic(popupInterval, (_) => _maybeSchedulePopup());

			// initial kick after app builds to avoid waiting 5 minutes
			Future.delayed(const Duration(seconds: 3), () => _initialKick());
			// also try right after first frame
			WidgetsBinding.instance.addPostFrameCallback((_) => _initialKick());
	}

	@override
	void onClose() {
		_timer?.cancel();
		super.onClose();
	}

	void _maybeSchedulePopup() {
		if (_suppressPopups) return;
		final now = DateTime.now();
		if (now.difference(_lastPopupAt) < popupInterval) return;

		final oc = Get.isRegistered<OrdersController>() ? Get.find<OrdersController>() : null;
		if (oc == null) return;

		// pick the most recent pending order not acted yet
		final pending = oc.orders.where((o) => o.status == OrderStatus.pending && !_actedIds.contains(o.id)).toList()
			..sort((a, b) => b.dateTime.compareTo(a.dateTime));
			final next = pending.isNotEmpty ? pending.first : null;
			_lastPopupAt = now;
						if (next == null) {
							_showDummyOrderPopup();
							// Only open empty state if not snoozed by user
							final sp = Get.isRegistered<OrderSidePanelController>()
								? Get.find<OrderSidePanelController>()
								: Get.put(OrderSidePanelController(), permanent: true);
							if (!sp.isSnoozed) sp.open();
						} else {
								// enqueue to side panel as well
								final sp = Get.isRegistered<OrderSidePanelController>()
									? Get.find<OrderSidePanelController>()
									: Get.put(OrderSidePanelController(), permanent: true);
								sp.addIncoming(next);
								_showOrderPopup(next);
						}
	}

	void _initialKick() {
		// Attempt to show something right after startup
		final oc = Get.isRegistered<OrdersController>() ? Get.find<OrdersController>() : null;
		final ctxReady = Get.overlayContext != null || Get.context != null;
		if (!ctxReady || oc == null || _suppressPopups) {
			// retry once a bit later if context/services not ready
			Future.delayed(const Duration(seconds: 2), () => _initialKick());
			return;
		}
		final pending = oc.orders.where((o) => o.status == OrderStatus.pending && !_actedIds.contains(o.id)).toList()
			..sort((a, b) => b.dateTime.compareTo(a.dateTime));
		_lastPopupAt = DateTime.now();
				if (pending.isNotEmpty) {
						final sp = Get.isRegistered<OrderSidePanelController>()
							? Get.find<OrderSidePanelController>()
							: Get.put(OrderSidePanelController(), permanent: true);
						for (final o in pending) { sp.addIncoming(o); }
						_showOrderPopup(pending.first);
				} else {
			_showDummyOrderPopup();
		}
	}

	bool get _suppressPopups {
		final r = Get.currentRoute;
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
		return !allowedRoutes.contains(r);
	}

		void _showOrderPopup(OrderModel order) {
			// Redirect popup into the new right-side panel.
			if (_suppressPopups) return;
			final sp = Get.isRegistered<OrderSidePanelController>()
				? Get.find<OrderSidePanelController>()
				: Get.put(OrderSidePanelController(), permanent: true);
			HapticFeedback.mediumImpact();
			SystemSound.play(SystemSoundType.click);
			sp.addIncoming(order);
		}

			void _showDummyOrderPopup() {
				// No-op: we rely on the side panel now.
			}
}

		// old snackbar banner replaced by the right-side panel

