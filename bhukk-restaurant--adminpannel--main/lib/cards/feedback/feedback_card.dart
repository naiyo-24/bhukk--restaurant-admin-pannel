// cards/feedback/feedback_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/controller/feedback/feedback_controller.dart';
import '../../../models/feedback_model.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackModel model;
  final VoidCallback? onTap;
  const FeedbackCard({super.key, required this.model, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fc = Get.find<FeedbackAdminController>(tag: 'feedback');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Obx(() {
            final meta = fc.meta[model.id];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  CircleAvatar(radius: 18, child: Text(model.customerName.isNotEmpty ? model.customerName[0].toUpperCase() : '?')),
                  const SizedBox(width: 12),
                  Expanded(child: Text(model.customerName, style: const TextStyle(fontWeight: FontWeight.w700)) ),
                  Row(children: List.generate(5, (i) => Icon(i < model.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 18))),
                  const SizedBox(width: 8),
                  if (meta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Text(meta.status, style: const TextStyle(fontSize: 12)),
                    ),
                ]),
                const SizedBox(height: 6),
                if (meta != null)
                  Text('Order: ${meta.orderId} • ${meta.orderType}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                // Tags
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (meta != null) ...meta.categories.map((c) => Chip(label: Text(c), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)),
                  Chip(label: Text(model.dishName), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                ]),
                const SizedBox(height: 6),
                // Review snippet
                Text(model.review, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // Footer with actions (responsive wrap to avoid overflow)
                Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: [
                  SizedBox(
                    width: 200,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Reply'),
                      onPressed: () async {
                        final ctl = TextEditingController();
                        final msg = await Get.dialog<String>(
                          AlertDialog(
                            title: const Text('Reply to customer'),
                            content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'Type your message')),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Get.back(result: ctl.text.trim()), child: const Text('Send')),
                            ],
                          ),
                        );
                        // Avoid using context after await without ensuring we still have a frame
                        if (msg != null && msg.isNotEmpty) {
                          fc.reply(model.id, msg);
                          Get.snackbar('Replied', 'Message sent', snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                    ),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedButton(onPressed: () { fc.markResolved(model.id); }, child: const Text('Resolve')),
                    const SizedBox(width: 8),
                    IconButton(tooltip: 'Pending', onPressed: () { fc.markPending(model.id); }, icon: const Icon(Icons.schedule_outlined)),
                    IconButton(tooltip: 'Spam', onPressed: () { fc.flagSpam(model.id); }, icon: const Icon(Icons.flag_outlined)),
                    if (meta != null)
                      Tooltip(message: meta.customerContact, child: IconButton(icon: const Icon(Icons.phone_outlined), onPressed: () {
                        Get.snackbar('Contact', meta.customerContact, snackPosition: SnackPosition.BOTTOM);
                      })),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (v) async {
                        if (v == 'escalate') fc.escalate(model.id);
                        if (v == 'coupon') {
                          final ctl = TextEditingController();
                          final val = await Get.dialog<double>(
                            AlertDialog(
                              title: const Text('Offer coupon'),
                              content: TextField(controller: ctl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '\u20b9 ')),
                              actions: [
                                TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () { final x = double.tryParse(ctl.text.trim()); if (x!=null) Get.back(result: x); }, child: const Text('Offer'))
                              ],
                            ),
                          );
                          if (val != null) fc.offerCompensation(model.id, 'Coupon', val);
                        }
                        if (v == 'assign') fc.assignTo(model.id, 'Team A');
                        if (v == 'note') {
                          final ctl = TextEditingController();
                          final note = await Get.dialog<String>(
                            AlertDialog(
                              title: const Text('Add internal note'),
                              content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'Note')),
                              actions: [
                                TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Get.back(result: ctl.text.trim()), child: const Text('Add')),
                              ],
                            ),
                          );
                          if (note != null && note.isNotEmpty) fc.addNote(model.id, note);
                        }
                        if (v == 'details' && onTap != null) onTap!();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'escalate', child: Text('Escalate')),
                        PopupMenuItem(value: 'coupon', child: Text('Offer coupon')),
                        PopupMenuItem(value: 'assign', child: Text('Assign')),
                        PopupMenuItem(value: 'note', child: Text('Add note')),
                        PopupMenuDivider(height: 8),
                        PopupMenuItem(value: 'details', child: Text('View details')),
                      ],
                    ),
                  ]),
                ]),
              ],
            );
          }),
        ),
      ),
    );
  }
}
