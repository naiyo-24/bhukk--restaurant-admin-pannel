// screens/account/account_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/account/account_controller.dart';
import '../../models/account_model.dart';
import '../../routes/app_routes.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final AccountController controller = Get.find<AccountController>();

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Account',
      child: LayoutBuilder(builder: (ctx, cons) {
        final width = cons.maxWidth;
        final isSmall = width < 800;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            final acct = controller.account.value;
    return isSmall ? _mobile(ctx, acct) : _desktop(ctx, acct, cons.maxWidth);
          }),
        );
      }),
    );
  }

  Widget _mobile(BuildContext context, AccountModel acct) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _profileCard(acct),
        const SizedBox(height: 12),
        _businessInfoCard(acct),
        const SizedBox(height: 12),
    _documentsCard(context),
      ]),
    );
  }

  Widget _desktop(BuildContext context, AccountModel acct, double width) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(children: [
            _profileCard(acct),
            const SizedBox(height: 12),
            _businessInfoCard(acct),
          ]),
        ),
      ),
      const SizedBox(width: 18),
      // Right pane scroll with Documents, Transactions, and Payouts
      Expanded(
        flex: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _documentsCard(context),
              const SizedBox(height: 12),
              _payoutsCard(),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _profileCard(AccountModel acct) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _logo(acct.logoPath),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(acct.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(acct.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(acct.phone, style: const TextStyle(color: Colors.grey)),
            ])),
            ElevatedButton.icon(onPressed: () => Get.toNamed('/edit-account'), icon: const Icon(Icons.edit), label: const Text('Edit'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
          ]),
          const Divider(height: 20),
          Text('Profile Details', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Address: ${acct.address}'),
          const SizedBox(height: 6),
          Text('Operating hours: ${acct.operatingHours}'),
        ]),
      ),
    );
  }

  Widget _businessInfoCard(AccountModel acct) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Business Info', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _infoRow('Name', acct.name),
          const Divider(),
          _infoRow('Address', acct.address),
          const Divider(),
          _infoRow('Phone', acct.phone),
          const Divider(),
          _infoRow('Email', acct.email),
          const Divider(),
          _infoRow('Hours', acct.operatingHours),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text('Bank & Settlement', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _infoRow('Bank', acct.bankName.isEmpty ? '—' : acct.bankName),
          _infoRow('Account', acct.bankAccountNo.isEmpty ? '—' : '•••• ${acct.bankAccountNo.length >= 4 ? acct.bankAccountNo.substring(acct.bankAccountNo.length - 4) : acct.bankAccountNo}'),
          _infoRow('IFSC', acct.bankIfsc.isEmpty ? '—' : acct.bankIfsc),
          _infoRow('UPI', (acct.upiId ?? '').isEmpty ? '—' : acct.upiId!),
          _infoRow('Cycle', acct.settlementCycle.name.toUpperCase()),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(onPressed: () => Get.toNamed(AppRoutes.TRANSACTIONS), icon: const Icon(Icons.history), label: const Text('Transactions')),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final path = await controller.exportTransactionsCsv();
                  Get.snackbar('Transactions exported', path, snackPosition: SnackPosition.BOTTOM);
                } catch (e) {
                  Get.snackbar('Export failed', '$e', snackPosition: SnackPosition.BOTTOM);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Statements'),
            ),
          ])
        ]),
      ),
    );
  }

  Widget _documentsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Documents', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Obx(() {
            final missing = controller.documents.any((d) => d.status != DocumentStatus.verified);
            if (!missing) return const SizedBox.shrink();
            return LayoutBuilder(builder: (c, cons) {
              final narrow = cons.maxWidth < 480;
              final content = [
                const Icon(Icons.assignment_late, color: Colors.amber),
                const SizedBox(width: 8),
                const Expanded(child: Text('Some documents are missing or not verified. You can apply to build required documents.', softWrap: true)),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: () => _openApplyDialog(context), icon: const Icon(Icons.description), label: const Text('Apply for Document')),
              ];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                child: narrow
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.assignment_late, color: Colors.amber), SizedBox(width: 8), Text('Action required')]),
                        const SizedBox(height: 8),
                        const Text('Some documents are missing or not verified. You can apply to build required documents.', softWrap: true),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(onPressed: () => _openApplyDialog(context), icon: const Icon(Icons.description), label: const Text('Apply for Document')),
                        ),
                      ])
                    : Row(children: content),
              );
            });
          }),
          Obx(() {
            final docs = controller.documents;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _documentRow(context, docs[i]),
            );
          }),
        ]),
      ),
    );
  }

  void _openApplyDialog(BuildContext context, {String? initialDoc}) {
    showDialog(context: context, builder: (ctx) => _ApplyDocumentDialog(controller: controller, initialDoc: initialDoc));
  }

  Widget _documentRow(BuildContext context, DocumentModel d) {
    Color bg;
    String label;
    switch (d.status) {
      case DocumentStatus.verified:
        bg = Colors.green.shade100;
        label = 'Verified';
        break;
      case DocumentStatus.pending:
        bg = Colors.amber.shade100;
        label = 'Pending';
        break;
      case DocumentStatus.rejected:
        bg = Colors.red.shade100;
        label = 'Rejected';
        break;
    }
    final canApply = d.status != DocumentStatus.verified;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(label)),
        const SizedBox(width: 8),
        if (canApply)
          TextButton.icon(
            onPressed: () => _openApplyDialog(context, initialDoc: d.name),
            icon: const Icon(Icons.description, size: 18),
            label: const Text('Apply'),
          ),
      ]),
    );
  }

  Widget _logo(String? path) {
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 72, height: 72, color: Colors.grey.shade200, child: const Icon(Icons.storefront, size: 36, color: Colors.grey)));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(width: 12), Expanded(child: Text(value))]),
    );
  }

  // _transactionsCard removed (migrated to TransactionsScreen)

  Widget _payoutsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payouts & Settlements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Obx(() {
            final pend = controller.pendingPayouts;
            final all = controller.payouts;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pend.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                  child: Text('Pending Payouts: ${pend.length} • Total ₹${pend.fold<double>(0, (s, p) => s + p.amount).toStringAsFixed(2)}'),
                ),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await controller.generateNextPayout();
                    } catch (e) {
                      Get.snackbar('Payouts', 'Failed: $e', snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Generate Next Payout'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final path = await controller.exportPayoutsCsv();
                      Get.snackbar('Payouts exported', path, snackPosition: SnackPosition.BOTTOM);
                    } catch (e) {
                      Get.snackbar('Export failed', '$e', snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = all[i];
                    return ListTile(
                      dense: true,
                      title: Text('₹${p.amount.toStringAsFixed(2)} — ${p.status.toUpperCase()}'),
                      subtitle: Text('Ref ${p.reference} • ${p.scheduledOn.toLocal().toString().split(' ').first}'),
                      trailing: IconButton(
                        onPressed: () async {
                          try {
                            final path = await controller.exportPayoutsCsv(list: [p], fileName: 'payout_${p.reference}.csv');
                            Get.snackbar('Statement saved', path, snackPosition: SnackPosition.BOTTOM);
                          } catch (e) {
                            Get.snackbar('Statement', 'Export failed: $e', snackPosition: SnackPosition.BOTTOM);
                          }
                        },
                        icon: const Icon(Icons.receipt_long),
                      ),
                      onLongPress: () async {
                        if (p.status != 'paid') {
                          await controller.markPayoutPaid(p.id);
                        }
                      },
                    );
                  },
                ),
              )
            ]);
          })
        ]),
      ),
    );
  }
}

