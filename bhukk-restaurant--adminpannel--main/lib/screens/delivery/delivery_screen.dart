// screens/delivery/delivery_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/delivery/delivery_controller.dart';
import '../../models/delivery_partner_model.dart';
import '../../routes/app_routes.dart';

class DeliveryScreen extends StatelessWidget {
  DeliveryScreen({super.key});

  final DeliveryController controller = Get.put(DeliveryController());

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Delivery',
      child: LayoutBuilder(builder: (ctx, cons) {
        final isSmall = cons.maxWidth < 1100;
        if (isSmall) {
          // mobile/tablet keeps its original internal scrolling behavior
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.DRIVER_HISTORY),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ),
              _metricsGrid(isSmall: true),
              const SizedBox(height: 14),
              Expanded(child: _mobile()),
            ]),
          );
        }

        // Desktop / large: wrap whole content in a scroll view so no overflow.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.DRIVER_HISTORY),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ),
              _metricsGrid(isSmall: false),
              const SizedBox(height: 18),
        Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          // Partner panel with fixed height list to avoid overflow
          Expanded(flex: 5, child: _partnersSection(desktop: true)),
                  const SizedBox(width: 18),
                  // Right side stack: Active + Past
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Larger active assignments card (height aligned with partner panel)
                        SizedBox(height: 618, child: _activeAssignmentsCard(fillHeight: true)),
                        // Past assignments moved below full-width
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Full-width past assignments section (taller + scrollable internally)
              LayoutBuilder(builder: (c, cs) {
                final h = MediaQuery.of(c).size.height * 0.75; // occupy ~75% of viewport height
                return SizedBox(
                  height: h < 500 ? 500 : h, // minimum sensible height
                  child: _pastAssignmentsCard(scrollable: true),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _mobile() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            children: [
              _partnersSection(),
              const SizedBox(height: 12),
              _activeAssignmentsCard(isMobile: true),
              const SizedBox(height: 12),
              _pastAssignmentsCard(isMobile: true),
            ],
          ),
        ),
      ),
    ]);
  }

  // _desktop removed: desktop layout handled directly in build with SingleChildScrollView.

  Widget _metricsGrid({required bool isSmall}) {
    return Obx(() {
      final metrics = [
        _interactiveMetric(
          label: 'Partners',
          value: controller.totalPartners.toString(),
          icon: Icons.people,
          color: Colors.indigo,
          onTap: () => _showPartnerListPopup('All Partners', controller.partners.toList()),
        ),
        _interactiveMetric(
          label: 'Online',
          value: controller.onlinePartners.toString(),
          icon: Icons.wifi,
          color: Colors.green,
          onTap: () => _showPartnerListPopup('Online Partners', controller.onlinePartnerList),
        ),
        _interactiveMetric(
          label: 'Offline',
          value: controller.offlinePartners.toString(),
          icon: Icons.wifi_off,
          color: Colors.grey,
          onTap: () => _showPartnerListPopup('Offline Partners', controller.offlinePartnerList),
        ),
        _interactiveMetric(
          label: 'Suspended',
          value: controller.suspendedPartners.toString(),
          icon: Icons.block,
          color: Colors.redAccent,
          onTap: () => _showPartnerListPopup('Suspended Partners', controller.suspendedPartnerList),
        ),
        _interactiveMetric(
          label: 'Orders Today',
          value: controller.todayOrders.toString(),
          icon: Icons.receipt_long,
          color: Colors.blue,
          onTap: () => _showAssignmentsPopup('Today\'s Orders', controller.todayAssignments),
        ),
        _interactiveMetric(
          label: 'Delivered Today',
          value: controller.deliveredToday.toString(),
          icon: Icons.done_all,
          color: Colors.teal,
          onTap: () => _showAssignmentsPopup('Delivered Today', controller.deliveredTodayAssignments),
        ),
        _interactiveMetric(
          label: 'Cancelled Today',
          value: controller.cancelledToday.toString(),
          icon: Icons.cancel,
          color: Colors.deepOrange,
          onTap: () => _showAssignmentsPopup('Cancelled Today', controller.cancelledTodayAssignments),
        ),
        _interactiveMetric(
          label: 'Available Now',
          value: controller.availablePartnersForNew.length.toString(),
          icon: Icons.assignment_turned_in_outlined,
          color: Colors.blueGrey,
          onTap: () => _showPartnerListPopup('Available Partners', controller.availablePartnersForNew),
        ),
        _interactiveMetric(
          label: 'Delivering',
          value: controller.deliveringPartners.length.toString(),
          icon: Icons.delivery_dining,
          color: Colors.deepPurple,
          onTap: () => _showPartnerListPopup('Currently Delivering', controller.deliveringPartners),
        ),
      ];
      final crossAxisCount = isSmall ? 2 : 4;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: metrics,
      );
    });
  }

  Widget _interactiveMetric({required String label, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: _metricTile(label: label, value: value, icon: icon, color: color),
    );
  }

  void _showPartnerListPopup(String title, List<DeliveryPartnerModel> list) {
    if (list.isEmpty) {
      Get.snackbar(title, 'No partners in this state', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.dialog(AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        height: 420,
        child: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = list[i];
            return ListTile(
              leading: CircleAvatar(backgroundColor: p.isOnline ? Colors.green.shade100 : Colors.grey.shade300, child: Icon(Icons.person, color: p.isOnline ? Colors.green : Colors.grey)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.vehicleType ?? '-'} • Rating ${p.rating.toStringAsFixed(1)}'),
              trailing: p.isOnline ? const Icon(Icons.circle, color: Colors.green, size: 12) : const SizedBox(width: 12),
              onTap: () { Get.back(); _showPartnerDetails(p); },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Close'))],
    ));
  }

  void _showAssignmentsPopup(String title, List<DeliveryAssignment> list) {
    if (list.isEmpty) {
      Get.snackbar(title, 'No assignments', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.dialog(AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        height: 420,
        child: ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final a = list[i];
            return ListTile(
              title: Text(a.orderId, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.pickup} → ${a.drop}'),
              trailing: Text(a.statusLabel, style: const TextStyle(fontSize: 12)),
              onTap: () { Get.back(); _showAssignmentDetails(a); },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Close'))],
    ));
  }

  Widget _metricTile({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
  CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.85))),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      ]),
    );
  }

  Widget _partnersSection({bool desktop = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Delivery Partners', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Obx(() => Switch(
                value: controller.showOnlyOnline.value,
                onChanged: (_) => controller.toggleFilterOnline(),
                activeTrackColor: Colors.green,
              )),
            const SizedBox(width: 4),
            const Text('Online Only'),
          ]),
          const SizedBox(height: 10),
          // Search bar
          TextField(
            onChanged: controller.setPartnerSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, vehicle... ',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.blue.shade400, width: 1.2)),
              suffixIcon: Obx(() => controller.partnerSearch.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.setPartnerSearch(''),
                    )),
            ),
          ),
          const SizedBox(height: 12),
          if (desktop)
            // fixed height scrollable list to prevent inside-item overflow
            SizedBox(height: 480, child: Obx(() => _partnerList(scrollable: true)))
          else
            Obx(() => _partnerList(scrollable: false)),
        ]),
      ),
    );
  }

  Widget _partnerList({required bool scrollable}) {
    final list = controller.searchedPartners;
    if (list.isEmpty) return const Text('No partners');
    return ListView.builder(
      physics: scrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !scrollable,
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final p = list[i];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showPartnerDetails(p),
              onLongPress: () => _partnerLongPress(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 26, backgroundColor: p.isSuspended ? Colors.red.shade100 : Colors.blue.shade100, child: Icon(p.isSuspended ? Icons.block : Icons.person, color: p.isSuspended ? Colors.red : Colors.blue)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${p.vehicleType ?? '-'} • ${p.vehicleNumber ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Rating: ${p.rating.toStringAsFixed(1)}  |  Completed: ${p.completedDeliveries}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.isSuspended
                            ? Colors.red.shade50
                            : p.isOnline
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(p.isSuspended ? 'Suspended' : p.isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(onPressed: () => _callNumber(p.phone), icon: const Icon(Icons.phone, size: 18), padding: EdgeInsets.zero),
                      IconButton(onPressed: () => Get.toNamed(AppRoutes.DELIVERY_CHAT, parameters: {'partnerId': p.id, 'partnerName': p.name}), icon: const Icon(Icons.chat, size: 18), padding: EdgeInsets.zero),
                    ])
                  ])
                ]),
              ),
            ),
        );
      },
    );
  }

  void _partnerLongPress(DeliveryPartnerModel p) {
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.visibility), title: const Text('View Details'), onTap: () { Get.back(); _showPartnerDetails(p); }),
          if (!p.isSuspended)
            ListTile(leading: const Icon(Icons.block, color: Colors.red), title: const Text('Suspend'), onTap: () { controller.suspendPartner(p.id, suspend: true); Get.back(); }),
          if (p.isSuspended)
            ListTile(leading: const Icon(Icons.lock_open, color: Colors.green), title: const Text('Unsuspend'), onTap: () { controller.suspendPartner(p.id, suspend: false); Get.back(); }),
          ListTile(leading: const Icon(Icons.close), title: const Text('Close'), onTap: () => Get.back()),
        ]),
      ),
    ));
  }

  void _showPartnerDetails(DeliveryPartnerModel p) {
    Get.dialog(AlertDialog(
      title: Text(p.name),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _detailRow('Phone', p.phone),
            if (p.email != null) _detailRow('Email', p.email!),
            _detailRow('Vehicle', '${p.vehicleType ?? '-'} / ${p.vehicleNumber ?? '-'}'),
            _detailRow('Rating', p.rating.toStringAsFixed(1)),
            _detailRow('Completed', p.completedDeliveries.toString()),
            _detailRow('Cancellations', p.cancellations.toString()),
            const Divider(),
            const Text('Recent Assignments', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Obx(() {
              final all = [...controller.activeAssignments, ...controller.pastAssignments];
              final related = all.where((a) => a.orderId.hashCode % 4 == p.id.hashCode % 4).take(5).toList(); // mock relation
              if (related.isEmpty) return const Text('None');
              return Column(children: related.map((a) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(a.orderId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${a.pickup} → ${a.drop}', style: const TextStyle(fontSize: 12)),
                trailing: Text(a.statusLabel, style: const TextStyle(fontSize: 11)),
                onTap: () { Get.back(); _showAssignmentDetails(a); },
              )).toList());
            })
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Close')),
      ],
    ));
  }

  Widget _detailRow(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(v))]),
  );

  void _showAssignmentDetails(DeliveryAssignment a) {
    Get.dialog(AlertDialog(
      title: Text('Order ${a.orderId}'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _detailRow('Pickup', a.pickup),
            _detailRow('Drop', a.drop),
            _detailRow('Status', a.statusLabel),
            if (a.cancelledBy != null) _detailRow('Cancelled By', a.cancelledBy!),
            if (a.cancelReason != null) _detailRow('Reason', a.cancelReason!),
            const Divider(),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (a.items.isEmpty) const Text('No items'),
            if (a.items.isNotEmpty)
              Column(children: a.items.map((it) => Row(children: [
                    Expanded(child: Text(it.name)),
                    Text('x${it.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])).toList()),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Close'))],
    ));
  }

  Future<void> _callNumber(String phone) async {
    // sanitize phone
    final sanitized = phone.replaceAll(RegExp(r"\s+"), '');
    try {
      if (Platform.isAndroid) {
        // request CALL_PHONE permission first
        final status = await Permission.phone.status;
        if (!status.isGranted) {
          final res = await Permission.phone.request();
          if (!res.isGranted) {
            Get.snackbar('Permission', 'Call permission denied');
            return;
          }
        }
        // place direct call
        final didCall = await FlutterPhoneDirectCaller.callNumber(sanitized);
        if (didCall == null || didCall == false) {
          // fallback: try to open dialer using tel: if plugin failed
          final uri = Uri(scheme: 'tel', path: sanitized);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            await Clipboard.setData(ClipboardData(text: sanitized));
            Get.snackbar('Call failed', 'Could not call $sanitized (copied to clipboard)');
          }
        }
        return;
      }

      // Non-Android: try launching tel: to open dialer, otherwise copy number
      final uri = Uri(scheme: 'tel', path: sanitized);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await Clipboard.setData(ClipboardData(text: sanitized));
        Get.snackbar('Copied', 'Phone number copied to clipboard');
      }
    } catch (e, st) {
      // fallback: copy to clipboard and show the real error so we can debug
      await Clipboard.setData(ClipboardData(text: sanitized));
      final msg = e is Exception ? e.toString() : '$e';
      Get.snackbar('Call error', '$msg — number copied to clipboard');
      // also print stack for developer debugging
      // ignore: avoid_print
      print('[_callNumber] exception: $e\n$st');
    }
  }

  // _sendSms removed: in-app chat is used instead (see delivery_chat_screen.dart)

  // Removed actions card per request

  Widget _activeAssignmentsCard({bool isMobile = false, bool fillHeight = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,16,16,12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Active Assignments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            if (!isMobile)
              IconButton(onPressed: () => controller.refresh(), icon: const Icon(Icons.refresh))
          ]),
          const SizedBox(height: 14),
          if (fillHeight)
            Expanded(
              child: Obx(() {
                final items = controller.activeAssignments;
                if (items.isEmpty) return const Center(child: Text('No active assignments'));
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => GestureDetector(onTap: () => _openAssignmentActions(items[i]), child: _assignmentTile(items[i])),
                );
              }),
            )
          else
            Obx(() {
              final items = controller.activeAssignments;
              if (items.isEmpty) return const Text('No active assignments');
              return Column(
                children: items
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(onTap: () => _openAssignmentActions(a), child: _assignmentTile(a)),
                        ))
                    .toList(),
              );
            })
        ]),
      ),
    );
  }

  Widget _assignmentTile(DeliveryAssignment a) {
    Color color;
    switch (a.status) {
      case AssignmentStatus.completed:
        color = Colors.green.shade50;
        break;
      case AssignmentStatus.inProgress:
        color = Colors.orange.shade50;
        break;
      case AssignmentStatus.cancelled:
        color = Colors.red.shade50;
        break;
      default:
        color = Colors.grey.shade50;
    }

    return Container(
      decoration: BoxDecoration(
  gradient: LinearGradient(colors: [color.withValues(alpha: 0.9), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,6))],
  border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16,14,16,14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.local_shipping, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.orderId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                  child: Text(a.statusLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                )
              ]),
              const SizedBox(height: 10),
              Wrap(runSpacing: 4, spacing: 12, children: [
                _infoChip(Icons.storefront, a.pickup, Colors.indigo),
                _infoChip(Icons.location_on, a.drop, Colors.deepPurple),
              ]),
              if (a.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: a.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final it = a.items[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.black12)),
                        child: Text('${it.name} x${it.quantity}', style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ]
            ]),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Reassign',
                onPressed: () => controller.reassign(a.id),
                icon: const Icon(Icons.swap_horiz),
                color: Colors.orange,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: color))]),
  );

  void _openAssignmentActions(DeliveryAssignment a) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Wrap(children: [
            ListTile(leading: const Icon(Icons.swap_horiz), title: const Text('Reassign'), onTap: () { controller.reassign(a.id); Get.back(); }),
            ListTile(leading: const Icon(Icons.check_circle), title: const Text('Mark Completed'), onTap: () { controller.completeAssignment(a.id); Get.back(); }),
            ListTile(leading: const Icon(Icons.cancel), title: const Text('Cancel Assignment'), onTap: () { controller.cancelAssignment(a.id); Get.back(); }),
            ListTile(leading: const Icon(Icons.close), title: const Text('Close'), onTap: () => Get.back()),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _pastAssignmentsCard({bool isMobile = false, bool scrollable = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Past Assignments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            PopupMenuButton<String>(onSelected: (v) {
              if (v == 'newest') controller.sortPast(newestFirst: true);
              if (v == 'oldest') controller.sortPast(newestFirst: false);
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'newest', child: Text('Newest')), PopupMenuItem(value: 'oldest', child: Text('Oldest'))])
          ]),
          const SizedBox(height: 12),
          Obx(() {
            final items = controller.pastAssignments;
            if (items.isEmpty) return const Text('No past assignments');
            if (scrollable) {
              return Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(items[i].orderId),
                    subtitle: Text('${items[i].pickup} → ${items[i].drop}'),
                    trailing: Text(items[i].statusLabel),
                    onTap: () => _showAssignmentDetails(items[i]),
                  ),
                ),
              );
            }
            return Column(children: items.map((a) => ListTile(
                  title: Text(a.orderId),
                  subtitle: Text('${a.pickup} → ${a.drop}'),
                  trailing: Text(a.statusLabel),
                  onTap: () => _showAssignmentDetails(a),
                )).toList());
          })
        ]),
      ),
    );
  }
}
