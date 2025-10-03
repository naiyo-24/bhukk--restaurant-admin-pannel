// screens/support/support_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../controller/common/file_picker_controller.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../controller/support/support_controller.dart';
import '../../models/support_request_model.dart';
import '../../widgets/main_scaffold.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final controller = Get.find<SupportController>();
    return MainScaffold(
      title: 'Support',
      child: LayoutBuilder(builder: (ctx, cons) {
        final width = cons.maxWidth;
        // make responsiveness flexible across devices: small phones <600, tablets 600-1200, desktop >1200
        final isSmall = width < 600;
        final isMedium = width >= 600 && width < 1200;
        final isLarge = width >= 1200;
        // choose padding per size class
        final pad = isSmall ? 12.0 : (isMedium ? 16.0 : 24.0);
        return Padding(
          padding: EdgeInsets.all(pad),
          child: isSmall ? _mobileLayout(context, controller) : _desktopLayout(context, controller, isMedium: isMedium, isLarge: isLarge),
        );
      }),
    );
  }

  Widget _mobileLayout(BuildContext context, SupportController controller) {
  // include bottom padding for safe area + keyboard (viewInsets) so buttons won't overflow
  final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 24;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding, left: 12, right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(context),
          const SizedBox(height: 12),
          _formCard(context, controller),
          const SizedBox(height: 18),
          _quickContactRow(context),
          const SizedBox(height: 18),
          _ticketsList(context, controller),
          SizedBox(height: bottomPadding + 8),
        ]),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, SupportController controller, {required bool isMedium, required bool isLarge}) {
    // adjust column proportions based on available width
    final leftFlex = isLarge ? 7 : (isMedium ? 6 : 6);
    final rightFlex = isLarge ? 5 : (isMedium ? 5 : 5);
  final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 24;
    return Row(children: [
      Expanded(
        flex: leftFlex,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _header(context),
            const SizedBox(height: 12),
            _formCard(context, controller),
            const SizedBox(height: 12),
            _quickContactRow(context),
          ]),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(flex: rightFlex, child: SingleChildScrollView(child: _ticketsList(context, controller))),
    ]);
  }

  Widget _header(BuildContext context) {
    return Text('Get help from our support team', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _formCard(BuildContext context, SupportController controller) {
    final formKey = GlobalKey<FormState>();
    final fullName = ''.obs;
    final email = ''.obs;
    final category = SupportCategory.general.obs;
    final description = ''.obs;
    final attachments = <String>[].obs;

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      await controller.createAndAdd(
        fullName: fullName.value,
        email: email.value,
        category: category.value,
        description: description.value,
        attachments: attachments.toList(),
      );
      // clear
      fullName.value = '';
      email.value = '';
      description.value = '';
      attachments.clear();
      Get.snackbar('Submitted', 'Your support request was submitted', snackPosition: SnackPosition.BOTTOM);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Support', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Full name
              Obx(() {
                return TextFormField(
                  initialValue: fullName.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Full name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => fullName.value = v,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
                );
              }),

              const SizedBox(height: 12),

              // Email
              Obx(() {
                return TextFormField(
                  initialValue: email.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => email.value = v,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Please enter email';
                    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+").hasMatch(s)) return 'Enter a valid email';
                    return null;
                  },
                );
              }),

              const SizedBox(height: 12),

              // Category
              Obx(() {
                return DropdownButtonFormField<SupportCategory>(
                  initialValue: category.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: SupportCategory.bug, child: Text('Bug')),
                    DropdownMenuItem(value: SupportCategory.billing, child: Text('Billing')),
                    DropdownMenuItem(value: SupportCategory.general, child: Text('General Query')),
                    DropdownMenuItem(value: SupportCategory.feature, child: Text('Feature Request')),
                  ],
                  onChanged: (v) => category.value = v ?? SupportCategory.general,
                );
              }),

              const SizedBox(height: 12),

              // Description
              Obx(() {
                return TextFormField(
                  initialValue: description.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.description),
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 6,
                  onChanged: (v) => description.value = v,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Please describe the issue' : null,
                );
              }),

              const SizedBox(height: 12),

              // Attachments stub
              Obx(() {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ...attachments.map((p) => _attachmentThumbnailTile(p, onDelete: () => attachments.remove(p))),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (!Get.isRegistered<FilePickerController>()) Get.put(FilePickerController());
                          final files = await FilePickerController.to.pickImages();
                          if (files == null) return;
                          for (final xf in files) {
                            if (xf.path.isNotEmpty && !attachments.contains(xf.path)) attachments.add(xf.path);
                          }
                        },
                        icon: const Icon(Icons.attachment),
                        label: const Text('Attach Screenshot'),
                      ),
                    ),
                  ]),
                ]);
              }),

              const SizedBox(height: 14),

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: controller.isSubmitting.value ? null : submit,
                    icon: controller.isSubmitting.value
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(controller.isSubmitting.value ? 'Submitting...' : 'Submit'),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentThumbnailTile(String path, {required VoidCallback onDelete}) {
    Widget thumb = Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
      child: const Icon(Icons.image, size: 32, color: Colors.grey),
    );
    if (!kIsWeb) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          thumb = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f, width: 80, height: 56, fit: BoxFit.cover));
        }
      } catch (_) {
        // fall back
      }
    }
    return Stack(children: [
      thumb,
      Positioned(
        right: -6,
        top: -6,
        child: IconButton(
          tooltip: 'Remove',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
          onPressed: onDelete,
        ),
      ),
    ]);
  }

  Widget _quickContactRow(BuildContext context) {
    // make buttons adaptive: on narrow screens they should expand, on wide screens they can wrap
    return LayoutBuilder(builder: (ctx, cons) {
      final isNarrow = cons.maxWidth < 600;
      final buttonStyle = ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48));
      if (isNarrow) {
        return Row(children: [
          Expanded(child: ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.redAccent)), onPressed: () => _launchDialer(), icon: const Icon(Icons.phone), label: const Text('Call'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.indigo)), onPressed: () => _launchEmail(), icon: const Icon(Icons.email), label: const Text('Email'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.teal)), onPressed: () => Get.snackbar('Live Chat', 'Chat is not implemented in this demo.'), icon: const Icon(Icons.chat), label: const Text('Chat'))),
        ]);
      }
      return Wrap(spacing: 12, runSpacing: 8, children: [
        ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.redAccent)), onPressed: () => _launchDialer(), icon: const Icon(Icons.phone), label: const Text('Call Support')),
        ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.indigo)), onPressed: () => _launchEmail(), icon: const Icon(Icons.email), label: const Text('Email Support')),
        ElevatedButton.icon(style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.teal)), onPressed: () => Get.snackbar('Live Chat', 'Chat is not implemented in this demo.'), icon: const Icon(Icons.chat), label: const Text('Live Chat')),
      ]);
    });
  }

  static Future<void> _launchDialer() async {
    const number = '+18001234567';
    final uri = 'tel:$number';
    try {
      await launchUrlString(uri);
    } catch (_) {
      Get.snackbar('Dialer', 'Could not open dialer', snackPosition: SnackPosition.BOTTOM);
    }
  }

  static Future<void> _launchEmail() async {
    final mail = Uri.encodeComponent('support@yourdomain.com');
    final subject = Uri.encodeComponent('Support request');
    final uri = 'mailto:$mail?subject=$subject';
    try {
      await launchUrlString(uri);
    } catch (_) {
      Get.snackbar('Email', 'Could not open email client', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _ticketsList(BuildContext context, SupportController controller) {
    return Obx(() {
      final list = controller.supportRequests;
      if (list.isEmpty) return const Center(child: Text('No tickets yet'));
      return ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final t = list[i];
          return GestureDetector(
            onTap: () => _openDetail(context, controller, t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [
                    _categoryBadge(t.category),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('#${t.id.substring(0, 8)} - ${t.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ])),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(t.formattedDate(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      _statusChip(t.status),
                    ])
                  ]),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _categoryBadge(SupportCategory c) {
    final map = {
      SupportCategory.bug: ['Bug', Colors.red.shade100, Colors.red],
      SupportCategory.billing: ['Billing', Colors.purple.shade100, Colors.purple],
      SupportCategory.general: ['General', Colors.blue.shade100, Colors.blue],
      SupportCategory.feature: ['Feature', Colors.green.shade100, Colors.green],
    };
    final info = map[c]!;
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: info[1] as Color, borderRadius: BorderRadius.circular(8)), child: Text(info[0] as String, style: TextStyle(color: info[2] as Color, fontWeight: FontWeight.w700)));
  }

  Widget _statusChip(SupportStatus s) {
    switch (s) {
      case SupportStatus.open:
        return Chip(label: const Text('Open'), backgroundColor: Colors.orange.shade100);
      case SupportStatus.inProgress:
        return Chip(label: const Text('In Progress'), backgroundColor: Colors.blue.shade100);
      case SupportStatus.resolved:
        return Chip(label: const Text('Resolved'), backgroundColor: Colors.green.shade100);
    }
  }

  void _openDetail(BuildContext context, SupportController controller, SupportRequest t) {
    Get.dialog(Dialog(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('#${t.id} - ${t.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('Category: ${t.category.name}'), const SizedBox(height: 8), Text('Submitted: ${t.formattedDate()}'), const SizedBox(height: 12), Text(t.description), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Get.back(), child: const Text('Close')), ElevatedButton(onPressed: () { controller.updateStatus(t.id, SupportStatus.resolved); Get.back(); }, child: const Text('Mark resolved'))])]))));
  }
}