class _ApplyDocumentDialog extends StatefulWidget {
  final AccountController controller;
  final String? initialDoc;
  const _ApplyDocumentDialog({required this.controller, this.initialDoc});

  @override
  State<_ApplyDocumentDialog> createState() => _ApplyDocumentDialogState();
}

class _ApplyDocumentDialogState extends State<_ApplyDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  String doc = 'GST Certificate';
  String name = '';
  String email = '';
  String phone = '';
  String notes = '';

  @override
  void initState() {
    super.initState();
    final acct = widget.controller.account.value;
    name = acct.name;
    email = acct.email;
    phone = acct.phone;
  }

  @override
  Widget build(BuildContext context) {
    final missingDocs = widget.controller.documents.where((d) => d.status != DocumentStatus.verified).map((d) => d.name).toList();
    final options = missingDocs.isEmpty ? ['Other'] : missingDocs;
    if (widget.initialDoc != null) {
      // Prefer initial if present; ensure it's part of options list
      if (!options.contains(widget.initialDoc)) {
        options.insert(0, widget.initialDoc!);
      }
      doc = widget.initialDoc!;
    }
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apply to Build Document', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: options.contains(doc) ? doc : options.first,
                    items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => setState(() => doc = v ?? options.first),
                    decoration: const InputDecoration(labelText: 'Document'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Applicant Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(v)) ? 'Invalid email' : null,
                    onChanged: (v) => email = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 7) ? 'Invalid phone' : null,
                    onChanged: (v) => phone = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 3,
                    onChanged: (v) => notes = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          await widget.controller.applyForDocument(documentName: doc, applicantName: name, email: email, phone: phone, notes: notes);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Submit Application'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
